-- =============================================================================
-- AGRISHIELD DEMO PORTFOLIO
-- Clearly labeled sample data for Phase 4-6 local vertical slice.
-- =============================================================================

BEGIN;

SET search_path = agri, public;

-- Demo users
INSERT INTO users (email, mobile_number, full_name, hashed_password, status) VALUES
    ('admin@agrishield.local', '+910000000001', 'Agrishield Admin', 'demo-password-hash-not-for-production', 'active'),
    ('underwriter@agrishield.local', '+910000000002', 'Latur Underwriter', 'demo-password-hash-not-for-production', 'active'),
    ('field.officer@agrishield.local', '+910000000003', 'Latur Field Officer', 'demo-password-hash-not-for-production', 'active')
ON CONFLICT (email) DO UPDATE
SET full_name = EXCLUDED.full_name,
    mobile_number = EXCLUDED.mobile_number,
    updated_at = NOW();

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON (
    (u.email = 'admin@agrishield.local' AND r.role_key = 'admin')
    OR (u.email = 'underwriter@agrishield.local' AND r.role_key = 'underwriter')
    OR (u.email = 'field.officer@agrishield.local' AND r.role_key = 'field_officer')
)
ON CONFLICT DO NOTHING;

-- Local geography
INSERT INTO talukas (district_id, taluka_name)
SELECT d.id, v.taluka_name
FROM districts d
CROSS JOIN (VALUES ('Latur'), ('Ausa'), ('Nilanga')) AS v(taluka_name)
WHERE d.district_name = 'Latur'
ON CONFLICT (district_id, taluka_name) DO NOTHING;

INSERT INTO villages (taluka_id, village_name)
SELECT t.id, v.village_name
FROM talukas t
JOIN (
    VALUES
        ('Latur', 'Harangul'),
        ('Latur', 'Babhalgaon'),
        ('Ausa', 'Killari'),
        ('Nilanga', 'Aurad Shahajani')
) AS v(taluka_name, village_name) ON v.taluka_name = t.taluka_name
ON CONFLICT (taluka_id, village_name) DO NOTHING;

-- Demo farmers
INSERT INTO farmers (
    farmer_code,
    full_name,
    aadhaar_hash,
    mobile_number,
    mobile_verified,
    preferred_language,
    village_id,
    address_text,
    bank_account_hash,
    upi_id,
    kyc_status,
    created_by
)
SELECT
    v.farmer_code,
    v.full_name,
    encode(digest(v.farmer_code || '-aadhaar-demo', 'sha256'), 'hex'),
    v.mobile_number,
    TRUE,
    'mr',
    vil.id,
    v.address_text,
    encode(digest(v.farmer_code || '-bank-demo', 'sha256'), 'hex'),
    v.upi_id,
    'verified',
    admin_user.id
FROM (
    VALUES
        ('LTR-2025-0001', 'Asha Shinde', '+919000000101', 'Harangul, Latur', 'asha.shinde@upi', 'Harangul'),
        ('LTR-2025-0002', 'Ramesh Pawar', '+919000000102', 'Babhalgaon, Latur', 'ramesh.pawar@upi', 'Babhalgaon'),
        ('LTR-2025-0003', 'Savita Jadhav', '+919000000103', 'Killari, Ausa', 'savita.jadhav@upi', 'Killari'),
        ('LTR-2025-0004', 'Mahadev Kale', '+919000000104', 'Aurad Shahajani, Nilanga', 'mahadev.kale@upi', 'Aurad Shahajani'),
        ('LTR-2025-0005', 'Nanda More', '+919000000105', 'Harangul, Latur', 'nanda.more@upi', 'Harangul')
) AS v(farmer_code, full_name, mobile_number, address_text, upi_id, village_name)
JOIN villages vil ON vil.village_name = v.village_name
CROSS JOIN LATERAL (
    SELECT id FROM users WHERE email = 'admin@agrishield.local' LIMIT 1
) admin_user
ON CONFLICT (farmer_code) DO UPDATE
SET full_name = EXCLUDED.full_name,
    mobile_number = EXCLUDED.mobile_number,
    mobile_verified = EXCLUDED.mobile_verified,
    preferred_language = EXCLUDED.preferred_language,
    village_id = EXCLUDED.village_id,
    address_text = EXCLUDED.address_text,
    upi_id = EXCLUDED.upi_id,
    kyc_status = EXCLUDED.kyc_status,
    updated_at = NOW();

-- Demo farms and plots.
WITH demo_plots AS (
    SELECT *
    FROM (
        VALUES
            ('LTR-FARM-0001', 'Asha Cotton Farm', 'LTR-2025-0001', 'Harangul', 2.40, 'LTR-PLOT-0001', '118/2', 1.20, 18.4132, 76.5661, 'POLYGON((76.5628 18.4107,76.5693 18.4107,76.5693 18.4160,76.5628 18.4160,76.5628 18.4107))'),
            ('LTR-FARM-0002', 'Ramesh Soybean Farm', 'LTR-2025-0002', 'Babhalgaon', 1.80, 'LTR-PLOT-0002', '74/1', 0.95, 18.3874, 76.6022, 'POLYGON((76.5991 18.3848,76.6052 18.3848,76.6052 18.3904,76.5991 18.3904,76.5991 18.3848))'),
            ('LTR-FARM-0003', 'Savita Paddy Farm', 'LTR-2025-0003', 'Killari', 3.10, 'LTR-PLOT-0003', '203/4', 1.60, 18.0657, 76.5680, 'POLYGON((76.5644 18.0626,76.5714 18.0626,76.5714 18.0688,76.5644 18.0688,76.5644 18.0626))'),
            ('LTR-FARM-0004', 'Mahadev Onion Farm', 'LTR-2025-0004', 'Aurad Shahajani', 1.25, 'LTR-PLOT-0004', '39/8', 0.70, 18.0611, 76.7680, 'POLYGON((76.7648 18.0587,76.7712 18.0587,76.7712 18.0637,76.7648 18.0637,76.7648 18.0587))'),
            ('LTR-FARM-0005', 'Nanda Mixed Farm', 'LTR-2025-0005', 'Harangul', 2.85, 'LTR-PLOT-0005', '121/1', 1.35, 18.4212, 76.5485, 'POLYGON((76.5450 18.4185,76.5520 18.4185,76.5520 18.4240,76.5450 18.4240,76.5450 18.4185))')
    ) AS x(farm_code, farm_name, farmer_code, village_name, farm_area_ha, plot_code, survey_number, plot_area_ha, lat, lon, wkt)
)
INSERT INTO farms (farm_code, display_name, farmer_id, village_id, total_area_ha, boundary, centroid, is_sample, created_by)
SELECT
    dp.farm_code,
    dp.farm_name,
    f.id,
    v.id,
    dp.farm_area_ha,
    ST_Multi(ST_GeomFromText(dp.wkt, 4326)),
    ST_Centroid(ST_GeomFromText(dp.wkt, 4326)),
    TRUE,
    u.id
FROM demo_plots dp
JOIN farmers f ON f.farmer_code = dp.farmer_code
JOIN villages v ON v.village_name = dp.village_name
JOIN users u ON u.email = 'admin@agrishield.local'
ON CONFLICT (farm_code) DO UPDATE
SET display_name = EXCLUDED.display_name,
    total_area_ha = EXCLUDED.total_area_ha,
    boundary = EXCLUDED.boundary,
    centroid = EXCLUDED.centroid,
    is_sample = TRUE,
    updated_at = NOW();

WITH demo_plots AS (
    SELECT *
    FROM (
        VALUES
            ('LTR-FARM-0001', 'LTR-2025-0001', 'Harangul', 'LTR-PLOT-0001', '118/2', 1.20, 18.4132, 76.5661, 'POLYGON((76.5628 18.4107,76.5693 18.4107,76.5693 18.4160,76.5628 18.4160,76.5628 18.4107))'),
            ('LTR-FARM-0002', 'LTR-2025-0002', 'Babhalgaon', 'LTR-PLOT-0002', '74/1', 0.95, 18.3874, 76.6022, 'POLYGON((76.5991 18.3848,76.6052 18.3848,76.6052 18.3904,76.5991 18.3904,76.5991 18.3848))'),
            ('LTR-FARM-0003', 'LTR-2025-0003', 'Killari', 'LTR-PLOT-0003', '203/4', 1.60, 18.0657, 76.5680, 'POLYGON((76.5644 18.0626,76.5714 18.0626,76.5714 18.0688,76.5644 18.0688,76.5644 18.0626))'),
            ('LTR-FARM-0004', 'LTR-2025-0004', 'Aurad Shahajani', 'LTR-PLOT-0004', '39/8', 0.70, 18.0611, 76.7680, 'POLYGON((76.7648 18.0587,76.7712 18.0587,76.7712 18.0637,76.7648 18.0637,76.7648 18.0587))'),
            ('LTR-FARM-0005', 'LTR-2025-0005', 'Harangul', 'LTR-PLOT-0005', '121/1', 1.35, 18.4212, 76.5485, 'POLYGON((76.5450 18.4185,76.5520 18.4185,76.5520 18.4240,76.5450 18.4240,76.5450 18.4185))')
    ) AS x(farm_code, farmer_code, village_name, plot_code, survey_number, plot_area_ha, lat, lon, wkt)
)
INSERT INTO plots (farm_id, farmer_id, plot_code, village_id, survey_number, area_ha, boundary, centroid, gps_lat, gps_lon, is_sample, created_by)
SELECT
    farm.id,
    farmer.id,
    dp.plot_code,
    village.id,
    dp.survey_number,
    dp.plot_area_ha,
    ST_Multi(ST_GeomFromText(dp.wkt, 4326)),
    ST_Centroid(ST_GeomFromText(dp.wkt, 4326)),
    dp.lat,
    dp.lon,
    TRUE,
    u.id
FROM demo_plots dp
JOIN farms farm ON farm.farm_code = dp.farm_code
JOIN farmers farmer ON farmer.farmer_code = dp.farmer_code
JOIN villages village ON village.village_name = dp.village_name
JOIN users u ON u.email = 'admin@agrishield.local'
ON CONFLICT (plot_code) DO UPDATE
SET area_ha = EXCLUDED.area_ha,
    boundary = EXCLUDED.boundary,
    centroid = EXCLUDED.centroid,
    gps_lat = EXCLUDED.gps_lat,
    gps_lon = EXCLUDED.gps_lon,
    is_sample = TRUE,
    updated_at = NOW();

-- Policies and policy crops.
WITH policy_rows AS (
    SELECT *
    FROM (
        VALUES
            ('POL-LTR-2025-000001', 'LTR-2025-0001', 'LTR-PLOT-0001', 'Cotton', 120000.00, 3000.00, 1),
            ('POL-LTR-2025-000002', 'LTR-2025-0002', 'LTR-PLOT-0002', 'Soybean', 90000.00, 2250.00, 1),
            ('POL-LTR-2025-000003', 'LTR-2025-0003', 'LTR-PLOT-0003', 'Paddy', 150000.00, 3750.00, 1),
            ('POL-LTR-2025-000004', 'LTR-2025-0004', 'LTR-PLOT-0004', 'Onion', 110000.00, 2750.00, 1),
            ('POL-LTR-2025-000005', 'LTR-2025-0005', 'LTR-PLOT-0005', 'Cotton', 140000.00, 3500.00, 1),
            ('POL-LTR-2025-000005', 'LTR-2025-0005', 'LTR-PLOT-0005', 'Onion', 65000.00, 1625.00, 2)
    ) AS x(policy_number, farmer_code, plot_code, crop_name, sum_insured, premium_amount, cycle_number)
)
INSERT INTO policies (
    policy_number,
    policy_type_id,
    farmer_id,
    plot_id,
    season,
    policy_year,
    policy_start,
    policy_end,
    total_sum_insured,
    premium_amount,
    premium_status,
    is_pmfby,
    status,
    created_by,
    approved_by,
    approved_at
)
SELECT
    pr.policy_number,
    pt.id,
    f.id,
    p.id,
    'kharif',
    2025,
    DATE '2025-06-01',
    DATE '2026-03-31',
    SUM(pr.sum_insured),
    SUM(pr.premium_amount),
    'paid',
    TRUE,
    'active',
    admin_user.id,
    underwriter_user.id,
    NOW()
FROM policy_rows pr
JOIN policy_types pt ON pt.policy_type_key = 'latur_crop_stress_parametric_cover'
JOIN farmers f ON f.farmer_code = pr.farmer_code
JOIN plots p ON p.plot_code = pr.plot_code
JOIN users admin_user ON admin_user.email = 'admin@agrishield.local'
JOIN users underwriter_user ON underwriter_user.email = 'underwriter@agrishield.local'
GROUP BY pr.policy_number, pt.id, f.id, p.id, admin_user.id, underwriter_user.id
ON CONFLICT (policy_number) DO UPDATE
SET total_sum_insured = EXCLUDED.total_sum_insured,
    premium_amount = EXCLUDED.premium_amount,
    premium_status = EXCLUDED.premium_status,
    status = EXCLUDED.status,
    updated_at = NOW();

WITH policy_rows AS (
    SELECT *
    FROM (
        VALUES
            ('POL-LTR-2025-000001', 'Cotton', 120000.00, DATE '2025-06-15', DATE '2025-12-10', 1),
            ('POL-LTR-2025-000002', 'Soybean', 90000.00, DATE '2025-06-20', DATE '2025-10-12', 1),
            ('POL-LTR-2025-000003', 'Paddy', 150000.00, DATE '2025-06-22', DATE '2025-11-15', 1),
            ('POL-LTR-2025-000004', 'Onion', 110000.00, DATE '2025-11-05', DATE '2026-03-10', 1),
            ('POL-LTR-2025-000005', 'Cotton', 140000.00, DATE '2025-06-18', DATE '2025-12-05', 1),
            ('POL-LTR-2025-000005', 'Onion', 65000.00, DATE '2025-12-20', DATE '2026-03-25', 2)
    ) AS x(policy_number, crop_name, sum_insured, sowing_date, harvest_date, cycle_number)
)
INSERT INTO policy_crops (policy_id, crop_id, crop_calendar_id, sum_insured, sowing_date, expected_harvest_date, cycle_number, is_primary)
SELECT
    pol.id,
    c.id,
    cc.id,
    pr.sum_insured,
    pr.sowing_date,
    pr.harvest_date,
    pr.cycle_number,
    pr.cycle_number = 1
FROM policy_rows pr
JOIN policies pol ON pol.policy_number = pr.policy_number
JOIN crops c ON c.crop_name = pr.crop_name
LEFT JOIN crop_calendar cc ON cc.crop_id = c.id AND cc.region_scope = 'Latur'
ON CONFLICT (policy_id, crop_id, cycle_number) DO UPDATE
SET sum_insured = EXCLUDED.sum_insured,
    sowing_date = EXCLUDED.sowing_date,
    expected_harvest_date = EXCLUDED.expected_harvest_date;

-- Model run and crop cycles.
INSERT INTO model_versions (model_name, version_tag, model_type, description, script_hash, parameters, is_active, created_by)
SELECT
    'crop_prediction',
    'demo-v1.0.0',
    'crop_prediction',
    'Demo crop cycle interpretation for Latur vertical slice.',
    encode(digest('crop_prediction_demo_v1', 'sha256'), 'hex'),
    '{"low_ndvi_threshold":0.30,"active_ndvi_threshold":0.45,"min_ndvi_rise":0.15,"min_ndvi_drop":0.20}'::jsonb,
    TRUE,
    u.id
FROM users u
WHERE u.email = 'admin@agrishield.local'
ON CONFLICT (model_name, version_tag) DO UPDATE
SET is_active = TRUE,
    parameters = EXCLUDED.parameters;

INSERT INTO prediction_runs (model_version_id, run_key, input_file_id, plots_processed, cycles_detected, avg_confidence_pct, run_notes, created_by)
SELECT
    mv.id,
    'demo-latur-2025-run',
    NULL,
    5,
    6,
    87.60,
    'Sample crop cycle run for local API and GIS validation.',
    u.id
FROM model_versions mv
JOIN users u ON u.email = 'admin@agrishield.local'
WHERE mv.model_name = 'crop_prediction'
  AND mv.version_tag = 'demo-v1.0.0'
ON CONFLICT (run_key) DO UPDATE
SET plots_processed = EXCLUDED.plots_processed,
    cycles_detected = EXCLUDED.cycles_detected,
    avg_confidence_pct = EXCLUDED.avg_confidence_pct;

WITH cycle_rows AS (
    SELECT *
    FROM (
        VALUES
            ('LTR-PLOT-0001', 'POL-LTR-2025-000001', 'Cotton', 'single', 1, DATE '2025-06-15', DATE '2025-09-18', DATE '2025-12-10', 0.29, 0.72, 0.42, 0.43, 0.30, 178, 92.4, TRUE),
            ('LTR-PLOT-0002', 'POL-LTR-2025-000002', 'Soybean', 'single', 1, DATE '2025-06-20', DATE '2025-09-05', DATE '2025-10-12', 0.31, 0.63, 0.36, 0.32, 0.27, 114, 89.2, TRUE),
            ('LTR-PLOT-0003', 'POL-LTR-2025-000003', 'Paddy', 'single', 1, DATE '2025-06-22', DATE '2025-09-20', DATE '2025-11-15', 0.34, 0.77, 0.52, 0.43, 0.25, 146, 91.1, TRUE),
            ('LTR-PLOT-0004', 'POL-LTR-2025-000004', 'Onion', 'single', 1, DATE '2025-11-05', DATE '2026-01-12', DATE '2026-03-10', 0.28, 0.58, 0.31, 0.30, 0.27, 125, 81.5, TRUE),
            ('LTR-PLOT-0005', 'POL-LTR-2025-000005', 'Cotton', 'double', 1, DATE '2025-06-18', DATE '2025-09-12', DATE '2025-12-05', 0.30, 0.69, 0.40, 0.39, 0.29, 170, 74.8, TRUE),
            ('LTR-PLOT-0005', 'POL-LTR-2025-000005', 'Onion', 'double', 2, DATE '2025-12-20', DATE '2026-02-08', DATE '2026-03-25', 0.27, 0.49, 0.34, 0.22, 0.15, 95, 68.3, TRUE)
    ) AS x(plot_code, policy_number, crop_name, intensity, cycle_number, cycle_start, cycle_peak, cycle_end, ndvi_start, ndvi_peak, ndvi_end, ndvi_rise, ndvi_drop, duration_days, confidence_pct, is_known)
)
INSERT INTO crop_cycles (
    plot_id,
    prediction_run_id,
    crop_id,
    crop_calendar_id,
    policy_crop_id,
    cropping_intensity,
    cycle_number,
    cycle_start,
    cycle_peak,
    cycle_end,
    ndvi_at_start,
    ndvi_at_peak,
    ndvi_at_end,
    ndvi_rise,
    ndvi_drop,
    duration_days,
    confidence_pct,
    is_known_crop,
    raw_prediction
)
SELECT
    p.id,
    prun.id,
    c.id,
    cc.id,
    pc.id,
    cr.intensity::cropping_intensity,
    cr.cycle_number,
    cr.cycle_start,
    cr.cycle_peak,
    cr.cycle_end,
    cr.ndvi_start,
    cr.ndvi_peak,
    cr.ndvi_end,
    cr.ndvi_rise,
    cr.ndvi_drop,
    cr.duration_days,
    cr.confidence_pct,
    cr.is_known,
    jsonb_build_object('demo', TRUE, 'source', 'phase_3_demo_seed')
FROM cycle_rows cr
JOIN plots p ON p.plot_code = cr.plot_code
JOIN prediction_runs prun ON prun.run_key = 'demo-latur-2025-run'
JOIN crops c ON c.crop_name = cr.crop_name
LEFT JOIN crop_calendar cc ON cc.crop_id = c.id AND cc.region_scope = 'Latur'
LEFT JOIN policies pol ON pol.policy_number = cr.policy_number
LEFT JOIN policy_crops pc ON pc.policy_id = pol.id AND pc.crop_id = c.id AND pc.cycle_number = cr.cycle_number
ON CONFLICT (plot_id, prediction_run_id, cycle_number) DO UPDATE
SET confidence_pct = EXCLUDED.confidence_pct,
    raw_prediction = EXCLUDED.raw_prediction;

-- Observation batch and sample observations.
INSERT INTO observation_batches (batch_key, source_id, batch_type, status, records_received, records_accepted, records_rejected, ingestion_completed_at, metadata)
SELECT
    'demo-latur-observations-2025',
    ds.id,
    'demo_seed',
    'completed',
    25,
    25,
    0,
    NOW(),
    '{"demo":true}'::jsonb
FROM data_sources ds
WHERE ds.source_key = 'mock_demo'
ON CONFLICT (batch_key) DO UPDATE
SET status = EXCLUDED.status,
    records_received = EXCLUDED.records_received,
    records_accepted = EXCLUDED.records_accepted,
    ingestion_completed_at = EXCLUDED.ingestion_completed_at;

WITH obs AS (
    SELECT *
    FROM (
        VALUES
            ('LTR-PLOT-0001', TIMESTAMPTZ '2025-09-18 00:00:00+00', 0.55, 0.72, 23.61, 42.00),
            ('LTR-PLOT-0002', TIMESTAMPTZ '2025-09-05 00:00:00+00', 0.49, 0.63, 22.22, 38.00),
            ('LTR-PLOT-0003', TIMESTAMPTZ '2025-09-20 00:00:00+00', 0.70, 0.77, 9.09, 12.00),
            ('LTR-PLOT-0004', TIMESTAMPTZ '2026-01-12 00:00:00+00', 0.36, 0.58, 37.93, 31.00),
            ('LTR-PLOT-0005', TIMESTAMPTZ '2025-09-12 00:00:00+00', 0.39, 0.69, 43.48, 47.00)
    ) AS x(plot_code, observed_at, observed_ndvi, expected_ndvi, ndvi_anomaly_pct, rainfall_anomaly_pct)
)
INSERT INTO ndvi_observations (plot_id, source_id, batch_id, observed_at, ndvi_value, cloud_cover_pct, quality, is_interpolated, pixel_count, metadata)
SELECT
    p.id,
    ds.id,
    b.id,
    obs.observed_at,
    obs.observed_ndvi,
    6.50,
    'clean',
    FALSE,
    128,
    jsonb_build_object('expected_ndvi', obs.expected_ndvi, 'demo', TRUE)
FROM obs
JOIN plots p ON p.plot_code = obs.plot_code
JOIN data_sources ds ON ds.source_key = 'mock_demo'
JOIN observation_batches b ON b.batch_key = 'demo-latur-observations-2025'
ON CONFLICT (plot_id, source_id, observed_at) DO UPDATE
SET ndvi_value = EXCLUDED.ndvi_value,
    metadata = EXCLUDED.metadata;

WITH obs AS (
    SELECT *
    FROM (
        VALUES
            ('LTR-PLOT-0001', TIMESTAMPTZ '2025-09-18 00:00:00+00', 62.0, 105.0, 42.0),
            ('LTR-PLOT-0002', TIMESTAMPTZ '2025-09-05 00:00:00+00', 74.0, 119.0, 38.0),
            ('LTR-PLOT-0003', TIMESTAMPTZ '2025-09-20 00:00:00+00', 132.0, 150.0, 12.0),
            ('LTR-PLOT-0004', TIMESTAMPTZ '2026-01-12 00:00:00+00', 25.0, 36.0, 31.0),
            ('LTR-PLOT-0005', TIMESTAMPTZ '2025-09-12 00:00:00+00', 58.0, 110.0, 47.0)
    ) AS x(plot_code, observed_at, rainfall_mm, normal_mm, anomaly_pct)
)
INSERT INTO rainfall_observations (plot_id, source_id, batch_id, observed_at, period, rainfall_mm, normal_mm, anomaly_pct, quality, metadata)
SELECT
    p.id,
    ds.id,
    b.id,
    obs.observed_at,
    '30_day',
    obs.rainfall_mm,
    obs.normal_mm,
    obs.anomaly_pct,
    'clean',
    '{"demo":true}'::jsonb
FROM obs
JOIN plots p ON p.plot_code = obs.plot_code
JOIN data_sources ds ON ds.source_key = 'mock_demo'
JOIN observation_batches b ON b.batch_key = 'demo-latur-observations-2025';

-- Trigger events.
WITH trigger_rows AS (
    SELECT *
    FROM (
        VALUES
            ('TRG-LTR-2025-000001', 'LTR-PLOT-0001', 'POL-LTR-2025-000001', 'Cotton', 1, DATE '2025-09-18', 0.55, 0.72, 23.61, 42.00, 'moderate', 50.00, 'B_MODERATE_NDVI_STRESS', FALSE, NULL, 'auto_approved'),
            ('TRG-LTR-2025-000002', 'LTR-PLOT-0002', 'POL-LTR-2025-000002', 'Soybean', 1, DATE '2025-09-05', 0.49, 0.63, 22.22, 38.00, 'moderate', 50.00, 'B_MODERATE_NDVI_STRESS', FALSE, NULL, 'auto_approved'),
            ('TRG-LTR-2025-000003', 'LTR-PLOT-0003', 'POL-LTR-2025-000003', 'Paddy', 1, DATE '2025-09-20', 0.70, 0.77, 9.09, 12.00, 'no_stress', 0.00, 'B_NO_STRESS', FALSE, NULL, 'auto_approved'),
            ('TRG-LTR-2025-000004', 'LTR-PLOT-0004', 'POL-LTR-2025-000004', 'Onion', 1, DATE '2026-01-12', 0.36, 0.58, 37.93, 31.00, 'severe', 75.00, 'B_SEVERE_NDVI_STRESS', TRUE, 'confidence below auto-approval threshold', 'under_review'),
            ('TRG-LTR-2025-000005', 'LTR-PLOT-0005', 'POL-LTR-2025-000005', 'Cotton', 1, DATE '2025-09-12', 0.39, 0.69, 43.48, 47.00, 'severe', 75.00, 'B_SEVERE_NDVI_STRESS', TRUE, 'low confidence and rainfall confirmation required', 'under_review')
    ) AS x(event_key, plot_code, policy_number, crop_name, cycle_number, trigger_date, observed_ndvi, expected_ndvi, ndvi_anomaly_pct, rainfall_anomaly_pct, stress_band, payout_pct, reason_code, review_flag, review_reason, approval_status)
)
INSERT INTO trigger_events (
    event_key,
    plot_id,
    policy_id,
    policy_crop_id,
    crop_cycle_id,
    trigger_rule_id,
    trigger_type,
    trigger_date,
    observed_value,
    expected_value,
    observed_ndvi,
    expected_ndvi,
    ndvi_anomaly_pct,
    rainfall_anomaly_pct,
    stress_band,
    payout_pct,
    reason_code,
    reason_detail,
    crop_confidence_pct,
    review_flag,
    review_reason,
    approval_status,
    source_observation_refs,
    record_hash
)
SELECT
    tr.event_key,
    p.id,
    pol.id,
    pc.id,
    ccyl.id,
    rule.id,
    'mid_season_stress',
    tr.trigger_date,
    tr.observed_ndvi,
    tr.expected_ndvi,
    tr.observed_ndvi,
    tr.expected_ndvi,
    tr.ndvi_anomaly_pct,
    tr.rainfall_anomaly_pct,
    tr.stress_band::stress_band,
    tr.payout_pct,
    tr.reason_code,
    format('Observed NDVI %s vs expected %s. NDVI anomaly %s%%. Rainfall anomaly %s%%.', tr.observed_ndvi, tr.expected_ndvi, tr.ndvi_anomaly_pct, tr.rainfall_anomaly_pct),
    ccyl.confidence_pct,
    tr.review_flag,
    tr.review_reason,
    tr.approval_status::approval_status,
    jsonb_build_array(jsonb_build_object('type', 'ndvi', 'source', 'mock_demo')),
    generate_record_hash(ARRAY[tr.event_key, tr.plot_code, tr.reason_code, tr.payout_pct::TEXT])
FROM trigger_rows tr
JOIN plots p ON p.plot_code = tr.plot_code
JOIN policies pol ON pol.policy_number = tr.policy_number
JOIN crops crop ON crop.crop_name = tr.crop_name
JOIN policy_crops pc ON pc.policy_id = pol.id AND pc.crop_id = crop.id AND pc.cycle_number = tr.cycle_number
JOIN crop_cycles ccyl ON ccyl.plot_id = p.id AND ccyl.policy_crop_id = pc.id
JOIN trigger_rules rule ON rule.rule_key = 'default_mid_season_stress'
ON CONFLICT (event_key) DO NOTHING;

INSERT INTO basis_risk_flags (trigger_event_id, flag_key, flag_reason, severity, confidence_pct, ndvi_anomaly_pct, rainfall_anomaly_pct)
SELECT
    te.id,
    v.flag_key,
    v.flag_reason,
    v.severity,
    te.crop_confidence_pct,
    te.ndvi_anomaly_pct,
    te.rainfall_anomaly_pct
FROM (
    VALUES
        ('TRG-LTR-2025-000004', 'low_confidence', 'Crop confidence is below auto-approval threshold.', 'medium'),
        ('TRG-LTR-2025-000005', 'low_confidence', 'Severe stress with low confidence requires underwriter review.', 'high')
) AS v(event_key, flag_key, flag_reason, severity)
JOIN trigger_events te ON te.event_key = v.event_key
WHERE NOT EXISTS (
    SELECT 1
    FROM basis_risk_flags brf
    WHERE brf.trigger_event_id = te.id
      AND brf.flag_key = v.flag_key
);

INSERT INTO payout_approvals (trigger_event_id, approver_id, previous_status, new_status, action_taken, notes)
SELECT
    te.id,
    u.id,
    'pending_review',
    te.approval_status,
    CASE WHEN te.approval_status = 'auto_approved' THEN 'auto_approved' ELSE 'sent_for_review' END,
    'Demo seed approval event.'
FROM trigger_events te
JOIN users u ON u.email = 'underwriter@agrishield.local'
WHERE te.event_key IN ('TRG-LTR-2025-000001', 'TRG-LTR-2025-000002', 'TRG-LTR-2025-000003', 'TRG-LTR-2025-000004', 'TRG-LTR-2025-000005')
  AND NOT EXISTS (
      SELECT 1 FROM payout_approvals pa WHERE pa.trigger_event_id = te.id
  );

INSERT INTO payout_records (
    payout_number,
    trigger_event_id,
    policy_id,
    farmer_id,
    plot_id,
    policy_crop_id,
    sum_insured,
    payout_pct,
    payout_amount,
    payment_status,
    approved_by,
    approved_at,
    record_hash
)
SELECT
    'PAY-' || replace(te.event_key, 'TRG-', ''),
    te.id,
    pol.id,
    pol.farmer_id,
    pol.plot_id,
    pc.id,
    pc.sum_insured,
    te.payout_pct,
    calculate_payout_amount(pc.sum_insured, te.payout_pct),
    'completed',
    u.id,
    NOW(),
    generate_record_hash(ARRAY[te.event_key, pc.sum_insured::TEXT, te.payout_pct::TEXT])
FROM trigger_events te
JOIN policies pol ON pol.id = te.policy_id
JOIN policy_crops pc ON pc.id = te.policy_crop_id
JOIN users u ON u.email = 'underwriter@agrishield.local'
WHERE te.approval_status = 'auto_approved'
  AND te.payout_pct > 0
ON CONFLICT (payout_number) DO NOTHING;

INSERT INTO payout_payment_events (payout_record_id, payment_status, payment_method, payment_reference, gateway_payload, acted_by)
SELECT
    pr.id,
    'completed',
    'upi',
    'DEMO-UPI-' || pr.payout_number,
    '{"demo":true,"provider":"mock"}'::jsonb,
    u.id
FROM payout_records pr
JOIN users u ON u.email = 'underwriter@agrishield.local'
WHERE NOT EXISTS (
    SELECT 1 FROM payout_payment_events ppe WHERE ppe.payout_record_id = pr.id
);

INSERT INTO notification_logs (farmer_id, channel, language, subject, body, payout_record_id, trigger_event_id, status, provider_ref, sent_at, delivered_at)
SELECT
    pr.farmer_id,
    'sms',
    f.preferred_language,
    NULL,
    format('Demo payout %s of INR %s completed for policy %s.', pr.payout_number, pr.payout_amount, pol.policy_number),
    pr.id,
    pr.trigger_event_id,
    'delivered',
    'DEMO-SMS-' || pr.payout_number,
    NOW(),
    NOW()
FROM payout_records pr
JOIN farmers f ON f.id = pr.farmer_id
JOIN policies pol ON pol.id = pr.policy_id
WHERE NOT EXISTS (
    SELECT 1 FROM notification_logs nl WHERE nl.payout_record_id = pr.id
);

INSERT INTO schema_migrations (version, description)
VALUES ('seed_0002_demo_latur_portfolio', 'Demo Latur farmers, plots, policies, observations, triggers, payouts')
ON CONFLICT (version) DO NOTHING;

COMMIT;
