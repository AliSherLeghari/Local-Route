# MVP scope

## Implemented in Phase 1

- OpenStreetMap-based interactive map, pan and zoom.
- Minimal UI with permanent linked attribution and zoom buttons.
- flutter_bloc/Cubit readiness state and explicit repository/service boundaries.
- Documentation and deterministic tests.

## Remaining in V1 (later phases)

- Pickup and destination selection.
- Standard road route.
- Alternative/local road route through one or more intermediate waypoints.
- Route comparison including distance and estimated duration.
- A real pickup/destination trial using a locally known route.

Routes must follow the actual road network, never be presented as straight-line
connections. Waypoints express preferred intermediate places; they do not by
themselves prove a road is accessible or the route is better.

## Excluded from V1

Backend/FastAPI, database/PostgreSQL/PostGIS, authentication/accounts, community
features, voting/reports, cloud infrastructure, Docker, microservices, Redis,
Kubernetes, analytics, and enterprise architecture.

Phase 1 deliberately includes none of the pickup, destination, route API,
polyline, waypoint, or comparison functionality above.
