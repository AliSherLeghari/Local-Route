# Project status

Verified 2026-10-01 against application baseline
`d322db58307d7087406e1a5878efd9e006c54578`. This is a living handoff; verify source
again before making implementation claims.

## Current phase and implemented behavior

The map foundation exists. Conventional road routing is not implemented.

- main.dart starts LocalRouteApp, which composes dependencies explicitly.
- One MapScreen renders OSM raster tiles through flutter_map, centered initially
  on Karachi at zoom 12. Pan/zoom are enabled; rotation is disabled; zoom is 3–19.
- Zoom buttons become available when the controller is ready. This does not
  indicate successful tile downloads.
- Permanent attribution opens the OSM copyright page through url_launcher;
  browser-launch failure has a snackbar fallback.
- The screen disposes its MapController; BlocProvider manages Cubit lifetime.
- Tile fetching/caching belongs to flutter_map, not the routing service.

Evidence: [composition](../lib/app.dart),
[screen](../lib/routing/presentation/screens/map_screen.dart), and
[Cubit](../lib/routing/presentation/cubit/routing_cubit.dart).

## Current architecture

Composition/wiring: UI → Cubit → Repository → Service.

Actual current behavior:

- MapScreen → RoutingCubit for controller readiness.
- MapScreen → flutter_map for tiles and map interaction.
- MapScreen → url_launcher for attribution.

RoutingState contains only isMapReady. The repository stores the service; the
service has no routing methods. No routing request currently traverses
Cubit → Repository → Service. See [Architecture](ARCHITECTURE.md).

## Test status

Baseline checks executed on 2026-10-01:

| Command | Result |
| --- | --- |
| `flutter analyze` | Exit 0; "No issues found!" (4.7 seconds reported). |
| `flutter test` | Exit 0; 2 tests passed; "All tests passed!" |

- [routing_cubit_test.dart](../test/routing_cubit_test.dart): initial readiness
  false and a single emission despite repeated readiness callbacks.
- [widget_test.dart](../test/widget_test.dart): title, attribution text, initial
  zoom, zoom buttons, dragging, and no captured widget exception. Uses transparent
  in-memory tiles, not public tile downloads.
- iOS RunnerTests contains a placeholder test without assertions.

The test run printed flutter_map's OSM tile-policy reminder; it was not a failure.
No manual/device verification was performed for this baseline. Tests do not prove
real network tiles load or that attribution launches on a device. Zoom limits,
launch failures, offline behavior, rotation/large text, and pinch/double-tap
behavior are not covered by the existing assertions.

## Security-relevant state and limitations

No obvious embedded secrets or precise-coordinate application logging were found
in source/configuration review. Android declares INTERNET; no GPS, auth, backend,
or application database exists. Tile traffic and caching do exist. Android
release signing still uses debug keys. See [Security](SECURITY.md) for review
limits and future requirements; these checks are not a security certification.

Public tile availability is not guaranteed; controller readiness is not tile
readiness. Offline mapping is not promised. Labels are baked into raster tiles
and have no application language control. Example application identifiers remain.

## Not implemented

Origin/destination flow; road routing or routing-provider integration; route
geometry/results; distance/duration; local waypoint routes or comparison; GPS;
backend; authentication; application database; community functionality; partner API.
Map-tile integration must not be mistaken for routing-provider integration.

## Next recommended milestone (not implemented)

One conventional road route between two selected points: select endpoints,
request actual road geometry through the existing boundaries, and display distance
and estimated duration with loading, no-route, failure, and stale-request handling.
The routing provider remains pending in [Decisions](DECISIONS.md). Keep later
waypoint/comparison work separate; see [MVP scope](MVP_SCOPE.md) and
[Future roadmap](FUTURE_ROADMAP.md).
