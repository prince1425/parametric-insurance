from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.config import get_settings
from app.db.session import healthcheck


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        description="Production-oriented API slice for Agrishield parametric agricultural insurance.",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(api_router, prefix=settings.api_prefix)

    from sqlalchemy.exc import SQLAlchemyError
    from fastapi import Request
    from fastapi.responses import JSONResponse

    @app.exception_handler(SQLAlchemyError)
    async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError) -> JSONResponse:
        # In a real production app, log the actual error securely here via a logger
        return JSONResponse(
            status_code=500,
            content={"message": "An internal database error occurred. Please try again later."},
        )

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok", **healthcheck()}

    return app


app = create_app()
