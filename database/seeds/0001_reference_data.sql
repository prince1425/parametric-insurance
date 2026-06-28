-- =============================================================================
-- AGRISHIELD PHASE 3 REFERENCE DATA
-- =============================================================================

BEGIN;

SET search_path = agri, public;

-- Roles
INSERT INTO roles (role_key, display_name, description) VALUES
    ('super_admin', 'Super Admin', 'Full platform administration.'),
    ('admin', 'Admin', 'Operational administration.'),
    ('underwriter', 'Underwriter', 'Policy and payout review.'),
    ('field_officer', 'Field Officer', 'Farm verification and field review.'),
    ('farmer', 'Farmer', 'Farmer self-service portal access.'),
    ('government', 'Government', 'Scheme and district monitoring.'),
    ('reinsurer', 'Reinsurance Company', 'Portfolio exposure and loss monitoring.'),
    ('auditor', 'Auditor', 'Read-only audit and compliance review.')
ON CONFLICT (role_key) DO NOTHING;

-- Permissions
INSERT INTO permissions (permission_key, module_key, action_key, description) VALUES
    ('auth.login', 'auth', 'login', 'Authenticate into the platform.'),
    ('users.manage', 'users', 'manage', 'Create and manage users.'),
    ('roles.manage', 'roles', 'manage', 'Manage roles and permissions.'),
    ('farmers.read', 'farmers', 'read', 'Read farmer profiles.'),
    ('farmers.manage', 'farmers', 'manage', 'Create and update farmer profiles.'),
    ('kyc.verify', 'kyc', 'verify', 'Verify farmer KYC documents.'),
    ('plots.read', 'plots', 'read', 'Read farm and plot records.'),
    ('plots.manage', 'plots', 'manage', 'Create and update farm and plot records.'),
    ('policies.read', 'policies', 'read', 'Read policies.'),
    ('policies.manage', 'policies', 'manage', 'Create and update policies.'),
    ('premium.calculate', 'premium', 'calculate', 'Calculate premium quotes.'),
    ('observations.read', 'observations', 'read', 'Read observation records.'),
    ('observations.ingest', 'observations', 'ingest', 'Ingest observation data.'),
    ('triggers.read', 'triggers', 'read', 'Read trigger events and rules.'),
    ('triggers.run', 'triggers', 'run', 'Run trigger calculations.'),
    ('basis_risk.review', 'basis_risk', 'review', 'Review basis-risk flags.'),
    ('approvals.manage', 'approvals', 'manage', 'Approve or reject trigger events.'),
    ('payouts.read', 'payouts', 'read', 'Read payout records.'),
    ('payouts.manage', 'payouts', 'manage', 'Create and manage payouts.'),
    ('reports.export', 'reports', 'export', 'Export reports.'),
    ('analytics.read', 'analytics', 'read', 'Read dashboards and analytics.'),
    ('audit.read', 'audit', 'read', 'Read immutable audit log.'),
    ('settings.manage', 'settings', 'manage', 'Manage system settings.'),
    ('api_clients.manage', 'api_clients', 'manage', 'Manage API clients and integrations.')
ON CONFLICT (permission_key) DO NOTHING;

-- Super admin receives all permissions.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_key = 'super_admin'
ON CONFLICT DO NOTHING;

-- Admin receives all non-sensitive platform operations.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.permission_key IN (
    'users.manage', 'farmers.read', 'farmers.manage', 'kyc.verify',
    'plots.read', 'plots.manage', 'policies.read', 'policies.manage',
    'premium.calculate', 'observations.read', 'observations.ingest',
    'triggers.read', 'basis_risk.review', 'approvals.manage',
    'payouts.read', 'reports.export', 'analytics.read',
    'audit.read', 'settings.manage'
)
WHERE r.role_key = 'admin'
ON CONFLICT DO NOTHING;

-- Domain roles.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON (
    (r.role_key = 'underwriter' AND p.permission_key IN ('farmers.read', 'plots.read', 'policies.read', 'policies.manage', 'premium.calculate', 'observations.read', 'triggers.read', 'basis_risk.review', 'approvals.manage', 'payouts.read', 'analytics.read', 'reports.export'))
    OR (r.role_key = 'field_officer' AND p.permission_key IN ('farmers.read', 'farmers.manage', 'kyc.verify', 'plots.read', 'plots.manage', 'observations.read', 'basis_risk.review'))
    OR (r.role_key = 'farmer' AND p.permission_key IN ('farmers.read', 'plots.read', 'policies.read', 'observations.read', 'triggers.read', 'payouts.read'))
    OR (r.role_key = 'government' AND p.permission_key IN ('farmers.read', 'plots.read', 'policies.read', 'observations.read', 'triggers.read', 'payouts.read', 'analytics.read', 'reports.export', 'audit.read'))
    OR (r.role_key = 'reinsurer' AND p.permission_key IN ('policies.read', 'observations.read', 'triggers.read', 'payouts.read', 'analytics.read', 'reports.export'))
    OR (r.role_key = 'auditor' AND p.permission_key IN ('farmers.read', 'plots.read', 'policies.read', 'observations.read', 'triggers.read', 'payouts.read', 'analytics.read', 'audit.read', 'reports.export'))
)
ON CONFLICT DO NOTHING;

-- Data sources
INSERT INTO data_sources (source_key, display_name, source_type, provider_url, is_live, priority_rank) VALUES
    ('mock_demo', 'Mock Demo Data', 'mock', NULL, FALSE, 10),
    ('sentinel2', 'Sentinel-2 Optical Imagery', 'satellite', 'https://dataspace.copernicus.eu/', TRUE, 20),
    ('sentinel1_sar', 'Sentinel-1 SAR RVI', 'satellite', 'https://dataspace.copernicus.eu/', TRUE, 30),
    ('google_earth_engine', 'Google Earth Engine', 'satellite', 'https://earthengine.google.com/', TRUE, 40),
    ('copernicus', 'Copernicus Data Space', 'satellite', 'https://dataspace.copernicus.eu/', TRUE, 50),
    ('usgs', 'USGS EarthExplorer', 'satellite', 'https://earthexplorer.usgs.gov/', TRUE, 60),
    ('isro_bhuvan', 'ISRO Bhuvan', 'satellite', 'https://bhuvan.nrsc.gov.in/', TRUE, 70),
    ('imd', 'India Meteorological Department', 'weather', 'https://mausam.imd.gov.in/', TRUE, 10),
    ('chirps', 'CHIRPS Rainfall', 'weather', 'https://www.chc.ucsb.edu/data/chirps', TRUE, 20),
    ('era5', 'ERA5 Reanalysis', 'weather', 'https://cds.climate.copernicus.eu/', TRUE, 30),
    ('nasa_power', 'NASA POWER', 'weather', 'https://power.larc.nasa.gov/', TRUE, 40),
    ('openweather', 'OpenWeather', 'weather', 'https://openweathermap.org/', TRUE, 50),
    ('tomorrow_io', 'Tomorrow.io', 'weather', 'https://www.tomorrow.io/', TRUE, 60),
    ('razorpay', 'Razorpay Payments', 'payment', 'https://razorpay.com/', TRUE, 100),
    ('pmfby', 'PMFBY', 'government', 'https://pmfby.gov.in/', TRUE, 100),
    ('agristack', 'Agristack', 'government', NULL, TRUE, 100)
ON CONFLICT (source_key) DO UPDATE
SET display_name = EXCLUDED.display_name,
    source_type = EXCLUDED.source_type,
    provider_url = EXCLUDED.provider_url,
    is_live = EXCLUDED.is_live,
    priority_rank = EXCLUDED.priority_rank,
    updated_at = NOW();

-- Geography
INSERT INTO states (state_name, state_code)
VALUES ('Maharashtra', 'MH')
ON CONFLICT (state_name) DO NOTHING;

INSERT INTO districts (state_id, district_name)
SELECT id, 'Latur'
FROM states
WHERE state_name = 'Maharashtra'
ON CONFLICT (state_id, district_name) DO NOTHING;

-- Common Latur POC crops. The full 34-record crop calendar should be ingested from the source workbook in the ML/data phase.
INSERT INTO crops (crop_name, crop_category) VALUES
    ('Cotton', 'fiber'),
    ('Soybean', 'oilseed'),
    ('Paddy', 'cereal'),
    ('Maize', 'cereal'),
    ('Onion', 'vegetable'),
    ('Tur', 'pulse'),
    ('Sorghum', 'cereal'),
    ('Groundnut', 'oilseed')
ON CONFLICT (crop_name) DO UPDATE
SET crop_category = EXCLUDED.crop_category;

INSERT INTO crop_calendar (crop_id, season, start_month, end_month, duration_days, region_scope, source_id)
SELECT c.id, v.season::season_type, v.start_month, v.end_month, v.duration_days, 'Latur', ds.id
FROM (
    VALUES
        ('Cotton', 'kharif', 6, 12, 180),
        ('Soybean', 'kharif', 6, 10, 120),
        ('Paddy', 'kharif', 6, 11, 150),
        ('Maize', 'kharif', 6, 10, 120),
        ('Onion', 'rabi', 11, 3, 120),
        ('Tur', 'kharif', 6, 1, 180),
        ('Sorghum', 'rabi', 10, 2, 120),
        ('Groundnut', 'kharif', 6, 10, 120)
) AS v(crop_name, season, start_month, end_month, duration_days)
JOIN crops c ON c.crop_name = v.crop_name
LEFT JOIN data_sources ds ON ds.source_key = 'mock_demo'
ON CONFLICT (crop_id, season, region_scope) DO UPDATE
SET start_month = EXCLUDED.start_month,
    end_month = EXCLUDED.end_month,
    duration_days = EXCLUDED.duration_days;

INSERT INTO crop_growth_stages (crop_calendar_id, stage_key, stage_label, start_day, end_day)
SELECT cc.id, v.stage_key, v.stage_label, v.start_day, LEAST(v.end_day, cc.duration_days)
FROM crop_calendar cc
CROSS JOIN (
    VALUES
        ('establishment', 'Establishment', 0, 45),
        ('active_growth', 'Active Growth', 46, 90),
        ('peak', 'Peak Vegetation', 91, 130),
        ('senescence', 'Senescence', 131, 220)
) AS v(stage_key, stage_label, start_day, end_day)
WHERE cc.region_scope = 'Latur'
  AND v.start_day <= cc.duration_days
ON CONFLICT (crop_calendar_id, stage_key) DO UPDATE
SET stage_label = EXCLUDED.stage_label,
    start_day = EXCLUDED.start_day,
    end_day = EXCLUDED.end_day;

INSERT INTO policy_types (policy_type_key, display_name, description, default_terms)
VALUES (
    'latur_crop_stress_parametric_cover',
    'Latur Crop Stress Parametric Cover',
    'NDVI-led parametric crop stress cover for Latur POC and future production slices.',
    '{"primary_trigger":"mid_season_stress","supporting_triggers":["establishment_failure","sudden_decline"],"currency":"INR"}'::jsonb
)
ON CONFLICT (policy_type_key) DO UPDATE
SET display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    default_terms = EXCLUDED.default_terms;

INSERT INTO premium_rules (rule_key, policy_type_id, crop_id, base_rate_pct, risk_multiplier)
SELECT 'default_latur_crop_stress_rate', pt.id, NULL, 2.5000, 1.0000
FROM policy_types pt
WHERE pt.policy_type_key = 'latur_crop_stress_parametric_cover'
ON CONFLICT (rule_key) DO NOTHING;

INSERT INTO trigger_rules (
    rule_key,
    version_tag,
    display_name,
    trigger_type,
    policy_type_id,
    threshold_value,
    threshold_unit,
    observation_window_days,
    payout_ladder,
    review_policy
)
SELECT
    v.rule_key,
    'v1',
    v.display_name,
    v.trigger_type::trigger_type,
    pt.id,
    v.threshold_value,
    v.threshold_unit,
    v.window_days,
    v.payout_ladder::jsonb,
    v.review_policy::jsonb
FROM (
    VALUES
        (
            'default_establishment_failure',
            'Trigger A - Establishment Failure',
            'establishment_failure',
            0.1500,
            'ndvi_rise',
            45,
            '[{"band":"no_stress","payout_pct":0},{"band":"extreme","payout_pct":100}]',
            '{"manual_review_when":["low_confidence","unknown_crop","no_clear_cycle"]}'
        ),
        (
            'default_mid_season_stress',
            'Trigger B - Mid-Season Vegetation Stress',
            'mid_season_stress',
            10.0000,
            'ndvi_anomaly_pct',
            30,
            '[{"band":"no_stress","min":0,"max":10,"payout_pct":0},{"band":"mild","min":10,"max":20,"payout_pct":25},{"band":"moderate","min":20,"max":35,"payout_pct":50},{"band":"severe","min":35,"max":60,"payout_pct":75},{"band":"extreme","min":60,"payout_pct":100}]',
            '{"auto_approval_confidence_threshold_pct":85,"manual_review_when":["extreme","unknown_fallow","basis_risk_flag"]}'
        ),
        (
            'default_sudden_decline',
            'Trigger C - Sudden Decline After Peak',
            'sudden_decline',
            0.2500,
            'ndvi_drop',
            30,
            '[{"band":"no_stress","payout_pct":0},{"band":"severe","payout_pct":75},{"band":"extreme","payout_pct":100}]',
            '{"manual_review_when":["calendar_mismatch","possible_harvest","low_confidence"]}'
        )
) AS v(rule_key, display_name, trigger_type, threshold_value, threshold_unit, window_days, payout_ladder, review_policy)
JOIN policy_types pt ON pt.policy_type_key = 'latur_crop_stress_parametric_cover'
ON CONFLICT (rule_key, version_tag) DO UPDATE
SET display_name = EXCLUDED.display_name,
    threshold_value = EXCLUDED.threshold_value,
    threshold_unit = EXCLUDED.threshold_unit,
    observation_window_days = EXCLUDED.observation_window_days,
    payout_ladder = EXCLUDED.payout_ladder,
    review_policy = EXCLUDED.review_policy;

INSERT INTO notification_templates (template_key, channel, language, subject_template, body_template) VALUES
    ('trigger_review_required', 'sms', 'en', NULL, 'Your crop insurance event requires review. Reason: {{reason_code}}.'),
    ('payout_approved', 'sms', 'en', NULL, 'Your crop insurance payout of INR {{payout_amount}} has been approved.'),
    ('payout_approved', 'sms', 'mr', NULL, 'Aaplya pik vima bhugtan INR {{payout_amount}} manjur jhale aahe.'),
    ('policy_active', 'email', 'en', 'Policy Active', 'Your policy {{policy_number}} is active.')
ON CONFLICT (template_key, channel, language) DO UPDATE
SET subject_template = EXCLUDED.subject_template,
    body_template = EXCLUDED.body_template;

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
    ('auto_approval_confidence_threshold_pct', '85'::jsonb, 'Minimum crop confidence required for auto-approval.'),
    ('extreme_stress_policy', '"manual_review_required"'::jsonb, 'Extreme stress or 100 percent payout candidates require manual review.'),
    ('supported_farmer_languages', '["mr","hi","en"]'::jsonb, 'Supported farmer notification languages.'),
    ('default_currency', '"INR"'::jsonb, 'Default payout and premium currency.'),
    ('geometry_policy', '"real_geometry_preferred_sample_geometry_must_be_labeled"'::jsonb, 'Sample geometries must be labeled.')
ON CONFLICT (setting_key) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    description = EXCLUDED.description,
    updated_at = NOW();

INSERT INTO schema_migrations (version, description)
VALUES ('seed_0001_reference_data', 'Initial roles, permissions, sources, crops, triggers, settings')
ON CONFLICT (version) DO NOTHING;

COMMIT;
