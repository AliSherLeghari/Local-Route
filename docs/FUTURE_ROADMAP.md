# Future roadmap

## Next: validate conventional routing

Configure the owner-supplied GraphHopper development key locally and execute the
six public Karachi acceptance cases. Validate snapping, road geometry and duration
plausibility on a device. Fix observed baseline issues before expanding features.
Provider/account entitlement and live route quality remain unverified.

## Remaining V1

After acceptance, add local waypoint routes and comparison through the existing
service/repository/Cubit boundaries. Use the same travel profile and make estimated
duration limitations clear. Presentation redesign should remain independent.

## Possible V2 (not current requirements)

Consider backend, accounts, community persistence, PostgreSQL/PostGIS, submissions,
validation/votes, confidence measures and infrastructure only if actual needs
justify them. A secret provider credential or shared paid-key abuse risk requires
an explicit architecture decision before distribution. No such infrastructure is
implemented. OSRM remains a possible engine behind a provisioned host; do not
substitute a public demo endpoint for production infrastructure.
