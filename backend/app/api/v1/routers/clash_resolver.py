from fastapi import APIRouter

from app.domains.clash_resolver.schemas import RecommendationRequest, RecommendationResponse
from app.domains.clash_resolver.service import clash_resolver_service

router = APIRouter()


@router.get("/conflicts")
def conflicts() -> dict[str, list[dict[str, str]]]:
    return {"conflicts": []}


@router.post("/recommendation", response_model=RecommendationResponse)
def recommendation(payload: RecommendationRequest) -> RecommendationResponse:
    return clash_resolver_service.recommend(payload)

