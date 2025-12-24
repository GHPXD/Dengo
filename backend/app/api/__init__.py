"""API routers."""

from app.api.cities import router as cities_router
from app.api.dashboard import router as dashboard_router

__all__ = ["cities_router", "dashboard_router"]
