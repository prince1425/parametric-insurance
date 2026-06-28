from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import create_access_token, verify_password
from app.repositories.auth_repository import AuthRepository


class AuthService:
    def __init__(self, db: Session) -> None:
        self.repo = AuthRepository(db)

    def login(self, email: str, password: str) -> dict:
        user = self.repo.get_user_by_email(email)
        if not user or user["status"] != "active":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
        if not verify_password(password, user["hashed_password"]):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

        token = create_access_token(
            user["id"],
            {"email": user["email"], "roles": list(user["roles"] or [])},
        )
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user["id"],
                "email": user["email"],
                "full_name": user["full_name"],
                "roles": list(user["roles"] or []),
            },
        }

    def current_user(self, user_id: str) -> dict:
        user = self.repo.get_user_by_id(user_id)
        if not user or user["status"] != "active":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Inactive user")
        user["roles"] = list(user["roles"] or [])
        return user
