from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class SquadCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=2, max_length=120)


class SquadJoinRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    code: str = Field(min_length=6, max_length=6, pattern=r"^[A-Fa-f0-9]{6}$")

    @field_validator("code")
    @classmethod
    def normalize_code(cls, value: str) -> str:
        return value.upper()


class SquadResponse(BaseModel):
    id: str
    name: str
    code: str
    owner_id: str
    member_ids: list[str]
    current_user_role: str

    @property
    def member_count(self) -> int:
        return len(self.member_ids)


class SquadMemberResponse(BaseModel):
    user_id: str
    name: str
    avatar_url: str | None = None
    role: Literal["admin", "member"]
    joined_at: datetime
    last_location_at: datetime | None = None
    is_owner: bool
    is_current_user: bool


class SquadRoleUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    role: Literal["admin", "member"]
