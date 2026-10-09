# Project status

## Stage 3 map comparison UI (2026-10-09)

Latest milestone on `feature/local-route-comparison`; earlier sections describe
historical stage boundaries. All Stage 1/2 work remains uncommitted and preserved.

- MapScreen exposes a collapsible 0/3 waypoint panel, long-press add/edit, ordered
  move/remove controls, labeled markers and a visible sequence. No automatic
  submission on edits. Existing gesture flags remain unchanged.
- Conventional and Via waypoints have distinct polylines, independent metrics,
  loading/errors, raw-value difference formatting and explicit selective retry.
  Waypoint changes preserve the baseline and show recalculation guidance.
- Camera fits combined current geometry after requests settle; selection, edits,
  reorder, and stale completions do not trigger a refit. Controls wrap/scroll;
  linked credits remain in a horizontal footer. Marker semantics are distinct.
- Added 12 widget tests covering controls, limit/order/edit/removal, two results,
  partial failures/retry, reset/stale completion, camera behavior, differences,
  narrow/landscape layouts and 2x text.
- Final verification: Dart format exited 0 on the two Stage 3 Dart files;
  `flutter analyze` exited 0 with no issues (7.5 seconds); `flutter test` exited 0
  with all 130 tests passed, including the prior 118; `git diff --check` passed.
  Tests used controlled futures and local tiles, never live GraphHopper requests.
  Tests caught marker semantics merging, a narrow large-text footer clipping
  issue and insufficient landscape map space; all were corrected. Initial lint
  and test-finder issues were also corrected. One permission-review timeout was
  retried successfully; no verification remains blocked.
- User-reported emulator verification: DNS resolved; OSM tiles load; conventional
  GraphHopper routing works; both conventional and waypoint routes appear.
  This session made no live provider calls. Detailed manual checklist/TalkBack,
  snapping/access correctness, and account entitlement remain unverified.
- No new dependencies, backend, credentials, permissions, commits, or pushes.
  Stop after verification for user review; no further stage is authorized.

## Stage 2 Cubit/state comparison support (2026-10-09)

Continued on `feature/local-route-comparison`, preserving approved uncommitted
Stage 1 work. This is the latest milestone; older next-step notes are historical.

- Added immutable ordered waypoint state and add/select/edit/replace/remove/reorder
  operations using the shared three-waypoint limit. Invalid indices are safe no-ops.
- Separate conventional/preferred results, loading, errors, and generation counters.
  Explicit submission requests only missing branches. No requests occur on edits.
- Waypoint edits preserve valid/in-flight conventional routing. Partial successes
  survive failures; stale completions after edits/reset/close cannot overwrite state.
- Raw preferred-minus-conventional distance and duration differences are available
  only when both current results exist. No fare or waiting-time logic.
- Existing map screen and Stage 1 service/repository are unchanged in this stage.
  Waypoint editing/comparison display are not yet available in the UI.
- Added 39 Cubit/state tests covering 0-3 waypoints, order/limits/invalid indices,
  immutable lists, raw comparison signs, partial failures, selective retry,
  request counts, baseline reuse, and stale success/failure after every edit,
  reset, and closure. Existing tests retained.
- Final verification: Dart format exited 0 on four Stage 2 Dart files;
  `flutter analyze` exited 0 with no issues (2.6 seconds); `flutter test` exited
  0 with all 118 tests passed; `git diff --check` exited 0. The first analysis
  found a missing brace block and unused test import; both were fixed before
  the final run. Tests use controlled futures/fake HTTP/local tiles only.
- No live GraphHopper requests or device verification. No commits or pushes.
- Next: Stage 3 UI work only after approval; see [Architecture](ARCHITECTURE.md).

## Stage 1 waypoint service/repository support (2026-10-09)

Started clean on `feature/local-route-comparison` after conventional routing was
merged into local `main` at `75ae6ee`. This section supersedes the older branch
and uncommitted-baseline description below; historical verification is retained.

- Repository/service accept zero to three ordered intermediate waypoints in one
  GraphHopper request. The shared limit rejects excess waypoints before HTTP.
- Supplied order and repeated points are preserved; caller mutations cannot
  alter the submitted request. Existing two-point routing remains supported.
- Parser, timeout/abort, response limits, fixed host, and safe errors are retained.
- Cubit, state, UI, dependencies, and platform configuration are unchanged.
- Added 11 unit tests for zero/one/two/three ordered waypoints, one-request totals,
  repeated points, caller-list mutation, forwarding, and pre-HTTP limit rejection.
- Verification: `flutter analyze` passed with no issues; `flutter test` passed all
  79 tests, including existing conventional routing, Cubit, and widget tests.
  `dart format` completed on seven changed Dart files; `git diff --check` passed.
  Tests used fake HTTP/local tiles only. Analysis/tests required SDK cache access.
  The sandboxed formatter stalled; SDK-access approval reviews timed out twice.
  Direct Dart formatting completed but initially failed on a telemetry write;
  rerunning the same SDK executable with `--suppress-analytics` exited 0 with no
  further formatting changes.
- No live API/device tests or account-limit verification in this stage. The owner
  reports conventional routing was manually verified; the detailed acceptance
  checklist has not been updated with those results.
- Stage 2 requires separate approval. No commit or push made.

See [Architecture](ARCHITECTURE.md) and [Security](SECURITY.md) for the boundary.

Updated 2026-10-08. Implementation work began clean on `feature/conventional-routing`, HEAD
`b728ba935ac477763a943eab85568a005c1ea2e1`. Changes are local and uncommitted.

## VERIFIED IMPLEMENTED

Conventional routing now has a complete application path:
UI → RoutingCubit → RoutingRepository → RoutingService → GraphHopper.

- Existing Karachi OSM map, pan/zoom, credits and controller readiness retained.
- Long-press selects A/origin then B/destination; chips select which endpoint to
  change; Reset clears endpoints and results.
- Explicit Get Route requests one car route. Successful provider geometry renders
  as a polyline with two markers, km and estimated minutes; camera fits the route.
- Loading disables duplicate submissions. Retry is explicit. Endpoint changes and
  reset clear obsolete results/errors; generations ignore stale success/failure.
- Validated RoutePoint/RouteResult, safe RoutingFailure, bounded HTTPS service.
  No straight-line fallback, GPS, search, route history, backend or database.
- Owner-supplied GraphHopper client key via compile-time Dart defines; missing
  key produces a safe configuration error. Development setup now recommends a
  JSON file outside the repository; the ignored local path remains compatible.
  Real-key setup has not been inspected or verified in this cleanup.

AGENTS.md and architecture/decision documentation now describe the implemented
GraphHopper route path rather than the earlier constructor-only scaffolding.
The 2026-10-08 cleanup changes documentation only; routing code, dependencies,
the placeholder template and existing ignore rules are preserved. No real secret
files were accessed or modified.

See [Architecture](ARCHITECTURE.md), [D7](DECISIONS.md),
[provider comparison](ROUTING_PROVIDER.md), and [Security](SECURITY.md).

## VERIFIED AUTOMATED

Map gesture fix verified on 2026-10-08:

- Disabled only double-tap-drag zoom in MapScreen; rotation remains disabled.
  Ordinary drag, pinch, double-tap and scroll-wheel zoom remain enabled; zoom
  buttons and long-press endpoint selection are unchanged.
- Extended the isolated-drag test to require a changed center and unchanged zoom.
  Added quick tap-and-drag regressions for touch and mouse, checking zoom during
  movement in both vertical directions and after release. Both new tests failed
  before the fix (zoom 12 became 15.25) and passed after it.
- `flutter analyze`: exit 0, no issues (6.0 seconds).
- `flutter test`: exit 0, all 68 tests passed. Checks ran with SDK cache access.
- Manual emulator verification is pending. Widget tests do not exercise Windows
  input translation. flutter_map 8.3.2 may briefly suppress panning after a quick
  tap even with double-tap-drag zoom disabled; this fix only prevents that zoom.
- No routing, credential configuration, architecture or dependency changes.

Rechecked for the documentation-only cleanup on 2026-10-08:

| Check | Actual result |
| --- | --- |
| `flutter analyze` | Exit 0; No issues found! (10.2 seconds) |
| `flutter test` | Exit 0; 66 tests passed, All tests passed! |
| `git diff --check` | Exit 0; no whitespace errors |
| `git check-ignore config/routing.local.json` | Existing ignore rule confirmed |

Initial sandboxed Flutter attempts stalled without output and were interrupted.
Reruns with SDK cache access outside the restricted sandbox passed. No secret
configuration was supplied. No live routing or manual/device checks were run.

Executed against this implementation on 2026-10-01:

| Check | Actual result |
| --- | --- |
| `flutter pub get --offline` | Exit 0; cached dependencies resolved |
| `dart format` on lib/test | Exit 0; changed Dart files formatted |
| `flutter analyze` | Exit 0; No issues found! (4.0 seconds) |
| `flutter test` | Exit 0; 66 tests passed, All tests passed! |

Initial runs found a test-fixture map type error and three brace lint findings;
these were fixed before the successful full suite/analysis above. Flutter's OSM
policy reminder is informational, not a test failure. SDK cache access required
running Flutter outside the restricted filesystem sandbox; no security control
was weakened and no provider API was used by the tests.

Coverage: coordinate boundaries/non-finite values; immutable results; request host,
HTTPS, redirect and coordinate ordering; geometry and unit parsing; no-route,
malformed, timeout/body abort, HTTP/auth/quota/network failures and size limits;
repository propagation; selection/loading/success/error/retry/duplicates; both
endpoint edits, reset, close and out-of-order success/failure; widget long-press,
markers, polyline, metrics, edit/reset/retry, credits, zoom/pan and small landscape.
Tests inject fake HTTP/controlled futures and in-memory tile images.

## VERIFIED MANUALLY (source/repository review only)

Provider official documentation, architecture, changed source/configuration and
Git diffs reviewed. `.gitignore` retains every existing rule and adds only the
local routing config rule; `git check-ignore` confirms it. No obvious actual
credentials in changed files; test values and config example are placeholders.
No platform files/permissions changed. The lockfile only promotes the already
resolved http 1.6.0 dependency to direct; no package version changed.

This is not manual application/device verification or an exhaustive secret audit.
No commit, push, merge or PR was made; no generated artifacts were staged.

## NOT VERIFIED / limitations

- No live GraphHopper request or account entitlement check in this cleanup.
- All six public Karachi cases and emulator/device checks remain
  **NOT VERIFIED — MANUAL TEST REQUIRED** in [the checklist](MANUAL_ROUTING_TESTS.md).
- No claim of route legality, appropriate snapping, current road access, live
  traffic, or accurate real-world duration. Geometry bounds do not establish these.
- Key is extractable from a compiled build. Selection covers owner-run personal
  non-commercial development, not broad distribution of a shared paid key.
- Per-account quota, exact free minute limits and production terms need checking
  before expanding usage. No automatic retry/budget enforcement is implemented.
- Tile availability and offline mapping are not guaranteed; labels are rasterized.
- Android debug release signing and example app identifiers remain unchanged.
- Attribution launching, real tiles/network, physical-device rendering and large
  accessibility text need manual validation. iOS tests still contain a placeholder.

## Exact next milestone

Configure the personal GraphHopper key locally using README; execute and record
K1–K6 and device UX checks. Fix any observed conventional-routing defects before
starting the separate local-waypoint/comparison milestone. No backend work needed
for the accepted personal development boundary.
