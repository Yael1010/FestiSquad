from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.domains.finances.db_models import Expense, ExpenseParticipant, SquadMember
from app.domains.finances.db_schemas import BalanceOutput, ExpenseInput
from app.domains.finances.exact_money import suggest_transfers


class DatabaseFinanceService:
    """Requiere actor_id obtenido de un JWT verificado, nunca del body.

    Usa sesión sin transacción activa. Commit/rollback terminan antes del return.
    No sustituye automáticamente el singleton en memoria del repositorio.
    """

    def create_expense(self, db: Session, payload: ExpenseInput, actor_id: UUID) -> UUID:
        # Revalida para proteger también llamadas internas con modelos modificados.
        payload = ExpenseInput.model_validate(payload.model_dump())
        expense_id = uuid4()
        with db.begin():
            members = set(db.scalars(select(SquadMember.user_id).where(
                SquadMember.squad_id == payload.squad_id)))
            if actor_id not in members:
                raise PermissionError('El actor no pertenece al squad')
            required = {payload.paid_by_user_id, *(p.user_id for p in payload.participants)}
            if not required <= members:
                raise ValueError('Pagador y participantes deben pertenecer al squad')
            db.add(Expense(id=expense_id, squad_id=payload.squad_id,
                           paid_by_user_id=payload.paid_by_user_id,
                           description=payload.description, amount=payload.amount))
            db.flush()  # FK del ticket disponible antes de insertar las cuotas.
            db.add_all([ExpenseParticipant(expense_id=expense_id, user_id=p.user_id,
                                          share_amount=p.share_amount) for p in payload.participants])
        return expense_id

    def balances_for_squad(self, db: Session, squad_id: UUID, actor_id: UUID) -> BalanceOutput:
        with db.begin():
            member = db.scalar(select(SquadMember.user_id).where(
                SquadMember.squad_id == squad_id, SquadMember.user_id == actor_id))
            if member is None:
                raise PermissionError('El actor no pertenece al squad')
            rows = db.execute(text('''
                SELECT user_id, balance FROM dbo.fund_balances
                WHERE squad_id = :squad_id
            '''), {'squad_id': str(squad_id)}).all()
            balances = {UUID(str(uid)): amount for uid, amount in rows}
            if any(not isinstance(v, Decimal) for v in balances.values()):
                raise TypeError('El driver debe devolver Decimal para los saldos')
            result = BalanceOutput(squad_id=squad_id, net_balances=balances,
                                   suggested_transfers=suggest_transfers(balances))
        return result
