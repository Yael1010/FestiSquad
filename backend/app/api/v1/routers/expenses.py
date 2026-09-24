from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.finances.db_schemas import BalanceOutput, ExpenseInput, ExpenseOutput
from app.domains.finances.db_service import finance_service

router = APIRouter()


@router.post('', response_model=ExpenseOutput, status_code=status.HTTP_201_CREATED)
def create_expense(
    payload: ExpenseInput,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> ExpenseOutput:
    try:
        return finance_service.create_expense(db, payload, current_user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail='No perteneces a este squad.') from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@router.get('/squad/{squad_id}', response_model=list[ExpenseOutput])
def list_expenses(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> list[ExpenseOutput]:
    try:
        return finance_service.list_expenses(
            db,
            squad_id,
            current_user.id,
            limit=limit,
            offset=offset,
        )
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail='No perteneces a este squad.') from exc


@router.get('/squad/{squad_id}/balances', response_model=BalanceOutput)
def balances(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> BalanceOutput:
    try:
        return finance_service.balances_for_squad(db, squad_id, current_user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail='No perteneces a este squad.') from exc
