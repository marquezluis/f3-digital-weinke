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
  static const String current = '2.4.0';
  static const String versionName = '2.4.0';
  static const String buildNumber = '12';
  static const String displayName = 'Digital Weinke v2.4.0';
  static const String fullDisplayName = 'Digital Weinke v2.4.0+12';

  static const List<AppRelease> releases = [
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