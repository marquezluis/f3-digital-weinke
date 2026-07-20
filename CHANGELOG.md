# Changelog

All notable user-facing changes to Digital Weinke are logged here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
