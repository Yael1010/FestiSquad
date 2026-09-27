from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession, PlatformAdmin
from app.domains.festivals.schemas import (
    FestivalAdminAccessResponse,
    FestivalCreateRequest,
    FestivalDetailResponse,
    FestivalSummaryResponse,
    FestivalUpdateRequest,
    StageCreateRequest,
    StageResponse,
    StageUpdateRequest,
)
from app.domains.festivals.service import festival_service

router = APIRouter()


@router.get("", response_model=list[FestivalSummaryResponse])
def festival_catalog(
    db: DatabaseSession,
    current_user: CurrentUser,
    include_past: bool = Query(default=False),
) -> list[FestivalSummaryResponse]:
    del current_user
    return festival_service.catalog(db, include_past=include_past)


@router.get("/admin/access", response_model=FestivalAdminAccessResponse)
def festival_admin_access(current_user: CurrentUser) -> FestivalAdminAccessResponse:
    return FestivalAdminAccessResponse(is_admin=current_user.is_platform_admin)


@router.get("/admin/catalog", response_model=list[FestivalSummaryResponse])
def festival_admin_catalog(
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> list[FestivalSummaryResponse]:
    del admin
    return festival_service.catalog(
        db,
        include_past=True,
        include_unpublished=True,
    )


@router.post(
    "",
    response_model=FestivalDetailResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_festival(
    payload: FestivalCreateRequest,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> FestivalDetailResponse:
    del admin
    return festival_service.create(db, payload)


@router.get("/{festival_id}", response_model=FestivalDetailResponse)
def festival_map(
    festival_id: UUID,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> FestivalDetailResponse:
    try:
        return festival_service.detail(
            db,
            festival_id,
            include_unpublished=current_user.is_platform_admin,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Festival no encontrado.") from exc


@router.patch("/{festival_id}", response_model=FestivalDetailResponse)
def update_festival(
    festival_id: UUID,
    payload: FestivalUpdateRequest,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> FestivalDetailResponse:
    del admin
    try:
        return festival_service.update(db, festival_id, payload)
    except ValueError as exc:
        if str(exc) == "invalid_dates":
            raise HTTPException(
                status_code=422,
                detail="La fecha final debe ser posterior a la inicial.",
            ) from exc
        raise HTTPException(status_code=404, detail="Festival no encontrado.") from exc


@router.delete("/{festival_id}", status_code=status.HTTP_204_NO_CONTENT)
def archive_festival(
    festival_id: UUID,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> None:
    del admin
    try:
        festival_service.archive(db, festival_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Festival no encontrado.") from exc


@router.post(
    "/{festival_id}/stages",
    response_model=StageResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_stage(
    festival_id: UUID,
    payload: StageCreateRequest,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> StageResponse:
    del admin
    try:
        return festival_service.add_stage(db, festival_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Festival no encontrado.") from exc


@router.patch("/{festival_id}/stages/{stage_id}", response_model=StageResponse)
def update_stage(
    festival_id: UUID,
    stage_id: UUID,
    payload: StageUpdateRequest,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> StageResponse:
    del admin
    try:
        return festival_service.update_stage(db, festival_id, stage_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Escenario no encontrado.") from exc


@router.delete(
    "/{festival_id}/stages/{stage_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_stage(
    festival_id: UUID,
    stage_id: UUID,
    db: DatabaseSession,
    admin: PlatformAdmin,
) -> None:
    del admin
    try:
        festival_service.delete_stage(db, festival_id, stage_id)
    except ValueError as exc:
        detail = (
            "El escenario tiene horarios asociados y no puede eliminarse."
            if str(exc) == "stage_has_schedule"
            else "Escenario no encontrado."
        )
        raise HTTPException(status_code=409, detail=detail) from exc
