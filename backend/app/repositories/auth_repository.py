from sqlalchemy import text
from sqlalchemy.orm import Session

from app.repositories.common import row_to_dict


class AuthRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_user_by_email(self, email: str) -> dict | None:
        row = self.db.execute(
            text(
                """
                SELECT
                    u.id::text,
                    u.email,
                    u.full_name,
                    u.hashed_password,
                    u.status,
                    COALESCE(array_agg(r.role_key) FILTER (WHERE r.role_key IS NOT NULL), '{}') AS roles
                FROM users u
                LEFT JOIN user_roles ur ON ur.user_id = u.id
                LEFT JOIN roles r ON r.id = ur.role_id
                WHERE lower(u.email) = lower(:email)
                GROUP BY u.id
                """
            ),
            {"email": email},
        ).mappings().first()
        return row_to_dict(row)

    def get_user_by_id(self, user_id: str) -> dict | None:
        row = self.db.execute(
            text(
                """
                SELECT
                    u.id::text,
                    u.email,
                    u.full_name,
                    u.status,
                    COALESCE(array_agg(r.role_key) FILTER (WHERE r.role_key IS NOT NULL), '{}') AS roles
                FROM users u
                LEFT JOIN user_roles ur ON ur.user_id = u.id
                LEFT JOIN roles r ON r.id = ur.role_id
                WHERE u.id = CAST(:user_id AS uuid)
                GROUP BY u.id
                """
            ),
            {"user_id": user_id},
        ).mappings().first()
        return row_to_dict(row)
