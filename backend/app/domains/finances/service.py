from decimal import Decimal
from uuid import uuid4

from app.domains.finances.schemas import BalanceResponse, DebtTransfer, ExpenseCreateRequest, ExpenseResponse

CENTS = Decimal("0.01")


class FinanceService:
    def __init__(self) -> None:
        self._expenses: list[ExpenseResponse] = []

    def create_expense(self, payload: ExpenseCreateRequest) -> ExpenseResponse:
        total_shares = sum((item.share_amount for item in payload.participants), Decimal("0.00"))
        if total_shares.quantize(CENTS) != payload.amount.quantize(CENTS):
            raise ValueError("shares_do_not_match_amount")

        expense = ExpenseResponse(id=str(uuid4()), **payload.model_dump())
        self._expenses.append(expense)
        return expense

    def balances_for_squad(self, squad_id: str) -> BalanceResponse:
        balances: dict[str, Decimal] = {}
        for expense in self._expenses:
            if expense.squad_id != squad_id:
                continue
            balances[expense.paid_by_user_id] = balances.get(expense.paid_by_user_id, Decimal("0.00")) + expense.amount
            for participant in expense.participants:
                balances[participant.user_id] = balances.get(participant.user_id, Decimal("0.00")) - participant.share_amount

        normalized = {user_id: amount.quantize(CENTS) for user_id, amount in balances.items() if amount.quantize(CENTS) != 0}
        return BalanceResponse(
            squad_id=squad_id,
            net_balances=normalized,
            suggested_transfers=self._minimize_transfers(normalized),
        )

    def _minimize_transfers(self, balances: dict[str, Decimal]) -> list[DebtTransfer]:
        debtors = sorted(
            [(user_id, -amount) for user_id, amount in balances.items() if amount < 0],
            key=lambda item: item[1],
            reverse=True,
        )
        creditors = sorted(
            [(user_id, amount) for user_id, amount in balances.items() if amount > 0],
            key=lambda item: item[1],
            reverse=True,
        )

        transfers: list[DebtTransfer] = []
        i = 0
        j = 0
        while i < len(debtors) and j < len(creditors):
            debtor_id, debt = debtors[i]
            creditor_id, credit = creditors[j]
            amount = min(debt, credit).quantize(CENTS)
            if amount > 0:
                transfers.append(DebtTransfer(from_user_id=debtor_id, to_user_id=creditor_id, amount=amount))

            debtors[i] = (debtor_id, (debt - amount).quantize(CENTS))
            creditors[j] = (creditor_id, (credit - amount).quantize(CENTS))
            if debtors[i][1] == 0:
                i += 1
            if creditors[j][1] == 0:
                j += 1
        return transfers


finance_service = FinanceService()

