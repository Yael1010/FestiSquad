from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.clash_resolver.schemas import (
    ConflictListResponse,
    RecommendationRequest,
    RecommendationResponse,
)
from app.domains.clash_resolver.service import clash_resolver_service

router = APIRouter()


@router.get("/conflicts", response_model=ConflictListResponse)
def conflicts(
    db: DatabaseSession,
    current_user: CurrentUser,
    festival_id: UUID | None = Query(default=None),
) -> ConflictListResponse:
    return clash_resolver_service.conflicts(db, current_user.id, festival_id)


@router.post("/recommendation", response_model=RecommendationResponse)
def recommendation(
    payload: RecommendationRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> RecommendationResponse:
    try:
        return clash_resolver_service.recommend_for_squad(
            db, current_user.id, payload
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes pertenecer al squad para solicitar una recomendación.",
        ) from exc
