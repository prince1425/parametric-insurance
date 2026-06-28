from fastapi import APIRouter

from app.api.v1 import auth, dashboard, farmers, gis, ml, observations, payouts, policies, triggers

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(farmers.router, prefix="/farmers", tags=["farmers"])
api_router.include_router(policies.router, prefix="/policies", tags=["policies"])
api_router.include_router(triggers.router, prefix="/triggers", tags=["triggers"])
api_router.include_router(payouts.router, prefix="/payouts", tags=["payouts"])
api_router.include_router(observations.router, prefix="/observations", tags=["observations"])
api_router.include_router(gis.router, prefix="/gis", tags=["gis"])
api_router.include_router(ml.router, prefix="/ml", tags=["ml"])
