import json
from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.domains.clash_resolver.db_models import Genre
from app.domains.festivals.db_models import (
    Festival,
    ScheduleItem,
    ScheduleItemGenre,
    Stage,
)
from app.domains.festivals.schemas import (
    FestivalCreateRequest,
    FestivalDetailResponse,
    FestivalSummaryResponse,
    FestivalUpdateRequest,
    ScheduleItemAdminRequest,
    ScheduleItemResponse,
    StageCreateRequest,
    StageResponse,
    StageUpdateRequest,
)


class FestivalService:
    def catalog(
        self,
        db: Session,
        *,
        include_past: bool = False,
        include_unpublished: bool = False,
    ) -> list[FestivalSummaryResponse]:
        statement = (
            select(Festival, func.count(Stage.id))
            .outerjoin(Stage, Stage.festival_id == Festival.id)
            .group_by(Festival)
            .order_by(Festival.starts_at)
        )
        if not include_unpublished:
            statement = statement.where(Festival.status == "published")
        if not include_past:
            statement = statement.where(Festival.ends_at >= datetime.utcnow())
        return [self._summary(item, count) for item, count in db.execute(statement)]

    def detail(
        self,
        db: Session,
        festival_id: UUID,
        *,
        include_unpublished: bool = False,
    ) -> FestivalDetailResponse:
        festival = db.get(Festival, festival_id)
        if festival is None or (
            festival.status != "published" and not include_unpublished
        ):
            raise ValueError("festival_not_found")
        stages = list(
            db.scalars(
                select(Stage)
                .where(Stage.festival_id == festival_id)
                .order_by(Stage.name)
            )
        )
        summary = self._summary(festival, len(stages))
        return FestivalDetailResponse(
            **summary.model_dump(),
            boundary=json.loads(festival.boundary_geojson),
            stages=[self._stage_response(stage) for stage in stages],
        )

    def create(
        self,
        db: Session,
        payload: FestivalCreateRequest,
    ) -> FestivalDetailResponse:
        festival = Festival(
            id=uuid4(),
            name=payload.name.strip(),
            venue_name=payload.venue_name.strip(),
            city=payload.city.strip(),
            country_code=payload.country_code,
            timezone=payload.timezone,
            starts_at=self._database_datetime(payload.starts_at),
            ends_at=self._database_datetime(payload.ends_at),
            boundary_geojson=json.dumps(payload.boundary.model_dump()),
            image_url=str(payload.image_url) if payload.image_url else None,
            official_url=str(payload.official_url) if payload.official_url else None,
            status=payload.status,
        )
        db.add(festival)
        stages = [self._new_stage(festival.id, stage) for stage in payload.stages]
        db.add_all(stages)
        db.flush()
        stages_by_name = {stage.name.casefold(): stage for stage in stages}
        for item in payload.schedule:
            stage = stages_by_name.get(item.stage_name.strip().casefold())
            if stage is None:
                raise ValueError("schedule_stage_not_found")
            self._add_schedule_item(
                db,
                festival,
                stage,
                item.artist_name,
                item.starts_at,
                item.ends_at,
                item.genres,
            )
        db.commit()
        return self.detail(db, festival.id, include_unpublished=True)

    def update(
        self,
        db: Session,
        festival_id: UUID,
        payload: FestivalUpdateRequest,
    ) -> FestivalDetailResponse:
        festival = self._required(db, festival_id)
        values = payload.model_dump(exclude_unset=True)
        if "boundary" in values:
            festival.boundary_geojson = json.dumps(payload.boundary.model_dump())
            values.pop("boundary")
        for url_field in ("image_url", "official_url"):
            if url_field in values:
                value = getattr(payload, url_field)
                values[url_field] = str(value) if value else None
        for field, value in values.items():
            if field in ("starts_at", "ends_at"):
                value = self._database_datetime(value)
            if isinstance(value, str):
                value = value.strip()
            setattr(festival, field, value)
        if festival.ends_at <= festival.starts_at:
            raise ValueError("invalid_dates")
        festival.updated_at = datetime.utcnow()
        db.commit()
        return self.detail(db, festival_id, include_unpublished=True)

    def archive(self, db: Session, festival_id: UUID) -> None:
        festival = self._required(db, festival_id)
        festival.status = "archived"
        festival.updated_at = datetime.utcnow()
        db.commit()

    def add_stage(
        self,
        db: Session,
        festival_id: UUID,
        payload: StageCreateRequest,
    ) -> StageResponse:
        self._required(db, festival_id)
        stage = self._new_stage(festival_id, payload)
        db.add(stage)
        db.commit()
        return self._stage_response(stage)

    def update_stage(
        self,
        db: Session,
        festival_id: UUID,
        stage_id: UUID,
        payload: StageUpdateRequest,
    ) -> StageResponse:
        stage = self._required_stage(db, festival_id, stage_id)
        if payload.name is not None:
            stage.name = payload.name.strip()
        if payload.polygon is not None:
            stage.polygon_geojson = json.dumps(payload.polygon.model_dump())
        db.commit()
        return self._stage_response(stage)

    def delete_stage(
        self,
        db: Session,
        festival_id: UUID,
        stage_id: UUID,
    ) -> None:
        stage = self._required_stage(db, festival_id, stage_id)
        try:
            db.delete(stage)
            db.commit()
        except IntegrityError as exc:
            db.rollback()
            raise ValueError("stage_has_schedule") from exc

    def schedule(
        self, db: Session, festival_id: UUID
    ) -> list[ScheduleItemResponse]:
        self._required(db, festival_id)
        rows = db.execute(
            select(ScheduleItem, Stage)
            .join(Stage, Stage.id == ScheduleItem.stage_id)
            .where(Stage.festival_id == festival_id)
            .order_by(ScheduleItem.starts_at, Stage.name, ScheduleItem.artist_name)
        ).all()
        result: list[ScheduleItemResponse] = []
        for item, stage in rows:
            genres = list(
                db.scalars(
                    select(Genre.name)
                    .join(ScheduleItemGenre, ScheduleItemGenre.genre_id == Genre.id)
                    .where(ScheduleItemGenre.schedule_item_id == item.id)
                    .order_by(Genre.name)
                )
            )
            result.append(self._schedule_response(item, stage, genres))
        return result

    def add_schedule_item(
        self,
        db: Session,
        festival_id: UUID,
        payload: ScheduleItemAdminRequest,
    ) -> ScheduleItemResponse:
        festival = self._required(db, festival_id)
        stage = self._required_stage(db, festival_id, UUID(payload.stage_id))
        item = self._add_schedule_item(
            db,
            festival,
            stage,
            payload.artist_name,
            payload.starts_at,
            payload.ends_at,
            payload.genres,
        )
        db.commit()
        return self._schedule_response(item, stage, payload.genres)

    def update_schedule_item(
        self,
        db: Session,
        festival_id: UUID,
        item_id: UUID,
        payload: ScheduleItemAdminRequest,
    ) -> ScheduleItemResponse:
        festival = self._required(db, festival_id)
        item = db.get(ScheduleItem, item_id)
        stage = self._required_stage(db, festival_id, UUID(payload.stage_id))
        current_stage = db.get(Stage, item.stage_id) if item else None
        if item is None or current_stage is None or current_stage.festival_id != festival_id:
            raise ValueError("schedule_not_found")
        self._validate_schedule_dates(festival, payload.starts_at, payload.ends_at)
        item.stage_id = stage.id
        item.artist_name = payload.artist_name.strip()
        item.starts_at = self._database_datetime(payload.starts_at)
        item.ends_at = self._database_datetime(payload.ends_at)
        db.execute(
            ScheduleItemGenre.__table__.delete().where(
                ScheduleItemGenre.schedule_item_id == item.id
            )
        )
        self._attach_genres(db, item.id, payload.genres)
        db.commit()
        return self._schedule_response(item, stage, payload.genres)

    def delete_schedule_item(
        self, db: Session, festival_id: UUID, item_id: UUID
    ) -> None:
        item = db.get(ScheduleItem, item_id)
        stage = db.get(Stage, item.stage_id) if item else None
        if item is None or stage is None or stage.festival_id != festival_id:
            raise ValueError("schedule_not_found")
        db.execute(
            ScheduleItemGenre.__table__.delete().where(
                ScheduleItemGenre.schedule_item_id == item.id
            )
        )
        db.execute(text("DELETE FROM dbo.clash_decisions WHERE schedule_item_id = :id"), {"id": str(item.id)})
        db.execute(text("DELETE FROM dbo.clash_votes WHERE schedule_item_id = :id"), {"id": str(item.id)})
        db.delete(item)
        db.commit()

    def _required(self, db: Session, festival_id: UUID) -> Festival:
        festival = db.get(Festival, festival_id)
        if festival is None:
            raise ValueError("festival_not_found")
        return festival

    def _required_stage(
        self,
        db: Session,
        festival_id: UUID,
        stage_id: UUID,
    ) -> Stage:
        stage = db.get(Stage, stage_id)
        if stage is None or stage.festival_id != festival_id:
            raise ValueError("stage_not_found")
        return stage

    def _new_stage(self, festival_id: UUID, payload: StageCreateRequest) -> Stage:
        return Stage(
            id=uuid4(),
            festival_id=festival_id,
            name=payload.name.strip(),
            polygon_geojson=json.dumps(payload.polygon.model_dump()),
        )

    def _add_schedule_item(
        self,
        db: Session,
        festival: Festival,
        stage: Stage,
        artist_name: str,
        starts_at: datetime,
        ends_at: datetime,
        genres: list[str],
    ) -> ScheduleItem:
        self._validate_schedule_dates(festival, starts_at, ends_at)
        item = ScheduleItem(
            id=uuid4(),
            stage_id=stage.id,
            artist_name=artist_name.strip(),
            starts_at=self._database_datetime(starts_at),
            ends_at=self._database_datetime(ends_at),
        )
        db.add(item)
        db.flush()
        self._attach_genres(db, item.id, genres)
        return item

    def _attach_genres(
        self, db: Session, schedule_item_id: UUID, genres: list[str]
    ) -> None:
        for name in genres:
            normalized = " ".join(name.strip().split()).casefold()
            genre = db.scalar(select(Genre).where(Genre.name == normalized))
            if genre is None:
                genre = Genre(name=normalized)
                db.add(genre)
                db.flush()
            db.add(
                ScheduleItemGenre(
                    schedule_item_id=schedule_item_id,
                    genre_id=genre.id,
                )
            )

    def _validate_schedule_dates(
        self, festival: Festival, starts_at: datetime, ends_at: datetime
    ) -> None:
        starts = self._database_datetime(starts_at)
        ends = self._database_datetime(ends_at)
        if ends <= starts or starts < festival.starts_at or ends > festival.ends_at:
            raise ValueError("schedule_outside_festival")

    def _schedule_response(
        self, item: ScheduleItem, stage: Stage, genres: list[str]
    ) -> ScheduleItemResponse:
        return ScheduleItemResponse(
            id=str(item.id),
            stage_id=str(stage.id),
            stage_name=stage.name,
            artist_name=item.artist_name,
            starts_at=self._response_datetime(item.starts_at),
            ends_at=self._response_datetime(item.ends_at),
            genres=genres,
        )

    def _summary(self, festival: Festival, stage_count: int) -> FestivalSummaryResponse:
        return FestivalSummaryResponse(
            id=str(festival.id),
            name=festival.name,
            venue_name=festival.venue_name,
            city=festival.city,
            country_code=festival.country_code.strip(),
            timezone=festival.timezone,
            starts_at=self._response_datetime(festival.starts_at),
            ends_at=self._response_datetime(festival.ends_at),
            image_url=festival.image_url,
            official_url=festival.official_url,
            status=festival.status,
            stage_count=stage_count,
        )

    def _stage_response(self, stage: Stage) -> StageResponse:
        return StageResponse(
            id=str(stage.id),
            name=stage.name,
            polygon=json.loads(stage.polygon_geojson),
        )

    def _database_datetime(self, value: datetime) -> datetime:
        if value.tzinfo is None:
            return value
        return value.astimezone(timezone.utc).replace(tzinfo=None)

    def _response_datetime(self, value: datetime) -> datetime:
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


festival_service = FestivalService()
