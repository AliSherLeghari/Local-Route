# Conventional routing provider evaluation

Checked 2026-10-01 against official sources. This is an engineering suitability
assessment for personal, non-commercial development, not a legal opinion.

| Requirement | GraphHopper Directions API | HERE Routing v8 | OSRM engine / public hosting |
| --- | --- | --- | --- |
| Car, geometry, distance, duration | Car profile; GeoJSON; meters; milliseconds | Car; flexible polyline; section length and duration | Driving profile; GeoJSON/polyline; meters; seconds |
| Waypoints / alternatives | Both supported; plan limits apply | Both supported | Both supported; alternatives not guaranteed |
| Karachi basis | Worldwide OSM coverage; local quality unverified | Pakistan not found in the reviewed navigable/intermediate routing lists; other map coverage pages are not proof of routing quality | Engine can ingest Pakistan OSM data; FOSSGIS advertises worldwide car coverage |
| Authentication / mobile | Account API key in query; official guide explicitly documents personal API keys in OSMAnd on Android/iOS | API key or OAuth; mobile apps supported; IAM filters matter, OAuth secrets are not suitable here | Engine itself requires no credential; hosting may add one |
| Map / result handling | Any map; temporary client caching allowed | Platform terms impose content-combination and attribution conditions; caching generally capped at 30 days with exceptions | Engine does not impose a vendor map; OSM data licence and host policy apply |
| Attribution | Keep linked OSM and GraphHopper attribution; elevation disabled | HERE origin must be distinguishable and attributed; exact app obligations would need final review | OSM attribution; FOSSGIS also requires a fix-the-map link |
| Development allowance / limits | Free: 500 credits/day, 5 locations; limited minute credits, no guarantees | Old Limited Plan pages still show 1,000/day and 10 routing RPS, but official release notes retire that plan on 2025-08-31. Do not treat those as a current new-account offer; Base Plan allowance/quota needs account verification | No engine licence fee; self-hosting has operating costs. Demo: reasonable non-commercial use, at most 1 request/sec, no heavy use or service guarantees |
| Commercial / distribution | Free plan treated as non-commercial only; wider distribution needs credential/quota review | Applicable plan, excluded uses and terms require review; not selected | Engine is self-hostable, but public demo is not production infrastructure |

## Decision and credential evidence

Select GraphHopper's managed OSM car routing for this personal learning MVP.
Credential classification **2: client credential intended for client use**, scoped
to an owner-supplied development key in a controlled personal build. This is an
engineering classification, not a claim that GraphHopper calls keys public tokens
or that exposing a shared paid key is safe.

The provider's [OSMAnd mobile guide](https://www.graphhopper.com/blog/2024/02/27/osmand-with-graphhopper-navigation/)
explicitly directs Android/iOS users to create and supply their own API key for
online routing. The current [API documentation](https://docs.graphhopper.com/openapi)
also provides client libraries. That supports direct client access for this scope;
no private/server-only credential or backend is needed. Keys remain extractable
from compiled Flutter builds. Do not distribute a shared account key broadly.

The [terms](https://www.graphhopper.com/terms/) allow mobile temporary caching and
use without a map. The [provider site](https://www.graphhopper.com/) supports any
map and worldwide OSM coverage. The free plan's current pricing footnote is
stricter about commercial use than the older terms' development exception; this
MVP follows the non-commercial restriction. Attribution pages differ on whether
GraphHopper credit is mandatory: showing both linked credits satisfies the
stricter published requirement. No elevation or TomTom add-on is requested.

Unverified: live account entitlement, exact current free-plan per-minute quota,
Karachi route quality, and broad redistribution suitability. These do not block
owner-run non-commercial development with safe quota errors; they must be checked
before increasing usage or distributing builds. No live routing request was made.

Mapbox is not selected: the prior mobile-SDK/terms blocker is accepted as the
reason to move on; this work did not reopen that investigation. HERE adds coverage
and commercial-plan uncertainty without improving this milestone. OSRM remains a
future engine option with an explicitly provisioned host; no public demo is wired
into this application and no infrastructure is deployed.

## Official evidence

- [GraphHopper route schema](https://docs.graphhopper.com/openapi/routing/getroute)
  (its `.md` version was read for parameter and response details).
- [GraphHopper pricing](https://www.graphhopper.com/pricing/),
  [credit calculation](https://www.graphhopper.com/faq/what-is-one-credit/),
  [attribution](https://www.graphhopper.com/attribution/).
- [HERE routing](https://docs.here.com/routing/docs/routing-v8-get-started),
  [API overview](https://docs.here.com/routing/reference/routing-v8-api-overview),
  [coverage](https://docs.here.com/routing/docs/routing-v8-car-routing-coverage),
  [navigable countries](https://docs.here.com/routing/docs/routing-v8-navigable-countries),
  [intermediate countries](https://docs.here.com/routing/docs/routing-v8-intermediate-countries).
- [HERE API keys](https://docs.here.com/identity-and-access-management/docs/plat-using-apikeys),
  [app credentials/filters](https://docs.here.com/identity-and-access-management/docs/manage-apps),
  [Platform Terms](https://legal.here.com/us-en/terms/here-platform-terms),
  [Limited Plan retirement](https://www.here.com/learn/blog/august-2025-platform-release-notes),
  [pricing](https://www.here.com/get-started/pricing).
- [OSRM API](https://project-osrm.org/docs/v5.24.0/api/),
  [engine](https://github.com/Project-OSRM/osrm-backend),
  [demo policy](https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server),
  [FOSSGIS operator](https://routing.openstreetmap.de/about.html).
  Full FOSSGIS terms/privacy links returned bot protection; no production-use
  clearance is inferred from the accessible excerpt.
