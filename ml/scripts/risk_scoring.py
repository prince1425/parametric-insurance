from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Any

import psycopg
from psycopg.rows import dict_row


DEFAULT_DATABASE_URL = "postgresql://postgres@localhost:5432/agrishield"


@dataclass(frozen=True)
class Score:
    risk_score: Decimal
    risk_band: str
    loss_probability_pct: Decimal
    drought_probability_pct: Decimal
    flood_probability_pct: Decimal
    disease_probability_pct: Decimal
    payout_prediction_pct: Decimal
    explanation: str


def as_decimal(value: Any, default: str = "0") -> Decimal:
    if value is None:
        return Decimal(default)
    return Decimal(str(value))


def clamp(value: Decimal, low: Decimal = Decimal("0"), high: Decimal = Decimal("100")) -> Decimal:
    return max(low, min(high, value)).quantize(Decimal("0.01"))


def risk_band(score: Decimal) -> str:
    if score < 25:
        return "low"
    if score < 50:
        return "guarded"
    if score < 75:
        return "high"
    return "critical"


def compute_score(row: dict[str, Any], config: dict[str, Any]) -> Score:
    weights = config["weights"]
    stress_weights = config["stress_weights"]

    ndvi = as_decimal(row.get("ndvi_anomaly_pct"))
    rainfall = as_decimal(row.get("rainfall_anomaly_pct"))
    confidence = as_decimal(row.get("crop_confidence_pct"), "100")
    payout_pct = as_decimal(row.get("payout_pct"))
    stress = str(row.get("stress_band") or "no_stress")
    review_flag = bool(row.get("review_flag"))

    confidence_gap = max(Decimal("0"), Decimal("100") - confidence)
    raw_score = (
        ndvi * Decimal(str(weights["ndvi_anomaly"]))
        + rainfall * Decimal(str(weights["rainfall_anomaly"]))
        + confidence_gap * Decimal(str(weights["confidence_gap"]))
        + Decimal(str(stress_weights.get(stress, 0)))
        + (Decimal(str(weights["review_flag"])) if review_flag else Decimal("0"))
    )

    score = clamp(raw_score)
    band = risk_band(score)
    loss_probability = clamp(score * Decimal("0.85"), high=Decimal("95"))
    drought_probability = clamp(max(ndvi * Decimal("1.1"), rainfall * Decimal("1.2")), high=Decimal("95"))
    flood_probability = clamp(Decimal("8") if stress in {"severe", "extreme"} else Decimal("4"))
    disease_probability = clamp(confidence_gap * Decimal("0.5") + (Decimal("10") if stress == "severe" else Decimal("0")), high=Decimal("70"))
    payout_prediction = clamp(max(payout_pct, score * Decimal("0.65")), high=Decimal("100"))

    explanation = (
        f"{band.upper()} risk from NDVI anomaly {ndvi}%, rainfall anomaly {rainfall}%, "
        f"crop confidence {confidence}%, stress band {stress}, review flag {review_flag}."
    )

    return Score(
        risk_score=score,
        risk_band=band,
        loss_probability_pct=loss_probability,
        drought_probability_pct=drought_probability,
        flood_probability_pct=flood_probability,
        disease_probability_pct=disease_probability,
        payout_prediction_pct=payout_prediction,
        explanation=explanation,
    )


def load_config(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def ensure_model_version(conn: psycopg.Connection, config: dict[str, Any]) -> int:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO agri.model_versions (
                model_name,
                version_tag,
                model_type,
                description,
                script_hash,
                parameters,
                is_active
            )
            VALUES (
                %(model_name)s,
                %(version_tag)s,
                'risk_scoring',
                'Deterministic baseline risk score for Phase 7 vertical slice.',
                encode(digest(%(hash_input)s, 'sha256'), 'hex'),
                %(parameters)s::jsonb,
                TRUE
            )
            ON CONFLICT (model_name, version_tag) DO UPDATE
            SET parameters = EXCLUDED.parameters,
                is_active = TRUE
            RETURNING id
            """,
            {
                "model_name": config["model_name"],
                "version_tag": config["version_tag"],
                "hash_input": f"{config['model_name']}:{config['version_tag']}",
                "parameters": json.dumps(config),
            },
        )
        return int(cur.fetchone()["id"])


def fetch_features(conn: psycopg.Connection) -> list[dict[str, Any]]:
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(
            """
            SELECT
                te.plot_id,
                p.plot_code,
                f.farmer_code,
                f.full_name AS farmer_name,
                te.trigger_date,
                te.stress_band::text,
                te.payout_pct,
                te.ndvi_anomaly_pct,
                te.rainfall_anomaly_pct,
                te.crop_confidence_pct,
                te.review_flag,
                te.reason_code,
                te.approval_status::text,
                COALESCE(c.crop_name, s.latest_crop_name) AS crop_name
            FROM agri.trigger_events te
            JOIN agri.plots p ON p.id = te.plot_id
            JOIN agri.farmers f ON f.id = p.farmer_id
            LEFT JOIN agri.crop_cycles cc ON cc.id = te.crop_cycle_id
            LEFT JOIN agri.crops c ON c.id = cc.crop_id
            LEFT JOIN agri.v_plot_trigger_summary s ON s.plot_id = p.id
            ORDER BY te.trigger_date DESC, te.created_at DESC
            """
        )
        return list(cur.fetchall())


def upsert_outputs(
    conn: psycopg.Connection,
    model_version_id: int,
    rows: list[dict[str, Any]],
    config: dict[str, Any],
    score_date: date,
) -> int:
    written = 0
    with conn.cursor(row_factory=dict_row) as cur:
        for row in rows:
            score = compute_score(row, config)
            feature_payload = json.dumps({key: str(value) for key, value in row.items()})
            cur.execute(
                """
                INSERT INTO agri.ml_feature_snapshots (
                    plot_id,
                    model_version_id,
                    snapshot_date,
                    feature_payload,
                    source_refs
                )
                VALUES (%s, %s, %s, %s::jsonb, %s::jsonb)
                ON CONFLICT (plot_id, model_version_id, snapshot_date) DO UPDATE
                SET feature_payload = EXCLUDED.feature_payload,
                    source_refs = EXCLUDED.source_refs
                RETURNING id
                """,
                (
                    row["plot_id"],
                    model_version_id,
                    score_date,
                    feature_payload,
                    json.dumps([{"type": "trigger_event", "reason_code": row.get("reason_code")}]),
                ),
            )
            snapshot_id = int(cur.fetchone()["id"])
            cur.execute(
                """
                INSERT INTO agri.ml_risk_scores (
                    plot_id,
                    model_version_id,
                    feature_snapshot_id,
                    score_date,
                    risk_score,
                    risk_band,
                    loss_probability_pct,
                    drought_probability_pct,
                    flood_probability_pct,
                    disease_probability_pct,
                    payout_prediction_pct,
                    explanation
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (plot_id, model_version_id, score_date) DO UPDATE
                SET feature_snapshot_id = EXCLUDED.feature_snapshot_id,
                    risk_score = EXCLUDED.risk_score,
                    risk_band = EXCLUDED.risk_band,
                    loss_probability_pct = EXCLUDED.loss_probability_pct,
                    drought_probability_pct = EXCLUDED.drought_probability_pct,
                    flood_probability_pct = EXCLUDED.flood_probability_pct,
                    disease_probability_pct = EXCLUDED.disease_probability_pct,
                    payout_prediction_pct = EXCLUDED.payout_prediction_pct,
                    explanation = EXCLUDED.explanation
                """,
                (
                    row["plot_id"],
                    model_version_id,
                    snapshot_id,
                    score_date,
                    score.risk_score,
                    score.risk_band,
                    score.loss_probability_pct,
                    score.drought_probability_pct,
                    score.flood_probability_pct,
                    score.disease_probability_pct,
                    score.payout_prediction_pct,
                    score.explanation,
                ),
            )
            written += 1
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Agrishield deterministic risk scoring.")
    parser.add_argument("--config", default=str(Path(__file__).parents[1] / "config.json"))
    parser.add_argument("--database-url", default=os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL))
    parser.add_argument("--score-date", default=date.today().isoformat())
    args = parser.parse_args()

    config = load_config(Path(args.config))
    score_date = date.fromisoformat(args.score_date)

    with psycopg.connect(args.database_url, row_factory=dict_row) as conn:
        model_version_id = ensure_model_version(conn, config)
        rows = fetch_features(conn)
        written = upsert_outputs(conn, model_version_id, rows, config, score_date)
        conn.commit()

    print(json.dumps({"model_version_id": model_version_id, "features": len(rows), "scores_written": written}, indent=2))


if __name__ == "__main__":
    main()
