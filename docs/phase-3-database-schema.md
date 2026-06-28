# Phase 3 - Database Schema

## Phase Status

Status: Complete

This phase creates the database schema for the Parametric Agricultural Insurance Platform. It defines normalized PostgreSQL tables, PostGIS geometry storage, time-series observation tables, reference seeds, reporting views, trigger helper functions, and optional TimescaleDB conversion.

No backend APIs, frontend screens, GIS UI, ML code, tests, deployment files, or production optimization are implemented in this phase.

## 1. Architecture

The schema uses one application schema:

```text
agri
```

Database engine:

- PostgreSQL 17 locally.
- PostGIS for spatial data.
- TimescaleDB optional for observation hypertables.
- `pgcrypto` and `uuid-ossp` for UUIDs and hashes.

Local database:

```text
agrishield
```

Important local finding:

- PostGIS is available and installed.
- TimescaleDB is not available on the local PostgreSQL instance at the time of this phase.
- The optional TimescaleDB migration is safe to run; it emits a notice and keeps time-series tables as standard PostgreSQL tables when the extension is unavailable.

Local apply result:

| Object | Count |
|---|---:|
| Tables in `agri` | 52 |
| Views in `agri` | 5 |
| Helper functions in `agri` | 7 |
| Roles seeded | 8 |
| Permissions seeded | 24 |
| Data sources seeded | 16 |
| Crops seeded | 8 |
| Trigger rules seeded | 3 |
| System settings seeded | 5 |

Applied migration records:

- `0001_initial_schema`
- `seed_0001_reference_data`
- `views_0001_reporting_views`

`0002_optional_timescaledb` did not record a migration row because TimescaleDB is not available locally and no hypertable changes were made.

## 2. Folder Structure

Phase 3 added:

```text
database/
  README.md
  migrations/
    0001_initial_schema.sql
    0002_optional_timescaledb.sql
  seeds/
    0001_reference_data.sql
  views/
    0001_reporting_views.sql
docs/
  phase-3-database-schema.md
shared/
  domain/
    phase3-schema.json
```

## 3. Database Changes

### 3.1 Extensions

Base schema migration enables:

- `postgis`
- `postgis_topology`
- `pgcrypto`
- `uuid-ossp`

Optional migration enables:

- `timescaledb`, only when it is available.

### 3.2 Core Entity Groups

| Group | Tables |
|---|---|
| Migration tracking | `schema_migrations` |
| Identity and RBAC | `roles`, `permissions`, `role_permissions`, `users`, `user_roles`, `refresh_tokens`, `api_clients` |
| Sources and files | `data_sources`, `file_objects` |
| Geography | `states`, `districts`, `talukas`, `villages`, `admin_boundaries` |
| Farmer and KYC | `farmers`, `farmer_kyc_documents` |
| Farms and plots | `farms`, `plots` |
| Crops and agronomy | `crops`, `crop_calendar`, `crop_growth_stages`, `ndvi_baselines` |
| Policy and premium | `policy_types`, `premium_rules`, `policies`, `policy_crops`, `premium_quotes` |
| Claims | `claims` |
| ML registry | `model_versions`, `prediction_runs`, `crop_cycles` |
| Observation ingestion | `observation_batches`, `satellite_observations`, `ndvi_observations`, `rvi_observations`, `rainfall_observations`, `temperature_observations`, `soil_moisture_observations`, `flood_observations` |
| Trigger and basis risk | `trigger_rules`, `trigger_events`, `basis_risk_flags` |
| Approval and payout | `payout_approvals`, `payout_records`, `payout_payment_events` |
| Notifications and reports | `notification_templates`, `notification_logs`, `report_exports` |
| Settings and idempotency | `system_settings`, `idempotency_keys` |
| Audit | `audit_log` |

### 3.3 Spatial Design

Spatial columns use SRID `4326`.

Geometry tables:

- `districts.geometry`
- `talukas.geometry`
- `villages.geometry`
- `admin_boundaries.geometry`
- `farms.boundary`
- `farms.centroid`
- `plots.boundary`
- `plots.centroid`
- `satellite_observations.footprint`
- `flood_observations.flood_extent`

Spatial indexes:

- GiST indexes are created for geometry and centroid columns.

### 3.4 Time-Series Design

Observation tables are normal PostgreSQL tables by default:

- `ndvi_observations`
- `rvi_observations`
- `rainfall_observations`
- `temperature_observations`
- `soil_moisture_observations`
- `flood_observations`
- `satellite_observations`

If TimescaleDB is installed later, run:

```text
database/migrations/0002_optional_timescaledb.sql
```

That migration converts observation tables to hypertables and adds compression policies for high-volume tables.

### 3.5 Immutability and Audit

Append-only protection is enforced for:

- `audit_log`
- `trigger_events`

Payouts use:

- `payout_records` for current payout record and core amount.
- `payout_payment_events` for payment state history.

Application services in Phase 4 should write audit records for business-critical changes.

### 3.6 Helper Functions

The schema includes:

- `set_updated_at()`
- `prevent_update_delete()`
- `compute_ndvi_anomaly(observed, expected)`
- `anomaly_to_stress_band(anomaly_pct)`
- `stress_band_to_payout_pct(band)`
- `calculate_payout_amount(sum_insured, payout_pct)`
- `generate_record_hash(parts)`

## 4. API Design

No API is implemented in Phase 3.

Phase 4 backend APIs should map to this schema through repository and service layers. API routes should not query tables directly.

Recommended repository groups:

- Identity repository.
- Farmer repository.
- Farm and plot repository.
- Policy repository.
- Observation repository.
- Crop intelligence repository.
- Trigger repository.
- Basis-risk repository.
- Approval repository.
- Payout repository.
- Notification repository.
- Audit repository.
- Reporting query repository.

## 5. UI Screens

No UI is implemented in Phase 3.

Phase 5 frontend screens should use read models from views such as:

- `v_plot_trigger_summary`
- `v_approval_queue`
- `v_district_risk_summary`
- `v_farmer_policy_summary`
- `v_latest_ndvi_by_plot`

## 6. Workflow

### 6.1 Local Run Order

```text
0001_initial_schema.sql
0001_reference_data.sql
0001_reporting_views.sql
0002_optional_timescaledb.sql
```

The optional TimescaleDB migration can run last because it depends on existing observation tables.

### 6.2 Data Flow

```text
data_sources -> observation_batches -> observations -> crop_cycles -> trigger_events -> basis_risk_flags -> payout_approvals -> payout_records -> payout_payment_events -> notification_logs -> audit_log
```

### 6.3 Policy Flow

```text
farmers -> farms -> plots -> policies -> policy_crops -> trigger_events -> payout_records
```

## 7. Code

Phase 3 code artifacts:

- `database/migrations/0001_initial_schema.sql`
- `database/migrations/0002_optional_timescaledb.sql`
- `database/seeds/0001_reference_data.sql`
- `database/views/0001_reporting_views.sql`
- `shared/domain/phase3-schema.json`

These are database artifacts, not backend application code.

## 8. Best Practices

- Do not store real passwords in repository files.
- Do not store raw Aadhaar or raw bank details.
- Treat sample geometry and mock data as explicitly labeled records.
- Keep observations separate from derived trigger events.
- Keep trigger rules versioned.
- Keep trigger events append-only.
- Store payout payment transitions in event history.
- Use views for dashboards instead of making UI pages join many normalized tables directly.
- Use TimescaleDB when production observation volume grows.
- Keep `agri` as the application schema to avoid collisions with PostGIS extension objects in `public`.

## 9. Phase 3 Acceptance Criteria

Phase 3 is complete when:

- Normalized PostgreSQL schema exists.
- PostGIS geometry columns and indexes exist.
- Time-series observation tables exist.
- Optional TimescaleDB migration exists and is safe when unavailable.
- RBAC tables exist.
- Farmer, KYC, farm, plot, policy, crop, observation, trigger, payout, notification, settings, and audit tables exist.
- Reference seeds exist.
- Dashboard/reporting views exist.
- Helper functions exist.
- Machine-readable schema catalog exists.

All criteria are satisfied by this phase.

## 10. Next Phase Gate

Next phase: Phase 4 - Backend APIs

Phase 4 should implement FastAPI, SQLAlchemy models, Alembic migration integration, authentication, RBAC dependencies, repositories, services, and initial API routes against this schema.
