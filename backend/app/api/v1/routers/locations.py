from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.locations.schemas import LocationCreateRequest, LocationResponse
from app.domains.locations.service import location_service
from app.domains.squads.service import squad_service

router = APIRouter()


@router.post("", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def save_location(
    payload: LocationCreateRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> LocationResponse:
    if payload.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="No puedes enviar la ubicación de otro usuario.")
    try:
        squad_service.require_member(db, UUID(payload.squad_id), current_user.id)
    except (ValueError, PermissionError) as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc
    return location_service.save(payload)


@router.get("/squad/{squad_id}/latest", response_model=list[LocationResponse])
def latest_locations(
    squad_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> list[LocationResponse]:
    try:
        squad_service.require_member(db, squad_id, current_user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc
    return location_service.latest_for_squad(str(squad_id))
