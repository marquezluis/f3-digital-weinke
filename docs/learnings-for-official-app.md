# Learnings for the Official App

For Moneyball's ground-up build. This is what Digital Weinke (DW) has to hand
over — access patterns, API quirks, auth lessons, Q workflow logic, field UX,
and answers to the wireframes' own open questions — not the codebase itself.
Everything here is drawn from working, tested code as of this demo-prep pass
(`feat/moneyball-wireframe-demo`), not speculation.

## API access patterns, by flow

Base URL `https://api.f3nation.com` (`F3_API_BASE_URL` override for staging).
Every call below goes through the signed-in PAX's own OAuth access token —
DW has never shipped a shared app-level API key.

| Flow | Endpoint(s) | Notes |
|---|---|---|
| **Sign in / identity** | OIDC discovery against `auth2.f3nation.com`, then `GET /v1/me/profile` | `auth2`, not `auth` — the old standalone server. Discovery doc confirms `/api/oauth/authorize` + `/api/oauth/token`. |
| **Browse AOs (signed out)** | `GET /v1/location` (paginated), `GET /v1/event` (paginated), `GET /v1/org` (paginated) | All three serve DW's public read tier with no Authorization header — the real precedent for "browse before account" (see open questions below). |
| **Schedule (a PAX's calendar)** | `GET /v1/event-instance/calendar-home-schedule?regionOrgId=…&userId=…&startDate=…&limit=…` | `regionOrgId` + `userId` are both required — omit either and the endpoint 400s and silently looks like "nothing scheduled" unless the caller checks for that explicitly. |
| **HC (sign up)** | `POST /v1/attendance` `{eventInstanceId, userId, attendanceTypeIds: [1]}` | Self-signup needs only the user's own token — no editor role. |
| **Un-HC** | `DELETE /v1/attendance/event-instance/{id}/user/{id}` | Deletes the whole attendance record — if the PAX was Q, this drops the Q too. |
| **Take Q** | `POST /v1/attendance/take-q` `{eventInstanceId, userId}` | |
| **Drop Q (stay HC'd)** | `DELETE /v1/attendance/remove-q` with a JSON body, not query params | See quirk below — this one bit us. |
| **Who's HC'd/Q'd (preblast visibility)** | `GET /v1/attendance/event-instance/{id}?isPlanned=true` | Needs *some* authenticated caller, confirmed — not fully public. |
| **Preblast** | `POST /v1/event-instance` `{id, orgId, startDate, preblast, preblastRich, preblastTs, isActive}` | `orgId` must be the event's own **AO**-level org, never the region — sending the region reassigns the event to it. `preblastRich` (a minimal Slack rich_text block) is required too: the API's `hasPreblast` flag other consumers (Slackbot) trust is computed from `preblastRich IS NOT NULL`, not the plain-text column. |
| **Backblast + attendance publish** | `POST /v1/event-instance` (backblast text + counts), `POST /v1/attendance/actual` per PAX | Same AO-org-id rule as preblast. `attendanceTypeIds`: `1` = PAX, `2` = Q, `3` = Co-Q. |
| **Past Qs with no backblast posted** | `GET /v1/event-instance/past-qs?userId=…&regionOrgId=…&notPostedOnly=true` | Powers "which of my Q'd events still need a backblast." |
| **Self-service profile edit** | `PATCH /v1/me/profile` | Switched to this from an app-key `POST /v1/user` this pass — see auth lessons. |
| **Editable locations (admin)** | `GET /v1/location?onlyMine=true`, `POST /v1/location` | Server-side-enforced editor role, resolved from the bearer token. |

One structural note worth carrying over: **the event instance id is the
thread that ties everything together.** HC, take-Q, preblast, backblast, and
attendance all key off the same `eventInstanceId` — DW's own "I'm at the
flag" GPS check-in resolves that id once and then threads it through every
later step, so the PAX is never asked "which event is this for?" twice in
one session. Worth keeping as a first-class concept in a ground-up build,
not an afterthought.

## API quirks actually hit in production use

- **`/v1/org` sends `id`/`parentId` as numbers, and the type field is
  `orgType`, not `type`.** A `String?` cast crashed the region picker on
  every real fetch until caught against live staging data. Coerce
  defensively (`.toString()`) rather than assuming a JSON type contract
  holds.
- **`DELETE` routes without a path-template parameter (e.g. `remove-q`)
  read their input from the request body, not the query string.** A query
  string there fails the server's own input validation with a 400
  ("expected object, received undefined") before the handler even runs.
- **`/v1/org` has no server-side name/search filter** — `name`/`search`/`q`
  params are silently ignored and `total` stays the same regardless. Fetch
  once, cache, and filter client-side instead of hitting the endpoint per
  keystroke.
- **As of August 2026, events/locations/orgs gained "stable pagination."**
  The old approach — one request with an oversized `pageSize` to get
  everything in one page — is a time bomb once the server starts enforcing
  a real page cap; it'll silently truncate instead of erroring. Walk pages
  and stop on an explicit `total`/`hasMore` signal, not on "the page I asked
  for came back."
- **Region/org ids need strict numeric types in write payloads**, not
  numeric-looking strings. Validate client-side before sending — a
  malformed id is a confusing server error otherwise, not a clear one.
- **`/v1/location`'s own `orgId` is the region, not the AO.** The AO's own
  identity (name, org id, for a logo lookup) only shows up by joining
  `/v1/event`'s `parents[].parentId` against `/v1/location` on
  `locationId` — `/v1/location` alone can't answer "what AO is this."

## Auth lessons

- **Public PKCE client, no client secret, ever.** A secret can't stay
  confidential once it ships in a compiled binary — DW's client
  (`digital-weinke`) is registered as public, Authorization Code + PKCE
  (S256), confirmed working end-to-end with no secret sent on either the
  `authorization_code` or `refresh_token` grant.
- **No API key in the binary either.** DW's compiled builds have never
  shipped a shared credential — every authenticated call uses the
  signed-in PAX's own token; signed-out reads use the API's public tier
  instead of a fallback key.
- **Take endpoints from OIDC discovery (`issuer:`), not a hardcoded
  path, wherever the OAuth library supports it.** DW's sign-in and
  token-refresh calls already do this. One spot didn't — the end-session
  (logout) call hardcoded `/api/oauth/authorize|token|logout` — and it's
  now discovery-first with the hardcoded paths as a last-resort fallback
  only. Worth building this pattern in from day one rather than retrofitting
  it.
- **Request `offline_access` explicitly once the issuing server goes
  strict OIDC.** A looser server may always include a refresh token; a
  strict one only issues one when the client scope says so — losing that
  scope silently breaks "stay signed in."
- **The auth3/Better Auth cutover (confirmed with Tackle, 2026-11-05;
  prod host and date still undecided, staging is
  `staging.auth3.f3nation.com`) is a clean example of discovery paying
  for itself.** auth3 is a separate Cloud Run service; existing public
  clients migrate server-side (same redirect URI, `token_endpoint_auth_method:
  "none"`, no re-registration needed) and discovery
  (`<issuer>/.well-known/openid-configuration`) returns a genuinely mixed
  set of endpoints — `authorization_endpoint` under Better Auth's own
  `/api/auth2/oauth2/...` route, while `token_endpoint` and
  `end_session_endpoint` stay at the legacy `/api/oauth/token` and
  `/api/oauth/logout` paths (kept as adapters forwarding into Better
  Auth). A client built on discovery needs zero code changes for this;
  one hardcoding any of those paths needs to track the split by hand.
  One real trap: **never send `prompt=consent`** — auth3 has no consent
  page, and that 404s with no authorization code at all. `prompt=login`
  is fine and is what forces the account chooser on a fresh sign-in.
- **A token-refresh call needs its own timeout, independent of the rest
  of your HTTP client's defaults.** A stalled connection to the token
  endpoint with no timeout hangs that await forever with nothing to
  catch — DW hit this as a real bug: the Profile screen got stuck on an
  infinite spinner, with no way to even sign out, because the one
  refresh call that mattered had no timeout while every other network call
  in the same file did.
- **A 401 means different things depending on who's asking.** A 401 on a
  call authenticated with the signed-in user's own token is a genuinely
  dead session (revoked/expired refresh token) — worth re-prompting
  sign-in for. A 401 on anything else (a network blip, an app-level
  credential) is not the same signal and re-signing in won't fix it;
  conflating the two trains users to distrust the sign-in prompt.

## Q workflow business logic

- **The 50-minute template**: Disclaimer (1 min) → Warm-O-Rama (7 min, ~4
  exercises) → The Thang (32 min, ~8 exercises, bodyweight/coupon split
  by settings) → Mary (6 min, ~4 exercises) → COT (4 min). This maps
  directly onto RES-04's live runner.
- **Coupon mode** (No Coupons / Mixed 50-50 / Coupons Only) and
  **intensity** (Beginner / Intermediate / Advanced) are per-PAX settings
  that bias exercise selection, not per-event — a Q's own device decides
  what it generates, nothing server-side gates it.
- **Call styles per block** differ by phase (Warm-O-Rama vs The Thang vs
  Mary have different cadences/call conventions) — worth encoding as
  data per exercise/block type, not assumed uniform.
- **COT capture** (Count-O-Rama, Name-O-Rama, FNG naming, announcements,
  closing word) is a fixed checklist DW surfaces at the right moment in
  the live timer — treat it as a first-class phase, not an afterthought
  tacked onto "the end of the workout."
- **An event instance id, once known, should never be re-asked for.**
  Backblast auto-fill and publish both key off the same id the check-in
  flow resolved — see "API access patterns" above.

## Field UX lessons

- **5:30 AM, sweaty, often gloved hands.** Big tap targets, big glanceable
  timer digits, high-contrast dark theme as the default (not a light
  theme nobody asked for at that hour). A destructive/irreversible action
  (skipping straight to Mary, dropping Q) needs a confirmation dialog —
  not because users are careless, but because gloved/wet fingers
  mis-tap.
- **Permission priming needs to run on every app resume, not just once
  after backgrounding.** A cold launch used to skip priming entirely — a
  feature needing a permission later (GPS for a check-in suggestion, a
  notification) could hit an unresolved OS dialog mid-flow instead of
  having already asked at a calmer moment.
- **A silent Android regression nearly broke every release build.**
  Scheduled local notifications depend on a serialization step (Gson)
  that a general release-build config change can quietly break — it's
  the kind of thing that passes every manual smoke test on a debug build
  and only shows up as "nobody got their Saturday reminder." Cover it
  with an explicit test, not just manual spot-checks.
- **A write that must survive a screen going away.** A PAX taps "publish"
  and immediately navigates elsewhere — the real HC/Q/preblast/backblast
  write still has to complete and the UI update has to check `mounted`
  before touching state, but the write itself must never be silently
  dropped just because the screen isn't visible anymore by the time the
  network round-trip finishes.

## Answers to the wireframes' open questions

- **FNG-01's framing question ("should a new visitor browse before
  creating an account?")** — yes, and DW already proves it works: the
  map/AO browse reads through the API's public tier with no
  Authorization header at all, so a visitor can see real, live AOs
  before ever touching sign-in. No backend change needed to support
  this in a ground-up build; it's a client-side choice about which
  reads require a token.
- **FNG-06's open question (how to auto-approve an FNG into a region
  without a human in the loop)** — DW's "I'm at the flag" GPS check-in is
  a real, working signal for exactly this: a device physically present at
  a known AO's location at the time of a real scheduled event is strong
  evidence the person showing up is legitimate. It's not wired to any
  approval decision today (there's no approval endpoint to wire it to),
  but it's the kind of signal a ground-up build's region-approval flow
  could reasonably key off, rather than inventing one from scratch.
- **"Is a private Q plan field actually necessary, or can the client
  just keep it local?"** — DW keeps its own Weinke draft entirely
  device-local (never sent to the API, only the already-public preblast
  text is), and that's held up fine in practice. A private
  server-side field buys cross-device continuity (a different device
  picking up where another left off) at the cost of a real schema
  addition; local-only is the cheaper default if that continuity isn't a
  priority for v1.
