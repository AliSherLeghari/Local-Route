# MVP scope

## Implemented

- Karachi OSM interactive map with pan/zoom and linked attribution.
- Long-press origin/destination selection, endpoint editing and reset.
- Explicit conventional car route through Cubit → Repository → Service → GraphHopper.
- Returned road polyline, distance and estimated duration; route camera fit.
- Loading, safe error/retry, duplicate and stale-response protection.
- Provider-neutral models, deterministic tests and local configuration instructions.
- Up to three ordered route-shaping waypoints, explicit route comparison,
  independent outcomes, and conventional-route reuse after waypoint edits.

The owner reports both route types working on the emulator; detailed Karachi
acceptance and account limits remain to be recorded/verified; see
[Project status](PROJECT_STATUS.md) and [manual cases](MANUAL_ROUTING_TESTS.md).

## Remaining in V1

Complete the detailed waypoint/device acceptance checklist and a public-location trial.
Waypoints alone never establish that a route is accessible or better. Never
present straight-line connections as road routes.

## Excluded

Backend/FastAPI, database/PostgreSQL/PostGIS, auth/accounts, community/voting,
cloud infrastructure, Docker, microservices, Redis, Kubernetes, analytics, GPS,
background location/history, geocoding and turn-by-turn navigation.
