SET search_path = agri, public;

SELECT 'farmers' AS check_name, COUNT(*) >= 5 AS passed FROM farmers
UNION ALL
SELECT 'plots', COUNT(*) >= 5 FROM plots
UNION ALL
SELECT 'policies', COUNT(*) >= 5 FROM policies
UNION ALL
SELECT 'trigger_events', COUNT(*) >= 5 FROM trigger_events
UNION ALL
SELECT 'ml_risk_scores', COUNT(*) >= 5 FROM ml_risk_scores
UNION ALL
SELECT 'gis_geojson_ready', COUNT(*) >= 5 FROM plots WHERE boundary IS NOT NULL
UNION ALL
SELECT 'views_available', COUNT(*) >= 6 FROM information_schema.views WHERE table_schema = 'agri';
