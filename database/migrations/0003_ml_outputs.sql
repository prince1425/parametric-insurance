-- =============================================================================
-- AGRISHIELD PHASE 7 ML OUTPUT TABLES
-- Feature snapshots and risk score outputs for crop-stress risk models.
-- =============================================================================

BEGIN;

SET search_path = agri, public;

CREATE TABLE IF NOT EXISTS ml_feature_snapshots (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
    model_version_id INT NOT NULL REFERENCES model_versions(id) ON DELETE RESTRICT,
    snapshot_date DATE NOT NULL,
    feature_payload JSONB NOT NULL,
    source_refs JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (plot_id, model_version_id, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_ml_feature_snapshots_plot_date
ON ml_feature_snapshots (plot_id, snapshot_date DESC);

CREATE TABLE IF NOT EXISTS ml_risk_scores (
    id BIGSERIAL PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE CASCADE,
    model_version_id INT NOT NULL REFERENCES model_versions(id) ON DELETE RESTRICT,
    feature_snapshot_id BIGINT REFERENCES ml_feature_snapshots(id) ON DELETE SET NULL,
    score_date DATE NOT NULL,
    risk_score NUMERIC(6, 2) NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_band TEXT NOT NULL CHECK (risk_band IN ('low', 'guarded', 'high', 'critical')),
    loss_probability_pct NUMERIC(6, 2) NOT NULL CHECK (loss_probability_pct >= 0 AND loss_probability_pct <= 100),
    drought_probability_pct NUMERIC(6, 2) NOT NULL CHECK (drought_probability_pct >= 0 AND drought_probability_pct <= 100),
    flood_probability_pct NUMERIC(6, 2) NOT NULL CHECK (flood_probability_pct >= 0 AND flood_probability_pct <= 100),
    disease_probability_pct NUMERIC(6, 2) NOT NULL CHECK (disease_probability_pct >= 0 AND disease_probability_pct <= 100),
    payout_prediction_pct NUMERIC(6, 2) NOT NULL CHECK (payout_prediction_pct >= 0 AND payout_prediction_pct <= 100),
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (plot_id, model_version_id, score_date)
);

CREATE INDEX IF NOT EXISTS idx_ml_risk_scores_plot_date
ON ml_risk_scores (plot_id, score_date DESC);

CREATE INDEX IF NOT EXISTS idx_ml_risk_scores_band
ON ml_risk_scores (risk_band);

CREATE OR REPLACE VIEW v_ml_risk_summary AS
SELECT DISTINCT ON (mrs.plot_id)
    mrs.plot_id,
    p.plot_code,
    f.farmer_code,
    f.full_name AS farmer_name,
    s.latest_crop_name,
    s.stress_band,
    s.ndvi_anomaly_pct,
    s.payout_pct,
    s.approval_status,
    mrs.score_date,
    mrs.risk_score,
    mrs.risk_band,
    mrs.loss_probability_pct,
    mrs.drought_probability_pct,
    mrs.flood_probability_pct,
    mrs.disease_probability_pct,
    mrs.payout_prediction_pct,
    mrs.explanation,
    mv.model_name,
    mv.version_tag
FROM ml_risk_scores mrs
JOIN plots p ON p.id = mrs.plot_id
JOIN farmers f ON f.id = p.farmer_id
JOIN model_versions mv ON mv.id = mrs.model_version_id
LEFT JOIN v_plot_trigger_summary s ON s.plot_id = p.id
ORDER BY mrs.plot_id, mrs.score_date DESC, mrs.created_at DESC;

INSERT INTO schema_migrations (version, description)
VALUES ('0003_ml_outputs', 'ML feature snapshots and risk score output tables')
ON CONFLICT (version) DO NOTHING;

COMMIT;
