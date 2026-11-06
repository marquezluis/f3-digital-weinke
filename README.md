# Digital Weinke

> The Q's cheat sheet — digitized.

A Flutter app for F3 Nation that generates a balanced 50-minute beatdown
plan, runs a phase-aware countdown timer, and signs in with your real F3
Nation account to pull live AO/schedule data and publish HC, Q, preblasts,
and backblasts back to the F3 Nation API. The Exicon, timer, and Q Field
Guide work fully offline; anything involving your F3 Nation identity or
region data needs a connection.

---

## What it does

| Feature | Description |
|---|---|
| **F3 Nation sign-in** | OAuth 2.0 / OIDC (Authorization Code + PKCE, public client, no secret shipped) against `auth2.f3nation.com`. Links your real F3 Nation identity — name, home region, roles/positions — to the app. Browsing AOs/the map works before signing in; HC, Q, and publishing need it. |
| **Browse AOs / Map** | Live, nationwide AO data from the F3 Nation API — search, filter, "Near Me Right Now," real AO logos, get-directions. Works signed out (public read tier). |
| **Schedule (HC / Take Q)** | Real calendar of upcoming beatdowns for your home region, synced from F3 Nation. HC (sign up), take or drop Q, write a preblast, filter and browse by AO. |
| **Workout Generator** | Randomly builds a 50-min beatdown from the full Exicon (907 exercises). Respects your coupon mode and intensity preferences. Every exercise can be swapped with one tap. |
| **Live Phase Timer** | Five-phase countdown that auto-advances: Disclaimer → Warm-O-Rama → The Thang → Mary → COT. Big glanceable digits for 5:30 AM. |
| **Emergency Mary** | One tap skips straight to Mary from any phase. Confirmation dialog prevents accidental taps with sweaty/gloved hands. |
| **Disclaimer & COT screens** | Phase-specific cards: the standard F3 disclaimer text and a step-by-step COT guide (Count-O-Rama, Name-O-Rama, FNG naming, announcements, closing word). |
| **Q Field Guide** | Offline reference tab covering all aspects of Q prep and QSource: Five F3 Workout Principles, standard disclaimer, sample workout structure, Q prep checklist, cadence call sequence, COT checklist, backblast template, QSource best practices, QSource agenda, QSource follow-up checklist, and QSource session formats. |
| **Exicon Library** | All 907 exercises, searchable by name/description/alias. Filter by category tab and intensity level. Live-synced against the real F3 Nation Codex for official/pending tags and demo videos. |
| **Workout History** | Saves completed beatdowns locally — title, date, AO, Q name, PAX list, FNG count, plan summary, notes — plus a heatmap and streak tracking. |
| **Backblast publish** | Publishes the backblast, attendance, and FNG count straight to the F3 Nation API for a real HC'd/Q'd event — not just a local draft. A Slack-ready text copy is still one tap away for pasting anywhere else. |
| **Brotherhood** | Your local roster — add PAX (with real F3 Nation lookup), track HCs, sponsors, first-post dates. |
| **Profile** | Your real F3 Nation profile (name, roles, home region), achievements, and an on-device-only emergency contact card. |
| **Settings** | Coupon mode (No Coupons / Mixed 50-50 / Coupons Only), intensity filter (Beginner / Intermediate / Advanced). Settings are persisted between launches. |

---

## 50-Minute Timeline

```
5:30 – 5:31   Disclaimer      1 min
5:31 – 5:38   Warm-O-Rama     7 min   ~4 exercises
5:38 – 6:10   The Thang      32 min   ~8 exercises (BW + Coupon split by settings)
6:10 – 6:16   Mary            6 min   ~4 exercises
6:16 – 6:20   COT             4 min   Circle of Trust
──────────────────────────────────────
                              50 min
```

---

## Zero-to-One Setup Walkthrough

This section takes you from a blank laptop to running Digital Weinke on a
physical phone.

### 1 — Install Flutter

1. Visit https://docs.flutter.dev/get-started/install and download the
   **stable** channel SDK for your OS (macOS / Windows / Linux).
2. Unzip to a permanent location, e.g.:
   - macOS: `~/development/flutter`
   - Windows: `C:\src\flutter`
3. Add the `flutter/bin` directory to your `PATH`.

**macOS example (add to `~/.zshrc` or `~/.bash_profile`):**
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

4. Restart your terminal and verify:
```bash
flutter --version
# Flutter 3.x.x • channel stable
```

### 2 — Install VS Code extensions

1. Install [VS Code](https://code.visualstudio.com) if you haven't.
2. Open the Extensions panel (`Cmd+Shift+X` / `Ctrl+Shift+X`).
3. Install:
   - **Flutter** (by Dart Code / Google) — includes the Dart extension
   - **Error Lens** (optional but recommended — inline error display)

### 3 — Install platform SDKs

#### Android
1. Install [Android Studio](https://developer.android.com/studio).
2. Open Android Studio → SDK Manager → install the latest Android SDK
   (API level 34 recommended).
3. Accept SDK licences:
   ```bash
   flutter doctor --android-licenses
   ```

#### iOS (macOS only)
1. Install Xcode from the Mac App Store.
2. Install the command-line tools:
   ```bash
   sudo xcode-select --install
   xcodebuild -runFirstLaunch
   ```
3. Install CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```

### 4 — Run flutter doctor

```bash
flutter doctor
```

Resolve every `[✗]` item before continuing.  A clean output looks like:

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Xcode
[✓] VS Code
[✓] Connected device (2 available)
```

### 5 — Clone / open the project

If you received the project as a folder:
```bash
cd f3_nation_app
code .          # open in VS Code
```

If the downloaded starter is missing native host files such as
`ios/Runner.xcodeproj`, regenerate the Flutter platform wrappers from the
project root before running on a simulator:

```bash
flutter create --project-name f3_nation_app --org com.digitalweinke --platforms=ios,android .
```

This should create the missing iOS/Android build scaffolding while preserving
the existing `lib/`, `assets/`, `test/`, and `pubspec.yaml` app code.

### 6 — Fetch dependencies

```bash
flutter pub get
```

This downloads all packages declared in `pubspec.yaml`:

| Package | Purpose |
|---|---|
| `provider` | State management (settings, timer, tab index) |
| `shared_preferences` | Persist coupon mode + intensity filter |
| `uuid` | Unique IDs for generated plans |
| `wakelock_plus` | Keep screen on during the session |

### 7 — Configure F3 Nation API access

F3 Nation sign-in and live data (map, schedule, publish) need a few
compile-time values, passed via `--dart-define-from-file` so they're never
hardcoded or committed. Create `dart-defines.json` at the project root
(already gitignored):

```json
{
  "F3_OAUTH_CLIENT_ID": "digital-weinke"
}
```

| Key | Required? | Purpose |
|---|---|---|
| `F3_OAUTH_CLIENT_ID` | Yes, for sign-in | The app's registered public OAuth client id. Without it, `LocalAuthService.f3LoginAvailable` is false and the sign-in CTA is hidden — the app still runs, just local-only. |
| `F3_AUTH_ISSUER` | No (defaults to `https://auth2.f3nation.com`) | Override to point sign-in at staging, e.g. `https://staging.auth2.f3nation.com`. |
| `F3_API_BASE_URL` | No (defaults to `https://api.f3nation.com`) | Override to point API reads/writes at staging. Pair with a staging `F3_AUTH_ISSUER` — staging-issued tokens only verify against staging's own JWKS. |
| `F3_API_ORG_ID` | No | A build-time default region, used for national read views before a user has signed in and set their own. |

There is **no API key to configure** — the app has never shipped one. Reads
that must work before sign-in (map/AO browse) go through the F3 API's
public read tier; everything else uses the signed-in PAX's own OAuth
access token.

`make run`/`make build-apk`/`make build-appbundle` already read this file
via `--dart-define-from-file=dart-defines.json`; `flutter run`/`flutter
build` need the flag passed explicitly (see step 8).

### 8 — Connect a device or start a simulator

**iOS Simulator:**
```bash
open -a Simulator      # macOS only
flutter devices        # lists running simulators
```

**Android Emulator:**
```bash
# Open Android Studio → Device Manager → create/start a device
flutter devices
```

**Physical device (both platforms):**
- Android: enable Developer Options → USB Debugging, then plug in via USB.
- iOS: trust the computer on the device prompt; set your Apple Team in
  Xcode (`ios/Runner.xcworkspace` → Signing & Capabilities).

### 9 — Run the app

```bash
make run                                          # reads dart-defines.json, defaults to -d iphone
flutter run --dart-define-from-file=dart-defines.json -d <device-id>
```

The app launches with the home screen showing the 50-minute timeline and
Exicon stats — all 907 exercises are available immediately, no internet
required. F3 Nation sign-in, the live map, schedule, and publish need a
connection and (for sign-in) `F3_OAUTH_CLIENT_ID` configured per step 7.

---

## Running on a Physical Device (Field Test)

Before your first real 5:30 AM beatdown, do one dry run:

1. Install on your Android phone (`flutter build apk --release` → sideload)
   or iOS device (via Xcode / TestFlight — see deployment section).
2. Open the Live tab, tap **START**, and let it run for ~5 minutes.
3. Verify:
   - Screen stays on (wakelock).
   - Phase auto-advances (Disclaimer → Warm-O-Rama after 1 min).
   - Emergency Mary button is visible during The Thang.
   - Timer digits are readable at arm's length in low light.

---

## Building Release Artefacts

Prefer `make build-apk` / `make build-appbundle` over calling `flutter
build` directly — they read `dart-defines.json` (step 7 above, needed for
F3 Nation sign-in to work in the build) and bump the version automatically.
The raw `flutter build` commands below need the same
`--dart-define-from-file=dart-defines.json` flag added, or the resulting
build ships with sign-in disabled.

### Android APK (sideload / Firebase App Distribution)
```bash
make build-apk
# or: flutter build apk --release --dart-define-from-file=dart-defines.json --split-per-abi
# Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Share the `arm64-v8a` APK for modern Android phones.

### Android App Bundle (Google Play)
```bash
make build-appbundle
# or: flutter build appbundle --release --dart-define-from-file=dart-defines.json
```

### iOS (TestFlight — requires Apple Developer Account, $99/year)
```bash
flutter build ipa
# Open Xcode → Organizer → Distribute App → TestFlight
```

---

## CSV Import — Updating the Exicon

The exercise database lives in `assets/data/exercises.json`, generated
from the F3 Exicon CSV export.  Re-run the script whenever the Exicon
is updated.

### Step 1 — Export the CSV

Export from the F3 Exicon / Sanity CMS.  The script expects at minimum:

| Column | Example |
|---|---|
| `ID` | `exicon-1776742880487-0-50-500` |
| `Name` | `Merkin` |
| `Description` | HTML or plain-text description |
| `Aliases` | `push-up` (optional) |

### Step 2 — Run the import script

```bash
# From the project root:
python3 scripts/exicon_csv_to_json.py \
    --input  path/to/f3-codex-export.csv \
    --output assets/data/exercises.json \
    --pretty \
    --stats
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--input / -i` | `f3-codex-export.csv` | Path to CSV export |
| `--output / -o` | `assets/data/exercises.json` | Destination JSON |
| `--pretty` | off | Indent JSON (easier to inspect) |
| `--stats` | off | Print category + intensity counts |

### Step 3 — What the script infers

**Category** — weighted keyword scoring on name + description:

| Category | Key words |
|---|---|
| `warmup` | SSH, mosey, windmill, arm circle, imperial walker… |
| `coupon` | coupon, block, sandbag, kettlebell, dumbbell, plate… |
| `mary` | plank, flutter kick, LBC, crunch, sit-up, ab… |
| `bodyweight` | default; merkin, squat, burpee, lunge, pull-up… |

**Intensity** — same scoring technique:

| Intensity | Key words |
|---|---|
| `beginner` | easy, basic, modified, low impact, hold, half… |
| `advanced` | ruck, ranger, diamond, explosive, pistol, max reps… |
| `intermediate` | everything else (default) |

**Tuning:** Edit the `*_WORDS` lists near the top of
`scripts/exicon_csv_to_json.py` to improve accuracy for your region's
naming conventions.

### Step 4 — Rebuild the app

```bash
flutter pub get   # re-bundles assets
flutter run
```

---

## Project Architecture

> This tree is from the original offline-only MVP and only shows a
> fraction of what's in `lib/` today (35 screens, 29 services as of this
> writing) — notably missing `services/f3_api_service.dart` (F3 Nation API
> client), `services/auth_service.dart` (OAuth/OIDC sign-in), and every
> screen added since (Browse AOs, Schedule, Profile, Brotherhood,
> Achievements, Emergency, and more). Treat `lib/screens/` and
> `lib/services/` themselves as the source of truth; this diagram is kept
> here for the original MVP pieces it still describes correctly.

```
f3_nation_app/
│
├── assets/
│   └── data/
│       └── exercises.json          ← 907 exercises (from Exicon CSV)
│
├── lib/
│   ├── main.dart                   ← App entry point + Provider setup
│   │
│   ├── models/                     ── Pure data, no Flutter dependencies
│   │   ├── exercise.dart           ← Exercise, ExerciseCategory, Equipment, Intensity
│   │   ├── workout_plan.dart       ← WorkoutPlan, WorkoutBlock
│   │   ├── workout_settings.dart   ← CouponMode, WorkoutSettings
│   │   ├── timer_state.dart        ← BootcampPhase, TimerState, TimerStatus
│   │   ├── qsource_data.dart       ← QGuideSection, QGuideEntry, QSourceData (static)
│   │   └── workout_history.dart    ← WorkoutHistory, HistoryBlock + JSON serialization
│   │
│   ├── services/                   ── Business logic, separated from UI
│   │   ├── exercise_service.dart   ← Loads + queries exercises.json
│   │   ├── workout_generator.dart  ← Balanced plan generator + swap logic
│   │   ├── timer_service.dart      ← Phase-aware countdown (ChangeNotifier)
│   │   ├── settings_service.dart   ← Persists settings via shared_preferences
│   │   ├── history_service.dart    ← CRUD history list; persists via shared_preferences
│   │   └── backblast_formatter.dart← Generates Slack-ready backblast text
│   │
│   ├── screens/                    ── One file per top-level screen
│   │   ├── shell_screen.dart       ← Bottom-nav shell (IndexedStack, 6 tabs)
│   │   ├── home_screen.dart        ← Dashboard: timeline, stats, quick actions
│   │   ├── workout_screen.dart     ← Weinke plan generator + per-exercise swap + save
│   │   ├── timer_screen.dart       ← Live phase timer + Emergency Mary + save
│   │   ├── history_screen.dart     ← Session history list + BackblastScreen detail
│   │   ├── library_screen.dart     ← Searchable Exicon with intensity filter
│   │   ├── qsource_screen.dart     ← Q/QSource field guide (collapsible sections)
│   │   └── settings_screen.dart    ← Coupon mode + intensity toggles
│   │
│   ├── widgets/                    ── Reusable UI components
│   │   ├── exercise_card.dart      ← Expandable card with swap support
│   │   ├── category_chip.dart      ← Colour-coded category label
│   │   ├── intensity_badge.dart    ← Colour-coded intensity label
│   │   ├── phase_segment_bar.dart  ← 5-segment visual timeline bar
│   │   └── save_session_sheet.dart ← Modal form to save the current beatdown
│   │
│   └── theme/
│       └── app_theme.dart          ← F3 colour palette + ThemeData
│
├── scripts/
│   └── exicon_csv_to_json.py       ← CSV → JSON import script (Python 3.8+)
│
├── test/
│   ├── exercise_service_test.dart    ← Model + generator unit tests
│   ├── timer_service_test.dart       ← Phase timer unit tests
│   └── workout_history_test.dart     ← History model, JSON round-trip, backblast format
│
├── android/                        ← Android host project
├── ios/                            ← iOS host project
├── pubspec.yaml
└── analysis_options.yaml
```

**Design principle: logic is fully separated from UI.**
`models/` and `services/` have zero Flutter widget imports — they can be
tested in a pure Dart environment and swapped to a different UI framework
without changes.

---

## Running Tests

```bash
flutter test
```

Tests cover:
- `BootcampPhase` — durations sum to 50 min, phase sequence
- `TimerState` — idle defaults, phaseProgress, formattedRemaining
- `TimerService` — start/pause/resume/reset, jumpToMary, advancePhase
- `ExerciseCategory` / `Intensity` — fromString parsing
- `Exercise.fromJson` — complete and partial records
- `WorkoutGenerator` — block structure, category ordering, uniqueness, randomness, coupon modes, swap logic
- `QSourceData` / `QGuideSection` / `QGuideEntry` — section count, entry count per named section, style correctness, construction with/without subtitle, QEntryStyle completeness
- `HistoryBlock` / `WorkoutHistory` — JSON round-trip, missing fields, copyWith, totalCount, paxDisplay, shortDate, photoPath
- `BackblastFormatter` — header fields, exercise sections, truncation, notes, empty-plan fallback, footer

---

## Analyse (lint)

```bash
flutter analyze
```

---

## Colour Palette

| Name | Hex | Usage |
|---|---|---|
| "Badass Black" | `#242A2B` | App background |
| Card surface | `#1E2123` | Cards, sheets, nav bar |
| Elevated surface | `#2C3234` | Control buttons |
| Primary text | `#FFFFFF` | All headings and body |
| Secondary text | `#B0B8BA` | Descriptions, subtitles |
| Muted text | `#6A7375` | Labels, timestamps |
| **F3 Accent** | **`#EE6059`** | **CTA buttons, active phase, Emergency Mary** |
| Warm-Up | `#4CAF50` | Green — warmup phase/category |
| The Thang | `#EE6059` | Red-orange — main workout phase |
| Mary | `#9C6FE0` | Purple — core phase/category |
| COT | `#FFD54F` | Gold — Circle of Trust |
| Coupon | `#FF9800` | Orange — coupon category |

---

## Deployment Options for Your F3 Team

### Android — Firebase App Distribution (free, easiest)
1. Create a Firebase project at https://console.firebase.google.com
2. Install the Firebase CLI: `npm install -g firebase-tools`
3. Build: `make build-apk` (reads `dart-defines.json` — see step 7 of the
   setup walkthrough; a plain `flutter build apk --release` ships with F3
   Nation sign-in disabled)
4. Upload:
   ```bash
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app <your-firebase-app-id> \
     --groups "f3-pax"
   ```
5. PAX install the Firebase App Tester app and accept the invite email.

### iOS — Apple TestFlight
1. Enrol in the Apple Developer Program ($99/year) at
   https://developer.apple.com/programs/
2. Build: `flutter build ipa`
3. Upload via Xcode Organizer → Distribute → TestFlight.
4. PAX install the TestFlight app and accept your invite.

---

## Workout History + Backblast

### How it works

1. Generate a Weinke on the **Weinke** or **Live** tab.
2. Tap the **save icon** (top-right of the AppBar) to open the "Save Beatdown" sheet.
3. Fill in Title, AO, Q Name, PAX names (comma-separated), FNG count, and optional notes. Tap **Save Session**.
4. The session appears in **Beatdown History** — accessible from the Home quick-actions card or directly via the History screen.
5. Tap any session to open its **Backblast** view. Either **Publish** it to F3 Nation (writes the real backblast, attendance, and FNG count to the event, if signed in and it's linked to one) or **Copy to Clipboard** for Slack/email/anywhere else.

### Privacy note — what's synced vs. local-only

- Signed in, a published backblast, attendance, HC, Q, and preblast all go to F3 Nation's real API, using your own OAuth access token — never a key shared across every install.
- Your saved session's own notes, plan summary, and local history list stay **only on the device** (`shared_preferences`), whether or not you ever publish.
- Emergency info is **mostly local-only**, readable from the login gate with no network or sign-in: it all lives in the device's secure storage first. Signed in, most fields additionally best-effort sync to F3 Nation — contact name/phone/notes to real profile columns, blood type/allergies/conditions/medications/preferred hospital/organ donor to the profile's freeform `meta` field. AO-site fields (nearest ER, AED location, EMS access notes) stay local-only always — they're per-location safety data, not yours to sync.
- No Slack OAuth, no webhooks — a backblast reaches Slack only indirectly, via F3 Nation's own existing Slack integration once published, or by pasting the clipboard copy yourself.
- To delete data: swipe open a session in History and delete it, or use the trash icon to wipe all sessions at once.
- Clearing the app's local storage (or uninstalling) permanently removes all history.

### Backblast format

```
*BackBlast: Saturday Storm*
Date: Sat Mar 15 2025
AO: Shovel Flag Park
Q: Dredd
PAX: Mayhem, Roscoe
FNG: 1
Count: 3

*The Thang:*
- *Warm-O-Rama* (7 min): SSH, Don Quixote, Windmill
- *The Thang — Bodyweight* (20 min): Merkin, Squat
- *The Thang — Coupons* (12 min): Curls for the Girls, Overhead Press
- *Mary* (6 min): LBC, Flutter

_Disclaimer given. COT held._

*Notes:*
Cold and windy but zero quitters.

_Generated by Digital Weinke — F3 local-first beatdown planner_
```

The `*bold*` and `_italic_` markers render in Slack. Paste as-is.

---

## Roadmap

Several items from the original MVP roadmap have since shipped — AO
map/geolocation, scheduling (HC/Q/calendar), Exicon demo videos (via live
Codex sync), a custom Weinke builder (Q Builder), per-exercise interval
timing, and light/dark mode are all in the app today, not listed below.
Still open:

1. **PAX photo capture** — attendance recording is real (HC/Q/actual
   attendance write to F3 Nation); attaching a group photo to a backblast
   isn't built yet.
2. **Cadence assistant** — haptic vibration or audio cue every rep. (Q Field
   Guide cadence section is the text-based v1.)
3. **AAR / feedback checklist** — structured After Action Review screen to
   capture what worked and what to improve after each beatdown or QSource
   session.
4. **Official logo / brand assets** — add only after confirming F3 logo and
   branding usage permissions. Until then, use text branding and
   F3-inspired colors.
5. **QSource scheduling / reminders** — plan and receive local push
   notifications for upcoming QSource sessions.
6. **Region Chat / Commz** — the F3 Nation API has no chat/messaging layer
   yet; the in-app Region Chat UI is a local-only preview pending a
   Slack-bridge or native backend on F3 Nation's side.
7. **Apple Watch companion** — mirror the phase timer on watchOS.
8. **Voluntary donation / tip jar** — support infrastructure while keeping
   F3 workouts free.
9. **Nationwide Q-sharing** — publish and discover beatdowns from other
   regions (a single shared-plan import/export already exists; this would
   make it a public, searchable feed).

---

## Q / QSource Field Guide

This app includes an **unofficial condensed Q and QSource field guide**
(`lib/screens/qsource_screen.dart`, `lib/models/qsource_data.dart`)
derived from user-supplied F3 PAX materials.  It covers:

- Five F3 Workout Principles
- Standard disclaimer text
- Sample 50-minute workout structure
- Q prep checklist
- Cadence call sequence
- COT checklist
- Backblast template
- QSource best practices, agenda, follow-up, and session formats

> **Important:** Before public or nationwide distribution of this app,
> please verify permission, branding compliance, and content accuracy
> with appropriate F3 Nation leadership.  The guide is provided in good
> faith as a practical field reference, not as an official F3 publication.

---

## F3 Nation

> Free. For men. In the gloom.

https://f3nation.com · https://f3nation.com/resources/exicon

*This app is an unofficial utility built by PAX, for PAX.*

---

## Q Workflow: Draft → Start → Live → Save

This is the intended end-to-end Q flow for a beatdown session:

### 1. Draft on the Weinke Tab

Open the **Weinke** tab. A plan is automatically generated on first launch.

| Control | What it does |
|---|---|
| **Shuffle icon (AppBar)** | **Regenerate** — reshuffles exercises for the current draft using your current settings. Does *not* clear history or disrupt any in-progress Live session. |
| **New Beatdown (bottom bar)** | Clears the current draft and generates a completely fresh plan. Use when starting over from scratch before the workout begins. |
| **Swap (per exercise)** | Replace one exercise with another of the same category. |
| **Save icon (AppBar)** | Save the draft plan to your local Beatdown History (useful for planning ahead). |

### 2. Start the Workout

When you're happy with the plan, tap **START WORKOUT** (bottom right of the Weinke tab). This:
- Accepts the draft as the *live plan* (stored in `CurrentWorkoutService`).
- Navigates automatically to the **Live** tab.
- Resets the exercise index to position 0.

### 3. Run the Session on the Live Tab

The Live tab shows the accepted plan from Weinke and never auto-generates its own.

| Control | What it does |
|---|---|
| **START / PAUSE / RESUME** | Primary timer control. |
| **Next Ex** | Advance to the next exercise *within* the current phase. Dots update in real time. |
| **Phase ▶** | Skip to the *next phase* early (Disclaimer → Warm-O-Rama → The Thang → Mary → COT). Resets exercise index for the new phase. |
| **EMERGENCY MARY** | Shown during Disclaimer, Warm-O-Rama, and The Thang. Immediately jumps the timer to the Mary phase. Confirmation dialog prevents accidental taps. |
| **Swap Exercise** | Replace the currently displayed exercise mid-workout. |
| **Reset** | Reset the timer to idle (does not clear the live plan). |
| **Save icon (AppBar)** | Save the live plan to Beatdown History at any point. |

**Empty state:** If you navigate to Live without having tapped "Start Workout" first, you'll see a prompt: "Build a Weinke first" with a button to go to the Weinke tab.

### 4. Save & Backblast

After the workout, tap the **save icon** on either tab. Fill in AO, Q name, PAX names, FNG count, and notes. The session is saved locally. Open **Beatdown History** from the Home tab or History screen to view and copy a Slack-ready backblast.

---
