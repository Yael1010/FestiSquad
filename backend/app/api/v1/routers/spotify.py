from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import HTMLResponse

from app.core.settings import settings
from app.domains.auth.dependencies import CurrentUser, DatabaseSession
from app.domains.clash_resolver.schemas import (
    ManualMusicPreferencesRequest,
    MusicPreferencesResponse,
    SpotifyAuthorizationResponse,
    SpotifyConnectRequest,
)
from app.domains.clash_resolver.service import clash_resolver_service
from app.domains.clash_resolver.spotify_service import (
    SpotifyConfigurationError,
    SpotifyProviderError,
    spotify_oauth_service,
)

router = APIRouter()


@router.post(
    "/spotify/authorize", response_model=SpotifyAuthorizationResponse
)
def authorize_spotify(current_user: CurrentUser) -> SpotifyAuthorizationResponse:
    try:
        return SpotifyAuthorizationResponse(
            authorization_url=spotify_oauth_service.authorization_url(current_user.id)
        )
    except SpotifyConfigurationError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc


@router.get("/spotify/callback", response_class=HTMLResponse, include_in_schema=False)
async def spotify_callback(
    db: DatabaseSession,
    code: str | None = Query(default=None),
    state_token: str | None = Query(default=None, alias="state"),
    error: str | None = Query(default=None),
) -> HTMLResponse:
    if error or not code or not state_token:
        return _oauth_page(
            False,
            "La autorización fue cancelada. Puedes usar el fallback manual.",
            status_code=400,
        )
    try:
        user_id = spotify_oauth_service.user_from_state(state_token)
        await spotify_oauth_service.import_preferences(
            db, user_id, code, settings.spotify_redirect_uri
        )
        return _oauth_page(True, "Preferencias importadas. Ya puedes volver a FestiSquad.")
    except (SpotifyConfigurationError, SpotifyProviderError) as exc:
        db.rollback()
        return _oauth_page(False, str(exc), status_code=502)


@router.post("/spotify/connect", response_model=MusicPreferencesResponse)
async def connect_spotify(
    payload: SpotifyConnectRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> MusicPreferencesResponse:
    try:
        return await spotify_oauth_service.import_preferences(
            db,
            current_user.id,
            payload.authorization_code,
            payload.redirect_uri,
            payload.code_verifier,
        )
    except SpotifyConfigurationError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except SpotifyProviderError as exc:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc


@router.get("/preferences/music", response_model=MusicPreferencesResponse)
def music_preferences(
    db: DatabaseSession, current_user: CurrentUser
) -> MusicPreferencesResponse:
    return clash_resolver_service.preferences(db, current_user.id)


@router.post("/preferences/music/manual", response_model=MusicPreferencesResponse)
def save_manual_preferences(
    payload: ManualMusicPreferencesRequest,
    db: DatabaseSession,
    current_user: CurrentUser,
) -> MusicPreferencesResponse:
    try:
        return clash_resolver_service.save_preferences(
            db, current_user.id, payload.genres, payload.artists, source="manual"
        )
    except Exception:
        db.rollback()
        raise


def _oauth_page(
    success: bool, message: str, status_code: int = 200
) -> HTMLResponse:
    color = "#2ec5f4" if success else "#ff718b"
    title = "Spotify conectado" if success else "No se pudo conectar Spotify"
    safe_message = (
        message.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )
    return HTMLResponse(
        "<!doctype html><html lang='es'><meta name='viewport' "
        "content='width=device-width,initial-scale=1'><body style='margin:0;"
        "background:#060b16;color:#f2f6ff;font-family:system-ui;display:grid;"
        "place-items:center;min-height:100vh'><main style='max-width:420px;padding:32px'>"
        f"<h1 style='color:{color}'>{title}</h1><p>{safe_message}</p>"
        "<p>Esta ventana ya se puede cerrar.</p></main></body></html>",
        status_code=status_code,
    )
