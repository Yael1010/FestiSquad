from datetime import datetime
from decimal import Decimal
from unittest.mock import MagicMock
from uuid import UUID

import pytest
from sqlalchemy.orm import Session

from app.domains.finances.db_models import Expense, ExpenseParticipant
from app.domains.finances.db_schemas import ExpenseInput
from app.domains.finances.db_service import DatabaseFinanceService
from app.domains.finances.exact_money import suggest_transfers

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
