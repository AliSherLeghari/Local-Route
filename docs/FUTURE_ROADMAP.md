# Future roadmap

## Next: complete route-comparison acceptance

The owner reports tiles and both conventional/waypoint routes working on the
emulator after resolving DNS. Complete the six public Karachi cases and the
waypoint checks in [Manual tests](MANUAL_ROUTING_TESTS.md). Validate snapping,
road geometry and duration plausibility; account entitlement remains unverified.

## Remaining V1

Ordered waypoint routes and comparison are implemented through all existing
layers. Remaining work is detailed device acceptance and a public-location trial.
Presentation redesign should remain independent.

## Possible V2 (not current requirements)

Consider backend, accounts, community persistence, PostgreSQL/PostGIS, submissions,
validation/votes, confidence measures and infrastructure only if actual needs
justify them. A secret provider credential or shared paid-key abuse risk requires
an explicit architecture decision before distribution. No such infrastructure is
implemented. OSRM remains a possible engine behind a provisioned host; do not
substitute a public demo endpoint for production infrastructure.
