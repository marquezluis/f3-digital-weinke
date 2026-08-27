# Digital Weinke — Project Memory

_Last updated: 2026-08-27. This file is the persistent context for this repo across
sessions (this environment is ephemeral per-session, so nothing survives here except
what's committed to git). Keep it current: update it when release status, open PRs, or
architecture notes change._

## What this project is

**Digital Weinke** (`f3_nation_app`, currently `2.6.0+29`) — a local-first Flutter app
for F3 Nation. Generates a balanced 50-minute beatdown plan, runs a phase-aware
countdown timer (Disclaimer → Warm-O-Rama → The Thang → Mary → COT), and gives offline
access to the full F3 Exicon (907 exercises). Zero network calls required for core
use; data is bundled JSON or `shared_preferences`.

It is a **client app that syncs with the F3 Nation platform**, not the platform
itself. The separate `F3-Nation/f3-nation` repo is F3 Nation's own community
platform/backend — a different codebase. This app talks to it over its API
(`lib/services/f3_api_service.dart`, `auth_service.dart`, `codex_sync_service.dart`).

Repo: `marquezluis/f3-digital-weinke`. This session works on branch
`claude/new-session-3i49jh`.

## Architecture (lib/)

- `config/`, `theme/`, `l10n/` — app config, theming, locale-aware strings
- `models/` — data models
- `screens/` — UI screens (Timer, Exicon, Q Field Guide, Brotherhood, Achievements, Profile, etc.)
- `services/` — business logic + integrations, notably:
  - `f3_api_service.dart` — F3 Nation API client
  - `auth_service.dart` — F3 Nation sign-in, **public PKCE client, no client_secret** (since 2.6.0)
  - `codex_sync_service.dart` — syncs demo videos + official/pending tags from live F3 Nation Codex
  - `emergency_service.dart` — emergency contact info (PHI-sensitive, was local-only; see PR #1)
  - `region_service.dart`, `geo_service.dart` — region/location handling
  - `workout_generator.dart`, `spartan_plan_builder.dart`, `q_builder_service.dart` — beatdown planning
  - `history_service.dart`, `backblast_formatter.dart`, `weinke_exporter.dart` — session history/backblast
- `painters/`, `widgets/` — custom drawing, shared widgets

## Recent history (most recent first)

- **2.6.0** (2026-08-15, latest release) — stability pass:
  - Fixed crashes from premature controller disposal across several add/edit sheets
    (disposed text fields mid-close-animation)
  - Fixed sheet-close races in Brotherhood's AO-name autocomplete and PAX F3-lookup
  - Fixed a bug where changing region in Profile silently wiped display name / F3
    Nation user id
  - Added: Founding Quest confetti celebration, AO logos on Near Me Right Now, real
    HC/Q commitment recognition threaded through check-in/backblast, more manual-entry
    fields backed by real F3 Nation data, permission priming on every app resume
  - Changed: switched sign-in to public PKCE client (no embedded secret)
- **2.5.0** (before 2.6.0) — typography/Fellowship rename, Convergence Mode
  investigation, global search, monthly recap, F3 Moments timeline, Codex demo-video
  sync

## Open work

- **PR #1 — "sync emergency contact info with F3 Nation profile"**
  (`feat/emergency-info-f3-nation-sync`, opened 2026-08-13, **stalled/idle since**
  — no activity for ~2 weeks while 2.5.0/2.6.0 shipped around it).
  - Syncs `contactName`/`contactPhone` with F3 Nation's real profile columns
    (`emergencyContact`, `emergencyPhone`) via authenticated `/v1/me/profile` GET and
    app-key `POST /v1/user`.
  - Blood type, allergies, conditions, medications, preferred hospital, organ donor
    status sync into the freeform `meta` JSON field instead (per Tackle's guidance:
    F3 Nation only gives real columns to core/common fields), via `PATCH
    /v1/me/profile` using the **PAX's own access token** (the only endpoint that
    merges into `meta` rather than overwriting the column).
  - Pull prefills only empty local fields (never overwrites saved data); push fires
    after local save and never blocks it (life-safety form must not stall on a flaky
    connection).
  - AO-site safety fields (nearest ER, AED location, EMS notes) stay local-only —
    they're per-location, not user-profile data.
  - Test plan: `flutter analyze` clean; **live-device round-trip check still not
    done** — this is the blocking item before merge.
  - **Next step if picked back up:** do the live-device check, then merge.

## Notes on `F3-Nation/f3-nation` (upstream org repo)

- Public repo, read-only for this session (cross-owner attach with push access isn't
  supported once a session already has repos from another owner — needs its own
  session). A separate CCR session was spawned to check its GitHub status; see that
  session's findings when picking this up again rather than re-deriving them here.
