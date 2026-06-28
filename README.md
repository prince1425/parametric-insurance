# Parametric Agricultural Insurance Platform

Production-oriented phased build for a parametric agricultural insurance platform using GIS, remote sensing, weather observations, and predefined payout rules.

## Current Phase

Phase 1 - Business Analysis is complete in:

- [docs/phase-1-business-analysis.md](docs/phase-1-business-analysis.md)
- [shared/domain/phase1-requirements.json](shared/domain/phase1-requirements.json)

Phase 2 - System Architecture is complete in:

- [docs/phase-2-system-architecture.md](docs/phase-2-system-architecture.md)
- [shared/domain/phase2-architecture.json](shared/domain/phase2-architecture.json)
- [docs/diagrams](docs/diagrams)

Phase 3 - Database Schema is complete in:

- [docs/phase-3-database-schema.md](docs/phase-3-database-schema.md)
- [shared/domain/phase3-schema.json](shared/domain/phase3-schema.json)
- [database/migrations](database/migrations)
- [database/seeds](database/seeds)
- [database/views](database/views)

Phase 4 - Backend APIs is complete in:

- [docs/phase-4-backend-apis.md](docs/phase-4-backend-apis.md)
- [backend](backend)

Phase 5 - Frontend is complete in:

- [docs/phase-5-frontend.md](docs/phase-5-frontend.md)
- [frontend](frontend)

Phase 6 - GIS is complete in:

- [docs/phase-6-gis.md](docs/phase-6-gis.md)

Phase 7 - ML is complete in:

- [docs/phase-7-ml.md](docs/phase-7-ml.md)
- [shared/domain/phase7-ml.json](shared/domain/phase7-ml.json)
- [ml/scripts/risk_scoring.py](ml/scripts/risk_scoring.py)

Phase 8 - Testing is complete in:

- [docs/phase-8-testing.md](docs/phase-8-testing.md)
- [shared/domain/phase8-testing.json](shared/domain/phase8-testing.json)
- [backend/tests](backend/tests)
- [database/validation](database/validation)
- [ml/tests](ml/tests)

Per the build instruction, the project proceeds phase by phase. Phase 8 testing verifies database, backend, frontend, GIS, and ML. Phase 9 deployment is next.

## Source Inputs Used

- `Parametric_Insurance_GIS_RS_POC_Case_Study.pdf`
- `PROJECT_STRUCTURE.md`
- `parametric_insurance_arch_analysis.md`
- `schema.sql`
- `instructions.txt`
- `drive-download-20260625T074451Z-3-001.zip`

## Product Direction

The platform automates agricultural insurance decisions using parametric triggers. Payout eligibility is calculated from measurable observations such as NDVI anomaly, rainfall deficit, flood extent, temperature stress, soil moisture, and other configured indexes.

The first product slice is the Latur crop stress insurance workflow:

- Monitor plot-level NDVI time series.
- Interpret crop cycles and crop calendar stages.
- Evaluate Trigger B mid-season vegetation stress as the primary POC trigger.
- Use Trigger A establishment failure and Trigger C sudden decline as supporting flags.
- Apply a payout ladder with reason codes.
- Route low-confidence, unknown/fallow, extreme, or basis-risk cases to manual review.

## Phase Gate

Phase 1 defines the business scope, user roles, workflows, requirements, and risk controls. Phase 2 converts those decisions into system architecture, bounded contexts, folder structure, integration rules, and implementation gates. Phase 3 converts the architecture into a normalized PostgreSQL/PostGIS schema with optional TimescaleDB hypertable conversion. Phase 4 implements backend APIs, Phase 5 implements the operations frontend, Phase 6 implements GIS, Phase 7 implements the first ML risk-scoring pipeline, and Phase 8 verifies the stack end to end.
