from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user
from app.services.platform_service import PlatformService

router = APIRouter()


@router.get("/ndvi/{plot_id}")
def ndvi_series(
    plot_id: int,
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    service = PlatformService(db)
    plot = service.plot_detail(plot_id)
    if not plot:
        raise HTTPException(status_code=404, detail="Plot not found")
    return {"plot": plot, "series": service.ndvi_series(plot_id)}
