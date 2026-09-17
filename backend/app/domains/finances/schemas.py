from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class ExpenseParticipant(BaseModel):
    user_id: str
    share_amount: Decimal = Field(gt=Decimal("0"))


class ExpenseCreateRequest(BaseModel):
    squad_id: str
    paid_by_user_id: str
    description: str = Field(min_length=2, max_length=180)
    amount: Decimal = Field(gt=Decimal("0"), decimal_places=2)
    participants: list[ExpenseParticipant]

    @field_validator("amount")
    @classmethod
    def money_has_two_decimals(cls, value: Decimal) -> Decimal:
        return value.quantize(Decimal("0.01"))


class ExpenseResponse(ExpenseCreateRequest):
    id: str


class DebtTransfer(BaseModel):
    from_user_id: str
    to_user_id: str
    amount: Decimal


class BalanceResponse(BaseModel):
    squad_id: str
    net_balances: dict[str, Decimal]
    suggested_transfers: list[DebtTransfer]

