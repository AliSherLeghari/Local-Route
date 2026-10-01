# Security and privacy

## A. Verified current posture

Source/configuration review: 2026-10-01, application baseline
`d322db58307d7087406e1a5878efd9e006c54578`. Recheck these facts as code changes.

- No obvious embedded credentials, passwords, tokens, or private keys were
  identified in the inspected source/configuration. No tracked keystores were
  identified. Android ignore rules exclude key.properties and keystores;
  ignore rules are not a substitute for reviewing changes for secrets.
- Android release builds currently use debug signing in
  [app/build.gradle.kts](../android/app/build.gradle.kts). This development setup
  must be replaced before production distribution.
- [MapScreen](../lib/routing/presentation/screens/map_screen.dart) uses HTTPS
  for OSM tiles and the fixed attribution link. No TLS/certificate bypass was
  found. XML namespace/doctype HTTP strings are not application network calls.
- Android source manifests declare INTERNET, with no location or other sensitive
  feature permissions. The iOS Info.plist has no location usage description or
  broad transport-security exception. There is no GPS functionality; Karachi is
  a fixed map starting position.
- No authentication, application database, or backend integration exists.
  No precise-location application logging was found.
- flutter_map handles tile downloads and default tile caching. Native tile
  caching/browser caching means this is not an application with no local storage
  whatsoever. No application route-history or credential storage is implemented.
- Tile requests are an external data flow: the tile host receives requested map
  areas and connection metadata. Requested areas are not proof of GPS location.
  Opening attribution also contacts an external website.

Review limitations: this was a source/configuration inspection, not a penetration
test, exhaustive Git-history secret scan, compiled-artifact/merged-permission
audit, device privacy test, or dependency advisory assessment. No obvious finding
does not establish absence of vulnerabilities. In particular, this review does
not establish that dependencies are vulnerability-free. See
[Project status](PROJECT_STATUS.md) for automated checks and runtime limitations.

## B. Future / production requirements

The following are requirements for future features or distribution, not claims
that these controls are currently implemented:

- **Credentials and trust boundary:** private provider credentials belong behind
  a server boundary, never in Flutter assets, source, or a bundled .env. Only use
  direct client integration when the credential model and terms permit it.
  Treat client requests as untrusted; a proxy alone does not prevent abuse.
- **Geographic input and responses:** validate finite coordinate values, ranges,
  coordinate order, supported profiles, waypoint counts, geometry, units, and
  response structure. Bound request/response sizes and execution time; handle
  malformed data, no-route results, and failures without unsafe assumptions.
- **Privacy and logging:** minimize coordinate collection and disclosure. Redact
  coordinates, credentials, and identifiers from routine logs. If location or
  route history is persisted, define purpose, access, retention, and deletion.
  Add location permissions only for an implemented feature and with least privilege.
- **Transport:** retain HTTPS and certificate validation across new integrations.
- **Shared services:** if accounts are introduced, enforce authentication and
  server-side authorization. Add rate limits, quotas, budget controls, and abuse
  protection when backend APIs are justified.
- **Protected intelligence and partners:** keep proprietary routing logic/data
  server-side when confidentiality is required. Partner APIs need appropriate
  credential isolation, access controls, contractual review, and data minimization.
- **Release and supply chain:** use controlled production signing and protect
  signing keys. Review dependency advisories, sources, lockfile changes, platform
  permissions, and release artifacts. Review tile/routing terms, licensing,
  attribution, capacity, and privacy before wider use.

Backend adoption is conditional on real requirements; see
[Decisions](DECISIONS.md) and [MVP scope](MVP_SCOPE.md).
