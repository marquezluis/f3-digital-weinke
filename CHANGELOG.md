# Changelog

All notable user-facing changes to Digital Weinke are logged here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

The patch digit (the third number, e.g. the `1` in 2.4.1) is our build
counter within a minor-version line — it goes up on every release build,
whether or not that build shipped, so "how many builds have we done on
2.4" is just the highest patch number under a `## [2.4.x]` heading.
`make build-apk`/`build-appbundle` bump it automatically.

## [Unreleased]

## [2.4.3] - 2026-07-22

### Added
- **Pic-o-Rama** — snap or pick a photo when saving a session (camera or gallery), with multi-photo support. Photos show up as thumbnails on Heatmap days (tap to view), aggregated per-AO on Browse AOs, and attach alongside the backblast text when sharing.
- **Share as Image** — any past beatdown can be exported as a shareable card image (title, date, AO/Q, block summary), not just plain text.
- **Call style per block** — In Cadence / On Your Own / On My Up / On My Down, set while building the Weinke. The live timer announces it before each exercise: name → get in position → call style → go.
- Achievement unlocks now show a real celebration (confetti) the moment they trip, instead of only being visible passively in the Achievements list.
- History has a Favorites ("Greatest Hits") filter using the existing thumbs-up rating.
- A "this month vs last month" comparison (sessions, FNGs, coupon sessions) on the Heatmap screen.
- Share your emergency medical info to a fellow PAX before a hard workout.

### Changed
- Posting a preblast now auto-sets your event reminder, matching what HC'ing or taking Q already did.
- The live rep counter, if used during a session, now carries over into the backblast notes instead of being silently lost on save.
- TTS voice now follows the app's language setting (English/Spanish/French) instead of always speaking English.
- The Weinke builder's time-budget bar accounts for real per-exercise timing on custom exercises instead of a generic estimate.

## [2.4.2] - 2026-07-20

### Added
- **Build my Weinke → use as preblast** — a Q'd beatdown's detail sheet now has a "Build my Weinke" button that opens the plan builder linked to that real event. Saving there still works as before, but a new "Use as Preblast" action summarizes the built plan (blocks + exercises) straight into the preblast composer's Plan field and pre-checks Coupon if the plan actually includes coupon exercises — nothing to retype.
- **Add Exercise** — replaces the old "ADD RANDOM EXERCISE" button in the Weinke builder. Opens a search sheet (name/description/alias match) with category filter chips, a Randomize action for the old one-tap behavior, and a Write Custom action straight into the existing custom-exercise form — all three ways to fill a block now live in one place.
- **Mixed — Same Block** coupon mode — interleaves bodyweight and coupon exercises together into one Thang block (shuffled), alongside the existing Mixed mode which keeps them as two separate labeled blocks.
- Writing a custom exercise now asks for an approximate time per set (required) — shown alongside the exercise wherever it's listed (Add Exercise sheet, custom exercise list).
- The Changelog (Settings → version tile) and the Release Log (version footer) now show the 3 most recent versions with a "Show 3 more" button instead of dumping the entire release history at once.

### Changed
- The builder's coupon-mix control (was labeled "Equipment", easy to miss) is now labeled "Coupons in The Thang" — the underlying Mixed/Coupons-only/No-Coupons setting already existed and already defaults to Mixed, it just wasn't discoverable.
- The Weinke builder's beatdown summary card (exercise/block count, time budget bar) now stays pinned at the top instead of scrolling out of view with the rest of the plan.

## [2.4.1] - 2026-07-20

### Added
- **Get Directions** — a directions button on any beatdown's detail sheet (next to Share) that opens your phone's maps app pointed at the AO's real address. There's no single endpoint that carries this for a Schedule event, so it's resolved by joining the AO's org id against F3's event-series and location data.
- **Structured preblast composer** — posting a preblast is now a form instead of one freeform box: date, time, AO, Q, and the live HC list are auto-filled from the event itself, and the Q only types the plan plus, optionally, a VQ flag and coupon notes. Assembles into the same format F3's Slack bot produces.
- Region picker (Settings/Profile → Change region) now caches the fetched region list instead of re-pulling it every time the sheet is reopened, and shows a "Loading regions…" label instead of a bare spinner.
- Schedule: a third filter for "Mine" (HC'd / Q'ing / both), alongside the existing AO and type filters.
- Home's upcoming-beatdowns "See all" link now jumps into Schedule pre-filtered to what you're HC'd or Q'ing for, instead of just switching tabs.
- Local notifications now fire on app resume (and every ~25 min while foregrounded) for a newly-assigned Q or a still-unposted backblast — client-side only, checked against whatever the app already fetches.
- iOS notification permission initialization (was Android-only before, so the new resume-check notifications above would have silently no-op'd on iOS).

### Changed
- The AO-filtered Schedule view is capped to the next 90 days instead of showing years of sparse data for AOs with a long recurring series.
- A dead F3 Nation session (revoked/expired token, confirmed via a real 401 — never just a network hiccup) is now detected directly and routes back to sign-in automatically, replacing the old heuristic on the Profile screen that couldn't reliably tell "offline" from "signed out."

### Fixed
- **"Change region" picker was actually crashing**, not just slow — `/v1/org` returns numeric `id`/`parentId` and a field named `orgType`, but the client expected strings and a field named `type`; every real fetch threw and left the sheet stuck loading.
- **Release-build notifications were silently broken** — `flutter_local_notifications` stores scheduled reminders via a Gson generic signature that R8 strips by default, throwing on every reminder cancel/reschedule (only visible once minification was actually verified against a device log, not just a successful Gradle build). Added the plugin's own keep rules.
- Preblasts posted from the app weren't showing as posted anywhere that reads `hasPreblast` (F3's calendar/past-Qs views compute that from the rich-text field, which the app wasn't populating) — flagged by an F3 Nation API maintainer; now sends a minimal rich-text payload alongside the plain text.

## [2.4.0] - 2026-07-20

### Added
- **Browse AOs map view** — OpenStreetMap-based map above the AO list, with numbered pins matching numbered badges in the list below. Auto-centers on your GPS position (10-mile default view) and re-fits to the matching AOs whenever you apply a state/region/day filter. A "recenter" button on the map returns you to your location instantly if it's already known, or fetches a fresh fix if not.
- **Schedule calendar** — month-grid calendar (default view) with a 7-day agenda underneath; tap a date to see just that day, tap it again (or "This week") to go back. AO/type filters carry through to the agenda.
- **Event reminders** — local notifications the day before and hour before anything you're HC'd or Q'd for, plus a backblast nudge after the event if you were Q. Notification permission is now actually requested (previously never wired up).
- **Home summary card** — "Upcoming Beatdowns" is a single card: how many you're HC'd for, the next one (with its real AO name), and a "See all" link to Schedule. When you're HC'd across more than one week, a small dot row shows the spread — accent-colored dots for this week, steel-blue for later weeks.
- **Onboarding** — a note on the setup step explaining the app will ask for location (nearby AOs) and notification (HC/Q reminders) permission the first time those features are used.
- **Profile** — full F3 Nation profile view with an edit sheet, sign out, and change-region, all in one place.

### Changed
- Settings: removed the unused Slack integration section.
- Schedule's 7-day agenda: added a section header, more spacing, and dividers between days instead of one dense block of text.

### Fixed
- "Change region" picker was silently empty — `/v1/org`'s response wraps its list in an `orgs` key that the client didn't recognize.
- Emergency info was shared across whichever PAX last signed in on a device instead of being scoped to the current one.
- Signing out from the Profile screen could strand you on an empty screen instead of returning to sign-in.
- Browse AOs map freezing (rendering thousands of nationwide markers at once) — now limited to what's in the visible viewport, with zooming out revealing more.
- Browse AOs map going blank after selecting a filter — a tightly clustered or single-AO match produced a near-zero-size bounding box that sent the camera to an unusable zoom with no tiles available; now capped.
- Schedule: deselecting a day, or tapping "Back to this week," left the calendar grid stuck on a different month than the agenda underneath it.
- Browse AOs location fetch felt like it hung with no feedback — now tries the OS's cached last-known position first (near-instant) before falling back to a fresh GPS request.
- Rebuilding and reinstalling the app onto the test device was wiping local data (emergency info, settings) because of an uninstall-then-reinstall install path; switched to an in-place update that preserves app data.
