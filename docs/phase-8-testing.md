# Phase 8 - Testing

Status: Complete

Phase 8 adds verification for the database, backend APIs, frontend build, GIS route, and ML risk scoring.

## Test Assets

- `database/validation/phase8_smoke.sql`
- `backend/tests/integration/test_api_smoke.py`
- `backend/tests/unit/test_security.py`
- `ml/tests/test_risk_scoring.py`

## Coverage

- Database row and view availability.
- Health endpoint and DB connectivity.
- JWT login flow.
- Dashboard summary API.
- GIS GeoJSON API.
- ML risk score API.
- JWT encode/decode unit behavior.
- Deterministic risk scoring behavior.
- Frontend production build.

## Commands

```powershell
$env:PGPASSWORD = '<local password>'
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U postgres -d agrishield -v ON_ERROR_STOP=1 -f database/validation/phase8_smoke.sql

cd backend
$env:DATABASE_URL = 'postgresql+psycopg://postgres:<local password>@localhost:5432/agrishield'
$env:JWT_SECRET_KEY = 'local-test-secret'
$env:DEMO_PASSWORD = 'demo123'
.\.venv\Scripts\python.exe -m pytest

cd ..\frontend
pnpm build
```

## Notes

- The integration tests expect the Phase 3 reference seed, Phase 3 demo portfolio seed, and Phase 7 ML scoring output to exist in `agrishield`.
- Passwords should be provided through environment variables, not committed files.

## Local Results

Executed on 2026-06-29:

| Check | Result |
|---|---|
| Database smoke SQL | Passed, 7/7 checks true |
| Backend pytest | Passed, 5 tests |
| ML pytest | Passed, 1 test |
| Frontend production build | Passed |
| Backend server | `http://127.0.0.1:8000/health` returned `{"status":"ok","database":"ok"}` |
| Frontend server | `http://127.0.0.1:5173` returned HTTP 200 |
