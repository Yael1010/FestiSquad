from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RegisterRequest(StrictModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(StrictModel):
    email: EmailStr
    password: str


class RefreshRequest(StrictModel):
    refresh_token: str


class AuthResponse(BaseModel):
    user_id: str
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    name: str
    email: EmailStr


class SocialAuthorizationResponse(BaseModel):
    provider: Literal["google", "spotify"]
    authorization_url: str
    flow_token: str
    expires_in_seconds: int


class SocialSessionRequest(StrictModel):
    flow_token: str = Field(min_length=32, max_length=200)


class SocialSessionResponse(BaseModel):
    status: Literal["pending", "completed", "failed"]
    session: AuthResponse | None = None
    error: str | None = None
