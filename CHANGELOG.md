# Changelog

All notable user-facing changes to Digital Weinke are logged here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

The patch digit (the third number, e.g. the `1` in 2.4.1) is our build
counter within a minor-version line — it goes up on every release build,
whether or not that build shipped, so "how many builds have we done on
2.4" is just the highest patch number under a `## [2.4.x]` heading.
`make build-apk`/`build-appbundle` bump it automatically.

## [Unreleased]

## [2.5.0] - 2026-08-13

The biggest release yet — a full pass on onboarding, Home, Brotherhood
Board, and Settings, plus two real F3 Nation integrations (live Codex
sync and a native admin screen), driven by a 100-item UX audit.

### Added
- **Region Chat** — a channel-aware chat screen (#general + one per AO),
  the local-only half of the planned Slack bridge; messages stay
  on-device until the relay exists.
- **Home redesign** around one dominant "Today" hero (Q'ing, HC'd, or a
  prompt to find a beatdown), a 10-week activity strip, PAX of the
  Quarter and this-month's region recap, a guided first-week "Founding
  Quest" with a badge, and a global search box (Exicon, Q Field Guide,
  AOs, all at once).
- **Live Codex sync** — pulls demo videos and confirms which exercises
  are Official vs. Pending directly from F3 Nation's real, live Exicon.
- **Native admin screen** — edit an AO's Location (name, address,
  lat/long, active status) right in the app, writing to the real F3
  Nation admin API, gated to editor/admin roles.
- **F3 Nation Links** in Settings — Map, Near Me, F3 Me, PAX Vault, the
  Codex, Org Chart, plus role-gated Admin Tools.
- **F3 Moments** — a chronological timeline of every Pic-o-Rama photo
  across every AO.
- **"F3 Near Me Right Now"** — beatdowns starting within the hour,
  sorted by distance.
- **"I'm at the flag"** — a one-tap personal check-in for today (not a
  broadcast — just saves re-typing the AO when you save a backblast).
- Real **Circle of Trust** capture during Q Mode — live note-taking that
  pre-fills the backblast's COT field instead of relying on memory.
- **App Lock** now has a real toggle in Settings → Safety, not just a
  one-time onboarding choice.
- **TTS voice preview** — hear a sample before picking a voice.
- **QSource bookmarking** + a recently-viewed quick-jump row.
- **Shareable achievement cards** and a **share-as-image** option for
  preblasts, alongside the existing beatdown card share.
- **F3 Lingo glossary** (Q, PAX, AO, HC, EH, FNG, COT…) from onboarding
  and Settings.
- Sign-in screen now shows a real, live AO count — genuine social proof.
- A "See AOs near you first" preview on the sign-in screen — browse
  real AOs before creating an account.
- A brand-new onboarding illustration (original artwork, not F3 photos)
  and a small celebration on completing setup.
- A distinct "gearing up" transition into Q Mode.
- Auto-mumblechatter — opt-in random callouts every 90–180s during a
  live session.

### Changed
- Language now defaults to your device's own locale and theme to
  System, instead of forcing a choice before you have any context —
  the picker's still in Settings if you want it.
- Daily mottos are now translated into Spanish and French.
- Dates across the app (Activity Feed, Brotherhood, Heatmap, Settings)
  are locale-aware instead of always showing English month names.
- The "Community" tab is now "Fellowship," matching F3's own language.
- HC/un-HC now respond instantly instead of waiting on the network.
- Destructive actions (deleting a custom exercise, achievement, EH
  prospect, or importing a backup) now confirm first, consistently.
- Headings and the app's wordmark now use a distinct display typeface
  instead of the same system font as everything else.
- Publishing a backblast, HC'ing, and other key actions now give
  haptic feedback on success or failure.

### Fixed
- A real streak-calculation bug: a perfectly consistent PAX's streak
  could silently reset to zero the moment a new week began, before
  they'd had a chance to post yet.
- Home's Quick Start row could overflow when all three actions showed
  together.
- Schedule's "Mine" filter could silently clear itself when reopened
  and dismissed without a new choice.
- The installed app name no longer implies official F3 Nation
  branding ahead of actual approval.
- A Reduced Motion audit caught two animations (achievement-unlock
  confetti, the onboarding scene) that weren't actually respecting the
  in-app toggle.
- Several silent failures now show real feedback: a failed music-app
  launch, a failed Exicon external link, a failed F3 Nation sign-in
  (previously showed raw error text).
- Accessibility: a text-clipping bug in Home's identity row at large
  text sizes, and missing screen-reader labels on Q Mode's EMOM/Tabata
  steppers.

## [2.4.10] - 2026-07-30

### Added
- **AO logos** on Browse AOs and a beatdown's detail sheet, sourced from F3 Nation's real org data (`logoUrl` on `/v1/org`) — falls back to the existing shield icon for AOs that haven't uploaded one.
- **Full F3 Me profile parity** — Profile now shows F3 Name Origin, My F3 Why, and your Roles/Positions across F3 Nation regions, matching what the real me.f3nation.com site shows (previously only name/phone/avatar were pulled in).

### Fixed
- Schedule's "Mine" filter pill silently cleared the active filter if the picker sheet was reopened and dismissed without choosing anything — `showModalBottomSheet` resolves to bare `null` on both an explicit "All" pick and a plain dismiss, and the two cases weren't being told apart.
- Home's Quick Start row could overflow when all three quick-start actions (Resume/Random/Last Plan) were showing together — the widest label ("Last Plan") had no room to shrink.

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
