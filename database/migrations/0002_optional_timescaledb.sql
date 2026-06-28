-- =============================================================================
-- Optional TimescaleDB conversion for observation tables.
-- This migration is safe to run when TimescaleDB is unavailable.
-- =============================================================================

DO $$
DECLARE
    has_timescaledb BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM pg_available_extensions
        WHERE name = 'timescaledb'
    )
    INTO has_timescaledb;

    IF NOT has_timescaledb THEN
        RAISE NOTICE 'TimescaleDB is not available on this PostgreSQL instance. Observation tables remain normal PostgreSQL tables.';
        RETURN;
    END IF;

    EXECUTE 'CREATE EXTENSION IF NOT EXISTS timescaledb';

    EXECUTE 'SELECT create_hypertable(''agri.ndvi_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.rvi_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.rainfall_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.temperature_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.soil_moisture_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.flood_observations'', ''observed_at'', if_not_exists => TRUE)';
    EXECUTE 'SELECT create_hypertable(''agri.satellite_observations'', ''observed_at'', if_not_exists => TRUE)';

    EXECUTE 'ALTER TABLE agri.ndvi_observations SET (timescaledb.compress)';
    EXECUTE 'ALTER TABLE agri.rvi_observations SET (timescaledb.compress)';
    EXECUTE 'ALTER TABLE agri.rainfall_observations SET (timescaledb.compress)';
    EXECUTE 'ALTER TABLE agri.temperature_observations SET (timescaledb.compress)';
    EXECUTE 'ALTER TABLE agri.soil_moisture_observations SET (timescaledb.compress)';

    EXECUTE 'SELECT add_compression_policy(''agri.ndvi_observations'', INTERVAL ''90 days'', if_not_exists => TRUE)';
    EXECUTE 'SELECT add_compression_policy(''agri.rvi_observations'', INTERVAL ''90 days'', if_not_exists => TRUE)';
    EXECUTE 'SELECT add_compression_policy(''agri.rainfall_observations'', INTERVAL ''90 days'', if_not_exists => TRUE)';
    EXECUTE 'SELECT add_compression_policy(''agri.temperature_observations'', INTERVAL ''90 days'', if_not_exists => TRUE)';
    EXECUTE 'SELECT add_compression_policy(''agri.soil_moisture_observations'', INTERVAL ''90 days'', if_not_exists => TRUE)';

    INSERT INTO agri.schema_migrations (version, description)
    VALUES ('0002_optional_timescaledb', 'Optional TimescaleDB hypertables and compression policies')
    ON CONFLICT (version) DO NOTHING;

    RAISE NOTICE 'TimescaleDB hypertable conversion completed.';
END $$;
