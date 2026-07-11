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
  static const String current = '2.2.0';
  static const String versionName = '2.2.0';
  static const String buildNumber = '6';
  static const String displayName = 'Digital Weinke v2.2.0';
  static const String fullDisplayName = 'Digital Weinke v2.2.0+6';

  static const List<AppRelease> releases = [
    AppRelease(
      version: '2.2.0',
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
        'Exicon library no longer shows a gray background.',
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