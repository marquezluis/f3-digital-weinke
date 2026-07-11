# Digital Weinke

> The Q's cheat sheet — digitized.

A local-first Flutter app for F3 Nation that generates a balanced 50-minute
beatdown plan, runs a phase-aware countdown timer, and gives you instant
access to the full F3 Exicon — all without a network connection.

---

## What it does

| Feature | Description |
|---|---|
| **Workout Generator** | Randomly builds a 50-min beatdown from the full Exicon (907 exercises). Respects your coupon mode and intensity preferences. Every exercise can be swapped with one tap. |
| **Live Phase Timer** | Five-phase countdown that auto-advances: Disclaimer → Warm-O-Rama → The Thang → Mary → COT. Big glanceable digits for 5:30 AM. |
| **Emergency Mary** | One tap skips straight to Mary from any phase. Confirmation dialog prevents accidental taps with sweaty/gloved hands. |
| **Disclaimer & COT screens** | Phase-specific cards: the standard F3 disclaimer text and a step-by-step COT guide (Count-O-Rama, Name-O-Rama, FNG naming, announcements, closing word). |
| **Q Field Guide** | Offline reference tab covering all aspects of Q prep and QSource: Five F3 Workout Principles, standard disclaimer, sample workout structure, Q prep checklist, cadence call sequence, COT checklist, backblast template, QSource best practices, QSource agenda, QSource follow-up checklist, and QSource session formats. |

| **Exicon Library** | All 907 exercises, searchable by name/description/alias. Filter by category tab and intensity level. |
| **Workout History** | Saves completed beatdowns locally. Records title, date, AO, Q name, PAX list, FNG count, plan summary, and notes. Sorted newest-first. All data stays on device. |
| **Backblast Draft** | Auto-generates a Slack-ready backblast from any saved session. One tap copies the full text to clipboard for pasting into Slack or email. |
| **Settings** | Coupon mode (No Coupons / Mixed 50-50 / Coupons Only), intensity filter (Beginner / Intermediate / Advanced). Settings are persisted between launches. |
| **Offline-first** | Zero network calls. All data is bundled as a JSON asset or stored in `shared_preferences`. |

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

### 7 — Connect a device or start a simulator

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

### 8 — Run the app

```bash
flutter run                         # runs on the first available device
flutter run -d "iPhone 15"         # specific simulator
flutter run -d <device-id>         # specific physical device
```

The app launches with the home screen showing the 50-minute timeline and
Exicon stats. All 907 exercises are available immediately — no internet
required.

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

### Android APK (sideload / Firebase App Distribution)
```bash
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Share the `arm64-v8a` APK for modern Android phones.

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
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
3. Build: `flutter build apk --release`
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
5. Tap any session to open its **Backblast** view. Tap **Copy to Clipboard** and paste directly into Slack, email, or any messaging app.

### Privacy note — local-only storage (MVP)

- All history data (PAX names, AO, notes, and any future photo paths) is stored **only on the device** using `shared_preferences`.
- Nothing is uploaded to any server, Slack workspace, or third-party service.
- No Slack OAuth, no webhooks, no cloud sync in this version.
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

The MVP is intentionally micro-first.  Future versions could add:

1. **PAX attendance + photo capture** — check off who posted, optionally attach a group photo, and reuse that data for the backblast.
2. **Exercise images/videos** — short demo clips for each Exicon entry. Start with optional URL fields in the local JSON, then add embedded/streamed demos later.
3. **Cadence assistant** — haptic vibration or audio cue every rep. (Q Field Guide cadence section is the text-based v1.)
4. **Custom Weinke builder** — manually pick exercises per block before the session.
5. **AAR / feedback checklist** — structured After Action Review screen to capture what worked and what to improve after each beatdown or QSource session.
6. **Light / dark mode** — keep dark mode as the 5:30 AM default, then add a high-contrast light theme for daytime planning.
7. **Official logo / brand assets** — add only after confirming F3 logo and branding usage permissions. Until then, use text branding and F3-inspired colors.
8. **QSource scheduling / reminders** — plan and receive local push notifications for upcoming QSource sessions.
9. **Per-exercise interval timer** — countdown inside each exercise slot.
10. **Slack webhook posting** — opt-in: PAX connects their Slack workspace and the app posts the backblast automatically. Requires Slack OAuth + a backend (or Slack's incoming webhook URL stored locally).
11. **AO map / geolocation** — show nearby AOs and their schedules.
12. **Scheduling** — plan beatdowns in advance with calendar integration.
13. **Firebase/Supabase sync** — optional cloud backup so Q plans, attendance, photos, and Slack settings survive a phone swap.
14. **Apple Watch companion** — mirror the phase timer on watchOS.
15. **Voluntary donation / tip jar** — support infrastructure while keeping F3 workouts free.
16. **Nationwide Q-sharing** — publish and discover beatdowns from other regions.

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
