import json
from uuid import UUID

from fastapi import APIRouter, HTTPException
from sqlalchemy import text

from app.domains.auth.dependencies import CurrentUser, DatabaseSession

router = APIRouter()


@router.get("/{festival_id}")
def festival_map(
    festival_id: UUID, db: DatabaseSession, current_user: CurrentUser
) -> dict:
    del current_user
    festival = db.execute(
        text(
            "SELECT id, name, starts_at, ends_at, boundary_geojson "
            "FROM dbo.festivals WHERE id = :festival_id"
        ),
        {"festival_id": str(festival_id)},
    ).mappings().first()
    if festival is None:
        raise HTTPException(status_code=404, detail="Festival no encontrado.")
    stages = db.execute(
        text(
            "SELECT id, name, polygon_geojson FROM dbo.stages "
            "WHERE festival_id = :festival_id ORDER BY name"
        ),
        {"festival_id": str(festival_id)},
    ).mappings().all()
    return {
        "id": str(festival["id"]),
        "name": festival["name"],
        "starts_at": festival["starts_at"],
        "ends_at": festival["ends_at"],
        "boundary": json.loads(festival["boundary_geojson"]),
        "stages": [
            {
                "id": str(stage["id"]),
                "name": stage["name"],
                "polygon": json.loads(stage["polygon_geojson"]),
            }
            for stage in stages
        ],
    }
