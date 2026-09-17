from fastapi import APIRouter, status

from app.domains.locations.schemas import LocationCreateRequest, LocationResponse
from app.domains.locations.service import location_service

router = APIRouter()


@router.post("", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def save_location(payload: LocationCreateRequest) -> LocationResponse:
    return location_service.save(payload)


@router.get("/squad/{squad_id}/latest", response_model=list[LocationResponse])
def latest_locations(squad_id: str) -> list[LocationResponse]:
    return location_service.latest_for_squad(squad_id)

