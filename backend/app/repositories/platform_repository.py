from sqlalchemy import text
from sqlalchemy.orm import Session

from app.repositories.common import row_to_dict, rows_to_dicts


class PlatformRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def dashboard_summary(self) -> dict:
        row = self.db.execute(
            text(
                """
                SELECT
                    (SELECT COUNT(*) FROM farmers) AS farmers,
                    (SELECT COUNT(*) FROM plots) AS plots,
                    (SELECT COUNT(*) FROM policies WHERE status = 'active') AS active_policies,
                    (SELECT COALESCE(SUM(total_sum_insured), 0) FROM policies WHERE status = 'active') AS exposure_amount,
                    (SELECT COUNT(*) FROM trigger_events) AS trigger_events,
                    (SELECT COUNT(*) FROM trigger_events WHERE review_flag = TRUE) AS review_cases,
                    (SELECT COALESCE(SUM(payout_amount), 0) FROM payout_records) AS paid_amount,
                    (SELECT COUNT(*) FROM payout_records WHERE payment_status = 'completed') AS completed_payouts
                """
            )
        ).mappings().one()
        return dict(row)

    def stress_distribution(self) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT stress_band::text AS stress_band, COUNT(*) AS count
                FROM trigger_events
                GROUP BY stress_band
                ORDER BY stress_band
                """
            )
        ).mappings().all()
        return rows_to_dicts(rows)

    def payout_distribution(self) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT
                    date_trunc('month', created_at)::date AS month,
                    COUNT(*) AS payout_count,
                    COALESCE(SUM(payout_amount), 0) AS payout_amount
                FROM payout_records
                GROUP BY 1
                ORDER BY 1
                """
            )
        ).mappings().all()
        return rows_to_dicts(rows)

    def farmers(self, limit: int = 50) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT *
                FROM v_farmer_policy_summary
                ORDER BY farmer_code
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()
        return rows_to_dicts(rows)

    def policies(self, limit: int = 50) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT
                    pol.id::text,
                    pol.policy_number,
                    pol.status::text,
                    pol.season::text,
                    pol.policy_year,
                    pol.policy_start,
                    pol.policy_end,
                    pol.total_sum_insured,
                    pol.premium_amount,
                    pol.premium_status::text,
                    f.farmer_code,
                    f.full_name AS farmer_name,
                    p.plot_code,
                    pt.display_name AS policy_type
                FROM policies pol
                JOIN farmers f ON f.id = pol.farmer_id
                JOIN plots p ON p.id = pol.plot_id
                JOIN policy_types pt ON pt.id = pol.policy_type_id
                ORDER BY pol.policy_number
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()
        return rows_to_dicts(rows)

    def triggers(self, limit: int = 100) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT
                    te.id,
                    te.event_key,
                    te.trigger_date,
                    te.trigger_type::text,
                    te.stress_band::text,
                    te.payout_pct,
                    te.ndvi_anomaly_pct,
                    te.rainfall_anomaly_pct,
                    te.reason_code,
                    te.reason_detail,
                    te.crop_confidence_pct,
                    te.review_flag,
                    te.review_reason,
                    te.approval_status::text,
                    p.plot_code,
                    f.farmer_code,
                    f.full_name AS farmer_name
                FROM trigger_events te
                JOIN plots p ON p.id = te.plot_id
                JOIN farmers f ON f.id = p.farmer_id
                ORDER BY te.trigger_date DESC, te.created_at DESC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()
        return rows_to_dicts(rows)

    def approval_queue(self) -> list[dict]:
        rows = self.db.execute(text("SELECT * FROM v_approval_queue")).mappings().all()
        return rows_to_dicts(rows)

    def payouts(self, limit: int = 100) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT
                    pr.id::text,
                    pr.payout_number,
                    pr.sum_insured,
                    pr.payout_pct,
                    pr.payout_amount,
                    pr.currency,
                    pr.payment_status::text,
                    pr.created_at,
                    pol.policy_number,
                    f.farmer_code,
                    f.full_name AS farmer_name,
                    p.plot_code,
                    te.reason_code
                FROM payout_records pr
                JOIN policies pol ON pol.id = pr.policy_id
                JOIN farmers f ON f.id = pr.farmer_id
                JOIN plots p ON p.id = pr.plot_id
                JOIN trigger_events te ON te.id = pr.trigger_event_id
                ORDER BY pr.created_at DESC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()
        return rows_to_dicts(rows)

    def risk_scores(self, limit: int = 100) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT *
                FROM v_ml_risk_summary
                ORDER BY risk_score DESC, plot_code
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()
        return rows_to_dicts(rows)

    def ndvi_series(self, plot_id: int) -> list[dict]:
        rows = self.db.execute(
            text(
                """
                SELECT
                    n.plot_id,
                    n.observed_at,
                    n.ndvi_value,
                    n.quality::text,
                    n.is_interpolated,
                    n.metadata,
                    ds.source_key
                FROM ndvi_observations n
                JOIN data_sources ds ON ds.id = n.source_id
                WHERE n.plot_id = :plot_id
                ORDER BY n.observed_at
                """
            ),
            {"plot_id": plot_id},
        ).mappings().all()
        return rows_to_dicts(rows)

    def plot_detail(self, plot_id: int) -> dict | None:
        row = self.db.execute(
            text("SELECT * FROM v_plot_trigger_summary WHERE plot_id = :plot_id"),
            {"plot_id": plot_id},
        ).mappings().first()
        return row_to_dict(row)
