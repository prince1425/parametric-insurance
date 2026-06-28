from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user
from app.services.platform_service import PlatformService

router = APIRouter()


@router.get("/plots")
def plot_geojson(
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    return PlatformService(db).plot_geojson()


@router.get("/summary")
def map_summary(
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    return PlatformService(db).map_summary()
