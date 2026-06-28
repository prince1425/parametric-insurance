# Phase 1 - Business Analysis

## Phase Status

Status: Complete

This phase converts the supplied platform brief, Latur POC case study, static dashboard bundle, architecture analysis, project structure draft, and database schema draft into an implementation-ready product brief. No runtime application code is added in this phase because the instruction is to proceed phase by phase and stop before Phase 2.

## 1. Business Context

Farmers face crop losses from drought, rainfall deficit, delayed sowing, flooding, pest outbreaks, disease, and temperature stress. Traditional agricultural insurance depends on physical inspections and manual claim assessment, which can be slow, expensive, inconsistent, and difficult to audit.

The product goal is to automate agricultural insurance using parametric triggers. A payout is calculated when an agreed measurable index crosses a configured threshold. The platform must support demo data first, but its domain model and service boundaries must be ready for live sources such as IMD, CHIRPS, NASA POWER, ERA5, Sentinel Hub, Google Earth Engine, Copernicus, USGS, OpenWeather, Tomorrow.io, and ISRO Bhuvan.

## 2. Product Definition

Product name: Parametric Agricultural Insurance Platform

Initial product slice: Latur Crop Stress Parametric Cover

Insured unit:
- Phase 1 assumption: plot or farmer record from the Latur NDVI dataset.
- Production target: geotagged farm polygon or verified land parcel boundary.

Covered risk:
- Vegetation stress during the crop growth window.
- For the POC, this is treated as a crop-stress signal rather than final cause attribution.

Primary index:
- NDVI anomaly or NDVI decline compared with expected crop-stage behavior.

Secondary indexes:
- Rainfall anomaly or rainfall deficit.
- Soil moisture.
- Sentinel-1 SAR/RVI during cloud-heavy monsoon periods.
- Flood extent and water-level observations.
- Temperature stress and heat/cold wave observations.

Business output:
- Plot-wise eligibility.
- Payout percentage.
- Estimated payout amount.
- Reason code.
- Confidence score.
- Review flag.
- Audit trail.
- GIS-ready map layer.

## 3. Source Material Assessment

### Latur Case Study

The case study defines the core POC: use NDVI time series, crop prediction output, crop calendar data, trigger rules, payout ladder, and GIS-ready outputs to simulate explainable parametric crop insurance.

Important extracted data facts:

| Metric | Value |
|---|---:|
| Crop master records | 34 |
| NDVI plot/farmer records | 96 |
| NDVI observation dates | 36 |
| NDVI date range | 2025-06-04 to 2026-03-26 |
| Missing NDVI cells | 2.14% |
| Final prediction records | 96 |
| Detected crop cycles | 70 |
| Known crop average confidence | 90.83% |
| Unknown/fallow/insufficient signal plots | 29 |
| Single-crop plots | 64 |
| Double-crop plots | 3 |
| No-clear-cycle plots | 29 |

### Static Dashboard Bundle

The ZIP contains a static Leaflet dashboard with rainfall, earthquake, and flood scenarios. It is useful as a UX reference but is not production-ready.

Keep:
- Scenario filters.
- Map-plus-table workflow.
- KPI cards.
- CSV export.
- Payout action pattern.
- GeoJSON visualization skeleton.

Replace:
- Hardcoded constants in JavaScript.
- In-memory payment state.
- Synthetic rainfall patterns.
- Static GeoJSON as the only source of truth.
- No-auth flow.
- No audit log.
- No NDVI/satellite module.

### Architecture and Schema Drafts

The supplied architecture analysis correctly identifies the need for:

- FastAPI backend.
- PostgreSQL with PostGIS and TimescaleDB.
- React, TypeScript, Tailwind, Leaflet, and Recharts frontend.
- Trigger engine, payout workflow, basis-risk evaluator, audit ledger, and approval workflow.
- Model registry for crop prediction traceability.

The schema draft is a strong Phase 3 seed and should be carried forward after Phase 2 locks the architecture.

## 4. User Roles

| Role | Primary Jobs |
|---|---|
| Farmer | Register, complete KYC, view farm and policy, track crop health, receive alerts, download policy, track payout. |
| Insurance Company | Create, approve, renew, suspend, and price policies; monitor risk; approve payouts. |
| Field Officer | Verify farms, upload documents, inspect flagged cases, resolve low-confidence/basis-risk cases. |
| Admin | Manage users, roles, crops, districts, triggers, premium rules, data sources, reports, and settings. |
| Government | Monitor scheme performance, district risk, claim ratio, payout status, and compliance evidence. |
| Reinsurance Company | Monitor portfolio exposure, risk concentration, trigger trends, payout distribution, and loss ratio. |
| Auditor | Review immutable event history, approval actions, rule versions, data provenance, and payout evidence. |

## 5. Product Modules

MVP modules:

- Authentication and RBAC.
- Farmer registration and KYC.
- Farm and plot management.
- Policy management.
- Premium calculator.
- Weather monitoring.
- Satellite and NDVI monitoring.
- Crop monitoring.
- Trigger engine.
- Basis-risk review.
- Payout approval.
- Claims and payout history.
- GIS dashboard.
- Analytics dashboard.
- Reports.
- Notifications.
- Audit logs.
- Admin settings.

Later modules:

- External API management.
- ML model registry and retraining workflow.
- Payment gateway reconciliation.
- PMFBY/Agristack/land-record integrations.
- Offline field officer workflow.
- Farmer PWA and multilingual notifications.

## 6. Parametric Trigger Model

### Trigger A - Establishment Failure

Purpose: identify plots where crop growth fails after sowing.

Business logic:
- During early growth, NDVI should rise from the cycle start.
- If NDVI rise is less than `0.15` within `30-45` days, flag establishment risk.

Default decision:
- Supporting flag in first product slice.
- Requires manual review when confidence is low or crop cycle is unclear.

### Trigger B - Mid-Season Vegetation Stress

Purpose: identify vegetation stress during active growth or peak crop stage.

Business logic:

```text
NDVI anomaly (%) = ((Expected NDVI for crop-stage - Observed NDVI) / Expected NDVI for crop-stage) * 100
```

Default decision:
- Primary product trigger for the first product slice.
- Expected NDVI should initially come from crop-wise or cycle-wise median NDVI from the provided plots, then later from multi-year historical baselines.

### Trigger C - Sudden Decline After Peak

Purpose: detect sharp decline before expected harvest.

Business logic:
- If NDVI drops more than `0.25` within `15-30` days before expected harvest, flag stress.

Default decision:
- Supporting flag in first product slice.
- Requires careful interpretation because harvest, disease, drought, damage, or crop calendar mismatch can produce similar signals.

## 7. Payout Ladder

| Stress Band | Trigger Condition | Indicative Payout | Decision |
|---|---|---:|---|
| No stress | NDVI anomaly less than 10% | 0% | No payout |
| Mild stress | NDVI anomaly 10% to less than 20% | 25% | Auto-eligible only if confidence and policy checks pass |
| Moderate stress | NDVI anomaly 20% to less than 35% | 50% | Auto-eligible only if confidence and policy checks pass |
| Severe stress | NDVI anomaly at least 35% | 75% | Review recommended for high-value policies |
| Extreme stress / crop failure | NDVI extremely low or no clear crop cycle | 100% or manual review | Manual review required |

Default payout formula:

```text
payout_amount = sum_insured * payout_pct / 100
```

## 8. Basis-Risk Controls

Basis risk is a core insurance risk: the index may trigger without actual loss, or actual loss may occur without a trigger.

Cases that must be flagged:

- Unknown, fallow, or no-clear-cycle plots.
- Crop prediction confidence below the product threshold.
- Extreme stress band.
- Missing or interpolated NDVI around the trigger window.
- NDVI stress contradicted by rainfall or soil-moisture evidence.
- Missing or unverifiable plot geometry.
- Crop calendar mismatch.
- Duplicate or suspicious policy/plot records.

Recommended Phase 2 default:
- Auto-approve only when crop confidence is at least 85%, stress band is not Extreme, crop cycle is known, and no basis-risk flag exists.
- Route all Extreme, unknown/fallow, low-confidence, and contradictory-index cases to underwriter or field officer review.

## 9. Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | Users can authenticate using JWT access tokens and refresh tokens. | Must |
| FR-002 | Role-based access controls protect farmer, insurer, admin, government, reinsurer, auditor, and field officer functions. | Must |
| FR-003 | Admins can manage users, roles, permissions, crops, districts, triggers, premium rules, and data sources. | Must |
| FR-004 | Farmers can register, complete KYC, manage farm details, upload documents, view policies, view alerts, and track payouts. | Must |
| FR-005 | Insurers can create, approve, reject, renew, suspend, and price policies. | Must |
| FR-006 | The system stores plot or farm geometry when available and supports sample geometry for demos with clear labeling. | Must |
| FR-007 | The system stores weather, satellite, NDVI, rainfall, temperature, and soil-moisture observations with source provenance. | Must |
| FR-008 | Trigger B evaluates NDVI anomaly against expected crop-stage NDVI and emits stress band, payout percentage, reason code, and confidence. | Must |
| FR-009 | Trigger A and Trigger C are implemented as supporting flags before being used for auto-payout decisions. | Should |
| FR-010 | Every trigger event is immutable and linked to the rule version, input observations, policy, plot, and crop cycle. | Must |
| FR-011 | Payouts require approval workflow unless they meet configured auto-approval criteria. | Must |
| FR-012 | All approval and payout actions write audit records. | Must |
| FR-013 | Reports can be exported as CSV and later PDF/Excel. | Should |
| FR-014 | GIS dashboard supports village, district, farm polygon, NDVI, rainfall, flood, heat, risk, and policy layers. | Should |
| FR-015 | Analytics dashboards show premium collection, policy count, claim ratio, district comparison, crop comparison, rainfall trend, NDVI trend, risk trend, loss trend, and payout trend. | Should |

## 10. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Security | JWT, refresh tokens, password hashing, RBAC, input validation, audit logging, HTTPS readiness, and secure headers. |
| Privacy | Aadhaar and bank data must not be stored raw; store hashes or references to a secrets vault. |
| Reliability | Trigger runs must be idempotent and traceable by rule version and input observation version. |
| Performance | Dashboard list APIs must support pagination, filtering, sorting, and search. |
| Observability | Structured logs, health checks, audit trail, task status, and data-ingestion metrics. |
| Scalability | PostGIS for spatial queries, TimescaleDB for observations, Redis/Celery for ingestion and async jobs. |
| Maintainability | Clean architecture with separated API, service, repository, model, schema, utility, and config layers. |
| Accessibility | Responsive UI, keyboard-friendly controls, sufficient contrast, and mobile-first farmer workflows. |
| Localization | Marathi support is required for Latur farmer notifications in later phases. |
| Compliance | PMFBY, land records, Agristack, UIDAI, and payment integrations require explicit compliance review before production use. |

## 11. Architecture View For Phase 1

This phase defines bounded contexts rather than implementation details.

Core contexts:

- Identity and Access.
- Farmer and KYC.
- Farm and GIS.
- Policy and Premium.
- Observation Ingestion.
- Crop Calendar and Crop Cycle.
- Trigger Engine.
- Basis Risk.
- Approval Workflow.
- Payout and Payment.
- Notification.
- Reporting and Analytics.
- Audit Ledger.
- ML Model Registry.

Key architectural rule:
- Mock/demo data must enter through the same service interfaces that later live APIs will use. The application should replace adapters, not business logic, when moving from demo data to live data.

## 12. Folder Structure For Phase 2

The next phase should create the implementation structure below:

```text
parametric-insurance/
  backend/
    app/
      api/
      core/
      db/
      models/
      repositories/
      schemas/
      services/
      workers/
    alembic/
    tests/
  frontend/
    src/
      components/
      hooks/
      lib/
      pages/
      router/
      store/
      styles/
  database/
    migrations/
    seeds/
  docs/
  infra/
  ml/
  shared/
```

## 13. Database Changes For Phase 1

No database migration is applied in Phase 1.

The Phase 3 schema must cover these entities:

- Users, roles, permissions, refresh tokens.
- Farmers and KYC documents.
- Farms, plots, field polygons, villages, districts, states.
- Policies, policy crops, policy types, premiums.
- Crop calendar and crop cycles.
- Weather observations.
- Satellite observations.
- NDVI, RVI, rainfall, temperature, soil moisture time series.
- Trigger rules and trigger events.
- Basis-risk flags.
- Payout approvals and payout records.
- Claims.
- Notifications.
- Audit logs.
- Settings and API source configuration.
- ML model versions and prediction runs.

## 14. API Design For Phase 1

No API is implemented in Phase 1.

Phase 4 should expose versioned REST APIs under `/api/v1`.

Required API groups:

- Auth: login, refresh, logout, current user.
- Users and roles.
- Farmers and KYC.
- Farms, plots, and GIS layers.
- Policies and policy crops.
- Premium calculator.
- Weather observations.
- Satellite and NDVI observations.
- Crop calendar and crop cycles.
- Triggers and trigger rules.
- Basis-risk flags.
- Payout approvals.
- Payout records.
- Claims.
- Notifications.
- Reports.
- Dashboard aggregates.
- Audit logs.
- Settings and data sources.

API standards:

- OpenAPI/Swagger documentation.
- Pagination.
- Filtering.
- Sorting.
- Search.
- Validation.
- Consistent error shape.
- Idempotency for trigger and payout actions.
- Request tracing and audit metadata.

## 15. UI Screens For Phase 1

Screens required for the product:

- Landing.
- About.
- Products.
- Solutions.
- Pricing.
- Contact.
- Login.
- Register.
- Main dashboard.
- Farmer dashboard.
- Insurance dashboard.
- Government dashboard.
- Reinsurance dashboard.
- Admin dashboard.
- GIS map.
- NDVI and satellite viewer.
- Weather monitoring.
- Policies.
- Policy detail.
- Farm detail.
- Premium calculator.
- Risk dashboard.
- Trigger monitor.
- Basis-risk queue.
- Payout approval queue.
- Payout detail.
- Claims audit.
- Analytics.
- Reports.
- Notifications.
- Settings.
- API management.

Enterprise UI principles:

- Dense but readable operational layouts.
- Map and data table workflows for underwriting and government monitoring.
- Clear status badges for stress, approval, payment, and review states.
- No decorative dashboard-only demo patterns.
- Light and dark mode.
- Responsive views, with farmer workflows optimized for mobile.

## 16. Workflow

### Farmer and Policy Workflow

1. Farmer registers or is onboarded by a field officer.
2. Farmer KYC and bank/UPI details are verified.
3. Farm or plot is created with parcel geometry or sample/demo geometry.
4. Policy is quoted using crop, plot, season, sum insured, and risk factors.
5. Policy is purchased or approved.
6. Monitoring starts for the covered period.

### Trigger and Payout Workflow

1. Weather and satellite observations are ingested.
2. NDVI series is cleaned and quality flagged.
3. Crop cycle and crop-stage context are resolved.
4. Trigger engine evaluates A, B, and C.
5. Trigger event is written with reason code and confidence.
6. Basis-risk evaluator flags risky cases.
7. Approval workflow auto-approves eligible cases or routes to review.
8. Payout record is created only after approval.
9. Notification is sent to farmer or internal users.
10. Audit log records all state transitions.

## 17. Phase 1 Code Artifact

The machine-readable requirements catalog is stored at:

```text
shared/domain/phase1-requirements.json
```

Purpose:
- Preserve core business rules in a structured format.
- Give later backend/frontend phases a single traceability source for roles, triggers, payout ladder, phase gate, data sources, and acceptance criteria.
- Avoid scattering product rules only across prose documents.

This is not placeholder application code. It is a versioned domain artifact for later implementation.

## 18. Best Practices

- Treat demo data as a source adapter, not as business logic.
- Keep trigger rules configurable and versioned.
- Never overwrite historical trigger decisions when rule versions or model versions change.
- Use immutable audit records for approvals and payouts.
- Separate trigger event creation from payout disbursement.
- Store sensitive identity and bank details as hashes or secure references.
- Flag all unknown/fallow and low-confidence crop predictions.
- Require manual review for Extreme stress or 100% payout candidates.
- Clearly label sample geometry and mock data.
- Use PostGIS for spatial queries and TimescaleDB for observation time series.
- Use OpenAPI contracts before frontend integration.

## 19. Open Decisions Before Phase 2

These decisions should be confirmed before architecture implementation:

| Decision | Recommended Default |
|---|---|
| Auto-approval confidence threshold | At least 85% crop confidence |
| Extreme stress handling | Always manual review |
| Expected NDVI source for first version | Crop-wise or cycle-wise median from available data |
| Long-term expected NDVI source | Rolling 3-5 year historical baseline |
| Sum insured granularity | Per policy crop, not only per plot |
| Double-crop handling | Separate crop cycle and policy crop eligibility |
| Geometry source | Use real parcel/GPS boundaries when available; otherwise clearly marked sample geometry |
| Weather authority | IMD primary when available; CHIRPS/ERA5/NASA POWER as fallback or validation |
| Payment provider | Razorpay/UPI adapter later, with reconciliation |
| Farmer notification language | Marathi, Hindi, English |
| PMFBY/Agristack integration | Defer until compliance review |

## 20. Phase 1 Acceptance Criteria

Phase 1 is complete when:

- Business problem and product scope are documented.
- Source materials are assessed.
- User roles and core jobs are documented.
- Trigger logic and payout ladder are defined.
- Basis-risk controls are defined.
- Functional and non-functional requirements are documented.
- Architecture boundaries are named without implementing later phases.
- Database/API/UI expectations are captured for future phases.
- Workflow and approval model are documented.
- A structured requirements artifact exists for traceability.

All criteria are satisfied by this document and the accompanying requirements catalog.
