# Local Route

A Flutter learning MVP with a Karachi map and comparison of a conventional driving
route with a route through up to three ordered waypoints. No GPS, search, account,
database or backend is included.

## Run and configure routing

Use the installed Flutter SDK (Dart ^3.10.4) and an Android emulator with internet.
The map works without a routing key; Get Route then shows a setup error.

1. Create your own development key in the
   [GraphHopper dashboard](https://graphhopper.com/dashboard/). Use a non-commercial
   Free account for this personal learning build; confirm current quotas there.
2. Use `config/routing.example.json` as the placeholder template. Keep your real
   development configuration outside the repository, for example at
   `$env:USERPROFILE\LocalRouteSecrets\graphhopper.json` on Windows. Create that
   directory and your private copy yourself, then replace the placeholder locally.
   Never paste your key into chat, source, screenshots, logs or documentation.
3. Run from the repository root in PowerShell:

```powershell
flutter pub get
flutter run --dart-define-from-file="$env:USERPROFILE\LocalRouteSecrets\graphhopper.json"
```

`$env:USERPROFILE` is PowerShell's user-profile environment variable; `$env` alone
does not identify that directory. The JSON property must remain
`GRAPHHOPPER_API_KEY`. Flutter supplies it at compile time; the file is not a
runtime asset. Keep the repository template free of real credentials.

For backward compatibility, `config/routing.local.json` remains ignored and the
existing `--dart-define-from-file=config/routing.local.json` command still works.
If using that location, confirm it with `git check-ignore config/routing.local.json`
before staging files. The outside-repository location is recommended.

Dart defines keep configuration out of committed source, **not secret in the
compiled app**. Use only your owner-supplied GraphHopper client key. Do not put a
private credential here, share key-bearing builds, or use an unrestricted paid
key for public distribution. Rebuild after changing configuration. See
[Security](docs/SECURITY.md) and [provider evidence](docs/ROUTING_PROVIDER.md).

## Use

- Map starts over Karachi at zoom 12. Drag/pinch/double-tap or use + / − (3–19).
- Long-press to set origin A, then long-press to set destination B.
- Choose A Origin or B Destination to edit that endpoint; long-press its new spot.
- Press Get Route. The app sends those two selected coordinates to GraphHopper.
- A successful result shows road geometry, distance and estimated duration; the
  camera fits the route. Duration is not a live-traffic prediction.
- Expand Waypoints, choose Add waypoint, then long-press the map. Repeat up to
  three times. Edit W1/W2/W3 selects a point for replacement by long-press; arrows
  change the order and the remove control deletes a point. Check the A → W1 → B
  sequence before pressing Compare routes. Edits never submit requests.
- Conventional is blue/wide; Via waypoints is orange/narrow. Each shows its own
  distance, estimated duration, and safe errors. Differences compare provider
  totals; waypoints are not guaranteed shortcuts and add no passenger stopping time.
- Waypoint edits retain the conventional route and require explicit recalculation.
  Retry requests only missing results. Completed unchanged routes are reused.
  The camera fits both current geometries when requests settle. Credits remain
  in the footer, which scrolls horizontally on narrow screens or with large text.
- Reset clears endpoints/results. Errors never create a substitute straight line.
  Retry is explicit; wait a minute after quota/rate-limit errors.
- Coordinates/results stay in application memory. Providers receive network
  requests; do not assume they have the same retention policy as the app.

## Map and packages

flutter_bloc handles state; flutter_map renders OSM raster tiles; latlong2 is used
only at the map boundary; url_launcher opens fixed credit links; package:http is
an explicit dependency for routing. No provider SDK is added.

Tiles: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. Native user agent identity
is `com.example.local_route`; align it when changing the application ID. Existing
Android INTERNET permission is sufficient. No GPS permission is requested.

Preserve [OSM attribution](https://www.openstreetmap.org/copyright) and linked
GraphHopper credit. Raster labels are baked into tiles and can use local/native
names. flutter_map's native cache honors HTTP headers; browsers handle web caching.
Do not bulk download or prefetch public tiles. Public tile availability is not
guaranteed; review the [tile policy](https://operations.osmfoundation.org/policies/tiles/)
before wider use. Tile hosting is separate from GraphHopper road routing.

## Verify

```sh
flutter analyze
flutter test
```

Automated tests use local tiles and fake HTTP/controlled futures, never live routing
or a real credential. They cover models, service validation/errors/limits, repository
propagation, Cubit transitions/stale results, and widget interaction. See
[Project status](docs/PROJECT_STATUS.md) for checks actually executed.

Follow the six public-landmark cases and record template in
[Manual routing tests](docs/MANUAL_ROUTING_TESTS.md). Live Karachi routing and device
behavior are not verified by unit/widget tests.

Also check on the emulator: real tile loading, pinch/double-tap, both credit links,
portrait/landscape and large text, route camera fit, offline errors, endpoint edits
while a request is loading, and reset. Do not use personal/private locations.

Read [Architecture](docs/ARCHITECTURE.md), [MVP scope](docs/MVP_SCOPE.md), and
[Future roadmap](docs/FUTURE_ROADMAP.md) before expanding functionality.
