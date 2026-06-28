# Database

Phase 3 database assets for the Parametric Agricultural Insurance Platform.

## Local Database

Target database name: `agrishield`

The local PostgreSQL instance has PostGIS available. TimescaleDB is optional and is handled by `migrations/0002_optional_timescaledb.sql`; if TimescaleDB is not installed, the migration emits a notice and leaves the time-series tables as normal PostgreSQL tables.

## Run Order

```powershell
$env:PGPASSWORD = '<your local password>'
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U postgres -d agrishield -v ON_ERROR_STOP=1 -f database/migrations/0001_initial_schema.sql
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U postgres -d agrishield -v ON_ERROR_STOP=1 -f database/seeds/0001_reference_data.sql
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U postgres -d agrishield -v ON_ERROR_STOP=1 -f database/views/0001_reporting_views.sql
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' -h localhost -p 5432 -U postgres -d agrishield -v ON_ERROR_STOP=1 -f database/migrations/0002_optional_timescaledb.sql
```

Do not commit real database passwords. Use environment variables or a local secrets manager.
