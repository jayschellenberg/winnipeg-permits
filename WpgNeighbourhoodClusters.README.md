# Using `WpgNeighbourhoodClusters.geojson`

Drop-in replacement for the 235-polygon `WpgNeighbourhoods.geojson` when you only
need the 23 WRHA **neighbourhood clusters** — dissolved, cleaned, and ready to map.

Canonical copy lives in `D:/Dropbox/Appraisal/RProjects/BaseFiles/`.
Project-local copies should match that one byte-for-byte.

---

## 1. What's in the file

- **Type:** `FeatureCollection`, CRS `urn:ogc:def:crs:OGC:1.3:CRS84` (= EPSG:4326, lon/lat).
- **Features:** 23 polygons, one per WRHA neighbourhood cluster.
- **Properties on each feature:**
  | property             | type    | notes                                                           |
  | -------------------- | ------- | --------------------------------------------------------------- |
  | `cluster`            | string  | **lowercase** — cluster name (e.g. `"Assiniboine South"`)       |
  | `neighbourhood_count`| integer | number of constituent neighbourhoods                            |
  | `neighbourhoods`     | string  | semicolon-separated list of the member neighbourhood names      |

The 23 cluster names:
```
Assiniboine South, Downtown East, Downtown West, Fort Garry North, Fort Garry South,
Inkster East, Inkster West, Point Douglas North, Point Douglas South, River East East,
River East South, River East West, River Heights East, River Heights West,
Seven Oaks East, Seven Oaks West, St. Boniface East, St. Boniface West,
St. James-Assiniboia East, St. James-Assiniboia West, St. Vital North, St. Vital South,
Transcona
```

---

## 2. Gotchas vs. the old `WpgNeighbourhoods.geojson`

| aspect              | `WpgNeighbourhoods.geojson` (235) | `WpgNeighbourhoodClusters.geojson` (23) |
| ------------------- | --------------------------------- | --------------------------------------- |
| field case          | `Cluster` (Pascal)                | `cluster` (lowercase)                   |
| individual hoods    | ✅ `Name`, `ID`                   | ❌ only the name list as a string       |
| pre-dissolved       | ❌ 235 raw polygons               | ✅ 23 clean cluster polygons            |
| geometry container  | WKT string in `Location`          | native GeoJSON geometry                 |
| needs Wilkes clip   | yes (for Assiniboine South)       | **no — already clipped**                |
| needs hole cleanup  | yes                               | **no — already cleaned**                |

If you're porting code from the 235-hood file, the checklist is:

1. Change `"Cluster"` → `"cluster"` in any `names(...)` / `select(Cluster)` check.
2. **Delete** any `group_by(Cluster) |> summarize(st_union(...))` dissolve — the file is pre-dissolved.
3. **Delete** any `clip_assiniboine_south_to_wilkes()` / `drop_polygon_holes()` helpers and the
   `wilkes_ave_boundary` matrix — no longer needed.
4. **Delete** any per-neighbourhood back-fill logic (`neighbourhood_cluster_lookup`, name-match fallback).
   The clusters file doesn't carry individual neighbourhood names.
5. **Do not read the geometry as WKT** — it's already a native GeoJSON geometry;
   `sf::read_sf()` / `st_read()` gives you an `sf` object directly.
6. If your data had a `neighbourhood_name` column populated elsewhere (e.g. from an API),
   leave it as-is — don't try to back-fill it from this file.

---

## 3. Minimal R recipe (sf + leaflet)

```r
library(sf); library(dplyr); library(leaflet)

clusters_sf <- sf::read_sf("WpgNeighbourhoodClusters.geojson", quiet = TRUE) |>
  sf::st_zm(drop = TRUE) |>
  sf::st_make_valid() |>
  dplyr::select(cluster)          # keep only the name; geometry rides along

# Tag points with their cluster (point-in-polygon, with fallback to nearest polygon)
prev_s2 <- sf::sf_use_s2(FALSE); on.exit(sf::sf_use_s2(prev_s2), add = TRUE)
pts <- sf::st_as_sf(df, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
suppressWarnings(sf::st_agr(clusters_sf) <- "constant")

joined <- sf::st_join(pts, clusters_sf, join = sf::st_within, left = TRUE)
missing <- which(is.na(joined$cluster))
if (length(missing)) {
  nearest <- sf::st_nearest_feature(pts[missing, ], clusters_sf)
  joined$cluster[missing] <- clusters_sf$cluster[nearest]
}

# Draw it
leaflet() |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(data = clusters_sf, label = ~cluster,
              color = "#c05621", weight = 2, fillOpacity = 0.05)
```

## 4. Minimal JS/Leaflet recipe

```js
fetch('WpgNeighbourhoodClusters.geojson')
  .then(r => r.json())
  .then(gj => L.geoJSON(gj, {
    style: { color: '#c05621', weight: 2, fillOpacity: 0.05 },
    onEachFeature: (f, layer) => layer.bindTooltip(f.properties.cluster)
  }).addTo(map));
```

(When serving from `file://`, embed the JSON in a `<script type="application/json">`
tag instead of fetching — browsers block `fetch()` on local files.
See `WpgNeighbourhoodsMap.html` for a working example.)

---

## 5. When to **not** use this file

Use `WpgNeighbourhoods.geojson` (235 polygons) instead when you need:

- to draw or label **individual neighbourhoods** (not clusters),
- a point-in-polygon lookup that returns the specific neighbourhood name,
- to build your own aggregation (e.g. into a non-WRHA grouping).

For that file the fields are `ID`, `Name`, `Cluster` (Pascal), `Location` (WKT), `lon`, `lat`.

---

## 6. Files already migrated in this repo

- `LandV2.3.qmd` — uses `wpg_neighbourhoods_clustered` derived from this file
- `WpgMultiResPermits.qmd` — spatial-joins permits against `clusters_sf`
- `WpgNonResPermits.qmd` — same pattern as MultiRes
- `WpgNeighbourhoodsMap.html` — standalone toggleable viewer (embedded GeoJSON)

When porting other projects, grep for these signals that the old file is still in use:

```
WpgNeighbourhoods.geojson
hoods_file
neighbourhoods_sf
neighbourhood_cluster_lookup
wilkes_ave_boundary
clip_assiniboine_south_to_wilkes
drop_polygon_holes
"Cluster" %in% names(
group_by(Cluster)
```

Any of these means the code still has the old machinery and is a candidate for the
simplification above.
