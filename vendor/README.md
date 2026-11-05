# vendor/

Third-party browser code checked in verbatim, pinned by version and SHA-256.
Do not edit by hand; re-vendor instead.

## protomaps-leaflet.js

Renders OpenStreetMap vector tiles from a PMTiles archive inside a Leaflet map.
Loaded by `R/basemap.R` (read that first) and inlined into each report by
Quarto's `embed-resources`.

| | |
|---|---|
| Version | 5.1.0 |
| Source | `https://cdn.jsdelivr.net/npm/protomaps-leaflet@5.1.0/dist/protomaps-leaflet.js` |
| SHA-256 | `26af014f7b1af308ec120b791cff76657bb9c3383633b52033e6edf9e5e4cdb5` |
| Vendored | 2026-11-05 (copied from RentalDashboard/vendor, same pin) |
| Licence | BSD-3-Clause |

Re-vendor only in step with the tile archive's schema major (v4 today, set by
mb-parcelsearch's `rebuild-basemap.ps1`). Update this table and the version
string in `basemap_dep()`, then re-render and confirm the maps draw.
