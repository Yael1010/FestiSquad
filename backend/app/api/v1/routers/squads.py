from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.squads.schemas import (
    SquadCreateRequest,
    SquadJoinRequest,
    SquadMemberResponse,
    SquadRoleUpdateRequest,
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
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail="No perteneces a este squad.",
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


@router.get("/{squad_id}/members", response_model=list[SquadMemberResponse])
def list_members(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> list[SquadMemberResponse]:
    try:
        return squad_service.members(db, squad_id, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Squad no encontrado.") from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc


@router.patch(
    "/{squad_id}/members/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def update_member_role(
    squad_id: UUID,
    user_id: UUID,
    payload: SquadRoleUpdateRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> None:
    try:
        squad_service.update_role(db, squad_id, user_id, payload.role, current_user)
    except ValueError as exc:
        detail = (
            "El rol del propietario no puede modificarse."
            if str(exc) == "owner_role_locked"
            else "Integrante no encontrado."
        )
        raise HTTPException(status_code=409, detail=detail) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="Se requiere rol de administrador.") from exc


@router.delete("/{squad_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(
    squad_id: UUID,
    user_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> None:
    try:
        squad_service.remove_member(db, squad_id, user_id, current_user)
    except ValueError as exc:
        detail = (
            "Transfiere la propiedad antes de abandonar el squad."
            if str(exc) == "owner_cannot_leave"
            else "Integrante no encontrado."
        )
        raise HTTPException(status_code=409, detail=detail) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No tienes permiso para expulsar integrantes.") from exc


@router.post("/{squad_id}/owner/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def transfer_ownership(
    squad_id: UUID,
    user_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> None:
    try:
        squad_service.transfer_ownership(db, squad_id, user_id, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=409, detail="Selecciona otro integrante.") from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="Solo el propietario puede transferir el squad.") from exc


@router.delete("/{squad_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_squad(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> None:
    try:
        squad_service.delete_squad(db, squad_id, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Squad no encontrado.") from exc
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail="Solo el propietario puede eliminar el squad.",
        ) from exc
