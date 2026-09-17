from pydantic import BaseModel, Field


class SquadCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    owner_id: str


class SquadJoinRequest(BaseModel):
    code: str = Field(min_length=6, max_length=12)
    user_id: str


class SquadResponse(BaseModel):
    id: str
    name: str
    code: str
    owner_id: str
    member_ids: list[str]

