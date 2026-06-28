# Phase 6 - GIS

Status: Complete

Phase 6 implements the GIS module as a working vertical slice backed by PostGIS and FastAPI.

## Implemented GIS Capabilities

- PostGIS sample plot polygons in `agri.plots`.
- GeoJSON API at `/api/v1/gis/plots`.
- Leaflet map in `frontend/src/pages/gis/GISMapPage.tsx`.
- Stress-band choropleth styling.
- Selected plot risk panel.
- Legend for stress classes.
- Sample geometry flag retained in database and API properties.

## Architecture

```text
PostGIS plots -> FastAPI GISRepository -> /api/v1/gis/plots -> React Leaflet GeoJSON layer
```

## Current Layer

The current layer is a clearly labeled Latur demo plot layer. Production plot or parcel boundaries can replace it through the same `plots.boundary` geometry field and GIS API route.
