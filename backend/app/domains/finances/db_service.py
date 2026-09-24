from datetime import timezone
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.domains.finances.db_models import Expense, ExpenseParticipant, SquadMember
from app.domains.finances.db_schemas import (
    BalanceOutput,
    ExpenseInput,
    ExpenseOutput,
    ShareInput,
)
from app.domains.finances.exact_money import suggest_transfers


class DatabaseFinanceService:
    """Servicio transaccional; actor_id siempre proviene del JWT verificado."""

    def create_expense(
        self, db: Session, payload: ExpenseInput, actor_id: UUID
    ) -> ExpenseOutput:
        payload = ExpenseInput.model_validate(payload.model_dump())
        members = self._member_ids(db, payload.squad_id)
        if actor_id not in members:
            raise PermissionError('El actor no pertenece al squad')

        existing = db.scalar(
            select(Expense).where(
                Expense.client_request_id == payload.client_request_id
            )
        )
        if existing is not None:
            if existing.squad_id != payload.squad_id:
                raise ValueError('El identificador de la operación ya está en uso')
            participants = self._participants(db, [existing.id])[existing.id]
            stored_shares = {
                participant.user_id: participant.share_amount
                for participant in participants
            }
            requested_shares = {
                participant.user_id: participant.share_amount
                for participant in payload.participants
            }
            if (
                existing.paid_by_user_id != payload.paid_by_user_id
                or existing.description != payload.description
                or existing.amount != payload.amount
                or stored_shares != requested_shares
            ):
                raise ValueError('La operación repetida no coincide con el ticket original')
            return self._output(existing, participants)

        required = {
            payload.paid_by_user_id,
            *(participant.user_id for participant in payload.participants),
        }
        if not required <= members:
            raise ValueError('Pagador y participantes deben pertenecer al squad')

        expense = Expense(
            id=uuid4(),
            squad_id=payload.squad_id,
            client_request_id=payload.client_request_id,
            paid_by_user_id=payload.paid_by_user_id,
            description=payload.description,
            amount=payload.amount,
        )
        try:
            db.add(expense)
            db.flush()
            db.add_all(
                [
                    ExpenseParticipant(
                        expense_id=expense.id,
                        user_id=participant.user_id,
                        share_amount=participant.share_amount,
                    )
                    for participant in payload.participants
                ]
            )
            db.commit()
            db.refresh(expense)
        except Exception:
            db.rollback()
            raise
        return self._output(expense, payload.participants)

    def list_expenses(
        self,
        db: Session,
        squad_id: UUID,
        actor_id: UUID,
        *,
        limit: int = 50,
        offset: int = 0,
    ) -> list[ExpenseOutput]:
        self._require_member(db, squad_id, actor_id)
        expenses = list(
            db.scalars(
                select(Expense)
                .where(Expense.squad_id == squad_id)
                .order_by(Expense.created_at.desc(), Expense.id.desc())
                .offset(offset)
                .limit(limit)
            )
        )
        participants = self._participants(db, [expense.id for expense in expenses])
        return [self._output(expense, participants[expense.id]) for expense in expenses]

    def balances_for_squad(
        self, db: Session, squad_id: UUID, actor_id: UUID
    ) -> BalanceOutput:
        self._require_member(db, squad_id, actor_id)
        rows = db.execute(
            text(
                '''
                SELECT user_id, balance FROM dbo.fund_balances
                WHERE squad_id = :squad_id
                '''
            ),
            {'squad_id': str(squad_id)},
        ).all()
        balances = {UUID(str(user_id)): amount for user_id, amount in rows}
        if any(not isinstance(value, Decimal) for value in balances.values()):
            raise TypeError('El driver debe devolver Decimal para los saldos')
        return BalanceOutput(
            squad_id=squad_id,
            net_balances=balances,
            suggested_transfers=suggest_transfers(balances),
        )

    def _member_ids(self, db: Session, squad_id: UUID) -> set[UUID]:
        return set(
            db.scalars(
                select(SquadMember.user_id).where(SquadMember.squad_id == squad_id)
            )
        )

    def _require_member(self, db: Session, squad_id: UUID, actor_id: UUID) -> None:
        if actor_id not in self._member_ids(db, squad_id):
            raise PermissionError('El actor no pertenece al squad')

    def _participants(
        self, db: Session, expense_ids: list[UUID]
    ) -> dict[UUID, list[ExpenseParticipant]]:
        result: dict[UUID, list[ExpenseParticipant]] = {
            expense_id: [] for expense_id in expense_ids
        }
        if not expense_ids:
            return result
        rows = db.scalars(
            select(ExpenseParticipant)
            .where(ExpenseParticipant.expense_id.in_(expense_ids))
            .order_by(ExpenseParticipant.expense_id, ExpenseParticipant.user_id)
        )
        for participant in rows:
            result[participant.expense_id].append(participant)
        return result

    def _output(
        self,
        expense: Expense,
        participants: list[ExpenseParticipant] | list[ShareInput],
    ) -> ExpenseOutput:
        return ExpenseOutput(
            id=expense.id,
            squad_id=expense.squad_id,
            client_request_id=expense.client_request_id,
            paid_by_user_id=expense.paid_by_user_id,
            description=expense.description,
            amount=expense.amount,
            participants=[
                ShareInput(
                    user_id=participant.user_id,
                    share_amount=participant.share_amount,
                )
                for participant in participants
            ],
            created_at=expense.created_at.replace(tzinfo=timezone.utc),
        )


finance_service = DatabaseFinanceService()
