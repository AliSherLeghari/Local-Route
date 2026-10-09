# Engineering decisions

## D8. Ordered waypoint comparison lifecycle (2026-10-09)

- **Status:** Accepted; implemented through Stage 3 UI. Device acceptance scope
  is tracked in [Project status](PROJECT_STATUS.md).
- **Decision:** Up to three ordered route-shaping waypoints; no waiting time or
  fare behavior. Only explicit submission requests routes. Keep separate outcomes
  and generations, retain the current conventional route across waypoint edits,
  and retry only failed/missing branches. See [Architecture](ARCHITECTURE.md).
- **Consequences:** No automatic recalculation or persistent cache. Reusing the
  current baseline does not refresh provider data; reset or endpoint editing
  invalidates it. Waypoints cannot establish road accessibility or a better route.

Recorded 2026-10-01 from current repository code/docs, not reconstructed chat
history. Accepted entries describe existing direction; pending entries do not
authorize implementation. Update status and consequences when decisions change.

## D1. Separate presentation from routing responsibilities

- **Status:** Accepted; documented in [Architecture](ARCHITECTURE.md).
- **Context:** Map interaction and conventional GraphHopper routing are implemented.
- **Decision:** Widgets capture input/render state. Keep routing algorithms,
  provider-response parsing, and persistence out of widgets.
- **Reason:** Presentation redesigns should not require rewriting routing logic.
- **Consequences / revisit:** MapController stays in presentation; future routing
  operations must follow the application boundaries rather than grow in MapScreen.

## D2. Use flutter_bloc Cubit

- **Status:** Accepted; implemented in [app.dart](../lib/app.dart) and RoutingCubit.
- **Context:** State now includes controller readiness, endpoints and route lifecycle.
- **Decision:** Use Cubit and explicit states, with BlocProvider managing lifetime.
- **Reason:** [Architecture](ARCHITECTURE.md) calls for small, explicit state
  management without event-based Bloc boilerplate or Riverpod.
- **Consequences / revisit:** Extend tested state transitions for real routing;
  state-management replacement needs an explicit decision.

## D3. Retain repository and service routing boundaries

- **Status:** Accepted and exercised by the conventional-routing implementation.
- **Context:** GraphHopper calls traverse the Cubit, repository and service.
- **Decision:** Preserve UI → Cubit → Repository → Service. Service translates
  provider responses/errors; repository exposes application-facing operations.
- **Reason:** [Architecture](ARCHITECTURE.md) allows a future provider/backend
  change without making UI/Cubit depend on transport details.
- **Consequences / revisit:** Keep the route operation provider-neutral and keep
  map/transport types out of higher layers.

## D4. Keep MVP architecture simple

- **Status:** Accepted; [Architecture](ARCHITECTURE.md) and [MVP scope](MVP_SCOPE.md).
- **Context:** Map foundation and conventional-routing flow are implemented.
- **Decision:** Concrete classes and constructor injection; no unnecessary DI
  framework, use-case layer, speculative interfaces, duplicate models, or microservices.
- **Reason:** Small models and concrete boundaries are sufficient for this phase.
- **Consequences / revisit:** Keep the existing small geographic/route models;
  add abstractions only for demonstrated needs.

## D5. Defer backend, database, and authentication

- **Status:** Accepted V1 scope exclusion; see [MVP scope](MVP_SCOPE.md).
- **Context:** No accounts, shared routes, or private provider credentials exist.
- **Decision:** Do not introduce backend/database/auth infrastructure without a
  justified requirement and explicit scope revision.
- **Reason:** [Future roadmap](FUTURE_ROADMAP.md) makes these possible V2 work,
  conditional on the MVP proving useful.
- **Consequences / revisit:** Revisit for private credentials, protected routing
  intelligence/data, shared persistent submissions, accounts, or partner APIs.
  A provider requiring server-only credentials can trigger earlier reconsideration;
  never embed them merely to preserve client-only scope. See [Security](SECURITY.md).

## D6. Separate map rendering from road routing

- **Status:** Accepted; [README](../README.md) and [Architecture](ARCHITECTURE.md).
- **Context:** OSM raster tiles render streets but are not routing results.
- **Decision:** Keep flutter_map/OSM standard tiles for V1 map rendering. Choose
  the road-routing provider independently. Preserve linked attribution and caching.
- **Reason:** Map imagery and road-network calculations are separate services;
  the current map needs no routing provider or key.
- **Consequences / revisit:** No application label-language control or guaranteed
  offline map. Revisit tile hosting/style for capacity, terms, or language needs.

## D7. Conventional routing provider

- **Status:** Accepted 2026-10-01 for controlled personal, non-commercial MVP use;
  implementation tested with fakes; live account and Karachi quality unverified.
- **Decision:** GraphHopper managed Directions API, OSM `car` profile, direct HTTPS
  client. Preserve flutter_map/OSM presentation. No backend or vendor SDK.
- **Credential classification:** 2, client credential for owner-supplied personal
  development use. The provider's official OSMAnd Android/iOS guide documents this
  usage. This is not a claim of secret storage or approval to widely distribute a
  shared paid key. Compile-time config is ignored locally but extractable in builds.
- **Reason:** Existing map compatibility, explicit client/mobile support, temporary
  result handling and replaceable service boundary. See the focused
  [provider comparison and official evidence](ROUTING_PROVIDER.md).
- **Limitations:** Free allowance and account quotas apply; no live traffic or
  guarantee of route legality/quality. Keep OSM and GraphHopper attribution visible.
  Only in-memory route results; no bulk collection. Use Free only non-commercially.
- **Alternatives:** Mapbox excluded for the previously identified terms blocker.
  HERE not selected due to coverage/plan uncertainty. OSRM is a possible future
  engine with an explicitly provisioned host, not an implicit public-demo dependency.
- **Revisit triggers:** Public distribution, paid/shared credentials, commercial
  use, quota abuse, terms changes, poor Karachi results or required server secrets.
  A private credential would require reconsidering D5, not embedding it in Flutter.
