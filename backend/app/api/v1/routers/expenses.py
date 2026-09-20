from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.finances.schemas import BalanceResponse, ExpenseCreateRequest, ExpenseResponse
from app.domains.finances.service import finance_service
from app.domains.squads.service import squad_service

router = APIRouter()


@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_expense(
    payload: ExpenseCreateRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> ExpenseResponse:
    try:
        squad_service.require_member(db, UUID(payload.squad_id), current_user.id)
        return finance_service.create_expense(payload)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="Las participaciones no coinciden con el total.") from exc


@router.get("/squad/{squad_id}/balances", response_model=BalanceResponse)
def balances(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> BalanceResponse:
    try:
        squad_service.require_member(db, squad_id, current_user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc
    return finance_service.balances_for_squad(str(squad_id))
