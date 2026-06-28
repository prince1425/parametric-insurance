# Phase 5 - Frontend

Status: Complete

Phase 5 implements a React, TypeScript, Vite, Tailwind, React Query, React Router, Recharts, Framer Motion-ready frontend shell for the Agrishield operations console.

## Implemented Screens

- Login
- Dashboard
- GIS map
- Policies
- Trigger monitor
- Payout ledger

## Architecture

- `src/lib/api.ts` centralizes API calls.
- `src/store/auth.tsx` manages bearer token and current user state.
- `src/components/layout/AppShell.tsx` provides role-aware operations layout.
- `src/components/shared` contains reusable KPI and status components.
- Route-level pages live under `src/pages`.

## API Integration

The frontend reads from:

- `/api/v1/auth/login`
- `/api/v1/dashboard/summary`
- `/api/v1/policies`
- `/api/v1/triggers`
- `/api/v1/payouts`
- `/api/v1/gis/plots`

## UI Direction

The UI is operational rather than marketing-led: dense KPI cards, tables, queues, charts, and map-first GIS workflows.
