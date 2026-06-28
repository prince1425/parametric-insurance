from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies import get_current_user
from app.schemas.auth import LoginRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Annotated[Session, Depends(get_db)]) -> dict:
    return AuthService(db).login(payload.email, payload.password)


@router.get("/me")
def me(current_user: Annotated[dict, Depends(get_current_user)]) -> dict:
    return current_user
