-- =============================================================================
-- AGRISHIELD PARAMETRIC AGRICULTURAL INSURANCE PLATFORM
-- Phase 3: Initial PostgreSQL + PostGIS schema
-- Target database: agrishield
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS agri;
SET search_path = agri, public;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Enumerated domain states
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    CREATE TYPE user_status AS ENUM ('invited', 'active', 'locked', 'disabled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE season_type AS ENUM ('kharif', 'rabi', 'zaid', 'annual');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE policy_status AS ENUM ('draft', 'quoted', 'active', 'expired', 'cancelled', 'suspended', 'claimed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE premium_status AS ENUM ('pending', 'paid', 'failed', 'refunded', 'waived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE stress_band AS ENUM ('no_stress', 'mild', 'moderate', 'severe', 'extreme');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE trigger_type AS ENUM (
        'rainfall_deficit',
        'rainfall_excess',
        'ndvi_drop',
        'flood_extent',
        'soil_moisture',
        'temperature_stress',
        'wind_speed',
        'cyclone',
        'heatwave',
        'cold_wave',
        'drought',
        'crop_stress',
        'pest_risk',
        'disease_risk',
        'establishment_failure',
        'mid_season_stress',
        'sudden_decline'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE approval_status AS ENUM (
        'pending_review',
        'auto_approved',
        'under_review',
        'field_verification_required',
        'approved',
        'rejected',
        'on_hold'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'initiated', 'processing', 'completed', 'failed', 'refunded', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE claim_status AS ENUM ('draft', 'open', 'under_review', 'approved', 'rejected', 'settled', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE notification_channel AS ENUM ('sms', 'email', 'webhook', 'push');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'delivered', 'failed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE data_source_type AS ENUM ('mock', 'weather', 'satellite', 'payment', 'government', 'notification', 'ml');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE observation_quality AS ENUM ('clean', 'cloud_affected', 'interpolated', 'missing', 'suspect');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE cropping_intensity AS ENUM ('single', 'double', 'no_clear_cycle', 'fallow');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Shared functions
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION prevent_update_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only and cannot be %', TG_TABLE_NAME, TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compute_ndvi_anomaly(observed NUMERIC, expected NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    IF expected IS NULL OR expected = 0 OR observed IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(((expected - observed) / expected) * 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION anomaly_to_stress_band(anomaly_pct NUMERIC)
RETURNS stress_band AS $$
BEGIN
    IF anomaly_pct IS NULL THEN RETURN 'extreme'; END IF;
    IF anomaly_pct < 10 THEN RETURN 'no_stress'; END IF;
    IF anomaly_pct < 20 THEN RETURN 'mild'; END IF;
    IF anomaly_pct < 35 THEN RETURN 'moderate'; END IF;
    IF anomaly_pct < 60 THEN RETURN 'severe'; END IF;
    RETURN 'extreme';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION stress_band_to_payout_pct(band stress_band)
RETURNS NUMERIC AS $$
BEGIN
    CASE band
        WHEN 'no_stress' THEN RETURN 0.0;
        WHEN 'mild' THEN RETURN 25.0;
        WHEN 'moderate' THEN RETURN 50.0;
        WHEN 'severe' THEN RETURN 75.0;
        WHEN 'extreme' THEN RETURN 100.0;
        ELSE RETURN 0.0;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION calculate_payout_amount(sum_insured NUMERIC, payout_pct NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    IF sum_insured IS NULL OR payout_pct IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(sum_insured * payout_pct / 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION generate_record_hash(parts TEXT[])
RETURNS TEXT AS $$
BEGIN
    RETURN encode(digest(array_to_string(parts, '|'), 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ---------------------------------------------------------------------------
-- Identity and access
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_key TEXT UNIQUE NOT NULL,
    module_key TEXT NOT NULL,
    action_key TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (module_key, action_key)
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    mobile_number TEXT,
    full_name TEXT NOT NULL,
    hashed_password TEXT NOT NULL,
    status user_status NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMPTZ,
    failed_login_count INT NOT NULL DEFAULT 0,
    password_changed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users (status);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT UNIQUE NOT NULL,
    family_id UUID NOT NULL DEFAULT gen_random_uuid(),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    replaced_by_token_id UUID REFERENCES refresh_tokens(id),
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family ON refresh_tokens (family_id);

CREATE TABLE IF NOT EXISTS api_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    owner_user_id UUID REFERENCES users(id),
    secret_hash TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    rate_limit_per_minute INT NOT NULL DEFAULT 120,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Reference sources and files
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    source_type data_source_type NOT NULL,
    provider_url TEXT,
    is_live BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    priority_rank INT NOT NULL DEFAULT 100,
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS file_objects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_provider TEXT NOT NULL DEFAULT 'local',
    bucket_name TEXT,
    object_key TEXT NOT NULL,
    original_filename TEXT,
    content_type TEXT,
    size_bytes BIGINT,
    checksum_sha256 TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Administrative geography
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    state_name TEXT UNIQUE NOT NULL,
    state_code TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS districts (
    id SERIAL PRIMARY KEY,
    state_id INT NOT NULL REFERENCES states(id) ON DELETE RESTRICT,
    district_name TEXT NOT NULL,
    lgd_code TEXT,
    geometry geometry(MultiPolygon, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (state_id, district_name)
);

CREATE INDEX IF NOT EXISTS idx_districts_geom ON districts USING GIST (geometry);

CREATE TABLE IF NOT EXISTS talukas (
    id SERIAL PRIMARY KEY,
    district_id INT NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
    taluka_name TEXT NOT NULL,
    lgd_code TEXT,
    geometry geometry(MultiPolygon, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (district_id, taluka_name)
);

CREATE INDEX IF NOT EXISTS idx_talukas_geom ON talukas USING GIST (geometry);

CREATE TABLE IF NOT EXISTS villages (
    id SERIAL PRIMARY KEY,
    taluka_id INT NOT NULL REFERENCES talukas(id) ON DELETE RESTRICT,
    village_name TEXT NOT NULL,
    lgd_code TEXT,
    geometry geometry(MultiPolygon, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (taluka_id, village_name)
);

CREATE INDEX IF NOT EXISTS idx_villages_geom ON villages USING GIST (geometry);

CREATE TABLE IF NOT EXISTS admin_boundaries (
    id SERIAL PRIMARY KEY,
    boundary_level TEXT NOT NULL CHECK (boundary_level IN ('state', 'district', 'taluka', 'village', 'block')),
    boundary_name TEXT NOT NULL,
    parent_boundary_id INT REFERENCES admin_boundaries(id),
    lgd_code TEXT,
    geometry geometry(MultiPolygon, 4326),
    source_id UUID REFERENCES data_sources(id),
    is_sample BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_boundaries_level ON admin_boundaries (boundary_level);
CREATE INDEX IF NOT EXISTS idx_admin_boundaries_geom ON admin_boundaries USING GIST (geometry);

-- ---------------------------------------------------------------------------
-- Farmers, KYC, farms, plots
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    farmer_code TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    aadhaar_hash TEXT,
    mobile_number TEXT NOT NULL,
    mobile_verified BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language TEXT NOT NULL DEFAULT 'mr',
    village_id INT REFERENCES villages(id),
    address_text TEXT,
    bank_account_hash TEXT,
    upi_id TEXT,
    agristack_id TEXT UNIQUE,
    pmfby_id TEXT,
    kyc_status verification_status NOT NULL DEFAULT 'pending',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farmers_code ON farmers (farmer_code);
CREATE INDEX IF NOT EXISTS idx_farmers_mobile ON farmers (mobile_number);
CREATE INDEX IF NOT EXISTS idx_farmers_kyc_status ON farmers (kyc_status);

CREATE TABLE IF NOT EXISTS farmer_kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    file_object_id UUID REFERENCES file_objects(id),
    document_hash TEXT,
    verification_status verification_status NOT NULL DEFAULT 'pending',
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farmer_kyc_farmer ON farmer_kyc_documents (farmer_id);

CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    farm_code TEXT UNIQUE NOT NULL,
    display_name TEXT,
    village_id INT REFERENCES villages(id),
    total_area_ha NUMERIC(10, 4),
    boundary geometry(MultiPolygon, 4326),
    centroid geometry(Point, 4326),
    is_sample BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farms_farmer ON farms (farmer_id);
CREATE INDEX IF NOT EXISTS idx_farms_boundary ON farms USING GIST (boundary);
CREATE INDEX IF NOT EXISTS idx_farms_centroid ON farms USING GIST (centroid);

CREATE TABLE IF NOT EXISTS plots (
    id BIGSERIAL PRIMARY KEY,
    farm_id UUID REFERENCES farms(id) ON DELETE SET NULL,
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    plot_code TEXT UNIQUE NOT NULL,
    village_id INT REFERENCES villages(id),
    survey_number TEXT,
    area_ha NUMERIC(10, 4),
    boundary geometry(MultiPolygon, 4326),
    centroid geometry(Point, 4326),
    gps_lat NUMERIC(10, 7) CHECK (gps_lat IS NULL OR (gps_lat >= -90 AND gps_lat <= 90)),
    gps_lon NUMERIC(10, 7) CHECK (gps_lon IS NULL OR (gps_lon >= -180 AND gps_lon <= 180)),
    land_record_url TEXT,
    is_sample BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_plots_farmer ON plots (farmer_id);
CREATE INDEX IF NOT EXISTS idx_plots_farm ON plots (farm_id);
CREATE INDEX IF NOT EXISTS idx_plots_village ON plots (village_id);
CREATE INDEX IF NOT EXISTS idx_plots_boundary ON plots USING GIST (boundary);
CREATE INDEX IF NOT EXISTS idx_plots_centroid ON plots USING GIST (centroid);

-- ---------------------------------------------------------------------------
-- Crops and agronomy
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS crops (
    id SERIAL PRIMARY KEY,
    crop_name TEXT UNIQUE NOT NULL,
    crop_category TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crop_calendar (
    id SERIAL PRIMARY KEY,
    crop_id INT NOT NULL REFERENCES crops(id) ON DELETE RESTRICT,
    season season_type NOT NULL,
    start_month INT NOT NULL CHECK (start_month BETWEEN 1 AND 12),
    end_month INT NOT NULL CHECK (end_month BETWEEN 1 AND 12),
    duration_days INT NOT NULL CHECK (duration_days > 0),
    region_scope TEXT NOT NULL DEFAULT 'Latur',
    source_id UUID REFERENCES data_sources(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (crop_id, season, region_scope)
);

CREATE INDEX IF NOT EXISTS idx_crop_calendar_crop ON crop_calendar (crop_id);
CREATE INDEX IF NOT EXISTS idx_crop_calendar_season ON crop_calendar (season);

CREATE TABLE IF NOT EXISTS crop_growth_stages (
    id SERIAL PRIMARY KEY,
    crop_calendar_id INT NOT NULL REFERENCES crop_calendar(id) ON DELETE CASCADE,
    stage_key TEXT NOT NULL,
    stage_label TEXT NOT NULL,
    start_day INT NOT NULL CHECK (start_day >= 0),
    end_day INT NOT NULL CHECK (end_day >= start_day),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (crop_calendar_id, stage_key)
);

CREATE TABLE IF NOT EXISTS ndvi_baselines (
    id BIGSERIAL PRIMARY KEY,
    crop_calendar_id INT NOT NULL REFERENCES crop_calendar(id) ON DELETE CASCADE,
    growth_stage_id INT REFERENCES crop_growth_stages(id) ON DELETE SET NULL,
    expected_ndvi NUMERIC(5, 3) NOT NULL CHECK (expected_ndvi >= -1 AND expected_ndvi <= 1),
    ndvi_lower_bound NUMERIC(5, 3),
    ndvi_upper_bound NUMERIC(5, 3),
    source_method TEXT NOT NULL DEFAULT 'historical_median',
    sample_size INT,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    model_version_id INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ndvi_baselines_calendar ON ndvi_baselines (crop_calendar_id);

-- ---------------------------------------------------------------------------
-- Policies, premiums, and claims
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS policy_types (
    id SERIAL PRIMARY KEY,
    policy_type_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    default_terms JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS premium_rules (
    id SERIAL PRIMARY KEY,
    rule_key TEXT UNIQUE NOT NULL,
    policy_type_id INT REFERENCES policy_types(id),
    crop_id INT REFERENCES crops(id),
    district_id INT REFERENCES districts(id),
    base_rate_pct NUMERIC(7, 4) NOT NULL CHECK (base_rate_pct >= 0),
    risk_multiplier NUMERIC(7, 4) NOT NULL DEFAULT 1.0 CHECK (risk_multiplier >= 0),
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_number TEXT UNIQUE NOT NULL,
    policy_type_id INT NOT NULL REFERENCES policy_types(id) ON DELETE RESTRICT,
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE RESTRICT,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    season season_type NOT NULL,
    policy_year INT NOT NULL CHECK (policy_year BETWEEN 2000 AND 2100),
    policy_start DATE NOT NULL,
    policy_end DATE NOT NULL,
    total_sum_insured NUMERIC(14, 2) NOT NULL CHECK (total_sum_insured >= 0),
    premium_amount NUMERIC(12, 2) CHECK (premium_amount IS NULL OR premium_amount >= 0),
    premium_status premium_status NOT NULL DEFAULT 'pending',
    is_pmfby BOOLEAN NOT NULL DEFAULT FALSE,
    status policy_status NOT NULL DEFAULT 'draft',
    created_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (policy_end >= policy_start)
);

CREATE INDEX IF NOT EXISTS idx_policies_farmer ON policies (farmer_id);
CREATE INDEX IF NOT EXISTS idx_policies_plot ON policies (plot_id);
CREATE INDEX IF NOT EXISTS idx_policies_status ON policies (status);
CREATE INDEX IF NOT EXISTS idx_policies_season_year ON policies (season, policy_year);

CREATE TABLE IF NOT EXISTS policy_crops (
    id BIGSERIAL PRIMARY KEY,
    policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
    crop_id INT NOT NULL REFERENCES crops(id) ON DELETE RESTRICT,
    crop_calendar_id INT REFERENCES crop_calendar(id),
    sum_insured NUMERIC(14, 2) NOT NULL CHECK (sum_insured >= 0),
    sowing_date DATE,
    expected_harvest_date DATE,
    cycle_number INT NOT NULL DEFAULT 1,
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (policy_id, crop_id, cycle_number)
);

CREATE INDEX IF NOT EXISTS idx_policy_crops_policy ON policy_crops (policy_id);
CREATE INDEX IF NOT EXISTS idx_policy_crops_crop ON policy_crops (crop_id);

CREATE TABLE IF NOT EXISTS premium_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_type_id INT NOT NULL REFERENCES policy_types(id),
    farmer_id UUID REFERENCES farmers(id),
    plot_id BIGINT REFERENCES plots(id),
    request_payload JSONB NOT NULL,
    premium_amount NUMERIC(12, 2) NOT NULL CHECK (premium_amount >= 0),
    sum_insured NUMERIC(14, 2) NOT NULL CHECK (sum_insured >= 0),
    quote_expires_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_number TEXT UNIQUE NOT NULL,
    policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE RESTRICT,
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE RESTRICT,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    claim_status claim_status NOT NULL DEFAULT 'draft',
    claim_reason TEXT,
    opened_by UUID REFERENCES users(id),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_claims_policy ON claims (policy_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims (claim_status);

-- ---------------------------------------------------------------------------
-- ML model registry and crop cycles
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS model_versions (
    id SERIAL PRIMARY KEY,
    model_name TEXT NOT NULL,
    version_tag TEXT NOT NULL,
    model_type TEXT NOT NULL DEFAULT 'crop_prediction',
    description TEXT,
    script_hash TEXT,
    parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    artifact_file_id UUID REFERENCES file_objects(id),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (model_name, version_tag)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_ndvi_baselines_model_version'
          AND conrelid = 'agri.ndvi_baselines'::regclass
    ) THEN
        ALTER TABLE ndvi_baselines
            ADD CONSTRAINT fk_ndvi_baselines_model_version
            FOREIGN KEY (model_version_id) REFERENCES model_versions(id);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS prediction_runs (
    id BIGSERIAL PRIMARY KEY,
    model_version_id INT NOT NULL REFERENCES model_versions(id) ON DELETE RESTRICT,
    run_key TEXT UNIQUE NOT NULL,
    run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    input_file_id UUID REFERENCES file_objects(id),
    plots_processed INT,
    cycles_detected INT,
    avg_confidence_pct NUMERIC(5, 2),
    run_notes TEXT,
    created_by UUID REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS crop_cycles (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
    prediction_run_id BIGINT NOT NULL REFERENCES prediction_runs(id) ON DELETE RESTRICT,
    crop_id INT REFERENCES crops(id),
    crop_calendar_id INT REFERENCES crop_calendar(id),
    policy_crop_id BIGINT REFERENCES policy_crops(id),
    cropping_intensity cropping_intensity NOT NULL DEFAULT 'single',
    cycle_number INT NOT NULL DEFAULT 1,
    cycle_start DATE,
    cycle_peak DATE,
    cycle_end DATE,
    ndvi_at_start NUMERIC(5, 3),
    ndvi_at_peak NUMERIC(5, 3),
    ndvi_at_end NUMERIC(5, 3),
    ndvi_rise NUMERIC(5, 3),
    ndvi_drop NUMERIC(5, 3),
    duration_days INT,
    confidence_pct NUMERIC(5, 2),
    is_known_crop BOOLEAN NOT NULL DEFAULT TRUE,
    raw_prediction JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (plot_id, prediction_run_id, cycle_number)
);

CREATE INDEX IF NOT EXISTS idx_crop_cycles_plot ON crop_cycles (plot_id);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_crop ON crop_cycles (crop_id);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_confidence ON crop_cycles (confidence_pct);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_dates ON crop_cycles (cycle_start, cycle_end);

-- ---------------------------------------------------------------------------
-- Observation ingestion and time-series records
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS observation_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_key TEXT UNIQUE NOT NULL,
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_type TEXT NOT NULL,
    source_file_id UUID REFERENCES file_objects(id),
    ingestion_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ingestion_completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'running',
    records_received INT,
    records_accepted INT,
    records_rejected INT,
    error_message TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_observation_batches_source ON observation_batches (source_id);

CREATE TABLE IF NOT EXISTS satellite_observations (
    id BIGSERIAL PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    scene_id TEXT,
    observed_at TIMESTAMPTZ NOT NULL,
    footprint geometry(MultiPolygon, 4326),
    cloud_cover_pct NUMERIC(5, 2),
    sensor_name TEXT,
    product_type TEXT,
    raster_file_id UUID REFERENCES file_objects(id),
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_satellite_observations_time ON satellite_observations (observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_satellite_observations_footprint ON satellite_observations USING GIST (footprint);

CREATE TABLE IF NOT EXISTS ndvi_observations (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    satellite_observation_id BIGINT REFERENCES satellite_observations(id),
    observed_at TIMESTAMPTZ NOT NULL,
    ndvi_value NUMERIC(5, 3) CHECK (ndvi_value IS NULL OR (ndvi_value >= -1 AND ndvi_value <= 1)),
    cloud_cover_pct NUMERIC(5, 2),
    quality observation_quality NOT NULL DEFAULT 'clean',
    is_interpolated BOOLEAN NOT NULL DEFAULT FALSE,
    raw_band_red NUMERIC(10, 6),
    raw_band_nir NUMERIC(10, 6),
    pixel_count INT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (plot_id, source_id, observed_at)
);

CREATE INDEX IF NOT EXISTS idx_ndvi_observations_plot_time ON ndvi_observations (plot_id, observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_ndvi_observations_source_time ON ndvi_observations (source_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS rvi_observations (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    satellite_observation_id BIGINT REFERENCES satellite_observations(id),
    observed_at TIMESTAMPTZ NOT NULL,
    rvi_value NUMERIC(6, 4),
    orbit_direction TEXT,
    polarization TEXT DEFAULT 'VH/VV',
    image_count INT,
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (plot_id, source_id, observed_at)
);

CREATE INDEX IF NOT EXISTS idx_rvi_observations_plot_time ON rvi_observations (plot_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS rainfall_observations (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT REFERENCES plots(id) ON DELETE CASCADE,
    village_id INT REFERENCES villages(id),
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    observed_at TIMESTAMPTZ NOT NULL,
    period TEXT NOT NULL DEFAULT 'daily',
    rainfall_mm NUMERIC(8, 2),
    normal_mm NUMERIC(8, 2),
    anomaly_pct NUMERIC(6, 2),
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rainfall_observations_plot_time ON rainfall_observations (plot_id, observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_rainfall_observations_village_time ON rainfall_observations (village_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS temperature_observations (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT REFERENCES plots(id) ON DELETE CASCADE,
    village_id INT REFERENCES villages(id),
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    observed_at TIMESTAMPTZ NOT NULL,
    min_temp_c NUMERIC(5, 2),
    max_temp_c NUMERIC(5, 2),
    mean_temp_c NUMERIC(5, 2),
    anomaly_c NUMERIC(5, 2),
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_temperature_observations_plot_time ON temperature_observations (plot_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS soil_moisture_observations (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT REFERENCES plots(id) ON DELETE CASCADE,
    village_id INT REFERENCES villages(id),
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    observed_at TIMESTAMPTZ NOT NULL,
    soil_moisture_pct NUMERIC(6, 2),
    depth_cm NUMERIC(6, 2),
    anomaly_pct NUMERIC(6, 2),
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_soil_moisture_plot_time ON soil_moisture_observations (plot_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS flood_observations (
    id BIGSERIAL PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES data_sources(id),
    batch_id UUID REFERENCES observation_batches(id),
    observed_at TIMESTAMPTZ NOT NULL,
    gauge_code TEXT,
    water_level_m NUMERIC(8, 2),
    danger_level_m NUMERIC(8, 2),
    flood_extent geometry(MultiPolygon, 4326),
    quality observation_quality NOT NULL DEFAULT 'clean',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flood_observations_time ON flood_observations (observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_flood_observations_extent ON flood_observations USING GIST (flood_extent);

-- ---------------------------------------------------------------------------
-- Triggers, basis risk, approvals, payouts
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS trigger_rules (
    id BIGSERIAL PRIMARY KEY,
    rule_key TEXT NOT NULL,
    version_tag TEXT NOT NULL DEFAULT 'v1',
    display_name TEXT NOT NULL,
    trigger_type trigger_type NOT NULL,
    policy_type_id INT REFERENCES policy_types(id),
    crop_id INT REFERENCES crops(id),
    season season_type,
    threshold_value NUMERIC(10, 4),
    threshold_unit TEXT,
    observation_window_days INT,
    payout_ladder JSONB NOT NULL DEFAULT '[]'::jsonb,
    review_policy JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (rule_key, version_tag)
);

CREATE INDEX IF NOT EXISTS idx_trigger_rules_type ON trigger_rules (trigger_type);
CREATE INDEX IF NOT EXISTS idx_trigger_rules_active ON trigger_rules (is_active);

CREATE TABLE IF NOT EXISTS trigger_events (
    id BIGSERIAL PRIMARY KEY,
    event_key TEXT UNIQUE NOT NULL,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    policy_id UUID REFERENCES policies(id) ON DELETE RESTRICT,
    policy_crop_id BIGINT REFERENCES policy_crops(id) ON DELETE RESTRICT,
    crop_cycle_id BIGINT REFERENCES crop_cycles(id) ON DELETE SET NULL,
    trigger_rule_id BIGINT NOT NULL REFERENCES trigger_rules(id) ON DELETE RESTRICT,
    trigger_type trigger_type NOT NULL,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    trigger_date DATE NOT NULL,
    observed_value NUMERIC(12, 4),
    expected_value NUMERIC(12, 4),
    observed_ndvi NUMERIC(5, 3),
    expected_ndvi NUMERIC(5, 3),
    ndvi_anomaly_pct NUMERIC(6, 2),
    rainfall_anomaly_pct NUMERIC(6, 2),
    soil_moisture_anomaly_pct NUMERIC(6, 2),
    temperature_anomaly_c NUMERIC(6, 2),
    stress_band stress_band NOT NULL,
    payout_pct NUMERIC(5, 2) NOT NULL CHECK (payout_pct >= 0 AND payout_pct <= 100),
    reason_code TEXT NOT NULL,
    reason_detail TEXT,
    crop_confidence_pct NUMERIC(5, 2),
    review_flag BOOLEAN NOT NULL DEFAULT FALSE,
    review_reason TEXT,
    approval_status approval_status NOT NULL DEFAULT 'pending_review',
    source_observation_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
    trigger_engine_version TEXT NOT NULL DEFAULT 'phase3-schema-v1',
    record_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trigger_events_plot ON trigger_events (plot_id);
CREATE INDEX IF NOT EXISTS idx_trigger_events_policy ON trigger_events (policy_id);
CREATE INDEX IF NOT EXISTS idx_trigger_events_status ON trigger_events (approval_status);
CREATE INDEX IF NOT EXISTS idx_trigger_events_stress ON trigger_events (stress_band);
CREATE INDEX IF NOT EXISTS idx_trigger_events_date ON trigger_events (trigger_date DESC);
CREATE INDEX IF NOT EXISTS idx_trigger_events_review ON trigger_events (review_flag) WHERE review_flag = TRUE;

CREATE TABLE IF NOT EXISTS basis_risk_flags (
    id BIGSERIAL PRIMARY KEY,
    trigger_event_id BIGINT NOT NULL REFERENCES trigger_events(id) ON DELETE CASCADE,
    flag_key TEXT NOT NULL,
    flag_reason TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    confidence_pct NUMERIC(5, 2),
    ndvi_anomaly_pct NUMERIC(6, 2),
    rainfall_anomaly_pct NUMERIC(6, 2),
    flagged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_action TEXT,
    resolution_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_basis_risk_trigger ON basis_risk_flags (trigger_event_id);
CREATE INDEX IF NOT EXISTS idx_basis_risk_unresolved ON basis_risk_flags (is_resolved) WHERE is_resolved = FALSE;

CREATE TABLE IF NOT EXISTS payout_approvals (
    id BIGSERIAL PRIMARY KEY,
    trigger_event_id BIGINT NOT NULL REFERENCES trigger_events(id) ON DELETE CASCADE,
    approver_id UUID REFERENCES users(id),
    previous_status approval_status,
    new_status approval_status NOT NULL,
    action_taken TEXT NOT NULL,
    notes TEXT,
    acted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    field_verification_required BOOLEAN NOT NULL DEFAULT FALSE,
    field_officer_id UUID REFERENCES users(id),
    field_verified_at TIMESTAMPTZ,
    field_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_payout_approvals_trigger ON payout_approvals (trigger_event_id);
CREATE INDEX IF NOT EXISTS idx_payout_approvals_status ON payout_approvals (new_status);

CREATE TABLE IF NOT EXISTS payout_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payout_number TEXT UNIQUE NOT NULL,
    trigger_event_id BIGINT NOT NULL UNIQUE REFERENCES trigger_events(id) ON DELETE RESTRICT,
    policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE RESTRICT,
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE RESTRICT,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    policy_crop_id BIGINT REFERENCES policy_crops(id) ON DELETE RESTRICT,
    sum_insured NUMERIC(14, 2) NOT NULL CHECK (sum_insured >= 0),
    payout_pct NUMERIC(5, 2) NOT NULL CHECK (payout_pct >= 0 AND payout_pct <= 100),
    payout_amount NUMERIC(14, 2) NOT NULL CHECK (payout_amount >= 0),
    currency TEXT NOT NULL DEFAULT 'INR',
    payment_status payment_status NOT NULL DEFAULT 'pending',
    current_payment_reference TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    record_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_records_farmer ON payout_records (farmer_id);
CREATE INDEX IF NOT EXISTS idx_payout_records_policy ON payout_records (policy_id);
CREATE INDEX IF NOT EXISTS idx_payout_records_status ON payout_records (payment_status);

CREATE TABLE IF NOT EXISTS payout_payment_events (
    id BIGSERIAL PRIMARY KEY,
    payout_record_id UUID NOT NULL REFERENCES payout_records(id) ON DELETE CASCADE,
    payment_status payment_status NOT NULL,
    payment_method TEXT,
    payment_reference TEXT,
    gateway_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    failure_reason TEXT,
    acted_by UUID REFERENCES users(id),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_payment_events_payout ON payout_payment_events (payout_record_id);

-- ---------------------------------------------------------------------------
-- Notifications, reports, settings, audit
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS notification_templates (
    id SERIAL PRIMARY KEY,
    template_key TEXT NOT NULL,
    channel notification_channel NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    subject_template TEXT,
    body_template TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (template_key, channel, language)
);

CREATE TABLE IF NOT EXISTS notification_logs (
    id BIGSERIAL PRIMARY KEY,
    farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    channel notification_channel NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    subject TEXT,
    body TEXT NOT NULL,
    template_id INT REFERENCES notification_templates(id),
    payout_record_id UUID REFERENCES payout_records(id),
    trigger_event_id BIGINT REFERENCES trigger_events(id),
    status notification_status NOT NULL DEFAULT 'pending',
    provider_ref TEXT,
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_farmer ON notification_logs (farmer_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON notification_logs (status);

CREATE TABLE IF NOT EXISTS report_exports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_key TEXT NOT NULL,
    requested_by UUID REFERENCES users(id),
    status TEXT NOT NULL DEFAULT 'pending',
    filters JSONB NOT NULL DEFAULT '{}'::jsonb,
    file_object_id UUID REFERENCES file_objects(id),
    error_message TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS system_settings (
    setting_key TEXT PRIMARY KEY,
    setting_value JSONB NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS idempotency_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_hash TEXT UNIQUE NOT NULL,
    operation_key TEXT NOT NULL,
    request_hash TEXT,
    response_body JSONB,
    status_code INT,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,
    actor_id UUID REFERENCES users(id),
    actor_role_key TEXT,
    old_state JSONB,
    new_state JSONB,
    ip_address INET,
    user_agent TEXT,
    request_id TEXT,
    notes TEXT,
    record_hash TEXT,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_time ON audit_log (occurred_at DESC);

-- ---------------------------------------------------------------------------
-- Updated-at triggers
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'users',
        'api_clients',
        'data_sources',
        'farmers',
        'farms',
        'plots',
        'policies',
        'claims',
        'payout_records'
    ]
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', 'trg_' || table_name || '_set_updated_at', table_name);
        EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()', 'trg_' || table_name || '_set_updated_at', table_name);
    END LOOP;
END $$;

DROP TRIGGER IF EXISTS trg_audit_log_append_only_update ON audit_log;
CREATE TRIGGER trg_audit_log_append_only_update
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_update_delete();

DROP TRIGGER IF EXISTS trg_trigger_events_append_only_update ON trigger_events;
CREATE TRIGGER trg_trigger_events_append_only_update
BEFORE UPDATE OR DELETE ON trigger_events
FOR EACH ROW EXECUTE FUNCTION prevent_update_delete();

INSERT INTO schema_migrations (version, description)
VALUES ('0001_initial_schema', 'Initial normalized Agrishield schema')
ON CONFLICT (version) DO NOTHING;

COMMIT;
