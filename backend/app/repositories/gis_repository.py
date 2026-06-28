from sqlalchemy import text
from sqlalchemy.orm import Session


class GISRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def plot_geojson(self) -> dict:
        row = self.db.execute(
            text(
                """
                SELECT jsonb_build_object(
                    'type', 'FeatureCollection',
                    'features', COALESCE(jsonb_agg(feature), '[]'::jsonb)
                ) AS geojson
                FROM (
                    SELECT jsonb_build_object(
                        'type', 'Feature',
                        'id', p.id,
                        'geometry', ST_AsGeoJSON(COALESCE(p.boundary, ST_Buffer(p.centroid, 0.001)::geometry))::jsonb,
                        'properties', jsonb_build_object(
                            'plot_id', p.id,
                            'plot_code', p.plot_code,
                            'farmer_code', f.farmer_code,
                            'farmer_name', f.full_name,
                            'village_name', v.village_name,
                            'area_ha', p.area_ha,
                            'is_sample', p.is_sample,
                            'stress_band', s.stress_band,
                            'payout_pct', s.payout_pct,
                            'ndvi_anomaly_pct', s.ndvi_anomaly_pct,
                            'reason_code', s.reason_code,
                            'approval_status', s.approval_status,
                            'payout_amount', s.payout_amount,
                            'payment_status', s.payment_status,
                            'latest_crop', s.latest_crop_name,
                            'crop_confidence', s.latest_crop_confidence_pct
                        )
                    ) AS feature
                    FROM plots p
                    JOIN farmers f ON f.id = p.farmer_id
                    LEFT JOIN villages v ON v.id = p.village_id
                    LEFT JOIN v_plot_trigger_summary s ON s.plot_id = p.id
                    WHERE p.is_active = TRUE
                    ORDER BY p.plot_code
                ) features
                """
            )
        ).scalar_one()
        return row

    def map_summary(self) -> dict:
        row = self.db.execute(
            text(
                """
                SELECT
                    COUNT(*) AS total_plots,
                    COUNT(*) FILTER (WHERE is_sample = TRUE) AS sample_plots,
                    ST_AsGeoJSON(ST_Extent(COALESCE(boundary, ST_Buffer(centroid, 0.001)::geometry))) AS bbox_geojson
                FROM plots
                WHERE is_active = TRUE
                """
            )
        ).mappings().one()
        return dict(row)
