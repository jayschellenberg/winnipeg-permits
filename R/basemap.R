# "Light" basemap for the permit report maps.
#
# Why this file exists: until 2026-11 every map here called
# `addProviderTiles(providers$CartoDB.Positron)`. CARTO now serves an
# "API KEY REQUIRED" watermark in place of every unkeyed raster tile and has
# announced the raster service's retirement.
#
# The fix is the one the Winnipeg Parcel Search app (WpgOpenData/ParcelSearch,
# REPLICATION_GUIDE.md section 8.8) and the Rental Dashboard
# (RentalDashboard/dashboard/R/basemap.R) already use: render OpenStreetMap
# vector tiles in the browser from one self-hosted PMTiles archive. No API key,
# no vendor tile quota.
#
# The archive is NOT ours to maintain. `basemap-manitoba.pmtiles` on the
# mb-ortho R2 bucket is a Manitoba cut of the Protomaps daily OSM build,
# rebuilt semiannually and watchdogged by mb-parcelsearch (MAINTENANCE.md
# section 7b, `rebuild-basemap.ps1`). Do not fork the file.
#
# Coupling: the archive is tileset schema v4 and vendor/protomaps-leaflet.js
# (5.1.0) targets v4. If mb-parcelsearch ever bumps to v5, re-vendor here in
# the same window (see vendor/README.md).

BASEMAP_PMTILES_URL <- Sys.getenv(
  "PERMITS_BASEMAP_PMTILES_URL",
  unset = "https://pub-091058079bf6458da1681945177e1682.r2.dev/basemap-manitoba.pmtiles"
)

# Archive is cut to z15; the renderer overzooms past that instead of going blank.
BASEMAP_MAX_DATA_ZOOM <- 15

# A canvas GridLayer declares no maxZoom, so state one for the map itself.
BASEMAP_MAX_ZOOM <- 19

BASEMAP_ATTRIBUTION <- paste0(
  "<a href=\"https://protomaps.com\">Protomaps</a> &copy; ",
  "<a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a> contributors"
)

# Raster fallback if the archive is unreachable.
BASEMAP_FALLBACK_URL <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
BASEMAP_FALLBACK_ATTRIBUTION <-
  "&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a> contributors"

# Reports render from the project root (quarto's cwd is the .qmd's folder).
basemap_dep <- function() {
  vendor <- normalizePath("vendor", winslash = "/", mustWork = FALSE)
  if (!file.exists(file.path(vendor, "protomaps-leaflet.js"))) {
    stop("vendor/protomaps-leaflet.js not found - see R/basemap.R and vendor/README.md")
  }
  htmltools::htmlDependency(
    name = "protomaps-leaflet",
    version = "5.1.0",
    src = c(file = vendor),
    script = "protomaps-leaflet.js",
    all_files = FALSE
  )
}

#' Add the Protomaps basemap to a leaflet widget.
#'
#' Replacement for `addProviderTiles(providers$CartoDB.Positron, group = ...)`.
#' The layer is placed inside leaflet's layer group `group`, so a
#' `addLayersControl(baseGroups = c(group, ...))` switcher toggles it exactly
#' as it toggled the CARTO tiles. Pipe it in where the CARTO call was.
add_basemap <- function(map, group = "Light") {
  map$dependencies <- c(map$dependencies, list(basemap_dep()))
  if (is.null(map$x$options$maxZoom)) {
    map$x$options$maxZoom <- BASEMAP_MAX_ZOOM
  }

  htmlwidgets::onRender(map, sprintf(
    "
function(el, x) {
  var map = this;
  var url = %s;
  var groupName = %s;

  // R leaflet defers building a map that sits in a hidden tab/panel
  // (width 0) until it is shown, but onRender hooks fire immediately. Wait
  // until its layerManager exists, by which point the layer control and its
  // base groups are built too.
  (function attach() {
    if (!map.layerManager) { setTimeout(attach, 250); return; }
    addBasemap(map.layerManager.getLayerGroup(groupName, true));
  })();

  function addBasemap(group) {
  var layer = protomapsL.leafletLayer({
    url: url,
    flavor: 'light',
    lang: 'en',
    maxDataZoom: %d,
    attribution: %s
  });
  group.addLayer(layer);

  // protomaps-leaflet reports tiles as rendered even when the archive fetch
  // failed, so a dead archive would be a silent blank map. Probe the header
  // and fall back to raster OSM tiles in the same group.
  fetch(url, { headers: { Range: 'bytes=0-15' } })
    .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); })
    .catch(function (err) {
      group.removeLayer(layer);
      group.addLayer(L.tileLayer(%s, { attribution: %s, maxZoom: %d }));
      if (window.console) console.warn('basemap archive unreachable, using raster OSM:', err);
    });
  }
}",
    jsonlite::toJSON(BASEMAP_PMTILES_URL, auto_unbox = TRUE),
    jsonlite::toJSON(group, auto_unbox = TRUE),
    BASEMAP_MAX_DATA_ZOOM,
    jsonlite::toJSON(BASEMAP_ATTRIBUTION, auto_unbox = TRUE),
    jsonlite::toJSON(BASEMAP_FALLBACK_URL, auto_unbox = TRUE),
    jsonlite::toJSON(BASEMAP_FALLBACK_ATTRIBUTION, auto_unbox = TRUE),
    BASEMAP_MAX_ZOOM
  ))
}
