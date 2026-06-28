# Local Runbook

## Running Services

Backend:

```powershell
cd D:\anti\InnoMick\POC\task\parametric-insurance\backend
$env:DATABASE_URL = 'postgresql+psycopg://postgres:<local password>@localhost:5432/agrishield'
$env:JWT_SECRET_KEY = 'local-dev-secret'
$env:DEMO_PASSWORD = 'demo123'
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Frontend:

```powershell
cd D:\anti\InnoMick\POC\task\parametric-insurance\frontend
$env:VITE_API_BASE_URL = 'http://127.0.0.1:8000/api/v1'
pnpm dev -- --port 5173
```

## URLs

- Frontend: `http://127.0.0.1:5173`
- Backend health: `http://127.0.0.1:8000/health`
- Swagger docs: `http://127.0.0.1:8000/docs`

## Demo Login

- Email: `admin@agrishield.local`
- Password: value of `DEMO_PASSWORD`, locally set to `demo123` during development
