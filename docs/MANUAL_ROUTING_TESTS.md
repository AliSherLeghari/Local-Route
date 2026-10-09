# Manual Karachi routing acceptance

The owner reports emulator DNS resolved, OSM tiles loading, and both conventional
and waypoint routes displayed successfully. This does not establish completion
of the cases below, which remain **NOT VERIFIED — MANUAL TEST REQUIRED** until
individually recorded. Automated fixtures do not establish Karachi road quality.

## Stage 3 waypoint/device checks

- Add W1/W2/W3 by long-press; confirm Add disables at three and markers/sequence
  match. Edit, reorder, remove, and verify no requests until explicit submission.
- Inspect snapping on divided roads and near a missing/inaccessible road. Record
  unexpected detours or U-turns; waypoints do not guarantee the intended road.
- Compare both polylines, including shared geometry, metric differences, and
  combined camera fit. Pan/zoom, edit or expand controls: no unexpected refit.
- Edit while loading and reset before completion: stale routes must not return.
  Exercise offline/partial failure and retry without repeatedly consuming quota.
- Check narrow portrait, landscape, large text, TalkBack labels/touch targets,
  footer credit links, and sequence visibility. Record findings and device details.
- Confirm no passenger stopping time/fare behavior is implied. Durations are
  estimates without live traffic. Use public locations only.

## Procedure

1. Follow README configuration using your own development key locally. Never
   paste it into reports. Confirm non-commercial plan entitlement and quotas.
2. Start the app on Android. Pan/zoom to the named public landmarks. Select a
   public road/access entrance near each landmark, not the center of its building.
   For the snapping case deliberately select the specified non-road position.
3. Reset, long-press A, long-press B, and press Get Route exactly once. Wait for the
   response. Space manual requests by at least five seconds; stop on a rate-limit
   error and check the account quota before any explicit retry.
4. Examine the returned polyline at street level. Record the fields below. A line
   alone cannot establish road legality: mark anything uncertain as unverified and
   check current signs/local knowledge before interpreting it as a valid maneuver.
5. Change B and request again; confirm the old route disappears immediately and
   cannot reappear from an older response. Reset and confirm all route state clears.
6. Check both attribution links, camera fit, pan/zoom and readability in portrait,
   landscape and large text. Test offline retry without repeated requests.

## Six public-landmark cases

These are test candidates, not verified itineraries or endorsements of access.
Use visible map labels to locate them; record the exact public selections locally
for reproducibility without recording any personal/home location.

| ID | Category | Origin → destination / selection instruction | Status |
| --- | --- | --- | --- |
| K1 | Straightforward arterial | Public road by Mazar-e-Quaid → public road by Numaish Chowrangi; inspect the arterial connection | NOT VERIFIED — MANUAL TEST REQUIRED |
| K2 | Divided road / U-turn | Public carriageway near NIPA Chowrangi → opposite carriageway near the same junction; zoom in and deliberately place A/B on opposite sides | NOT VERIFIED — MANUAL TEST REQUIRED |
| K3 | Flyover / interchange | Public access road by National Stadium → public road by Expo Centre Karachi; inspect any interchange/flyover actually used (record if route does not exercise one) | NOT VERIFIED — MANUAL TEST REQUIRED |
| K4 | Local-road access | Public access by Hill Park → public access by Jheel Park; inspect neighborhood connections and entrances | NOT VERIFIED — MANUAL TEST REQUIRED |
| K5 | Longer cross-city | Public access by Dolmen Mall Clifton → public passenger approach at Jinnah International Airport; avoid restricted/service areas | NOT VERIFIED — MANUAL TEST REQUIRED |
| K6 | Difficult endpoint / snapping | Public road near Empress Market → deliberately select inside the public Bagh Ibn-e-Qasim park area, away from a drivable road; inspect snapping or a safe no-route outcome | NOT VERIFIED — MANUAL TEST REQUIRED |

## Record one entry per case

- Case ID, date, app revision, device, provider/profile and public endpoint choices.
- Request success: yes / no / not run; friendly failure category if applicable.
- Road-following geometry: yes / no / uncertain.
- Origin snapping: appropriate / inappropriate / uncertain; note displacement.
- Destination snapping: appropriate / inappropriate / uncertain; note displacement.
- Obvious illegal maneuver: none observed / observed / uncertain; describe.
- One-way or U-turn issue: none observed / observed / uncertain; describe.
- Distance displayed (km) and estimated duration displayed (minutes), or not returned.
- Geometry anomalies (gaps, wrong carriageway, unexpected shortcut, etc.).
- Notes and unresolved checks. Optional screenshots must contain no credentials or
  private locations. Do not treat simulated test fixtures as manual results.

Pass criteria: responsive app; real returned road geometry; sensible snapping and
metrics; no obvious invalid maneuver; correct clearing/edit/retry behavior; visible
credits. Any uncertain road-access claim remains unverified. A safe no-route error
can pass K6's error behavior but does not prove successful routing there.
