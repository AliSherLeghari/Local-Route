# Future roadmap

## Next: Phase 2 within V1

Add pickup/destination input and small geographic/route models. Choose a road
routing provider after reviewing coverage, waypoint/alternative support, travel
profiles, terms, limits, and credential requirements. Implement calls in
RoutingService, expose operations through RoutingRepository, and let RoutingCubit
coordinate loading/results/errors. UI then renders actual road geometry,
waypoints, distance, estimated duration, and comparisons.

Validate on a real trip where the user knows a local route. Compare under the
same travel profile; explain engine limitations and that duration is an estimate.
Keep redesigns of presentation independent from these routing operations.

## Possible V2 — not current requirements

If the MVP proves useful, consider a backend API, users/authentication, persistent
community routes in PostgreSQL/PostGIS, route submissions and validation,
votes/reports, confidence measures, caching, and cloud deployment.

The service can move from a third-party routing API to our backend while the
repository continues exposing routing operations. Add infrastructure only when
real requirements justify it. None of these V2 features should be implemented
as part of the current MVP.
