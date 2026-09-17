from fastapi import APIRouter, HTTPException, status
from jose import JWTError

from app.domains.auth.schemas import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest
from app.domains.auth.service import auth_service

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest) -> AuthResponse:
    try:
        return auth_service.register(payload)
    except ValueError as exc:
        if str(exc) == "email_already_registered":
            raise HTTPException(status_code=409, detail="El correo ya está registrado.") from exc
        raise


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest) -> AuthResponse:
    try:
        return auth_service.login(payload)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Credenciales inválidas.") from exc


@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest) -> AuthResponse:
    try:
        return auth_service.refresh(payload.refresh_token)
    except (JWTError, ValueError) as exc:
        raise HTTPException(status_code=401, detail="Refresh token inválido.") from exc

