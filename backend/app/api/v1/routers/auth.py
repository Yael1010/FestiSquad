from fastapi import APIRouter, HTTPException, status
from jose import JWTError

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.auth.schemas import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    UserResponse,
)
from app.domains.auth.service import auth_service

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: DatabaseSession) -> AuthResponse:
    try:
        return auth_service.register(db, payload)
    except ValueError as exc:
        if str(exc) == "email_already_registered":
            raise HTTPException(status_code=409, detail="El correo ya está registrado.") from exc
        raise


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: DatabaseSession) -> AuthResponse:
    try:
        return auth_service.login(db, payload)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Credenciales inválidas.") from exc


@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest, db: DatabaseSession) -> AuthResponse:
    try:
        return auth_service.refresh(db, payload.refresh_token)
    except (JWTError, ValueError) as exc:
        raise HTTPException(status_code=401, detail="Refresh token inválido.") from exc


@router.get("/me", response_model=UserResponse)
def me(current_user: CurrentUser) -> UserResponse:
    return UserResponse(
        id=str(current_user.id),
        name=current_user.name,
        email=current_user.email,
    )
