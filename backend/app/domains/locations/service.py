from datetime import timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.domains.locations.db_models import Location, MeetingPoint
from app.domains.locations.schemas import (
    LocationCreateRequest,
    LocationResponse,
    MeetingPointCreateRequest,
    MeetingPointResponse,
)


def _utc_naive(value):
    return value.astimezone(timezone.utc).replace(tzinfo=None)


def _location_response(row: Location) -> LocationResponse:
    return LocationResponse(
        id=row.id,
        squad_id=row.squad_id,
        user_id=row.user_id,
        latitude=row.latitude,
        longitude=row.longitude,
        accuracy_meters=row.accuracy_meters,
        recorded_at=row.recorded_at.replace(tzinfo=timezone.utc),
    )


def _meeting_response(row: MeetingPoint) -> MeetingPointResponse:
    return MeetingPointResponse(
        id=row.id,
        squad_id=row.squad_id,
        title=row.title,
        latitude=row.latitude,
        longitude=row.longitude,
        created_by_user_id=row.created_by_user_id,
        created_at=row.created_at.replace(tzinfo=timezone.utc),
    )


class LocationService:
    def save(
        self, db: Session, payload: LocationCreateRequest, user_id: UUID
    ) -> LocationResponse:
        row = Location(
            squad_id=payload.squad_id,
            user_id=user_id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            accuracy_meters=payload.accuracy_meters,
            recorded_at=_utc_naive(payload.recorded_at),
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return _location_response(row)

    def latest_for_squad(self, db: Session, squad_id: UUID) -> list[LocationResponse]:
        ranked = (
            select(
                Location.id.label("id"),
                func.row_number()
                .over(
                    partition_by=Location.user_id,
                    order_by=(Location.recorded_at.desc(), Location.created_at.desc()),
                )
                .label("rank"),
            )
            .where(Location.squad_id == squad_id)
            .subquery()
        )
        rows = db.scalars(
            select(Location)
            .join(ranked, ranked.c.id == Location.id)
            .where(ranked.c.rank == 1)
            .order_by(Location.recorded_at.desc())
        ).all()
        return [_location_response(row) for row in rows]

    def create_meeting_point(
        self, db: Session, payload: MeetingPointCreateRequest, user_id: UUID
    ) -> MeetingPointResponse:
        row = MeetingPoint(
            squad_id=payload.squad_id,
            title=payload.title,
            latitude=payload.latitude,
            longitude=payload.longitude,
            created_by_user_id=user_id,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return _meeting_response(row)

    def meeting_points(self, db: Session, squad_id: UUID) -> list[MeetingPointResponse]:
        rows = db.scalars(
            select(MeetingPoint)
            .where(MeetingPoint.squad_id == squad_id)
            .order_by(MeetingPoint.created_at.desc())
        ).all()
        return [_meeting_response(row) for row in rows]


location_service = LocationService()
