# Security and privacy

## Implemented boundary (2026-10-01)

GraphHopper's OSM car routing is called directly from RoutingService. Its
owner-supplied API key is classified as a client credential for controlled personal
non-commercial builds, based on the provider's documented mobile integration.
See [decision and evidence](ROUTING_PROVIDER.md). No private/server-only key,
backend, account system, GPS or database is introduced.

Configuration is `GRAPHHOPPER_API_KEY` via compile-time Dart defines. Store the
development JSON outside the repository as recommended in [setup](../README.md);
keep `config/routing.example.json` as a placeholder template. The ignored
`config/routing.local.json` remains supported for backward compatibility. No runtime
credential file is bundled as an asset. This reduces routine source disclosure,
not extraction from compiled code. Build outputs and .dart_tool may contain the
value and remain ignored. Never upload them as public artifacts with your key.
Never use a bundled .env as secret storage. Do not paste credentials into chat,
logs, screenshots or issue reports. Do not force-add the ignored config.

The key authenticates billable/quota-bearing requests; exposure can consume the
account allowance. Use a dedicated development key, inspect/revoke it through the
provider dashboard if exposed, and confirm the current Free entitlement/quotas.
There is no claim of an enforceable client-side spending or abuse boundary. Public
or commercial distribution/shared paid keys require a fresh architecture review.

## Data flow and transport

- Get Route explicitly sends the two selected coordinates and key over HTTPS to
  fixed `graphhopper.com/api/1/route`. Redirects are disabled so a redirect cannot
  forward the key to another host. No TLS/certificate bypass exists.
- Stage 1 (2026-10-09): repository/service callers can additionally supply up to
  three ordered intermediate coordinates, sent in the same HTTPS request. Excess
  waypoints fail before HTTP. Stage 3 now exposes this through Compare routes.
  Waypoints remain in memory and add no logging, retention, or permissions.
- The service requests car geometry, no instructions/elevation. It validates JSON,
  schema, finite coordinate ranges, geometry type/count and non-negative metrics.
  Limits: 2 MiB response, 25,000 points, 100,000,000 meters, 365 days duration.
  These are defensive ceilings, not promised route capabilities.
- A 15-second overall timeout covers headers and body; transport is aborted on
  exit. No automatic retries. HTTP auth/configuration, quota, availability,
  malformed responses, known no-route errors and connection failures become safe
  fixed messages. Raw errors/bodies/URLs never reach UI. App code logs neither
  precise coordinates nor credentials nor provider responses.
- Endpoint changes/reset invalidate pending results. They do not undo coordinate
  disclosure or necessarily cancel earlier server computation.
- Stage 2: explicit Cubit submission may send two independent requests (A/B and
  A/ordered waypoints/B). Waypoint edits send nothing and invalidate only the
  preferred request's generation. Valid conventional results remain in memory
  for reuse until endpoint changes/reset; no persistent route history is added.
  Each branch sanitizes unexpected failures independently. Stage 3 UI explains
  selected-coordinate disclosure and that waypoints add no passenger stopping
  time. Controls delegate to Cubit; no new permissions or storage are added.
- Route points/results remain in memory; no history, analytics or persistence.
  The provider still receives connection metadata and may keep server logs under
  its own [privacy policy](https://www.graphhopper.com/privacy/). Do not confuse
  app retention with provider retention.
- OSM tile requests separately disclose viewed map areas and connection metadata.
  flutter_map/browser caching remains enabled. Credit links contact external sites.

## Platform and review limits

Android keeps its existing INTERNET permission only; iOS has no GPS usage
strings or broad transport-security exception. No permission changes were needed.
Android release still uses debug signing and example application identifiers;
replace those before production distribution. No production readiness is claimed.

Changed source/configuration was reviewed for credential values and unexpected
files. Tests use fake keys and local tiles. This is not a penetration test,
exhaustive Git-history scan, dependency advisory audit or compiled-artifact review.
The ignore rule is only a guardrail, not proof that secrets can never enter Git.
Before any commit, review all changes and confirm local config/build files remain
ignored. See [Project status](PROJECT_STATUS.md) for executed checks.

## Revisit before expansion

Private credentials belong behind a justified server boundary; never put them in
Flutter. Add permission, identity, database, budget controls or location retention
only with a real authorized feature. Recheck provider terms, public tile capacity,
credential limits, signing and data accuracy before wider distribution. Backend
adoption remains conditional; see [D5/D7](DECISIONS.md).
