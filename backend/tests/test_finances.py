from decimal import Decimal

from app.domains.finances.schemas import ExpenseCreateRequest, ExpenseParticipant
from app.domains.finances.service import FinanceService


def test_balances_are_exact_decimals_and_minimize_transfers() -> None:
    service = FinanceService()
    service.create_expense(
        ExpenseCreateRequest(
            squad_id="squad-1",
            paid_by_user_id="ana",
            description="Taxi",
            amount=Decimal("300.00"),
            participants=[
                ExpenseParticipant(user_id="ana", share_amount=Decimal("100.00")),
                ExpenseParticipant(user_id="luis", share_amount=Decimal("100.00")),
                ExpenseParticipant(user_id="mario", share_amount=Decimal("100.00")),
            ],
        )
    )

    result = service.balances_for_squad("squad-1")

    assert result.net_balances["ana"] == Decimal("200.00")
    assert result.net_balances["luis"] == Decimal("-100.00")
    assert result.net_balances["mario"] == Decimal("-100.00")
    assert len(result.suggested_transfers) == 2
    assert sum(item.amount for item in result.suggested_transfers) == Decimal("200.00")

