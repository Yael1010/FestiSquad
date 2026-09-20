"""App de diagnóstico: uvicorn app.db_probe:app --reload.

Puede incorporarse el router a main.py. No expone datos financieros.
"""
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import APIRouter, Depends, FastAPI, HTTPException
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from app.core.database import dispose_engine, get_db

router = APIRouter()


@router.get('/health/db', tags=['health'])
def database_health(db: Annotated[Session, Depends(get_db)]):
    try:
        db.execute(text('SELECT 1')).scalar_one()
    except SQLAlchemyError:
        raise HTTPException(status_code=503, detail='database_unavailable') from None
    return {'status': 'ok', 'database': 'sqlserver'}


@asynccontextmanager
async def lifespan(_app: FastAPI):
    yield
    dispose_engine()


app = FastAPI(title='FestiSquad SQL Server probe', lifespan=lifespan)
app.include_router(router)
