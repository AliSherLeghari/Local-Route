# Architecture

## Phase 1

`main.dart` starts `LocalRouteApp`. `app.dart` composes dependencies explicitly:

Presentation → RoutingCubit → RoutingRepository → RoutingService → future provider

- **Presentation:** `MapScreen` renders tiles, instructions, controls, and attribution.
  Its map controller and camera gestures are presentation details. flutter_map
  owns tile fetching/caching; there is no handwritten HTTP or routing logic here.
- **Cubit/state:** `RoutingCubit` records only whether the map controller is ready.
  This enables zoom buttons. It does not report tile download success. Cubit is
  small and explicit, without event-based Bloc boilerplate or Riverpod.
- **Repository:** a concrete, wired boundary for routing operations. Retain it
  even while small so application workflow does not depend on provider details.
- **Service:** a concrete boundary reserved for provider/API work. No provider or
  routing methods exist yet. Repository/service constructors are intentionally the
  only scaffolding: do not invent fake route results to exercise these layers.

The repository is injected into Cubit but not called in Phase 1 because no routing
operations are in scope. Add actual methods to both boundaries in Phase 2.
No domain models, core helpers, or extra widget folders are needed yet.
BlocProvider creates and closes Cubit; MapScreen owns/disposes its MapController.

## Rules to preserve

1. UI captures input, calls Cubit, and displays state. Keep API requests, route
   comparison algorithms, persistence, and routing business logic out of widgets.
2. Cubit coordinates routing through the repository; the repository uses the
   service. Keep map-package types in presentation where practical; introduce
   small geographic/route models when routing needs them.
3. Service translates provider responses/errors. It can later call our backend;
   preserve the repository's application-facing operations so the UI/Cubit need
   minimal changes. No backend is required now.
4. A Figma redesign should replace presentation without rewriting routing logic.
5. Use concrete classes and constructor injection. No DI framework, use-case
   layer, speculative interfaces, or duplicate DTO/entity models.
6. Keep OSM attribution visible and respect tile caching/usage requirements.

Map images are not road-network route data. The routing provider remains a
separate decision for Phase 2; no engine, travel profile, or ETA assumptions have
been chosen yet.
