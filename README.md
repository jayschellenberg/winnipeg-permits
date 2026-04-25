# Winnipeg Building Permits

Interactive reports on City of Winnipeg new-construction building permits, prepared by Jason M. Schellenberg, P. App, AACI ([JKS Consulting Inc.](https://jksconsultinginc.com)).

**Live site:** https://winnipeg-permits.vercel.app

## Reports

| Report | What it covers |
|---|---|
| [Non-Residential Permits](https://winnipeg-permits.vercel.app/WpgNonResPermits.html) | New-construction permits filed under the Non-Residential permit group (commercial, institutional, industrial). Map, filters, parcel overlay, CSV export. |
| [Multi-Residential Permits](https://winnipeg-permits.vercel.app/WpgMultiResPermits.html) | New-construction permits with more than two dwelling units (apartments, condominiums, multi-family). Map, filters, neighbourhood + cluster overlays, CSV export. |

Each report is a single self-contained HTML file: sticky filter bar, interactive Leaflet map, DT data table with CSV download, and dynamic filters that narrow each other (e.g. selecting "Apartments" hides neighbourhoods with no matching permits).

## Data source

Live City of Winnipeg open data via the [SODA2 API](https://data.winnipeg.ca/):

- [Building Permits (`it4w-cpf4`)](https://data.winnipeg.ca/Permits-Licences-and-Inspections/Building-Permits/it4w-cpf4) — permits since 2010, work type "Construct New".
- [Assessment Parcels (`d4mq-wa44`)](https://data.winnipeg.ca/Assessment-Taxation-Corporate/Assessment-Parcels/d4mq-wa44) — parcel polygons for the map overlay (Non-Res report).
- `WpgNeighbourhoods.geojson` — local copy of City of Winnipeg neighbourhood polygons with neighbourhood-cluster attribution.

Data is © City of Winnipeg under the [Open Government Licence – Winnipeg](https://data.winnipeg.ca/open-data-licence).

## How it builds

The reports are written in [Quarto](https://quarto.org) (`.qmd` → self-contained HTML) using R with `leaflet`, `crosstalk`, `DT`, `sf`, and `downloadthis`. A GitHub Actions workflow ([`.github/workflows/render.yml`](.github/workflows/render.yml)) renders both reports weekly (Monday 11:00 UTC), commits the HTML back to `main`, and Vercel auto-deploys the site.

To render locally:

```bash
quarto render WpgNonResPermits.qmd
quarto render WpgMultiResPermits.qmd
```

R package list: `httr2`, `jsonlite`, `dplyr`, `tidyr`, `stringr`, `lubridate`, `leaflet`, `leaflet.extras`, `DT`, `crosstalk`, `htmltools`, `downloadthis`, `rlang`, `sf`.

## Licence

Code in this repository is provided as-is for transparency. Underlying data is © City of Winnipeg under the [Open Government Licence – Winnipeg](https://data.winnipeg.ca/open-data-licence).
