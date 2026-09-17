from fastapi import APIRouter, HTTPException, status

from app.domains.squads.schemas import SquadCreateRequest, SquadJoinRequest, SquadResponse
from app.domains.squads.service import squad_service

router = APIRouter()


@router.post("", response_model=SquadResponse, status_code=status.HTTP_201_CREATED)
def create_squad(payload: SquadCreateRequest) -> SquadResponse:
    return squad_service.create(payload)


@router.post("/join", response_model=SquadResponse)
def join_squad(payload: SquadJoinRequest) -> SquadResponse:
    try:
        return squad_service.join(payload)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Squad no encontrado.") from exc


@router.get("/{squad_id}", response_model=SquadResponse)
def get_squad(squad_id: str) -> SquadResponse:
    try:
        return squad_service.get(squad_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Squad no encontrado.") from exc

