# Engineering operating contract

## Authority and required reading

Repository code, configuration, tests, and documentation are authoritative.
Previous AI conversations are not project state. Inspect actual code before
claiming functionality exists; never treat a roadmap item as implemented.

Before meaningful work, read [README](README.md), this file,
[Architecture](docs/ARCHITECTURE.md), [Security](docs/SECURITY.md),
[MVP scope](docs/MVP_SCOPE.md), [Future roadmap](docs/FUTURE_ROADMAP.md),
[Project status](docs/PROJECT_STATUS.md), and [Decisions](docs/DECISIONS.md).
Resolve documentation/code discrepancies explicitly rather than silently assuming.

## Architecture and scope

Preserve the intended routing direction: UI → Cubit → Repository → Service.
Currently this is routing scaffolding: no real routing request traverses all
layers. Map tiles are handled separately by flutter_map.

- Keep routing algorithms and provider-response parsing out of widgets.
- Keep provider-specific transport, parsing, and errors behind the service boundary.
- Avoid leaking flutter_map or provider transport types into higher layers;
  introduce small application models when actual functionality needs them.
- Do not silently replace Cubit/state management.
- Prefer concrete classes and constructor injection. Avoid unnecessary DI
  frameworks, use-case layers, microservices, speculative abstractions, and
  duplicate models. Important business/routing logic requires tests.
- Keep work within the authorized milestone; consult MVP scope before adding features.

## Security rules

- Never commit secrets or put private/server-only credentials in Flutter.
  An .env bundled in a distributed client is not secure secret storage.
- Never disable TLS/certificate validation to make a request work.
- Permissions need a real feature requirement; apply least privilege.
- Avoid precise-coordinate logging. Treat user geographic data and provider
  responses as untrusted; validate at trust boundaries.
- Follow [Security](docs/SECURITY.md) for data-flow and production requirements.

## Change control and verification

- Inspect Git status before and after meaningful tasks. Preserve unrelated work;
  do not silently modify unrelated files. Keep changes narrowly scoped.
- Do not commit, push, or merge without authorization. Inspect the final diff,
  including new files, and report every important changed file.
- Normally run `flutter analyze` and `flutter test` for Flutter implementation
  changes. Respect task restrictions on generated files and command execution;
  report checks that could not run. Never claim an unexecuted check passed.
- Report manual/device verification separately from automated checks.

## Continuity

After meaningful implementation work, update PROJECT_STATUS.md. Update
ARCHITECTURE.md when architecture changes; SECURITY.md when security, privacy,
networking, data handling, or permissions change; and DECISIONS.md for meaningful
long-term decisions. Keep facts, recommendations, and pending decisions distinct.
If task scope excludes a needed documentation update, report the gap rather than
silently expanding scope. Link between documents instead of duplicating them.
