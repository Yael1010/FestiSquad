from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.squads.schemas import (
    SquadCreateRequest,
    SquadJoinRequest,
    SquadResponse,
)
from app.domains.squads.service import squad_service

router = APIRouter()


@router.get("", response_model=list[SquadResponse])
def list_squads(
    db: DatabaseSession,
    current_user: CurrentUser,
) -> list[SquadResponse]:
    return squad_service.list_for_user(db, current_user)


@router.post("", response_model=SquadResponse, status_code=status.HTTP_201_CREATED)
def create_squad(
    payload: SquadCreateRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> SquadResponse:
    try:
        return squad_service.create(db, payload, current_user)
    except ValueError as exc:
        raise HTTPException(
            status_code=409,
            detail="No se pudo generar un código único para el squad.",
        ) from exc


@router.post("/join", response_model=SquadResponse)
def join_squad(
    payload: SquadJoinRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> SquadResponse:
    try:
        return squad_service.join(db, payload, current_user)
    except ValueError as exc:
        raise HTTPException(
            status_code=404,
            detail="Squad no encontrado.",
        ) from exc


@router.get("/{squad_id}", response_model=SquadResponse)
def get_squad(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> SquadResponse:
    try:
        return squad_service.get(db, squad_id, current_user)
    except ValueError as exc:
        raise HTTPException(
            status_code=404,
            detail="Squad no encontrado.",
        ) from exc
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail="No perteneces a este squad.",
        ) from exc
