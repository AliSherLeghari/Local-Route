# Local Route

A Flutter learning/MVP project for comparing conventional road routes with routes
known by local residents. **Phase 1 implements the map foundation only.**

## Run

Use the existing Flutter SDK (Dart ^3.10.4) and an Android emulator with internet:

```sh
flutter pub get
flutter run
```

The map opens over Karachi at zoom 12. Drag to pan, pinch or double-tap to zoom,
or use the + / - buttons (zoom range 3–19). This is a fixed starting view, not
GPS tracking. No account, API key, location permission, or paid service is needed.

## Packages and map source

- `flutter_bloc` ^9.1.1: Cubit state and its widget integration.
- `flutter_map` ^8.3.2: maintained, Flutter-based interactive raster map.
- `latlong2` ^0.10.1: coordinates consumed by the map.
- `url_launcher` ^6.3.2: opens the map attribution/licence page.

The map requests HTTPS tiles from `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
Visible, tappable © OpenStreetMap contributors attribution stays below the map.
The Android application ID `com.example.local_route` identifies native tile
requests; keep the tile user agent aligned if the application ID changes.
Android's main manifest declares INTERNET so release builds can also load tiles.
No other Android build settings were changed.

V1 keeps OpenStreetMap standard raster tiles. Labels may use local/native names
because they are rendered into the tile images; the app cannot change their
language. This is a presentation limitation only and does not affect routing
functionality (routing itself is planned for later phases). A future production
or UI-polish version may switch to a configurable map style/provider if English
or multilingual label control is required. V1 needs no additional provider,
account, API key, or language configuration.

flutter_map's default native cache honours HTTP cache headers; web uses browser
caching. This cache is disposable and does not promise offline mapping. Do not
add bulk downloads, offline prefetching, or disable caching for public OSM tiles.
The public service has limited capacity and no availability guarantee. Review
its policy before wider distribution and choose a suitable tile host as needed.
Tile hosting and road routing are separate services: this phase makes no road
routing requests and cannot calculate routes.

Sources checked for package selection:
- [flutter_map package](https://pub.dev/packages/flutter_map)
- [Built-in tile caching](https://docs.fleaflet.dev/layers/tile-layer/caching)
- [OSM tile usage policy](https://operations.osmfoundation.org/policies/tiles/)

## Verify

```sh
flutter pub get
flutter analyze
flutter test
```

Tests use in-memory tiles, never the public tile server. They check map/UI startup,
attribution, zoom buttons, dragging, and the Cubit's readiness transition. They
cannot prove real network tiles load on an emulator.

Manual Android checklist after `flutter run`:
- App launches without a crash; title is Local Route.
- Karachi map tiles load and streets/labels are visible.
- Dragging pans and loads the newly visible area.
- Pinch, double-tap, and + / - controls zoom correctly.
- Controls and attribution are readable, including after device rotation.
- Tapping attribution opens the OSM copyright page.
- With internet unavailable, the app remains usable but uncached areas may be blank.

## Continue development

Read [Architecture](docs/ARCHITECTURE.md), [MVP scope](docs/MVP_SCOPE.md), and
[Future roadmap](docs/FUTURE_ROADMAP.md) before implementing Phase 2.
