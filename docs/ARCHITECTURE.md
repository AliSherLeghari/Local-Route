# Architecture

## Conventional routing MVP

`main.dart` starts `LocalRouteApp`. The app composes a single HTTP client,
RoutingService, RoutingRepository and RoutingCubit with constructors:

UI → RoutingCubit → RoutingRepository → RoutingService → GraphHopper

`LocalRouteApp` reads `GRAPHHOPPER_API_KEY` with a const `String.fromEnvironment`
and injects it into RoutingService. Flutter's `--dart-define-from-file` supplies
the compile-time value; there is no runtime JSON or .env loader. The recommended
development file lives outside the repository; see [setup](../README.md) and
[credential limitations](SECURITY.md). The existing ignored repository-local file
remains compatible. Automated tests exercise the route path with fakes; live
provider/device acceptance details are recorded in [Project status](PROJECT_STATUS.md).

- **UI:** MapScreen owns/disposes MapController, keeps OSM raster tiles, pan/zoom,
  and linked credits. Long-press selects the active endpoint or waypoint. A
  collapsible waypoint panel delegates add/edit/reorder/remove to Cubit. Get Route
  or Compare routes explicitly submits; independent summaries/errors and raw
  comparison differences are formatted for display. Blue/wide and orange/narrow
  polylines use only provider geometry. Camera fitting runs after layout when
  submitted branches settle, using both current geometries; edits/selection do
  not refit. Controls scroll vertically; credits stay in a horizontal footer.
- **Cubit:** owns endpoint/waypoint selection, readiness, and separate conventional
  and preferred results, loading flags, safe failures, and generation counters.
  Endpoint changes/reset invalidate both branches; waypoint edits invalidate only
  the preferred branch, retaining a current conventional result or request.
  Only explicit submission starts missing requests; successful and in-flight
  branches are not requested again. Each branch publishes independently so partial
  success survives the other's failure. Stale completions and completions after
  closure are ignored. Retry is user initiated and targets missing results only.
- **Repository:** forwards a provider-neutral route operation and typed failures.
  It does not parse JSON or expose HTTP.
- **Service:** fixed HTTPS GraphHopper host, car request with two endpoints and
  zero to three ordered intermediate waypoints in one request, bounded
  response, timeout/abort, response validation and safe failure translation.
  GET input order is latitude,longitude; returned GeoJSON is longitude,latitude.
  Provider duration is milliseconds and becomes Dart Duration here.
- **Models:** RoutePoint validates finite bounds; RouteResult copies geometry into
  an immutable list, stores meters and Duration. RoutingFailure contains only
  fixed safe messages. No Flutter map or HTTP types escape into these models.

Stage 1 (2026-10-09) exposes an optional `waypoints` list through repository and
service. The shared `maxIntermediateWaypoints` constant is three. The service
rejects excess waypoints before HTTP and snapshots their supplied order; it does
not optimize, sort, or remove repeated points. Existing two-argument calls retain
conventional routing.

Stage 2 (2026-10-09) adds immutable ordered waypoint state and Cubit operations:
`beginAddWaypoint`, `addWaypoint`, `selectWaypoint`, `replaceWaypoint`,
`removeWaypoint`, and `reorderWaypoint`. Reorder indices mean final positions.
Invalid indices return false without changing state; over-limit additions expose
a fixed safe input failure. Rejected coordinates leave valid selections intact.
Waypoint changes clear waypoint-edit selection. Endpoint selection cancels it.
`selectPosition` applies the active target. Edits never initiate network traffic.

`requestRoute` calculates A-to-B and, when waypoints exist, the ordered preferred
route. State differences are preferred minus conventional raw meters/Duration,
or null until both results exist. Compatibility getters `route`, `failure`, and
`isLoading` remain available. Completed unchanged submissions are no-ops;
`canRequest` indicates whether any missing branch can start. Stage 3 now exposes
the comparison lifecycle in MapScreen without changing the lower layers.

App state owns and closes the HTTP client it creates. Tests may inject a repository
(the caller then owns its dependencies). BlocProvider owns the Cubit. The service
aborts its transport on timeout/completion; endpoint changes use stale-result
protection, not transport cancellation. There are no automatic network retries.

Tile requests/caching remain separately owned by flutter_map. No route cache,
GPS, geocoder, database, account, backend, or navigation engine is added. Map
readiness means controller attachment, not that network tiles loaded.

## Boundaries to preserve

Keep business logic and provider parsing out of widgets. Preserve the repository
operation when replacing the provider or introducing a justified backend. Use
small concrete classes, not duplicate domain/DTO hierarchies or DI frameworks.
Automatic provider alternatives and local-route intelligence remain future work.

See [provider decision](DECISIONS.md), [security](SECURITY.md), and
[manual validation](MANUAL_ROUTING_TESTS.md).
