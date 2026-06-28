from decimal import Decimal

from scripts.risk_scoring import compute_score


def test_compute_score_marks_severe_low_confidence_as_high_or_critical():
    score = compute_score(
        {
            "ndvi_anomaly_pct": Decimal("43.48"),
            "rainfall_anomaly_pct": Decimal("47.00"),
            "crop_confidence_pct": Decimal("74.80"),
            "stress_band": "severe",
            "review_flag": True,
            "payout_pct": Decimal("75.00"),
        },
        {
            "weights": {
                "ndvi_anomaly": 1.2,
                "rainfall_anomaly": 0.35,
                "confidence_gap": 0.45,
                "review_flag": 8.0,
            },
            "stress_weights": {
                "no_stress": 0,
                "mild": 8,
                "moderate": 18,
                "severe": 30,
                "extreme": 42,
            },
        },
    )

    assert score.risk_score >= Decimal("75")
    assert score.risk_band == "critical"
    assert score.payout_prediction_pct >= Decimal("75")
