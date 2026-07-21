// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Digital Weinke';

  @override
  String get appTagline =>
      'The digital Q sheet for the modern PAX.\nBuild Weinkes, run Q Mode, track your crew — all offline, all yours.';

  @override
  String get welcomeSetupProfile => 'SET UP YOUR PROFILE';

  @override
  String get welcomeF3Name => 'F3 Name (optional)';

  @override
  String get welcomeF3NameHint => 'e.g. Dredd, Mayhem, Roscoe';

  @override
  String get welcomeHomeAo => 'Home AO (optional)';

  @override
  String get welcomeHomeAoHint => 'e.g. The Patriot';

  @override
  String get welcomeRegion => 'Region (optional)';

  @override
  String get welcomeRegionHint => 'e.g. F3 Kansas City';

  @override
  String get welcomeYourRole => 'YOUR ROLE';

  @override
  String get welcomePrivacy =>
      'Your profile stays on this device. Nothing is sent anywhere unless you choose to share it.';

  @override
  String get welcomeProtectApp => 'Protect This App';

  @override
  String get welcomeProtectAppDesc =>
      'Use Face ID, fingerprint, or device PIN on open.';

  @override
  String get welcomeProtectNotAvailable =>
      'Device lock is not available on this device.';

  @override
  String get welcomeCta => 'LOCK IN — LET\'S GO';

  @override
  String get welcomeCtaLoading => 'LOADING...';

  @override
  String get welcomeSubtext => 'EH · MODIFY · MOSEY';

  @override
  String get roleQName => 'Q (Workout Leader)';

  @override
  String get roleQDesc =>
      'I plan and lead beatdowns. I need full Weinke-building tools.';

  @override
  String get rolePaxName => 'PAX';

  @override
  String get rolePaxDesc =>
      'I show up and sweat. Give me the timer and the library.';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'ABOUT';

  @override
  String get changelogTitle => 'CHANGELOG';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingGloom => 'Embrace the gloom';

  @override
  String get welcomeSignInF3 => 'Sign in with F3 Nation';

  @override
  String get welcomeSignInF3Sub =>
      'Pulls your PAX profile — F3 name, region, avatar — straight from F3 Nation. No typing.';

  @override
  String get welcomeSetupManually => 'OR SET UP MANUALLY';

  @override
  String get navHome => 'Home';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navCommunity => 'Community';

  @override
  String get navYou => 'You';

  @override
  String get navSpartanCoQ => 'Spartan Co-Q';

  @override
  String get loginGateForF3Nation => 'FOR F3 NATION';

  @override
  String get loginGateSubtitle =>
      'Sign in with your F3 Nation account to continue.';

  @override
  String get loginGateSigningIn => 'Signing in…';

  @override
  String get loginGateSignIn => 'Sign in with F3 Nation';

  @override
  String get loginGateEmergencyInfo => 'Emergency Info';

  @override
  String get localLoginTagline => 'F3 NATION · SPARTAN UP';

  @override
  String localLoginWelcomeBack(String name) {
    return 'Welcome back, $name.';
  }

  @override
  String get localLoginProtects =>
      'This local lock protects your signed-in F3 Nation session on this device.';

  @override
  String get localLoginUnlocking => 'UNLOCKING...';

  @override
  String get localLoginUnlockApp => 'UNLOCK APP';

  @override
  String get localLoginEmergencyInfo => 'EMERGENCY INFO';

  @override
  String get localLoginCanceled =>
      'Unlock was canceled or unavailable. Use your device Face ID, fingerprint, or PIN to continue.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingIntro1Title => 'Build a Beatdown';

  @override
  String get onboardingIntro1Body =>
      'Generate or hand-build a Weinke from the full F3 Exicon, with Spartan AI as your Co-Q for audibles and prep.';

  @override
  String get onboardingIntro2Title => 'Run the Q';

  @override
  String get onboardingIntro2Body =>
      'A live, phase-aware timer walks you through the beatdown, then turns it into a backblast you can share.';

  @override
  String get onboardingIntro3Title => 'Connect to F3 Nation';

  @override
  String get onboardingIntro3Body =>
      'HC to beatdowns, take the Q, post preblasts and backblasts, and find AOs near you — all tied to your F3 account.';

  @override
  String get onboardingSetupTitle => 'Optional setup';

  @override
  String get onboardingSetupSubtitle =>
      'You can do these now or later from Settings.';

  @override
  String get onboardingPermissionsNotice =>
      'We\'ll ask for location access (to find AOs near you) and notification permission (for HC/Q reminders) the first time you use those features.';

  @override
  String get onboardingAppLockTitle => 'App lock';

  @override
  String get onboardingAppLockEnabled => 'Enabled — biometric required to open';

  @override
  String get onboardingAppLockSubtitle =>
      'Require biometric / PIN to open the app';

  @override
  String get onboardingEmergencyTitle => 'Emergency info';

  @override
  String get onboardingEmergencySubtitle =>
      'Medical + AO-site info, on your device';

  @override
  String get onboardingEnterApp => 'Enter the app';

  @override
  String get homeWelcomeFallback => 'Welcome';

  @override
  String get homeSyitg => 'SYITG — See You in the Gloom.';

  @override
  String get homeQuickActions => 'QUICK ACTIONS';

  @override
  String get homeGenerateBeatdown => 'Generate Beatdown';

  @override
  String get homeGenerateBeatdownSub => 'Random plan from the full Exicon';

  @override
  String get homeQFieldGuide => 'Q Field Guide';

  @override
  String get homeQFieldGuideSub => 'Prep · cadence · COT · backblast · QSource';

  @override
  String get homeBeatdownHistory => 'Beatdown History';

  @override
  String get homeBeatdownHistoryEmpty =>
      'No sessions yet — save your first beatdown';

  @override
  String homeBeatdownHistorySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0 · tap to view & share backblast';
  }

  @override
  String get homeBrowseAos => 'Browse AOs';

  @override
  String get homeBrowseAosSub => 'Find F3 Nation AOs near you';

  @override
  String homeCurrentWeinke(int count) {
    return 'CURRENT WEINKE — $count exercises';
  }

  @override
  String get homeQuickStart => 'QUICK START';

  @override
  String get homeResume => 'RESUME';

  @override
  String get homeRandom => 'RANDOM';

  @override
  String get homeLastPlan => 'LAST PLAN';

  @override
  String get homeLastBeatdown => 'LAST BEATDOWN';

  @override
  String get homeBeatdownFallback => 'Beatdown';

  @override
  String homeExercisesCount(int count) {
    return '$count exercises';
  }

  @override
  String get homeExerciseOfDay => 'EXERCISE OF THE DAY';

  @override
  String get homeWeekStreakLabel => 'WEEK STREAK';

  @override
  String get homeStreakDesc => 'Consecutive weeks with a completed beatdown';

  @override
  String homeStatsLed(int paxCount, int beatdownCount) {
    String _temp0 = intl.Intl.pluralLogic(
      beatdownCount,
      locale: localeName,
      other: '$beatdownCount beatdowns',
      one: '1 beatdown',
    );
    return 'You\'ve led $paxCount PAX across $_temp0';
  }

  @override
  String homeStatsUniquePax(int count) {
    return '$count unique PAX';
  }

  @override
  String get homeCoreValuesTitle => 'THE THREE F\'S';

  @override
  String get homeCoreFitness => 'FITNESS';

  @override
  String get homeCoreFitnessDesc => 'Free, peer-led outdoor workouts for men.';

  @override
  String get homeCoreFellowship => 'FELLOWSHIP';

  @override
  String get homeCoreFellowshipDesc =>
      'Community forged through shared struggle.';

  @override
  String get homeCoreFaith => 'FAITH';

  @override
  String get homeCoreFaithDesc => 'Spiritual growth through accountability.';

  @override
  String get homeUpcomingBeatdowns => 'YOUR UPCOMING BEATDOWNS';

  @override
  String get homeNothingHcd =>
      'Nothing HC\'d or Q\'d yet — find a beatdown on Schedule.';

  @override
  String homeHcdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'re HC\'d for $count beatdowns',
      one: 'You\'re HC\'d for 1 beatdown',
    );
    return '$_temp0';
  }

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTomorrow => 'Tomorrow';

  @override
  String get homeYoureQ => 'You\'re Q';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleJumpToday => 'Jump to today';

  @override
  String get scheduleNext7Days => 'NEXT 7 DAYS';

  @override
  String get scheduleUpcomingFiltered => 'UPCOMING';

  @override
  String get scheduleTapDateHint =>
      'Tap a date on the calendar above to see just that day.';

  @override
  String get scheduleNoMatches => 'No matches';

  @override
  String get scheduleNothingScheduled => 'Nothing scheduled';

  @override
  String get scheduleFilterAo => 'AO';

  @override
  String get scheduleFilterType => 'Type';

  @override
  String get scheduleFilterByAo => 'Filter by AO';

  @override
  String get scheduleFilterByType => 'Filter by type';

  @override
  String get scheduleFilterAll => 'All';

  @override
  String get scheduleFilterMine => 'Mine';

  @override
  String get scheduleFilterMineTitle => 'Filter by involvement';

  @override
  String get scheduleFilterMineHc => 'I\'m HC\'d';

  @override
  String get scheduleFilterMineQ => 'I\'m Q\'ing';

  @override
  String get scheduleFilterMineHcOrQ => 'I\'m HC\'d or Q\'ing';

  @override
  String get scheduleClearAll => 'Clear all';

  @override
  String get scheduleThisWeek => 'This week';

  @override
  String get scheduleLoadingEllipsis => 'Loading…';

  @override
  String scheduleBeatdownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beatdowns',
      one: '1 beatdown',
    );
    return '$_temp0';
  }

  @override
  String get scheduleNothingThisDay => 'Nothing scheduled this day.';

  @override
  String get scheduleTodayFull => 'TODAY';

  @override
  String get scheduleTomorrowFull => 'TOMORROW';

  @override
  String get scheduleTodayShort => 'Today';

  @override
  String get scheduleTomorrowShort => 'Tomorrow';

  @override
  String get scheduleQNeeded => 'Q needed';

  @override
  String scheduleQLabel(String name) {
    return 'Q: $name';
  }

  @override
  String get scheduleQSet => 'set';

  @override
  String scheduleHcCount(int count) {
    return '$count HC';
  }

  @override
  String get scheduleWhosIn => 'WHO\'S IN';

  @override
  String get scheduleDirectionsTooltip => 'Get directions to this AO';

  @override
  String get scheduleShareTooltip => 'Share this beatdown';

  @override
  String get scheduleShareTagline =>
      'Shared from Digital Weinke — the F3 Nation app';

  @override
  String get scheduleApiNotConfiguredTitle => 'F3 Nation API not configured';

  @override
  String get scheduleApiNotConfiguredSub =>
      'This build isn\'t connected to the F3 Nation API.';

  @override
  String get scheduleSignInFirst => 'Sign in to F3 Nation first.';

  @override
  String get scheduleHcSuccess => 'You\'re HC\'d — see you in the gloom.';

  @override
  String get scheduleUnhcSuccess => 'Un-HC\'d. Hope to catch you next time.';

  @override
  String get scheduleTakeQSuccess =>
      'You\'ve got the Q. Time to build a Weinke.';

  @override
  String get schedulePostPreblast => 'Post Preblast';

  @override
  String get scheduleEditPreblast => 'Edit Preblast';

  @override
  String get schedulePreblastHeader => 'PREBLAST';

  @override
  String get scheduleSignInToHc =>
      'Sign in to F3 Nation (Settings) to HC or take the Q.';

  @override
  String get scheduleHcImIn => 'HC — I\'m in';

  @override
  String get scheduleUnHc => 'Un-HC';

  @override
  String get scheduleTakeQ => 'Take Q';

  @override
  String get schedulePreblastHint =>
      'The plan, the theme, coupons, what to expect...';

  @override
  String get schedulePreblastPlanLabel => 'The Plan';

  @override
  String get schedulePreblastPlanHint =>
      'Warmup, THE THANG, Mary — what are you running?';

  @override
  String get schedulePreblastVq => 'This is my first time Q\'ing here (VQ)';

  @override
  String get schedulePreblastCoupon => 'Coupon needed';

  @override
  String get schedulePreblastCouponNotesHint =>
      'e.g. bring your own, or grab one at the flag';

  @override
  String get schedulePreblastAutoFilled =>
      'Auto-filled from this beatdown — date, time, Q, and HCs are added automatically.';

  @override
  String get scheduleBuildWeinke => 'Build my Weinke';

  @override
  String get scheduleCancel => 'Cancel';

  @override
  String get schedulePost => 'Post';

  @override
  String get scheduleSignInToPostPreblast => 'Sign in to post a preblast.';

  @override
  String get schedulePreblastPosted => 'Preblast posted.';

  @override
  String get scheduleBeatdownFallback => 'Beatdown';

  @override
  String get browseAosTitle => 'Browse AOs';

  @override
  String get browseAosSearchHint => 'Search AOs';

  @override
  String get browseAosRefreshLocation => 'Refresh my location';

  @override
  String get browseAosLocationError =>
      'Couldn\'t get your location — showing AOs alphabetically instead.';

  @override
  String get browseAosStateFilter => 'State';

  @override
  String get browseAosRegionFilter => 'Region';

  @override
  String get browseAosDayFilter => 'Day';

  @override
  String get browseAosClearAll => 'Clear all';

  @override
  String get browseAosNoAosFound => 'No AOs found';

  @override
  String get browseAosCouldntLoad => 'Couldn\'t load AOs — pull to refresh.';

  @override
  String get browseAosNoMatches => 'No AOs match your search/filters.';

  @override
  String get browseAosZoomForMore => 'Zoom out for more';

  @override
  String get browseAosNoBeatdownsScheduled => 'No beatdowns scheduled yet';

  @override
  String get browseAosApiNotConfiguredTitle => 'F3 Nation API not configured';

  @override
  String get browseAosApiNotConfiguredSub =>
      'This build isn\'t connected to the F3 Nation API, so AO data isn\'t available.';

  @override
  String get browseAosRegion => 'REGION';

  @override
  String get browseAosAddress => 'ADDRESS';

  @override
  String get browseAosNotes => 'NOTES';

  @override
  String get browseAosSchedule => 'SCHEDULE';

  @override
  String get browseAosOpenInMaps => 'Open in Maps';

  @override
  String get browseAosSeeBeatdowns => 'See beatdowns';

  @override
  String get browseAosFilterByState => 'Filter by state';

  @override
  String get browseAosFilterByRegion => 'Filter by region';

  @override
  String get browseAosFilterByDay => 'Filter by workout day';

  @override
  String browseAosShowOnMap(String name) {
    return 'Show $name on the map';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileChooseFromLibrary => 'Choose from library';

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String profilePhotoFailed(String error) {
    return 'Photo failed: $error';
  }

  @override
  String get profileSignInFirstToast =>
      'Sign in to F3 Nation first, then pull to refresh here.';

  @override
  String get profileEditTitle => 'Edit F3 Nation Profile';

  @override
  String get profileF3NameField => 'F3 Name';

  @override
  String get profileFirstNameField => 'First Name';

  @override
  String get profileLastNameField => 'Last Name';

  @override
  String get profileEmailField => 'Email';

  @override
  String get profilePhoneField => 'Phone';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutBody =>
      'This signs you out of F3 Nation and returns to the login screen.';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileNotLinked => 'Not linked to F3 Nation';

  @override
  String get profileNotLinkedDesc =>
      'Sign in from Settings to pull your profile, region, and emergency info.';

  @override
  String get profileSessionExpired => 'F3 Nation session expired';

  @override
  String get profileSessionExpiredDesc =>
      'Your sign-in stopped working (this happens after extended testing/idle time). Sign out below, then sign in again to refresh it.';

  @override
  String get profileSectionF3Nation => 'F3 NATION';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileNameField => 'Name';

  @override
  String get profileHomeRegionField => 'Home Region';

  @override
  String get profileEmergencyInfo => 'Emergency info';

  @override
  String get profileEmergencyInfoSub => 'Medical + AO-site · stored on device';

  @override
  String get profileChangeRegion => 'Change region';

  @override
  String get settingsVoiceAccessibility => 'VOICE & ACCESSIBILITY';

  @override
  String get settingsEnableVoiceCallouts => 'Enable Voice Callouts';

  @override
  String get settingsVoiceCalloutsDesc =>
      'TTS for phase changes and exercises.';

  @override
  String get settingsReducedMotion => 'Reduced Motion';

  @override
  String get settingsReducedMotionDesc => 'Disables non-essential animations.';

  @override
  String get settingsMusic => 'MUSIC';

  @override
  String get settingsLaunchMusic => 'Launch music on workout start';

  @override
  String get settingsLaunchMusicDesc =>
      'Opens your music app when you tap START WORKOUT.';

  @override
  String get settingsMusicProvider => 'Music Provider';

  @override
  String get settingsPlaylistUrl => 'Playlist URL (optional)';

  @override
  String get settingsPlaylistUrlHint =>
      'Paste a Spotify / Apple Music / YouTube link';

  @override
  String get settingsPlaylistUrlHelp =>
      'Leave blank to just open the app. Paste a share link to jump straight to your beatdown playlist.';

  @override
  String get settingsSafety => 'SAFETY';

  @override
  String get settingsEmergencyInfo => 'Emergency Info';

  @override
  String get settingsEmergencyInfoSub =>
      'Medical + AO-site info · works without sign-in';

  @override
  String get settingsData => 'DATA';

  @override
  String get settingsExportBackup => 'Export Backup';

  @override
  String get settingsExportBackupSub => 'Share all sessions as a JSON file';

  @override
  String get settingsImportBackup => 'Import Backup';

  @override
  String get settingsImportBackupSub => 'Paste backup JSON from clipboard';

  @override
  String get settingsClipboardEmpty => 'Clipboard is empty.';

  @override
  String get settingsBackupImported => 'Backup imported successfully!';

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsMyF3Name => 'My F3 Name';

  @override
  String get settingsMyF3NameHint => 'Your F3 handle (auto-fills the Q field)';

  @override
  String settingsBeatdownsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beatdowns',
      one: '1 beatdown',
    );
    return '$_temp0 planned';
  }

  @override
  String get settingsBeatdownsPlannedSub =>
      'Every one of them, posted in the gloom.';

  @override
  String get settingsExiconCount => '907 Exicon exercises';

  @override
  String get settingsExiconCountSub => 'Full F3 Codex, bundled offline.';

  @override
  String get settingsFullyOffline => 'Fully offline';

  @override
  String get settingsFullyOfflineSub => 'No account or internet required.';

  @override
  String get settingsTapToSeeWhatsNew => 'Tap to see what\'s new';

  @override
  String get settingsNotLinked => 'Not linked';

  @override
  String get settingsLinked => 'Linked';

  @override
  String get settingsWorkingCheckBrowser => 'Working… (check your browser)';

  @override
  String get settingsSignOutRegionNote =>
      'Sign out and region switching are on your Profile screen.';

  @override
  String get settingsLinksAccountNote =>
      'Links your Digital Weinke profile to your F3 Nation account (auth2.f3nation.com).';

  @override
  String get settingsF3SignInErrorTitle => 'F3 Nation Sign-In Error';

  @override
  String get settingsCopyAndClose => 'Copy & Close';

  @override
  String get settingsSelectTtsVoice => 'Select TTS Voice';

  @override
  String get settingsUseDefault => 'USE DEFAULT';

  @override
  String get settingsCancel => 'CANCEL';

  @override
  String get settingsTtsVoice => 'TTS Voice';

  @override
  String get settingsLoadingVoices => 'Loading voices…';

  @override
  String get settingsSystemDefault => 'System Default';
}
