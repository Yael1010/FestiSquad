from datetime import timezone
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.domains.finances.db_models import (
    Expense,
    ExpenseParticipant,
    Settlement,
    SquadMember,
)
from app.domains.finances.db_schemas import (
    BalanceOutput,
    ExpenseInput,
    ExpenseOutput,
    SettlementInput,
    SettlementOutput,
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
        balances = self._balance_map(db, squad_id)
        return BalanceOutput(
            squad_id=squad_id,
            net_balances=balances,
            suggested_transfers=suggest_transfers(balances),
        )

    def create_settlement(
        self,
        db: Session,
        payload: SettlementInput,
        actor_id: UUID,
    ) -> SettlementOutput:
        payload = SettlementInput.model_validate(payload.model_dump())
        members = self._member_ids(db, payload.squad_id)
        if actor_id not in members:
            raise PermissionError('El actor no pertenece al squad')
        if actor_id != payload.from_user_id:
            raise PermissionError('Solo quien paga puede registrar la liquidación')

        existing = db.scalar(
            select(Settlement).where(
                Settlement.client_request_id == payload.client_request_id
            )
        )
        if existing is not None:
            if (
                existing.squad_id != payload.squad_id
                or existing.from_user_id != payload.from_user_id
                or existing.to_user_id != payload.to_user_id
                or existing.amount != payload.amount
                or existing.note != payload.note
            ):
                raise ValueError('La operación repetida no coincide con el pago original')
            return self._settlement_output(existing)

        if {payload.from_user_id, payload.to_user_id} - members:
            raise ValueError('Pagador y receptor deben pertenecer al squad')

        balances = self._balance_map(db, payload.squad_id)
        debt = -balances.get(payload.from_user_id, Decimal('0.00'))
        credit = balances.get(payload.to_user_id, Decimal('0.00'))
        maximum = min(debt, credit)
        if maximum <= Decimal('0.00'):
            raise ValueError('No existe una deuda pendiente entre estos saldos')
        if payload.amount > maximum:
            raise ValueError(f'El pago no puede exceder {maximum:.2f} MXN')

        settlement = Settlement(
            id=uuid4(),
            squad_id=payload.squad_id,
            client_request_id=payload.client_request_id,
            from_user_id=payload.from_user_id,
            to_user_id=payload.to_user_id,
            amount=payload.amount,
            note=payload.note,
        )
        try:
            db.add(settlement)
            db.commit()
            db.refresh(settlement)
        except Exception:
            db.rollback()
            raise
        return self._settlement_output(settlement)

    def list_settlements(
        self,
        db: Session,
        squad_id: UUID,
        actor_id: UUID,
        *,
        limit: int = 50,
        offset: int = 0,
    ) -> list[SettlementOutput]:
        self._require_member(db, squad_id, actor_id)
        rows = db.scalars(
            select(Settlement)
            .where(Settlement.squad_id == squad_id)
            .order_by(Settlement.created_at.desc(), Settlement.id.desc())
            .offset(offset)
            .limit(limit)
        )
        return [self._settlement_output(row) for row in rows]

    def _balance_map(self, db: Session, squad_id: UUID) -> dict[UUID, Decimal]:
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
        return balances

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

    def _settlement_output(self, settlement: Settlement) -> SettlementOutput:
        created_at = settlement.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        return SettlementOutput(
            id=settlement.id,
            squad_id=settlement.squad_id,
            client_request_id=settlement.client_request_id,
            from_user_id=settlement.from_user_id,
            to_user_id=settlement.to_user_id,
            amount=settlement.amount,
            note=settlement.note,
            created_at=created_at,
        )


finance_service = DatabaseFinanceService()
