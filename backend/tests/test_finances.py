from datetime import datetime
from decimal import Decimal
from unittest.mock import MagicMock
from uuid import UUID

import pytest
from sqlalchemy.orm import Session

from app.domains.finances.db_models import Expense, ExpenseParticipant, Settlement
from app.domains.finances.db_schemas import ExpenseInput, SettlementInput
from app.domains.finances.db_service import DatabaseFinanceService
from app.domains.finances.exact_money import suggest_transfers
from app.domains.squads.db_models import SquadMember

A, B, C = (UUID(int=value) for value in (1, 2, 3))


def expense_input() -> ExpenseInput:
    return ExpenseInput(
        squad_id=A,
        client_request_id=UUID(int=99),
        paid_by_user_id=A,
        description='Taxi',
        amount='300.00',
        participants=[
            {'user_id': A, 'share_amount': '100.00'},
            {'user_id': B, 'share_amount': '100.00'},
            {'user_id': C, 'share_amount': '100.00'},
        ],
    )


def settlement_input(amount: str = '100.00') -> SettlementInput:
    return SettlementInput(
        squad_id=A,
        client_request_id=UUID(int=199),
        from_user_id=B,
        to_user_id=A,
        amount=amount,
        note='Transferencia SPEI',
    )


def test_balances_are_exact_and_transfers_clear_debts() -> None:
    balances = {
        A: Decimal('200.00'),
        B: Decimal('-100.00'),
        C: Decimal('-100.00'),
    }

    transfers = suggest_transfers(balances)

    assert len(transfers) == 2
    assert sum(item['amount'] for item in transfers) == Decimal('200.00')


def test_create_expense_is_persisted_transactionally() -> None:
    db = MagicMock(spec=Session)
    db.scalars.return_value = [A, B, C]
    db.scalar.return_value = None

    def refresh(expense: Expense) -> None:
        expense.created_at = datetime(2026, 9, 23)

    db.refresh.side_effect = refresh
    result = DatabaseFinanceService().create_expense(db, expense_input(), A)

    assert result.amount == Decimal('300.00')
    assert result.client_request_id == UUID(int=99)
    assert len(result.participants) == 3
    db.commit.assert_called_once()
    inserted = db.add.call_args.args[0]
    assert isinstance(inserted, Expense)
    assert inserted.amount == Decimal('300.00')
    assert all(isinstance(row, ExpenseParticipant) for row in db.add_all.call_args.args[0])


def test_create_expense_rejects_non_members() -> None:
    db = MagicMock(spec=Session)
    db.scalars.return_value = [A]
    db.scalar.return_value = None

    with pytest.raises(ValueError, match='pertenecer'):
        DatabaseFinanceService().create_expense(db, expense_input(), A)

    db.commit.assert_not_called()


def test_repeated_client_request_returns_original_expense() -> None:
    db = MagicMock(spec=Session)
    existing = Expense(
        id=UUID(int=100),
        squad_id=A,
        client_request_id=UUID(int=99),
        paid_by_user_id=A,
        description='Taxi',
        amount=Decimal('300.00'),
        created_at=datetime(2026, 9, 23),
    )
    participants = [
        ExpenseParticipant(
            expense_id=existing.id,
            user_id=user_id,
            share_amount=Decimal('100.00'),
        )
        for user_id in (A, B, C)
    ]
    db.scalars.side_effect = [[A, B, C], participants]
    db.scalar.return_value = existing

    result = DatabaseFinanceService().create_expense(db, expense_input(), A)

    assert result.id == existing.id
    db.add.assert_not_called()
    db.commit.assert_not_called()


def test_create_settlement_reduces_an_existing_debt() -> None:
    db = MagicMock(spec=Session)
    db.scalars.return_value = [A, B, C]
    db.scalar.return_value = None
    db.execute.return_value.all.return_value = [
        (A, Decimal('200.00')),
        (B, Decimal('-100.00')),
        (C, Decimal('-100.00')),
    ]

    def refresh(settlement: Settlement) -> None:
        settlement.created_at = datetime(2026, 9, 29)

    db.refresh.side_effect = refresh
    result = DatabaseFinanceService().create_settlement(
        db,
        settlement_input(),
        B,
    )

    assert result.amount == Decimal('100.00')
    assert result.from_user_id == B
    assert isinstance(db.add.call_args.args[0], Settlement)
    db.commit.assert_called_once()


def test_settlement_cannot_be_recorded_by_another_member() -> None:
    db = MagicMock(spec=Session)
    db.scalars.return_value = [A, B, C]

    with pytest.raises(PermissionError, match='quien paga'):
        DatabaseFinanceService().create_settlement(
            db,
            settlement_input(),
            C,
        )

    db.commit.assert_not_called()


def test_settlement_cannot_exceed_current_debt() -> None:
    db = MagicMock(spec=Session)
    db.scalars.return_value = [A, B]
    db.scalar.return_value = None
    db.execute.return_value.all.return_value = [
        (A, Decimal('50.00')),
        (B, Decimal('-50.00')),
    ]

    with pytest.raises(ValueError, match='no puede exceder'):
        DatabaseFinanceService().create_settlement(
            db,
            settlement_input('50.01'),
            B,
        )

    db.commit.assert_not_called()


def test_payer_can_cancel_expense_without_deleting_audit_record() -> None:
    expense = Expense(
        id=UUID(int=300),
        squad_id=A,
        client_request_id=UUID(int=301),
        paid_by_user_id=A,
        description='Bebidas',
        amount=Decimal('120.00'),
        status='active',
        created_at=datetime(2026, 10, 1),
    )
    membership = SquadMember(squad_id=A, user_id=A, role='member')
    participant = ExpenseParticipant(
        expense_id=expense.id,
        user_id=A,
        share_amount=Decimal('120.00'),
    )
    db = MagicMock(spec=Session)
    db.get.side_effect = [expense, membership]
    db.scalars.return_value = [participant]

    result = DatabaseFinanceService().cancel_expense(db, expense.id, A)

    assert result.status == 'cancelled'
    assert result.cancelled_by_user_id == A
    assert expense.cancelled_at is not None
    db.delete.assert_not_called()
    db.commit.assert_called_once()


def test_non_payer_member_cannot_cancel_expense() -> None:
    expense = Expense(
        id=UUID(int=310),
        squad_id=A,
        client_request_id=UUID(int=311),
        paid_by_user_id=A,
        description='Taxi',
        amount=Decimal('80.00'),
        status='active',
        created_at=datetime(2026, 10, 1),
    )
    membership = SquadMember(squad_id=A, user_id=B, role='member')
    db = MagicMock(spec=Session)
    db.get.side_effect = [expense, membership]

    with pytest.raises(PermissionError, match='pagador'):
        DatabaseFinanceService().cancel_expense(db, expense.id, B)

    db.commit.assert_not_called()
