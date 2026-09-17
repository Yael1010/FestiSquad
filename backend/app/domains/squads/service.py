import secrets
from uuid import uuid4

from app.domains.squads.schemas import SquadCreateRequest, SquadJoinRequest, SquadResponse


class SquadService:
    def __init__(self) -> None:
        self._squads: dict[str, SquadResponse] = {}
        self._ids_by_code: dict[str, str] = {}

    def create(self, payload: SquadCreateRequest) -> SquadResponse:
        code = self._unique_code()
        squad = SquadResponse(
            id=str(uuid4()),
            name=payload.name,
            code=code,
            owner_id=payload.owner_id,
            member_ids=[payload.owner_id],
        )
        self._squads[squad.id] = squad
        self._ids_by_code[code] = squad.id
        return squad

    def join(self, payload: SquadJoinRequest) -> SquadResponse:
        squad_id = self._ids_by_code.get(payload.code.upper())
        if squad_id is None:
            raise ValueError("squad_not_found")

        squad = self._squads[squad_id]
        if payload.user_id not in squad.member_ids:
            squad.member_ids.append(payload.user_id)
        return squad

    def get(self, squad_id: str) -> SquadResponse:
        squad = self._squads.get(squad_id)
        if squad is None:
            raise ValueError("squad_not_found")
        return squad

    def _unique_code(self) -> str:
        while True:
            code = secrets.token_hex(3).upper()
            if code not in self._ids_by_code:
                return code


squad_service = SquadService()

