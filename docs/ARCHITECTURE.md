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
provider/device acceptance remains pending.

- **UI:** MapScreen owns/disposes MapController, keeps OSM raster tiles, pan/zoom,
  and linked credits. Long-press selects the active endpoint; A/B controls choose
  which endpoint to edit. Get Route is explicit. Returned geometry alone is drawn
  as a polyline; success fits the camera and displays km/estimated minutes.
- **Cubit:** owns selection, endpoints, readiness, loading, result and safe error.
  Endpoint changes/reset invalidate route/error/loading and advance a generation
  counter. Only the current generation may publish success or failure. Duplicate
  submissions while loading are ignored. A changed endpoint allows a new request;
  obsolete requests may finish but cannot overwrite the current state. Closing
  the Cubit also invalidates outstanding results. Retry is user initiated.
- **Repository:** forwards a provider-neutral route operation and typed failures.
  It does not parse JSON or expose HTTP.
- **Service:** fixed HTTPS GraphHopper host, car request with two points, bounded
  response, timeout/abort, response validation and safe failure translation.
  GET input order is latitude,longitude; returned GeoJSON is longitude,latitude.
  Provider duration is milliseconds and becomes Dart Duration here.
- **Models:** RoutePoint validates finite bounds; RouteResult copies geometry into
  an immutable list, stores meters and Duration. RoutingFailure contains only
  fixed safe messages. No Flutter map or HTTP types escape into these models.

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
Provider alternatives and local-route intelligence remain future work.

See [provider decision](DECISIONS.md), [security](SECURITY.md), and
[manual validation](MANUAL_ROUTING_TESTS.md).
