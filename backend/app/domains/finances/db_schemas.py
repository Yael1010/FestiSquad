from decimal import Decimal, localcontext
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, BeforeValidator, ConfigDict, Field, model_validator
from app.domains.finances.exact_money import money

Money = Annotated[Decimal, BeforeValidator(money), Field(max_digits=18, decimal_places=2)]


class ShareInput(BaseModel):
    model_config = ConfigDict(extra='forbid')
    user_id: UUID
    share_amount: Money


class ExpenseInput(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    squad_id: UUID
    paid_by_user_id: UUID
    description: str = Field(min_length=2, max_length=180)
    amount: Money
    participants: list[ShareInput] = Field(min_length=1, max_length=500)

    @model_validator(mode='after')
    def exact_shares(self):
        ids = [p.user_id for p in self.participants]
        if len(ids) != len(set(ids)):
            raise ValueError('Participantes repetidos')
        with localcontext() as context:
            context.prec = 50
            if sum((p.share_amount for p in self.participants), Decimal('0.00')) != self.amount:
                raise ValueError('Las cuotas deben sumar exactamente el total')
        return self


class TransferOutput(BaseModel):
    from_user_id: UUID
    to_user_id: UUID
    amount: Decimal


class BalanceOutput(BaseModel):
    squad_id: UUID
    currency: str = 'MXN'
    net_balances: dict[UUID, Decimal]
    suggested_transfers: list[TransferOutput]
