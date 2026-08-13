// lib/models/app_version.dart
// Centralized app versioning and release notes.

class AppRelease {
  final String version;
  final String title;
  final String summary;
  final List<String> newItems;
  final List<String> enhancements;
  final List<String> bugFixes;

  const AppRelease({
    required this.version,
    required this.title,
    required this.summary,
    this.newItems = const [],
    this.enhancements = const [],
    this.bugFixes = const [],
  });
}

class AppVersion {
  // NOTE: `make build-apk`/`build-appbundle` auto-bump pubspec.yaml's version
  // on every build (scripts/bump_version.py) — this class does NOT read that
  // automatically, since release notes are hand-written prose. Update these
  // four constants and add a new AppRelease entry below whenever you want a
  // build's changes to actually show up in the in-app Release Log.
  static const String current = '2.5.0';
  static const String versionName = '2.5.0';
  static const String buildNumber = '28';
  static const String displayName = 'Digital Weinke v2.5.0';
  static const String fullDisplayName = 'Digital Weinke v2.5.0+28';

  static const List<AppRelease> releases = [
    AppRelease(
      version: '2.5.0',
      title: 'The Big One',
      summary:
          'A full pass on onboarding, Home, Brotherhood Board, and Settings, plus two real F3 Nation integrations — live Codex sync and a native admin screen — driven by a 100-item UX audit.',
      newItems: [
        'Region Chat — a channel-aware chat screen (#general + one per AO), the local-only half of the planned Slack bridge; messages stay on-device until the relay exists.',
        'Home redesign around one dominant "Today" hero (Q\'ing, HC\'d, or a prompt to find a beatdown), a 10-week activity strip, PAX of the Quarter, this month\'s region recap, a guided first-week "Founding Quest" with a badge, and a global search box across the Exicon, Q Field Guide, and AOs at once.',
        'Live Codex sync — pulls demo videos and confirms which exercises are Official vs. Pending directly from F3 Nation\'s real, live Exicon.',
        'Native admin screen — edit an AO\'s Location (name, address, lat/long, active status) right in the app, writing to the real F3 Nation admin API, gated to editor/admin roles.',
        'F3 Nation Links in Settings — Map, Near Me, F3 Me, PAX Vault, the Codex, Org Chart, plus role-gated Admin Tools.',
        'F3 Moments — a chronological timeline of every Pic-o-Rama photo across every AO.',
        '"F3 Near Me Right Now" — beatdowns starting within the hour, sorted by distance.',
        '"I\'m at the flag" — a one-tap personal check-in for today (not a broadcast, just saves re-typing the AO when you save a backblast).',
        'Real Circle of Trust capture during Q Mode — live note-taking that pre-fills the backblast\'s COT field instead of relying on memory.',
        'App Lock now has a real toggle in Settings → Safety, not just a one-time onboarding choice.',
        'TTS voice preview — hear a sample before picking a voice.',
        'QSource bookmarking plus a recently-viewed quick-jump row.',
        'Shareable achievement cards and a share-as-image option for preblasts.',
        'F3 Lingo glossary (Q, PAX, AO, HC, EH, FNG, COT…) from onboarding and Settings.',
        'Sign-in screen now shows a real, live AO count, and a "See AOs near you first" preview so you can browse before creating an account.',
        'A brand-new onboarding illustration (original artwork) and a small celebration on completing setup.',
      ],
      enhancements: [
        'Language now defaults to your device\'s own locale and theme to System, instead of forcing a choice up front — the picker\'s still in Settings if you want it.',
        'Daily mottos are now translated into Spanish and French, and dates across the app are locale-aware instead of always showing English month names.',
        'The "Community" tab is now "Fellowship," matching F3\'s own language.',
        'HC/un-HC now respond instantly instead of waiting on the network.',
        'Destructive actions (deleting a custom exercise, achievement, EH prospect, or importing a backup) now confirm first, consistently.',
        'Headings and the app\'s wordmark now use a distinct display typeface instead of the same system font as everything else.',
        'Publishing a backblast, HC\'ing, and other key actions now give haptic feedback on success or failure.',
      ],
      bugFixes: [
        'A real streak-calculation bug: a perfectly consistent PAX\'s streak could silently reset to zero the moment a new week began, before they\'d had a chance to post yet.',
        'Home\'s Quick Start row could overflow when all three actions showed together.',
        'Schedule\'s "Mine" filter could silently clear itself when reopened and dismissed without a new choice.',
        'The installed app name no longer implies official F3 Nation branding ahead of actual approval.',
        'Several silent failures now show real feedback: a failed music-app launch, a failed Exicon external link, a failed F3 Nation sign-in.',
        'Accessibility: a text-clipping bug in Home\'s identity row at large text sizes, and missing screen-reader labels on Q Mode\'s EMOM/Tabata steppers.',
      ],
    ),
    AppRelease(
      version: '2.4.15',
      title: 'The Region Chat Preview',
      summary:
          'A first look at Region Chat on the Brotherhood Board — a Digital Weinke-native message screen for your region, ahead of the Slack bridge that will actually connect it.',
      newItems: [
        'Region Chat — a new card on the Brotherhood Board opens a message list and compose box for your region. It\'s a local-only preview right now: messages stay on this device and don\'t reach anyone yet, clearly marked as such, until the Slack-bridge relay service lands.',
      ],
    ),
    AppRelease(
      version: '2.4.12',
      title: 'Renamed to Digital Weinke',
      summary:
          'The app is now called Digital Weinke instead of F3 Nation App — it isn\'t an officially approved F3 Nation app yet, and the name shouldn\'t imply otherwise.',
      bugFixes: [
        'App display name, icon label, and bundle metadata updated across Android and iOS to Digital Weinke.',
      ],
    ),
    AppRelease(
      version: '2.4.11',
      title: 'The Offline Resilience & Q Toolkit Update',
      summary:
          'Automatic backups, a smarter plan generator that avoids repeating recent exercises, an EH prospect tracker, Co-Q plan sharing, and a handful of other Q-toolkit additions.',
      newItems: [
        'Automatic rotating local backups — a silent weekly safety-net snapshot, restorable from Settings → Data.',
        '"Haven\'t used lately" recency bias in plan generation — the Weinke builder and Q Builder wizard now favor exercises you haven\'t run recently instead of repeating the same handful.',
        'Co-Q collaborative draft sharing — export a beatdown plan as an importable code for a Co-Q, and import one shared with you.',
        'Slack channel confirmation — after publishing a preblast or backblast, the app confirms which Slack channel it posted to.',
        'EH Prospect tracker on the Brotherhood Board — separate from FNG Pipeline, for tracking people you\'ve talked to but who haven\'t posted yet.',
        'Weather-aware Q Builder — flag rain/ice/heat conditions and get a plan warning tailored to it (e.g. rain → avoid slick pull-up bars).',
        'Offline-cached Spartan AI plan fallback — if Spartan can\'t reach the network, it falls back to a recent cached plan instead of just failing.',
        'Site-Q custom local achievements — define your own achievement badges (sessions at an AO, unique PAX, FNGs welcomed) alongside the built-in ones.',
        'A small bank of mumblechatter lines Q Mode can call out mid-session.',
      ],
    ),
    AppRelease(
      version: '2.4.10',
      title: 'The AO Logos & Full Profile Update',
      summary:
          'AO logos on Browse AOs and beatdown details, your full F3 Me profile (roles, positions, name origin, why), and a couple of real bug fixes.',
      newItems: [
        'AO logos now show on Browse AOs and a beatdown\'s detail sheet, pulled from F3 Nation\'s real org data (falls back to the shield icon for AOs that haven\'t uploaded one).',
        'Your Profile now shows F3 Name Origin, My F3 Why, and your Roles/Positions across F3 Nation regions — the same info the real F3 Me site shows, not just name/phone/avatar.',
      ],
      bugFixes: [
        'Schedule\'s "Mine" filter pill was silently clearing your selection if you reopened it and dismissed it without picking anything.',
        'Home\'s Quick Start row ("Last Plan" button) could overflow its width when all three quick-start actions were showing.',
      ],
    ),
    AppRelease(
      version: '2.4.3',
      title: 'The Pic-o-Rama Update',
      summary:
          'Capture and share photos from your beatdowns, richer TTS callouts, and a batch of history/community polish.',
      newItems: [
        'Pic-o-Rama — snap or pick photos when saving a session, view them on Heatmap days and per-AO on Browse AOs, and share them alongside your backblast text.',
        'Share any past beatdown as a shareable image card, not just plain text.',
        'A per-block "call style" (In Cadence / On Your Own / On My Up / On My Down) you set while building — the live timer now announces it before each exercise.',
        'Achievement unlocks now get a real celebration (confetti) instead of just showing up quietly in the Achievements list.',
        'History has a Favorites filter for your thumbs-up sessions.',
        'A "this month vs last month" comparison (sessions, FNGs, coupon sessions) on the Heatmap screen.',
        'Share your emergency medical info to a fellow PAX before a hard workout.',
      ],
      enhancements: [
        'Posting a preblast now auto-sets your event reminder, the same as HC\'ing or taking Q already did.',
        'The live rep counter, if you used it, now carries over into the backblast notes instead of being lost when you save.',
        'TTS voice now follows the app\'s language setting (English/Spanish/French) instead of always speaking English.',
        'The Weinke builder\'s time-budget bar accounts for real per-exercise timing on custom exercises instead of a generic estimate.',
      ],
    ),
    AppRelease(
      version: '2.4.2',
      title: 'The Weinke-to-Preblast Update',
      summary:
          'Build a Weinke for a real beatdown and use it as the preblast, a smarter Add Exercise flow, and the beatdown summary now stays on screen while you scroll.',
      newItems: [
        'Beatdowns you\'re Q\'d for now have a "Build my Weinke" button — build the plan, then "Use as Preblast" hands it straight to the preblast composer with the plan and coupon status already filled in.',
        'Add Exercise replaces the old random-only button: search by name, filter by category, randomize, or write a custom exercise — all from one sheet.',
        'Writing a custom exercise now asks for an approximate time per set, shown alongside it wherever it\'s listed.',
        'A new "Mixed — Same Block" coupon option interleaves bodyweight and coupon exercises together in one Thang block, alongside the existing separate-blocks Mixed mode.',
      ],
      enhancements: [
        'The beatdown summary card (exercise/block count, time budget) stays pinned at the top of the Weinke builder instead of scrolling out of view.',
        'The coupon-mix dropdown is now labeled "Coupons in The Thang" instead of "Equipment" so it\'s actually easy to find.',
        'This release log now shows the 3 most recent versions with a "Show more" button instead of the entire history at once.',
      ],
    ),
    AppRelease(
      version: '2.4.1',
      title: 'The Directions & Structured Preblast Update',
      summary:
          'Get directions to any beatdown, a guided preblast composer, and a batch of real bug fixes caught against live F3 Nation data.',
      newItems: [
        'A directions button on any beatdown\'s detail sheet opens your maps app pointed at the AO\'s real address.',
        'Posting a preblast is now a short form instead of a blank box — date, time, AO, Q, and the live HC list fill in automatically; you just write the plan.',
        'Schedule has a "Mine" filter (HC\'d / Q\'ing / both), and Home\'s "See all" link jumps straight into it pre-filtered.',
        'The app now notices when your F3 Nation session actually died (not just a bad connection) and routes you back to sign-in automatically.',
      ],
      bugFixes: [
        'The region picker in Settings/Profile was actually crashing on real data, not just slow.',
        'Notifications were silently broken in release builds due to how the app was packaged — fixed.',
        'Preblasts posted from the app weren\'t showing up as posted anywhere that checks for one — fixed.',
      ],
    ),
    AppRelease(
      version: '2.4.0',
      title: 'The Schedule, Map & Notifications Update',
      summary:
          'A real calendar for Schedule, HC/Q reminders, a map view for Browse AOs, and a full F3 Nation profile screen.',
      newItems: [
        'Schedule now has a month calendar (the default view) with a 7-day agenda underneath — tap any date to see just that day, with AO/type filters and HC/take-Q/preblast actions right from the event card.',
        'Reminders for anything you\'re HC\'d or Q\'d for — a day before, an hour before, and a nudge to post the backblast afterward if you were Q.',
        'Browse AOs has a map view — AOs plotted on the map, numbered to match the list below, centered on your location.',
        'Full F3 Nation profile screen (tap your name/avatar) — edit your name/email/phone, sign out, and change region, all in one place.',
        'Emergency info is now tied to whoever\'s actually signed in, so a device shared between PAX never shows the wrong person\'s medical info.',
      ],
      enhancements: [
        'Home\'s Upcoming Beatdowns is a single card: how many you\'re HC\'d for, the next one, and a link to see them all — with a small dot row when they\'re spread across more than one week.',
        'Onboarding now tells you up front that the app will ask for location and notification permission.',
        'Faster, clearer location lookup on Browse AOs, plus a dedicated recenter button on the map.',
      ],
      bugFixes: [
        'Change Region picker was silently showing no results.',
        'Signing out from your Profile could strand you on a blank screen instead of returning to sign-in.',
        'Browse AOs map freezing on load, and going blank after applying a filter.',
        'Schedule\'s calendar could get stuck on a different month than the agenda underneath it after backing out of a selected day.',
      ],
    ),
    AppRelease(
      version: '2.3.0',
      title: 'The F3 Nation Integration Update',
      summary:
          'Sign in with your F3 Nation account, browse AOs near you, full official event types and tags, and the Deck of Pain game mode.',
      newItems: [
        'Sign in with F3 Nation (Settings → F3 Nation Account) — secure OAuth login against the F3 Nation auth server, ready to activate once client registration completes.',
        'Browse AOs (Settings → Explore) — real F3 Nation AOs from the live API, sorted by distance when you allow location, tap to open in your maps app.',
        'Deck of Pain (Settings → Explore) — draw from a full 52-card deck; suit picks the exercise, rank picks the reps. Suit-to-exercise mapping is editable to match your AO\'s tradition.',
        'Event tags on saved sessions — VQ, Convergence, F3versary, Pre-Workout, and Off-The-Books, included in the backblast under EVENT TAG.',
        'Five new beatdown types matching F3 Nation\'s full official list: QSource, Mobility, Gear, Wild Card, and Sports.',
      ],
      enhancements: [
        'Beatdown types now map exactly to F3 Nation\'s official event_type values behind the scenes, ready for publishing backblasts through the F3 Nation API.',
        'History cards show distinct badge colors and icons for all ten beatdown types.',
      ],
    ),
    AppRelease(
      version: '2.2.4',
      title: 'F3 Nation Beatdown Types',
      summary: 'Beatdown type now matches F3 Nation\'s official event categories — Boot Camp, Ruck, Run, Bike, Swim, or Other.',
      newItems: [
        'Beatdown type picker in the Save Session sheet (Boot Camp, Ruck, Run, Bike, Swim, Other).',
        'Type badge on each history card for at-a-glance identification.',
        'Beatdown type included in the backblast text under WORKOUT TYPE.',
        'Type shown in the beatdown detail view.',
      ],
    ),
    AppRelease(
      version: '2.2.3',
      title: 'F3 Nation Slack Integration',
      summary: 'Post backblasts directly to your region\'s Slack via the F3 Nation API — no webhook setup needed.',
      newItems: [
        'Post backblasts to Slack via the F3 Nation app (Settings → Slack Integration → Channel ID).',
        'Falls back to Incoming Webhook URL if API key is not configured.',
      ],
    ),
    AppRelease(
      version: '2.2.2',
      title: 'The Polish Update',
      summary: 'Venezuelan flag, cleaner TTS voice picker, and branded music provider icons.',
      bugFixes: [
        'Venezuelan flag (🇻🇪) now shows correctly for Español in the language picker.',
        'TTS voice picker now shows only English voices with friendly numbered labels (e.g. "English (US) — Voice 1").',
        'Music provider dropdown now shows real brand-colored icons for Spotify, Apple Music, YouTube Music, and Amazon Music.',
      ],
    ),
    AppRelease(
      version: '2.2.1',
      title: 'The Rounds & Timer Fix Update',
      summary: 'Rounds now scale total workout time and the live timer. API key secured at build time.',
      bugFixes: [
        'Rounds correctly scale plan total time in the budget bar and per-block label.',
        'Live timer phase durations now reflect rounds — no longer hardcoded at 50 minutes.',
        'Halfway alert fires at the true session midpoint, not always at 25 minutes.',
        'API key removed from Settings UI — secured as a build-time constant.',
      ],
      newItems: [
        'Spartan Co-Q hero screen — shield, capability chips, and 2-column prompt grid on empty state.',
        'Home screen upcoming beatdowns carousel from F3 Nation API.',
        'Brotherhood Add PAX sheet: look up any PAX by F3 name from the F3 Nation directory.',
        'Venezuelan flag in language picker.',
      ],
      enhancements: [
        'Full light/dark theme across all screens via F3ThemeX context extension.',
      ],
    ),
    AppRelease(
      version: '2.2.0',
      title: 'The F3 Nation Connect Update',
      summary: 'F3 Nation API integration, full light theme, Exicon crash fix, and app icon.',
      newItems: [
        'F3 Nation API integration — API key secured at build time.',
        'Test your connection and pull your F3 profile (name, region) directly from F3 Nation.',
        'Full light theme — all screens, cards, and text respond correctly to Dark/Light/System.',
        'App icon — custom F3 shield, applied to Android and iOS.',
        'Language picker now shows Venezuelan flag for Español.',
      ],
      enhancements: [
        'Theme selector: Dark, Light, or System in Settings → Appearance.',
        'TTS voice names are now human-readable.',
        'Settings → F3 NATION section for API key management.',
        'Version is now synced between pubspec and in-app display.',
      ],
      bugFixes: [
        'Exicon library gray screen fixed — unmodifiable list sort crash resolved.',
        'Exicon filters and sort now work correctly after the fix.',
      ],
    ),
    AppRelease(
      version: '2.1.1',
      title: 'The Polish & Spartan Fix Update',
      summary: 'Spartan AI connection restored, new artwork, theme picker, and UI improvements across the board.',
      newItems: [
        'Spartan Co-Q is back — upgraded to Gemini Flash model.',
        'Custom Spartan helmet illustration in the chat screen.',
        'F3 Nation shield on the welcome and lock screens.',
        'Theme selector: Dark, Light, or System.',
        'Music player now asks before launching and tells you how to return.',
        'Version changelog — you\'re reading it!',
      ],
      enhancements: [
        '7-tab navigation with Spartan and Settings as dedicated tabs.',
        'Q Mode at center position for fast gloom access.',
        'Rest timer is now opt-in (toggle in Q Mode AppBar).',
        'TTS voice names are now human-readable.',
        'Contextual TTS callouts: "Starting Warm-O-Rama", "Next exercise: X".',
        'Settings shows your F3 name, Home AO, and role at the top.',
        'Snackbars are floating with rounded corners.',
        'Nav bar has a separator and improved 7-icon layout.',
      ],
      bugFixes: [
        'Q Field Guide now opens correctly.',
        'Rest timer clears properly when tapping Next.',
        'Welcome screen no longer auto-prompts biometric on open.',
        'App launch stays dark during entire startup sequence.',
      ],
    ),
    AppRelease(
      version: '2.1.0',
      title: 'The Brotherhood & Accessibility Update',
      summary: 'Huge expansion adding local PAX tracking, custom exercises, Slack integration, and voice callouts.',
      newItems: [
        'Brotherhood Dashboard: Track your local AOs, PAX directory, Hard Commits (HCs), and recent attendance.',
        'Achievements System: Earn badges based on your local workout history and consistency.',
        'Activity Heatmap: Visualize your workout frequency over the past 52 weeks.',
        'Custom Exercises: Build and save your own custom exercises locally to the Exicon.',
        'Slack Paste Integration: Auto-extract AO, Q, PAX, and FNGs from Slack preblasts/backblasts directly into the Save Beatdown form.',
      ],
      enhancements: [
        'Voice & Accessibility: Optional TTS voice callouts for phase changes and exercises.',
        'Reduced Motion toggle to disable non-essential animations for accessibility.',
        'Exercise Management: Added the ability to Favorite and Blacklist exercises from the Exicon.',
        'Various UI polish and bug fixes across the app.',
      ],
    ),
    AppRelease(
      version: '2.0.0',
      title: 'The Spartan AI & Super-App Update',
      summary: 'Major update introducing AI features and circuit mode.',
      newItems: [
        'Added "Spartan" AI Co-Q Chatbot to generate audibles, custom workouts, and FNG names.',
        'Pre-workout Beatdown Auditor powered by Gemini AI to review your Weinke for safety and flow.',
        'Auto-Backblast Scribe: AI generates a Slack-ready backblast from your session history.',
        'Offline Q-Builder Wizard to create custom beatdowns based on time, theme, and equipment.',
        'Circuit Mode: Auto-scales time based on number of circuits and adds rest blocks.',
        'Interactive animated exercise demo placeholders for visual guidance.',
      ],
      enhancements: [
        'Intelligent "Swap Down" logic for active recovery when swapping exercises.',
        'Consolidated Live Timer controls (Previous, Play/Pause, Next) with smart phase navigation.',
      ],
    ),
    AppRelease(
      version: '1.1.0',
      title: 'Tracking & Customization',
      summary: 'Added session history and exercise filtering.',
      newItems: [
        'Save completed beatdowns locally to device history.',
        'One-tap Backblast generation with Slack formatting.',
      ],
      enhancements: [
        'Exercise filtering by intensity (Beginner, Intermediate, Advanced) and coupon requirements.',
        'Added F3-branded Dark Mode UI enhancements for better 5:30 AM visibility.',
      ],
    ),
    AppRelease(
      version: '1.0.0',
      title: 'The Digital Weinke Foundation',
      summary: 'Initial release of the Digital Weinke.',
      newItems: [
        'Local-first, completely offline Flutter app for the Gloom.',
        'Full F3 Exicon library mapped with 900+ searchable exercises.',
        'Automated 50-minute balanced Beatdown generator.',
        'Phase-aware countdown timer (Warm-O-Rama, Thang, Mary, COT).',
        'Offline QSource and Q-Prep field guide.',
      ],
    ),
  ];

  static List<Map<String, dynamic>> get changelog {
    return releases.map((r) => {
      'version': r.version,
      'title': r.title,
      'changes': [
        ...r.newItems,
        ...r.enhancements,
        ...r.bugFixes,
      ],
    }).toList();
  }
}