from fastapi import APIRouter, HTTPException, status

from app.domains.finances.schemas import BalanceResponse, ExpenseCreateRequest, ExpenseResponse
from app.domains.finances.service import finance_service

router = APIRouter()


@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreateRequest) -> ExpenseResponse:
    try:
        return finance_service.create_expense(payload)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="Las participaciones no coinciden con el total.") from exc


@router.get("/squad/{squad_id}/balances", response_model=BalanceResponse)
def balances(squad_id: str) -> BalanceResponse:
    return finance_service.balances_for_squad(squad_id)

