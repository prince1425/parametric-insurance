def test_health(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["database"] == "ok"


def test_login_and_dashboard(client, auth_headers):
    response = client.get("/api/v1/dashboard/summary", headers=auth_headers)

    assert response.status_code == 200
    payload = response.json()
    assert int(payload["summary"]["farmers"]) >= 5
    assert int(payload["summary"]["active_policies"]) >= 5
    assert "stress_distribution" in payload


def test_gis_plot_geojson(client, auth_headers):
    response = client.get("/api/v1/gis/plots", headers=auth_headers)

    assert response.status_code == 200
    payload = response.json()
    assert payload["type"] == "FeatureCollection"
    assert len(payload["features"]) >= 5
    assert "stress_band" in payload["features"][0]["properties"]


def test_ml_risk_scores(client, auth_headers):
    response = client.get("/api/v1/ml/risk-scores", headers=auth_headers)

    assert response.status_code == 200
    payload = response.json()
    assert len(payload) >= 5
    assert {"risk_score", "risk_band", "loss_probability_pct"} <= payload[0].keys()
