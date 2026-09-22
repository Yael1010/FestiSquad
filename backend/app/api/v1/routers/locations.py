from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.locations.schemas import (
    LocationCreateRequest,
    LocationResponse,
    MeetingPointCreateRequest,
    MeetingPointResponse,
)
from app.domains.locations.service import location_service
from app.domains.squads.service import squad_service

router = APIRouter()


def _require_member(db: DatabaseSession, squad_id: UUID, user: CurrentUser) -> None:
    try:
        squad_service.require_member(db, squad_id, user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail="No perteneces a este squad.") from exc


@router.post("", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def save_location(
    payload: LocationCreateRequest, db: DatabaseSession, current_user: CurrentUser
) -> LocationResponse:
    _require_member(db, payload.squad_id, current_user)
    return location_service.save(db, payload, current_user.id)


@router.get("/squad/{squad_id}/latest", response_model=list[LocationResponse])
def latest_locations(
    squad_id: UUID, db: DatabaseSession, current_user: CurrentUser
) -> list[LocationResponse]:
    _require_member(db, squad_id, current_user)
    return location_service.latest_for_squad(db, squad_id)


@router.post(
    "/meeting-points",
    response_model=MeetingPointResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_meeting_point(
    payload: MeetingPointCreateRequest, db: DatabaseSession, current_user: CurrentUser
) -> MeetingPointResponse:
    _require_member(db, payload.squad_id, current_user)
    return location_service.create_meeting_point(db, payload, current_user.id)


@router.get(
    "/squad/{squad_id}/meeting-points",
    response_model=list[MeetingPointResponse],
)
def meeting_points(
    squad_id: UUID, db: DatabaseSession, current_user: CurrentUser
) -> list[MeetingPointResponse]:
    _require_member(db, squad_id, current_user)
    return location_service.meeting_points(db, squad_id)
