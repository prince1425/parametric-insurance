from sqlalchemy.orm import Session

from app.repositories.gis_repository import GISRepository
from app.repositories.platform_repository import PlatformRepository


class PlatformService:
    def __init__(self, db: Session) -> None:
        self.repo = PlatformRepository(db)
        self.gis_repo = GISRepository(db)

    def dashboard(self) -> dict:
        return {
            "summary": self.repo.dashboard_summary(),
            "stress_distribution": self.repo.stress_distribution(),
            "payout_distribution": self.repo.payout_distribution(),
            "approval_queue": self.repo.approval_queue(),
        }

    def farmers(self) -> list[dict]:
        return self.repo.farmers()

    def policies(self) -> list[dict]:
        return self.repo.policies()

    def triggers(self) -> list[dict]:
        return self.repo.triggers()

    def payouts(self) -> list[dict]:
        return self.repo.payouts()

    def risk_scores(self) -> list[dict]:
        return self.repo.risk_scores()

    def ndvi_series(self, plot_id: int) -> list[dict]:
        return self.repo.ndvi_series(plot_id)

    def plot_detail(self, plot_id: int) -> dict | None:
        return self.repo.plot_detail(plot_id)

    def plot_geojson(self) -> dict:
        return self.gis_repo.plot_geojson()

    def map_summary(self) -> dict:
        return self.gis_repo.map_summary()
