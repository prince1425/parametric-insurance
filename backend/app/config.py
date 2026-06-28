from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Agrishield API"
    api_prefix: str = "/api/v1"
    database_url: str = Field(..., alias="DATABASE_URL")
    jwt_secret_key: str = Field("dev-only-change-me", alias="JWT_SECRET_KEY")
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 60
    cors_origins: str = Field("http://localhost:5173,http://127.0.0.1:5173", alias="CORS_ORIGINS")
    demo_password: str = Field("demo123", alias="DEMO_PASSWORD")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
