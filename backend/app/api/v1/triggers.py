from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user
from app.services.platform_service import PlatformService

router = APIRouter()


@router.get("")
def list_triggers(
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
) -> list[dict]:
    return PlatformService(db).triggers()


@router.get("/approval-queue")
def approval_queue(
    db: Annotated[Session, Depends(get_db)],
    _user: Annotated[dict, Depends(get_current_user)],
) -> list[dict]:
    return PlatformService(db).repo.approval_queue()
