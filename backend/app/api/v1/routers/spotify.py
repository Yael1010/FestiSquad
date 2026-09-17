from pydantic import BaseModel
from fastapi import APIRouter

router = APIRouter()


class SpotifyConnectRequest(BaseModel):
    user_id: str
    authorization_code: str
    redirect_uri: str


class ManualMusicPreferencesRequest(BaseModel):
    user_id: str
    genres: list[str]
    artists: list[str] = []


@router.post("/spotify/connect")
def connect_spotify(payload: SpotifyConnectRequest) -> dict[str, str]:
    return {
        "status": "pending_oauth_exchange",
        "message": "Contrato preparado para integrar OAuth 2.0 de Spotify.",
        "user_id": payload.user_id,
    }


@router.post("/preferences/music/manual")
def save_manual_preferences(payload: ManualMusicPreferencesRequest) -> dict[str, object]:
    return {"status": "saved", "user_id": payload.user_id, "genres": payload.genres, "artists": payload.artists}

