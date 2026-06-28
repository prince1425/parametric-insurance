# Phase 4 - Backend APIs

Status: Complete

Phase 4 implements a FastAPI backend vertical slice against the local `agrishield` database and `agri` schema.

## Architecture

- FastAPI application under `backend/app`.
- SQLAlchemy database sessions with `search_path=agri,public`.
- Repository layer for SQL queries.
- Service layer for auth and platform workflows.
- Versioned routes under `/api/v1`.
- JWT bearer authentication for protected endpoints.

## Implemented API Groups

| Group | Endpoints |
|---|---|
| Health | `GET /health` |
| Auth | `POST /api/v1/auth/login`, `GET /api/v1/auth/me` |
| Dashboard | `GET /api/v1/dashboard/summary` |
| Farmers | `GET /api/v1/farmers` |
| Policies | `GET /api/v1/policies` |
| Triggers | `GET /api/v1/triggers`, `GET /api/v1/triggers/approval-queue` |
| Payouts | `GET /api/v1/payouts` |
| Observations | `GET /api/v1/observations/ndvi/{plot_id}` |
| GIS | `GET /api/v1/gis/plots`, `GET /api/v1/gis/summary` |
| ML | `GET /api/v1/ml/risk-scores` |

## Local Demo Login

The seed creates:

```text
admin@agrishield.local
underwriter@agrishield.local
field.officer@agrishield.local
```

For local development only, demo users use the `DEMO_PASSWORD` environment variable.

## Best Practices Applied

- Database password is not committed.
- API routes do not contain business SQL.
- Repositories isolate database queries.
- Protected endpoints require bearer tokens.
- GeoJSON is served from PostGIS, not static files.
- Demo data is labeled as sample data in database rows.
