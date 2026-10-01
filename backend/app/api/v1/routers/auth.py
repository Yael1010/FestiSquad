from fastapi import APIRouter, File, HTTPException, UploadFile, status
from fastapi.responses import HTMLResponse
from jose import JWTError

from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.auth.schemas import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    UserResponse,
    SocialAuthorizationResponse,
    SocialSessionRequest,
    SocialSessionResponse,
)
from app.domains.auth.service import auth_service
from app.domains.auth.social_service import (
    SocialAuthError,
    SocialProvider,
    social_auth_service,
)
from app.core.avatar_storage import AvatarValidationError, avatar_storage

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
    return _user_response(current_user)


@router.post("/avatar", response_model=UserResponse)
async def upload_avatar(
    current_user: CurrentUser,
    db: DatabaseSession,
    file: UploadFile = File(...),
) -> UserResponse:
    # Se lee un byte adicional para identificar cargas que exceden el límite.
    content = await file.read(avatar_storage.max_bytes + 1)
    try:
        new_avatar_url = avatar_storage.save(current_user.id, content)
    except AvatarValidationError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    previous_avatar_url = current_user.avatar_url
    try:
        current_user.avatar_url = new_avatar_url
        db.commit()
    except Exception:
        db.rollback()
        avatar_storage.delete(new_avatar_url)
        raise
    avatar_storage.delete(previous_avatar_url)
    return _user_response(current_user)


@router.delete("/avatar", response_model=UserResponse)
def delete_avatar(
    current_user: CurrentUser,
    db: DatabaseSession,
) -> UserResponse:
    previous_avatar_url = current_user.avatar_url
    current_user.avatar_url = None
    db.commit()
    avatar_storage.delete(previous_avatar_url)
    return _user_response(current_user)


@router.post(
    "/social/{provider}/start",
    response_model=SocialAuthorizationResponse,
    status_code=status.HTTP_201_CREATED,
)
def start_social_login(
    provider: SocialProvider,
    db: DatabaseSession,
) -> SocialAuthorizationResponse:
    try:
        return social_auth_service.start(db, provider)
    except SocialAuthError as exc:
        raise HTTPException(status_code=503, detail=_social_error(str(exc))) from exc


@router.post(
    "/social/{provider}/link",
    response_model=SocialAuthorizationResponse,
    status_code=status.HTTP_201_CREATED,
)
def start_social_link(
    provider: SocialProvider,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> SocialAuthorizationResponse:
    try:
        return social_auth_service.start(db, provider, current_user.id)
    except SocialAuthError as exc:
        raise HTTPException(status_code=503, detail=_social_error(str(exc))) from exc


@router.get(
    "/social/{provider}/callback",
    response_class=HTMLResponse,
    include_in_schema=False,
)
async def social_callback(
    provider: SocialProvider,
    state: str,
    db: DatabaseSession,
    code: str | None = None,
    error: str | None = None,
) -> HTMLResponse:
    try:
        await social_auth_service.complete(db, provider, state, code, error)
        return HTMLResponse(_social_callback_page(provider, success=True))
    except SocialAuthError:
        return HTMLResponse(_social_callback_page(provider, success=False))


@router.post("/social/session", response_model=SocialSessionResponse)
def consume_social_session(
    payload: SocialSessionRequest,
    db: DatabaseSession,
) -> SocialSessionResponse:
    try:
        return social_auth_service.consume(db, payload.flow_token)
    except SocialAuthError as exc:
        raise HTTPException(status_code=404, detail=_social_error(str(exc))) from exc


def _social_error(code: str) -> str:
    messages = {
        "provider_not_configured": "El proveedor social no está configurado.",
        "flow_not_found": "El intento de acceso expiró o ya fue utilizado.",
        "flow_expired": "El intento de acceso expiró.",
        "authorization_denied": "La autorización fue cancelada.",
        "provider_unavailable": "El proveedor no pudo completar el acceso.",
        "provider_profile_incomplete": "El proveedor no compartió un correo válido.",
        "email_requires_account_link": (
            "Ese correo ya existe. Inicia sesión con contraseña y vincula el proveedor."
        ),
        "provider_already_linked": "Ese proveedor ya está vinculado a una cuenta.",
    }
    return messages.get(code, "No fue posible completar el acceso social.")


def _user_response(user) -> UserResponse:
    return UserResponse(
        id=str(user.id),
        name=user.name,
        email=user.email,
        avatar_url=user.avatar_url,
    )


def _social_callback_page(provider: SocialProvider, *, success: bool) -> str:
    title = "Cuenta conectada" if success else "No se pudo conectar la cuenta"
    detail = (
        "Vuelve a FestiSquad y confirma el acceso."
        if success
        else "Vuelve a FestiSquad para intentarlo de nuevo."
    )
    color = "#28d17c" if success else "#ff6680"
    return f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>{title}</title></head>
<body style="margin:0;background:#050a13;color:white;font-family:system-ui;display:grid;min-height:100vh;place-items:center">
<main style="max-width:560px;padding:32px"><p style="color:#32c5ff;text-transform:uppercase">{provider}</p>
<h1 style="color:{color};font-size:42px">{title}</h1><p style="font-size:20px">{detail}</p></main>
</body></html>"""
