from datetime import datetime, timedelta, timezone
import logging
from urllib.parse import urlencode
from uuid import UUID

import httpx
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.settings import settings
from app.domains.clash_resolver.schemas import MusicPreferencesResponse
from app.domains.clash_resolver.service import ClashResolverService

logger = logging.getLogger(__name__)


class SpotifyConfigurationError(RuntimeError):
    pass


class SpotifyProviderError(RuntimeError):
    pass


class SpotifyOAuthService:
    authorize_url = "https://accounts.spotify.com/authorize"
    token_url = "https://accounts.spotify.com/api/token"
    top_artists_url = "https://api.spotify.com/v1/me/top/artists"

    def __init__(self, preferences: ClashResolverService):
        self._preferences = preferences

    def authorization_url(self, user_id: UUID) -> str:
        self._require_configuration()
        now = datetime.now(timezone.utc)
        state = jwt.encode(
            {
                "sub": str(user_id),
                "type": "spotify_oauth",
                "iat": now,
                "exp": now + timedelta(minutes=10),
            },
            settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
        )
        return self.authorize_url + "?" + urlencode(
            {
                "client_id": settings.spotify_client_id,
                "response_type": "code",
                "redirect_uri": settings.spotify_redirect_uri,
                "scope": "user-top-read",
                "state": state,
                "show_dialog": "true",
            }
        )

    def user_from_state(self, state: str) -> UUID:
        try:
            claims = jwt.decode(
                state,
                settings.jwt_secret_key,
                algorithms=[settings.jwt_algorithm],
            )
            if claims.get("type") != "spotify_oauth":
                raise ValueError("invalid_state_type")
            return UUID(str(claims["sub"]))
        except (JWTError, KeyError, TypeError, ValueError) as exc:
            raise SpotifyProviderError("El estado OAuth es inválido o expiró.") from exc

    async def import_preferences(
        self,
        db: Session,
        user_id: UUID,
        authorization_code: str,
        redirect_uri: str,
        code_verifier: str | None = None,
    ) -> MusicPreferencesResponse:
        self._require_configuration()
        token_data = {
            "grant_type": "authorization_code",
            "code": authorization_code,
            "redirect_uri": redirect_uri,
        }
        if code_verifier:
            token_data["code_verifier"] = code_verifier
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                token_response = await client.post(
                    self.token_url,
                    data=token_data,
                    auth=(settings.spotify_client_id, settings.spotify_client_secret),
                )
                if token_response.is_error:
                    raise self._provider_error("token", token_response)
                access_token = token_response.json()["access_token"]
                artists_response = await client.get(
                    self.top_artists_url,
                    params={"limit": 20, "time_range": "medium_term"},
                    headers={"Authorization": f"Bearer {access_token}"},
                )
                if artists_response.is_error:
                    raise self._provider_error("artists", artists_response)
        except SpotifyProviderError:
            raise
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            raise SpotifyProviderError(
                "No se pudo comunicar con Spotify. Intenta nuevamente o usa "
                "el fallback manual."
            ) from exc

        items = artists_response.json().get("items", [])
        artists = [str(item["name"]) for item in items if item.get("name")][:12]
        genre_counts: dict[str, int] = {}
        for item in items:
            for genre in item.get("genres", []):
                normalized = str(genre).strip().casefold()
                if normalized:
                    genre_counts[normalized] = genre_counts.get(normalized, 0) + 1
        genres = sorted(genre_counts, key=lambda name: (-genre_counts[name], name))[:12]
        if not artists and not genres:
            raise SpotifyProviderError(
                "Spotify no devolvió datos suficientes. Usa el fallback manual."
            )
        return self._preferences.save_preferences(
            db, user_id, genres, artists, source="spotify"
        )

    def _require_configuration(self) -> None:
        if not settings.spotify_client_id or not settings.spotify_client_secret:
            raise SpotifyConfigurationError(
                "Spotify OAuth no está configurado en el backend. "
                "Usa preferencias manuales por ahora."
            )

    def _provider_error(
        self, stage: str, response: httpx.Response
    ) -> SpotifyProviderError:
        error_code = "unknown"
        try:
            payload = response.json()
            error = payload.get("error", payload)
            if isinstance(error, dict):
                error_code = str(error.get("reason") or error.get("status") or "unknown")
            elif error:
                error_code = str(error)
        except (TypeError, ValueError):
            pass
        logger.warning(
            "Spotify request failed stage=%s status=%s error=%s",
            stage,
            response.status_code,
            error_code,
        )
        if stage == "artists" and response.status_code == 403:
            return SpotifyProviderError(
                "Spotify rechazó el acceso a tus artistas. Verifica que la cuenta "
                "esté agregada en Users Management y que el propietario de la app "
                "tenga Spotify Premium."
            )
        if response.status_code == 429:
            return SpotifyProviderError(
                "Spotify alcanzó el límite temporal de solicitudes. Intenta más tarde."
            )
        if stage == "token" and response.status_code in {400, 401}:
            return SpotifyProviderError(
                "Spotify rechazó las credenciales o el callback. Revisa Client ID, "
                "Client Secret y la Redirect URI registrada."
            )
        return SpotifyProviderError(
            f"Spotify no pudo completar la importación (HTTP {response.status_code}). "
            "Usa el fallback manual."
        )


spotify_oauth_service = SpotifyOAuthService(ClashResolverService())
