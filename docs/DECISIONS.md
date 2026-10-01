# Engineering decisions

Recorded 2026-10-01 from current repository code/docs, not reconstructed chat
history. Accepted entries describe existing direction; pending entries do not
authorize implementation. Update status and consequences when decisions change.

## D1. Separate presentation from routing responsibilities

- **Status:** Accepted; documented in [Architecture](ARCHITECTURE.md).
- **Context:** Map interaction is implemented; routing business logic is not.
- **Decision:** Widgets capture input/render state. Keep routing algorithms,
  provider-response parsing, and persistence out of widgets.
- **Reason:** Presentation redesigns should not require rewriting routing logic.
- **Consequences / revisit:** MapController stays in presentation; future routing
  operations must follow the application boundaries rather than grow in MapScreen.

## D2. Use flutter_bloc Cubit

- **Status:** Accepted; implemented in [app.dart](../lib/app.dart) and RoutingCubit.
- **Context:** Current state is a single controller-readiness flag.
- **Decision:** Use Cubit and explicit states, with BlocProvider managing lifetime.
- **Reason:** [Architecture](ARCHITECTURE.md) calls for small, explicit state
  management without event-based Bloc boilerplate or Riverpod.
- **Consequences / revisit:** Extend tested state transitions for real routing;
  state-management replacement needs an explicit decision.

## D3. Retain repository and service routing boundaries

- **Status:** Accepted scaffolding; no routing workflow exists yet.
- **Context:** The provider is undecided; both classes currently have constructors
  only, with references wired through the Cubit.
- **Decision:** Preserve UI → Cubit → Repository → Service. Service will translate
  provider responses/errors; repository exposes application-facing operations.
- **Reason:** [Architecture](ARCHITECTURE.md) allows a future provider/backend
  change without making UI/Cubit depend on transport details.
- **Consequences / revisit:** Add actual methods with routing, not fake results
  merely to exercise scaffolding. Keep map/transport types out of higher layers
  where practical.

## D4. Keep MVP architecture simple

- **Status:** Accepted; [Architecture](ARCHITECTURE.md) and [MVP scope](MVP_SCOPE.md).
- **Context:** Only the map foundation is implemented.
- **Decision:** Concrete classes and constructor injection; no unnecessary DI
  framework, use-case layer, speculative interfaces, duplicate models, or microservices.
- **Reason:** The documented phase needs no additional domain/core/widget structure.
- **Consequences / revisit:** Introduce small geographic/route models when real
  routing requires them; add abstractions only for demonstrated needs.

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

- **Status:** OPEN / PENDING; no provider selected or integrated.
- **Context:** The next milestone needs a real road route; service is still empty.
- **Decision:** Pending evaluation; this document selects no provider.
- **Reason:** Coverage, capabilities, credentials, and operational constraints
  must fit the actual MVP before implementation.
- **Evaluation criteria:** Karachi/Pakistan road coverage and route quality;
  travel profiles; waypoint support; alternative-route support; credential model
  and whether credentials may safely be distributed in a client; usage limits
  and quotas; terms/licensing; ETA/duration semantics; cost; reliability.
- **Consequences / revisit:** Record evidence, chosen profile, limitations, and
  client/server boundary when resolved. Do not imply traffic-aware ETA or safe
  road access without evidence. Private credentials require revisiting D5.
