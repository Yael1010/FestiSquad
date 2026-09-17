from uuid import uuid4

from app.domains.locations.schemas import LocationCreateRequest, LocationResponse


class LocationService:
    def __init__(self) -> None:
        self._locations: list[LocationResponse] = []

    def save(self, payload: LocationCreateRequest) -> LocationResponse:
        location = LocationResponse(id=str(uuid4()), **payload.model_dump())
        self._locations.append(location)
        return location

    def latest_for_squad(self, squad_id: str) -> list[LocationResponse]:
        latest_by_user: dict[str, LocationResponse] = {}
        for location in self._locations:
            if location.squad_id != squad_id:
                continue
            current = latest_by_user.get(location.user_id)
            if current is None or location.recorded_at > current.recorded_at:
                latest_by_user[location.user_id] = location
        return list(latest_by_user.values())


location_service = LocationService()

