# MVP scope

## Implemented

- Karachi OSM interactive map with pan/zoom and linked attribution.
- Long-press origin/destination selection, endpoint editing and reset.
- Explicit conventional car route through Cubit → Repository → Service → GraphHopper.
- Returned road polyline, distance and estimated duration; route camera fit.
- Loading, safe error/retry, duplicate and stale-response protection.
- Provider-neutral models, deterministic tests and local configuration instructions.

Live provider/account setup and Karachi acceptance remain unverified; see
[Project status](PROJECT_STATUS.md) and [manual cases](MANUAL_ROUTING_TESTS.md).

## Remaining in V1

After conventional routing passes manual acceptance: alternative/local road route
through intermediate waypoints, route comparison and a public-location trial.
Waypoints alone never establish that a route is accessible or better. Never
present straight-line connections as road routes.

## Excluded

Backend/FastAPI, database/PostgreSQL/PostGIS, auth/accounts, community/voting,
cloud infrastructure, Docker, microservices, Redis, Kubernetes, analytics, GPS,
background location/history, geocoding and turn-by-turn navigation.
