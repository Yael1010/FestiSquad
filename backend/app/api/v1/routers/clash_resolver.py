from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.clash_resolver.schemas import (
    ClashDecisionRequest,
    ClashVoteRequest,
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
    squad_id: UUID | None = Query(default=None),
) -> ConflictListResponse:
    try:
        return clash_resolver_service.conflicts(
            db, current_user.id, festival_id, squad_id
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes pertenecer al squad para consultar sus votos.",
        ) from exc


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


@router.put("/votes", response_model=ConflictListResponse)
def vote(
    payload: ClashVoteRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> ConflictListResponse:
    try:
        return clash_resolver_service.vote(db, current_user.id, payload)
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes pertenecer al squad para votar.",
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El empalme o la opción ya no está disponible.",
        ) from exc


@router.put("/decision", response_model=ConflictListResponse)
def decide(
    payload: ClashDecisionRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> ConflictListResponse:
    try:
        return clash_resolver_service.decide(db, current_user.id, payload)
    except PermissionError as exc:
        detail = (
            "Solo un administrador del squad puede confirmar la decisión."
            if str(exc) == "admin_required"
            else "Debes pertenecer al squad para confirmar la decisión."
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El empalme o la opción ya no está disponible.",
        ) from exc
