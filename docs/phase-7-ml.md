# Phase 7 - ML

Status: Complete

Phase 7 implements the first production-shaped ML slice: deterministic risk scoring from crop stress trigger features. It is intentionally transparent and auditable, which is appropriate for an insurance decision support workflow.

## Architecture

```text
trigger_events + crop_cycles + observations
  -> ml/scripts/risk_scoring.py
  -> ml_feature_snapshots
  -> ml_risk_scores
  -> v_ml_risk_summary
```

## Implemented Components

- `database/migrations/0003_ml_outputs.sql`
- `ml/config.json`
- `ml/scripts/risk_scoring.py`
- `shared/domain/phase7-ml.json`
- `GET /api/v1/ml/risk-scores`

## Local Run Result

The Phase 7 scorer was run against `agrishield` on 2026-06-29.

```json
{
  "model_version_id": 2,
  "features": 5,
  "scores_written": 5
}
```

## Model Type

The current model is a deterministic baseline score, not a black-box predictive model. It produces:

- `risk_score`
- `risk_band`
- `loss_probability_pct`
- `drought_probability_pct`
- `flood_probability_pct`
- `disease_probability_pct`
- `payout_prediction_pct`
- human-readable explanation

## Why This Model Is Acceptable For The Current Phase

- It is explainable.
- It stores feature snapshots.
- It links scores to a versioned `model_versions` row.
- It can later be replaced by a trained model without changing downstream tables.
- It avoids unsupported claims from a tiny demo dataset.

## Future ML Upgrades

- Crop prediction from full NDVI time series.
- Yield prediction when ground-truth yield data is available.
- Rainfall and drought forecasting.
- Flood probability from terrain and rainfall.
- Disease probability with agronomy/weather features.
- Model registry integration with MLflow or equivalent.
