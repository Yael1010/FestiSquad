from fastapi import APIRouter

from app.api.v1.routers import auth, clash_resolver, expenses, festivals, locations, squads, spotify

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(squads.router, prefix="/squads", tags=["squads"])
api_router.include_router(locations.router, prefix="/locations", tags=["locations"])
api_router.include_router(festivals.router, prefix="/festivals", tags=["festivals"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["expenses"])
api_router.include_router(clash_resolver.router, prefix="/clash-resolver", tags=["clash-resolver"])
api_router.include_router(spotify.router, tags=["spotify"])
