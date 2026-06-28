-- =============================================================================
-- AGRISHIELD PHASE 3 REPORTING AND DASHBOARD VIEWS
-- =============================================================================

BEGIN;

SET search_path = agri, public;

CREATE OR REPLACE VIEW v_plot_trigger_summary AS
SELECT
    p.id AS plot_id,
    p.plot_code,
    p.is_sample AS plot_is_sample,
    f.id AS farmer_id,
    f.farmer_code,
    f.full_name AS farmer_name,
    f.mobile_number,
    v.village_name,
    t.taluka_name,
    d.district_name,
    c.crop_name AS latest_crop_name,
    cyc.confidence_pct AS latest_crop_confidence_pct,
    cyc.cropping_intensity,
    te.id AS latest_trigger_event_id,
    te.trigger_type,
    te.stress_band,
    te.payout_pct,
    te.ndvi_anomaly_pct,
    te.reason_code,
    te.review_flag,
    te.review_reason,
    te.approval_status,
    te.trigger_date,
    pr.payout_number,
    pr.payout_amount,
    pr.payment_status
FROM plots p
JOIN farmers f ON f.id = p.farmer_id
LEFT JOIN villages v ON v.id = p.village_id
LEFT JOIN talukas t ON t.id = v.taluka_id
LEFT JOIN districts d ON d.id = t.district_id
LEFT JOIN LATERAL (
    SELECT *
    FROM crop_cycles
    WHERE plot_id = p.id
    ORDER BY created_at DESC
    LIMIT 1
) cyc ON TRUE
LEFT JOIN crops c ON c.id = cyc.crop_id
LEFT JOIN LATERAL (
    SELECT *
    FROM trigger_events
    WHERE plot_id = p.id
    ORDER BY trigger_date DESC, created_at DESC
    LIMIT 1
) te ON TRUE
LEFT JOIN payout_records pr ON pr.trigger_event_id = te.id;

CREATE OR REPLACE VIEW v_approval_queue AS
SELECT
    te.id AS trigger_event_id,
    te.event_key,
    te.trigger_date,
    te.trigger_type,
    te.stress_band,
    te.payout_pct,
    te.ndvi_anomaly_pct,
    te.reason_code,
    te.reason_detail,
    te.review_flag,
    te.review_reason,
    te.crop_confidence_pct,
    te.approval_status,
    p.id AS plot_id,
    p.plot_code,
    p.is_sample AS plot_is_sample,
    f.id AS farmer_id,
    f.full_name AS farmer_name,
    f.mobile_number,
    pol.policy_number,
    pc.sum_insured,
    calculate_payout_amount(pc.sum_insured, te.payout_pct) AS estimated_payout_amount,
    brf.flag_key AS basis_risk_flag_key,
    brf.flag_reason AS basis_risk_reason,
    brf.severity AS basis_risk_severity
FROM trigger_events te
JOIN plots p ON p.id = te.plot_id
JOIN farmers f ON f.id = p.farmer_id
LEFT JOIN policies pol ON pol.id = te.policy_id
LEFT JOIN policy_crops pc ON pc.id = te.policy_crop_id
LEFT JOIN LATERAL (
    SELECT *
    FROM basis_risk_flags
    WHERE trigger_event_id = te.id
      AND is_resolved = FALSE
    ORDER BY flagged_at DESC
    LIMIT 1
) brf ON TRUE
WHERE te.approval_status IN ('pending_review', 'under_review', 'field_verification_required', 'on_hold')
ORDER BY te.trigger_date DESC, te.created_at DESC;

CREATE OR REPLACE VIEW v_district_risk_summary AS
SELECT
    d.id AS district_id,
    d.district_name,
    COUNT(DISTINCT p.id) AS total_plots,
    COUNT(DISTINCT pol.id) AS active_policies,
    COUNT(te.id) FILTER (WHERE te.stress_band = 'no_stress') AS no_stress_count,
    COUNT(te.id) FILTER (WHERE te.stress_band = 'mild') AS mild_count,
    COUNT(te.id) FILTER (WHERE te.stress_band = 'moderate') AS moderate_count,
    COUNT(te.id) FILTER (WHERE te.stress_band = 'severe') AS severe_count,
    COUNT(te.id) FILTER (WHERE te.stress_band = 'extreme') AS extreme_count,
    COUNT(te.id) FILTER (WHERE te.review_flag = TRUE) AS review_count,
    COALESCE(SUM(pr.payout_amount), 0) AS total_payout_amount
FROM districts d
LEFT JOIN talukas t ON t.district_id = d.id
LEFT JOIN villages v ON v.taluka_id = t.id
LEFT JOIN plots p ON p.village_id = v.id
LEFT JOIN policies pol ON pol.plot_id = p.id AND pol.status = 'active'
LEFT JOIN LATERAL (
    SELECT *
    FROM trigger_events
    WHERE plot_id = p.id
    ORDER BY trigger_date DESC, created_at DESC
    LIMIT 1
) te ON TRUE
LEFT JOIN payout_records pr ON pr.trigger_event_id = te.id
GROUP BY d.id, d.district_name;

CREATE OR REPLACE VIEW v_farmer_policy_summary AS
SELECT
    f.id AS farmer_id,
    f.farmer_code,
    f.full_name,
    f.mobile_number,
    f.kyc_status,
    COUNT(DISTINCT p.id) AS plot_count,
    COUNT(DISTINCT pol.id) AS policy_count,
    COALESCE(SUM(pol.total_sum_insured), 0) AS total_sum_insured,
    COALESCE(SUM(pol.premium_amount), 0) AS total_premium_amount,
    COALESCE(SUM(pr.payout_amount), 0) AS total_payout_amount
FROM farmers f
LEFT JOIN plots p ON p.farmer_id = f.id
LEFT JOIN policies pol ON pol.farmer_id = f.id
LEFT JOIN payout_records pr ON pr.farmer_id = f.id
GROUP BY f.id, f.farmer_code, f.full_name, f.mobile_number, f.kyc_status;

CREATE OR REPLACE VIEW v_latest_ndvi_by_plot AS
SELECT DISTINCT ON (n.plot_id)
    n.plot_id,
    p.plot_code,
    n.observed_at,
    n.ndvi_value,
    n.quality,
    n.is_interpolated,
    ds.source_key,
    ds.display_name AS source_name
FROM ndvi_observations n
JOIN plots p ON p.id = n.plot_id
JOIN data_sources ds ON ds.id = n.source_id
ORDER BY n.plot_id, n.observed_at DESC;

INSERT INTO schema_migrations (version, description)
VALUES ('views_0001_reporting_views', 'Initial dashboard and reporting views')
ON CONFLICT (version) DO NOTHING;

COMMIT;
