import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// The app name.
  ///
  /// In en, this message translates to:
  /// **'Digital Weinke'**
  String get appTitle;

  /// Welcome screen tagline shown below the logo.
  ///
  /// In en, this message translates to:
  /// **'The digital Q sheet for the modern PAX.\nBuild Weinkes, run Q Mode, track your crew — all offline, all yours.'**
  String get appTagline;

  /// Section label for the profile fields on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'SET UP YOUR PROFILE'**
  String get welcomeSetupProfile;

  /// Label for the F3 name text field.
  ///
  /// In en, this message translates to:
  /// **'F3 Name (optional)'**
  String get welcomeF3Name;

  /// Hint text for the F3 name text field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dredd, Mayhem, Roscoe'**
  String get welcomeF3NameHint;

  /// Label for the Home AO text field.
  ///
  /// In en, this message translates to:
  /// **'Home AO (optional)'**
  String get welcomeHomeAo;

  /// Hint text for the Home AO text field.
  ///
  /// In en, this message translates to:
  /// **'e.g. The Patriot'**
  String get welcomeHomeAoHint;

  /// Label for the Region text field.
  ///
  /// In en, this message translates to:
  /// **'Region (optional)'**
  String get welcomeRegion;

  /// Hint text for the Region text field.
  ///
  /// In en, this message translates to:
  /// **'e.g. F3 Kansas City'**
  String get welcomeRegionHint;

  /// Section label for the role picker on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'YOUR ROLE'**
  String get welcomeYourRole;

  /// Privacy notice on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Your profile stays on this device. Nothing is sent anywhere unless you choose to share it.'**
  String get welcomePrivacy;

  /// Switch label for enabling app lock on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Protect This App'**
  String get welcomeProtectApp;

  /// Description for the app lock switch when the device supports biometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, fingerprint, or device PIN on open.'**
  String get welcomeProtectAppDesc;

  /// Subtitle shown when app lock is not available on the device.
  ///
  /// In en, this message translates to:
  /// **'Device lock is not available on this device.'**
  String get welcomeProtectNotAvailable;

  /// Call-to-action button label on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'LOCK IN — LET\'S GO'**
  String get welcomeCta;

  /// Button label shown while the welcome screen is saving.
  ///
  /// In en, this message translates to:
  /// **'LOADING...'**
  String get welcomeCtaLoading;

  /// Small decorative subtext at the bottom of the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'EH · MODIFY · MOSEY'**
  String get welcomeSubtext;

  /// Display name for the Q role.
  ///
  /// In en, this message translates to:
  /// **'Q (Workout Leader)'**
  String get roleQName;

  /// Description for the Q role.
  ///
  /// In en, this message translates to:
  /// **'I plan and lead beatdowns. I need full Weinke-building tools.'**
  String get roleQDesc;

  /// Display name for the PAX role.
  ///
  /// In en, this message translates to:
  /// **'PAX'**
  String get rolePaxName;

  /// Description for the PAX role.
  ///
  /// In en, this message translates to:
  /// **'I show up and sweat. Give me the timer and the library.'**
  String get rolePaxDesc;

  /// Title for the settings screen.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// Section header for the appearance settings.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsAppearance;

  /// Dark theme option label.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Light theme option label.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// System theme option label.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Language picker label in settings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Section header for the About section in settings.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsAbout;

  /// Title for the changelog bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'CHANGELOG'**
  String get changelogTitle;

  /// Time-of-day greeting, morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// Time-of-day greeting, afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// Time-of-day greeting, evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// Pre-dawn greeting (before 5am).
  ///
  /// In en, this message translates to:
  /// **'Embrace the gloom'**
  String get greetingGloom;

  /// Primary F3 Nation sign-in button on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with F3 Nation'**
  String get welcomeSignInF3;

  /// Subtext under the F3 Nation sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Pulls your PAX profile — F3 name, region, avatar — straight from F3 Nation. No typing.'**
  String get welcomeSignInF3Sub;

  /// Divider label before the manual profile form.
  ///
  /// In en, this message translates to:
  /// **'OR SET UP MANUALLY'**
  String get welcomeSetupManually;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @navSpartanCoQ.
  ///
  /// In en, this message translates to:
  /// **'Spartan Co-Q'**
  String get navSpartanCoQ;

  /// No description provided for @loginGateForF3Nation.
  ///
  /// In en, this message translates to:
  /// **'FOR F3 NATION'**
  String get loginGateForF3Nation;

  /// No description provided for @loginGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your F3 Nation account to continue.'**
  String get loginGateSubtitle;

  /// No description provided for @loginGateSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get loginGateSigningIn;

  /// No description provided for @loginGateSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with F3 Nation'**
  String get loginGateSignIn;

  /// No description provided for @loginGateEmergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency Info'**
  String get loginGateEmergencyInfo;

  /// No description provided for @localLoginTagline.
  ///
  /// In en, this message translates to:
  /// **'F3 NATION · SPARTAN UP'**
  String get localLoginTagline;

  /// No description provided for @localLoginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}.'**
  String localLoginWelcomeBack(String name);

  /// No description provided for @localLoginProtects.
  ///
  /// In en, this message translates to:
  /// **'This local lock protects your signed-in F3 Nation session on this device.'**
  String get localLoginProtects;

  /// No description provided for @localLoginUnlocking.
  ///
  /// In en, this message translates to:
  /// **'UNLOCKING...'**
  String get localLoginUnlocking;

  /// No description provided for @localLoginUnlockApp.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK APP'**
  String get localLoginUnlockApp;

  /// No description provided for @localLoginEmergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY INFO'**
  String get localLoginEmergencyInfo;

  /// No description provided for @localLoginCanceled.
  ///
  /// In en, this message translates to:
  /// **'Unlock was canceled or unavailable. Use your device Face ID, fingerprint, or PIN to continue.'**
  String get localLoginCanceled;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingIntro1Title.
  ///
  /// In en, this message translates to:
  /// **'Build a Beatdown'**
  String get onboardingIntro1Title;

  /// No description provided for @onboardingIntro1Body.
  ///
  /// In en, this message translates to:
  /// **'Generate or hand-build a Weinke from the full F3 Exicon, with Spartan AI as your Co-Q for audibles and prep.'**
  String get onboardingIntro1Body;

  /// No description provided for @onboardingIntro2Title.
  ///
  /// In en, this message translates to:
  /// **'Run the Q'**
  String get onboardingIntro2Title;

  /// No description provided for @onboardingIntro2Body.
  ///
  /// In en, this message translates to:
  /// **'A live, phase-aware timer walks you through the beatdown, then turns it into a backblast you can share.'**
  String get onboardingIntro2Body;

  /// No description provided for @onboardingIntro3Title.
  ///
  /// In en, this message translates to:
  /// **'Connect to F3 Nation'**
  String get onboardingIntro3Title;

  /// No description provided for @onboardingIntro3Body.
  ///
  /// In en, this message translates to:
  /// **'HC to beatdowns, take the Q, post preblasts and backblasts, and find AOs near you — all tied to your F3 account.'**
  String get onboardingIntro3Body;

  /// No description provided for @onboardingSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional setup'**
  String get onboardingSetupTitle;

  /// No description provided for @onboardingSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can do these now or later from Settings.'**
  String get onboardingSetupSubtitle;

  /// No description provided for @onboardingPermissionsNotice.
  ///
  /// In en, this message translates to:
  /// **'We\'ll ask for location access (to find AOs near you) and notification permission (for HC/Q reminders) the first time you use those features.'**
  String get onboardingPermissionsNotice;

  /// No description provided for @onboardingAppLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get onboardingAppLockTitle;

  /// No description provided for @onboardingAppLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled — biometric required to open'**
  String get onboardingAppLockEnabled;

  /// No description provided for @onboardingAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometric / PIN to open the app'**
  String get onboardingAppLockSubtitle;

  /// No description provided for @onboardingEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency info'**
  String get onboardingEmergencyTitle;

  /// No description provided for @onboardingEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Medical + AO-site info, on your device'**
  String get onboardingEmergencySubtitle;

  /// No description provided for @onboardingEnterApp.
  ///
  /// In en, this message translates to:
  /// **'Enter the app'**
  String get onboardingEnterApp;

  /// No description provided for @homeWelcomeFallback.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcomeFallback;

  /// No description provided for @homeSyitg.
  ///
  /// In en, this message translates to:
  /// **'SYITG — See You in the Gloom.'**
  String get homeSyitg;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get homeQuickActions;

  /// No description provided for @homeGenerateBeatdown.
  ///
  /// In en, this message translates to:
  /// **'Generate Beatdown'**
  String get homeGenerateBeatdown;

  /// No description provided for @homeGenerateBeatdownSub.
  ///
  /// In en, this message translates to:
  /// **'Random plan from the full Exicon'**
  String get homeGenerateBeatdownSub;

  /// No description provided for @homeQFieldGuide.
  ///
  /// In en, this message translates to:
  /// **'Q Field Guide'**
  String get homeQFieldGuide;

  /// No description provided for @homeQFieldGuideSub.
  ///
  /// In en, this message translates to:
  /// **'Prep · cadence · COT · backblast · QSource'**
  String get homeQFieldGuideSub;

  /// No description provided for @homeBeatdownHistory.
  ///
  /// In en, this message translates to:
  /// **'Beatdown History'**
  String get homeBeatdownHistory;

  /// No description provided for @homeBeatdownHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet — save your first beatdown'**
  String get homeBeatdownHistoryEmpty;

  /// No description provided for @homeBeatdownHistorySub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}} · tap to view & share backblast'**
  String homeBeatdownHistorySub(int count);

  /// No description provided for @homeBrowseAos.
  ///
  /// In en, this message translates to:
  /// **'Browse AOs'**
  String get homeBrowseAos;

  /// No description provided for @homeBrowseAosSub.
  ///
  /// In en, this message translates to:
  /// **'Find F3 Nation AOs near you'**
  String get homeBrowseAosSub;

  /// No description provided for @homeCurrentWeinke.
  ///
  /// In en, this message translates to:
  /// **'CURRENT WEINKE — {count} exercises'**
  String homeCurrentWeinke(int count);

  /// No description provided for @homeQuickStart.
  ///
  /// In en, this message translates to:
  /// **'QUICK START'**
  String get homeQuickStart;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get homeResume;

  /// No description provided for @homeRandom.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get homeRandom;

  /// No description provided for @homeLastPlan.
  ///
  /// In en, this message translates to:
  /// **'LAST PLAN'**
  String get homeLastPlan;

  /// No description provided for @homeLastBeatdown.
  ///
  /// In en, this message translates to:
  /// **'LAST BEATDOWN'**
  String get homeLastBeatdown;

  /// No description provided for @homeBeatdownFallback.
  ///
  /// In en, this message translates to:
  /// **'Beatdown'**
  String get homeBeatdownFallback;

  /// No description provided for @homeExercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String homeExercisesCount(int count);

  /// No description provided for @homeExerciseOfDay.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE OF THE DAY'**
  String get homeExerciseOfDay;

  /// No description provided for @homeWeekStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'WEEK STREAK'**
  String get homeWeekStreakLabel;

  /// No description provided for @homeStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Consecutive weeks with a completed beatdown'**
  String get homeStreakDesc;

  /// No description provided for @homeStatsLed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve led {paxCount} PAX across {beatdownCount, plural, =1{1 beatdown} other{{beatdownCount} beatdowns}}'**
  String homeStatsLed(int paxCount, int beatdownCount);

  /// No description provided for @homeStatsUniquePax.
  ///
  /// In en, this message translates to:
  /// **'{count} unique PAX'**
  String homeStatsUniquePax(int count);

  /// No description provided for @homeCoreValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'THE THREE F\'S'**
  String get homeCoreValuesTitle;

  /// No description provided for @homeCoreFitness.
  ///
  /// In en, this message translates to:
  /// **'FITNESS'**
  String get homeCoreFitness;

  /// No description provided for @homeCoreFitnessDesc.
  ///
  /// In en, this message translates to:
  /// **'Free, peer-led outdoor workouts for men.'**
  String get homeCoreFitnessDesc;

  /// No description provided for @homeCoreFellowship.
  ///
  /// In en, this message translates to:
  /// **'FELLOWSHIP'**
  String get homeCoreFellowship;

  /// No description provided for @homeCoreFellowshipDesc.
  ///
  /// In en, this message translates to:
  /// **'Community forged through shared struggle.'**
  String get homeCoreFellowshipDesc;

  /// No description provided for @homeCoreFaith.
  ///
  /// In en, this message translates to:
  /// **'FAITH'**
  String get homeCoreFaith;

  /// No description provided for @homeCoreFaithDesc.
  ///
  /// In en, this message translates to:
  /// **'Spiritual growth through accountability.'**
  String get homeCoreFaithDesc;

  /// No description provided for @homeUpcomingBeatdowns.
  ///
  /// In en, this message translates to:
  /// **'YOUR UPCOMING BEATDOWNS'**
  String get homeUpcomingBeatdowns;

  /// No description provided for @homeNothingHcd.
  ///
  /// In en, this message translates to:
  /// **'Nothing HC\'d or Q\'d yet — find a beatdown on Schedule.'**
  String get homeNothingHcd;

  /// No description provided for @homeHcdCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You\'re HC\'d for 1 beatdown} other{You\'re HC\'d for {count} beatdowns}}'**
  String homeHcdCount(int count);

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTomorrow;

  /// No description provided for @homeYoureQ.
  ///
  /// In en, this message translates to:
  /// **'You\'re Q'**
  String get homeYoureQ;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleJumpToday.
  ///
  /// In en, this message translates to:
  /// **'Jump to today'**
  String get scheduleJumpToday;

  /// No description provided for @scheduleNext7Days.
  ///
  /// In en, this message translates to:
  /// **'NEXT 7 DAYS'**
  String get scheduleNext7Days;

  /// No description provided for @scheduleUpcomingFiltered.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get scheduleUpcomingFiltered;

  /// No description provided for @scheduleTapDateHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a date on the calendar above to see just that day.'**
  String get scheduleTapDateHint;

  /// No description provided for @scheduleNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get scheduleNoMatches;

  /// No description provided for @scheduleNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get scheduleNothingScheduled;

  /// No description provided for @scheduleFilterAo.
  ///
  /// In en, this message translates to:
  /// **'AO'**
  String get scheduleFilterAo;

  /// No description provided for @scheduleFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get scheduleFilterType;

  /// No description provided for @scheduleFilterByAo.
  ///
  /// In en, this message translates to:
  /// **'Filter by AO'**
  String get scheduleFilterByAo;

  /// No description provided for @scheduleFilterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get scheduleFilterByType;

  /// No description provided for @scheduleFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scheduleFilterAll;

  /// No description provided for @scheduleFilterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get scheduleFilterMine;

  /// No description provided for @scheduleFilterMineTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by involvement'**
  String get scheduleFilterMineTitle;

  /// No description provided for @scheduleFilterMineHc.
  ///
  /// In en, this message translates to:
  /// **'I\'m HC\'d'**
  String get scheduleFilterMineHc;

  /// No description provided for @scheduleFilterMineQ.
  ///
  /// In en, this message translates to:
  /// **'I\'m Q\'ing'**
  String get scheduleFilterMineQ;

  /// No description provided for @scheduleFilterMineHcOrQ.
  ///
  /// In en, this message translates to:
  /// **'I\'m HC\'d or Q\'ing'**
  String get scheduleFilterMineHcOrQ;

  /// No description provided for @scheduleClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get scheduleClearAll;

  /// No description provided for @scheduleThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get scheduleThisWeek;

  /// No description provided for @scheduleLoadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get scheduleLoadingEllipsis;

  /// No description provided for @scheduleBeatdownCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 beatdown} other{{count} beatdowns}}'**
  String scheduleBeatdownCount(int count);

  /// No description provided for @scheduleNothingThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled this day.'**
  String get scheduleNothingThisDay;

  /// No description provided for @scheduleTodayFull.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get scheduleTodayFull;

  /// No description provided for @scheduleTomorrowFull.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get scheduleTomorrowFull;

  /// No description provided for @scheduleTodayShort.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleTodayShort;

  /// No description provided for @scheduleTomorrowShort.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get scheduleTomorrowShort;

  /// No description provided for @scheduleQNeeded.
  ///
  /// In en, this message translates to:
  /// **'Q needed'**
  String get scheduleQNeeded;

  /// No description provided for @scheduleQLabel.
  ///
  /// In en, this message translates to:
  /// **'Q: {name}'**
  String scheduleQLabel(String name);

  /// No description provided for @scheduleQSet.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get scheduleQSet;

  /// No description provided for @scheduleHcCount.
  ///
  /// In en, this message translates to:
  /// **'{count} HC'**
  String scheduleHcCount(int count);

  /// No description provided for @scheduleWhosIn.
  ///
  /// In en, this message translates to:
  /// **'WHO\'S IN'**
  String get scheduleWhosIn;

  /// No description provided for @scheduleDirectionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Get directions to this AO'**
  String get scheduleDirectionsTooltip;

  /// No description provided for @scheduleShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share this beatdown'**
  String get scheduleShareTooltip;

  /// No description provided for @scheduleShareTagline.
  ///
  /// In en, this message translates to:
  /// **'Shared from Digital Weinke — the F3 Nation app'**
  String get scheduleShareTagline;

  /// No description provided for @scheduleApiNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'F3 Nation API not configured'**
  String get scheduleApiNotConfiguredTitle;

  /// No description provided for @scheduleApiNotConfiguredSub.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t connected to the F3 Nation API.'**
  String get scheduleApiNotConfiguredSub;

  /// No description provided for @scheduleSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in to F3 Nation first.'**
  String get scheduleSignInFirst;

  /// No description provided for @scheduleHcSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re HC\'d — see you in the gloom.'**
  String get scheduleHcSuccess;

  /// No description provided for @scheduleUnhcSuccess.
  ///
  /// In en, this message translates to:
  /// **'Un-HC\'d. Hope to catch you next time.'**
  String get scheduleUnhcSuccess;

  /// No description provided for @scheduleTakeQSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got the Q. Time to build a Weinke.'**
  String get scheduleTakeQSuccess;

  /// No description provided for @scheduleDropQSuccess.
  ///
  /// In en, this message translates to:
  /// **'Q dropped. Still HC\'d for the beatdown.'**
  String get scheduleDropQSuccess;

  /// No description provided for @schedulePostPreblast.
  ///
  /// In en, this message translates to:
  /// **'Post Preblast'**
  String get schedulePostPreblast;

  /// No description provided for @scheduleEditPreblast.
  ///
  /// In en, this message translates to:
  /// **'Edit Preblast'**
  String get scheduleEditPreblast;

  /// No description provided for @schedulePreblastHeader.
  ///
  /// In en, this message translates to:
  /// **'PREBLAST'**
  String get schedulePreblastHeader;

  /// No description provided for @schedulePreblastUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Posted, but the text isn\'t available right now.'**
  String get schedulePreblastUnavailable;

  /// No description provided for @scheduleSignInToHc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to F3 Nation (Settings) to HC or take the Q.'**
  String get scheduleSignInToHc;

  /// No description provided for @scheduleHcImIn.
  ///
  /// In en, this message translates to:
  /// **'HC — I\'m in'**
  String get scheduleHcImIn;

  /// No description provided for @scheduleUnHc.
  ///
  /// In en, this message translates to:
  /// **'Un-HC'**
  String get scheduleUnHc;

  /// No description provided for @scheduleTakeQ.
  ///
  /// In en, this message translates to:
  /// **'Take Q'**
  String get scheduleTakeQ;

  /// No description provided for @scheduleDropQ.
  ///
  /// In en, this message translates to:
  /// **'Drop Q'**
  String get scheduleDropQ;

  /// No description provided for @schedulePreblastHint.
  ///
  /// In en, this message translates to:
  /// **'The plan, the theme, coupons, what to expect...'**
  String get schedulePreblastHint;

  /// No description provided for @schedulePreblastPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'The Plan'**
  String get schedulePreblastPlanLabel;

  /// No description provided for @schedulePreblastPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Warmup, THE THANG, Mary — what are you running?'**
  String get schedulePreblastPlanHint;

  /// No description provided for @schedulePreblastVq.
  ///
  /// In en, this message translates to:
  /// **'This is my first time Q\'ing here (VQ)'**
  String get schedulePreblastVq;

  /// No description provided for @schedulePreblastCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon needed'**
  String get schedulePreblastCoupon;

  /// No description provided for @schedulePreblastCouponNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. bring your own, or grab one at the flag'**
  String get schedulePreblastCouponNotesHint;

  /// No description provided for @schedulePreblastAutoFilled.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from this beatdown — date, time, Q, and HCs are added automatically.'**
  String get schedulePreblastAutoFilled;

  /// No description provided for @scheduleBuildWeinke.
  ///
  /// In en, this message translates to:
  /// **'Build my Weinke'**
  String get scheduleBuildWeinke;

  /// No description provided for @scheduleCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scheduleCancel;

  /// No description provided for @schedulePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get schedulePost;

  /// No description provided for @scheduleSignInToPostPreblast.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post a preblast.'**
  String get scheduleSignInToPostPreblast;

  /// No description provided for @schedulePreblastPosted.
  ///
  /// In en, this message translates to:
  /// **'Preblast posted.'**
  String get schedulePreblastPosted;

  /// No description provided for @scheduleBeatdownFallback.
  ///
  /// In en, this message translates to:
  /// **'Beatdown'**
  String get scheduleBeatdownFallback;

  /// No description provided for @browseAosTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse AOs'**
  String get browseAosTitle;

  /// No description provided for @browseAosSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search AOs'**
  String get browseAosSearchHint;

  /// No description provided for @browseAosRefreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh my location'**
  String get browseAosRefreshLocation;

  /// No description provided for @browseAosLocationError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location — showing AOs alphabetically instead.'**
  String get browseAosLocationError;

  /// No description provided for @browseAosStateFilter.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get browseAosStateFilter;

  /// No description provided for @browseAosRegionFilter.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get browseAosRegionFilter;

  /// No description provided for @browseAosDayFilter.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get browseAosDayFilter;

  /// No description provided for @browseAosClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get browseAosClearAll;

  /// No description provided for @browseAosNoAosFound.
  ///
  /// In en, this message translates to:
  /// **'No AOs found'**
  String get browseAosNoAosFound;

  /// No description provided for @browseAosCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load AOs — pull to refresh.'**
  String get browseAosCouldntLoad;

  /// No description provided for @browseAosNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No AOs match your search/filters.'**
  String get browseAosNoMatches;

  /// No description provided for @browseAosZoomForMore.
  ///
  /// In en, this message translates to:
  /// **'Zoom out for more'**
  String get browseAosZoomForMore;

  /// No description provided for @browseAosNoBeatdownsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No beatdowns scheduled yet'**
  String get browseAosNoBeatdownsScheduled;

  /// No description provided for @browseAosApiNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'F3 Nation API not configured'**
  String get browseAosApiNotConfiguredTitle;

  /// No description provided for @browseAosApiNotConfiguredSub.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t connected to the F3 Nation API, so AO data isn\'t available.'**
  String get browseAosApiNotConfiguredSub;

  /// No description provided for @browseAosRegion.
  ///
  /// In en, this message translates to:
  /// **'REGION'**
  String get browseAosRegion;

  /// No description provided for @browseAosAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get browseAosAddress;

  /// No description provided for @browseAosNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get browseAosNotes;

  /// No description provided for @browseAosSchedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get browseAosSchedule;

  /// No description provided for @browseAosOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get browseAosOpenInMaps;

  /// No description provided for @browseAosSeeBeatdowns.
  ///
  /// In en, this message translates to:
  /// **'See beatdowns'**
  String get browseAosSeeBeatdowns;

  /// No description provided for @browseAosFilterByState.
  ///
  /// In en, this message translates to:
  /// **'Filter by state'**
  String get browseAosFilterByState;

  /// No description provided for @browseAosFilterByRegion.
  ///
  /// In en, this message translates to:
  /// **'Filter by region'**
  String get browseAosFilterByRegion;

  /// No description provided for @browseAosFilterByDay.
  ///
  /// In en, this message translates to:
  /// **'Filter by workout day'**
  String get browseAosFilterByDay;

  /// No description provided for @browseAosShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show {name} on the map'**
  String browseAosShowOnMap(String name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get profileChooseFromLibrary;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileTakePhoto;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo failed: {error}'**
  String profilePhotoFailed(String error);

  /// No description provided for @profileSignInFirstToast.
  ///
  /// In en, this message translates to:
  /// **'Sign in to F3 Nation first, then pull to refresh here.'**
  String get profileSignInFirstToast;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit F3 Nation Profile'**
  String get profileEditTitle;

  /// No description provided for @profileF3NameField.
  ///
  /// In en, this message translates to:
  /// **'F3 Name'**
  String get profileF3NameField;

  /// No description provided for @profileFirstNameField.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profileFirstNameField;

  /// No description provided for @profileLastNameField.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profileLastNameField;

  /// No description provided for @profileEmailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailField;

  /// No description provided for @profilePhoneField.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneField;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'This signs you out of F3 Nation and returns to the login screen.'**
  String get profileSignOutBody;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to F3 Nation'**
  String get profileNotLinked;

  /// No description provided for @profileNotLinkedDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in from Settings to pull your profile, region, and emergency info.'**
  String get profileNotLinkedDesc;

  /// No description provided for @profileSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'F3 Nation session expired'**
  String get profileSessionExpired;

  /// No description provided for @profileSessionExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in stopped working (this happens after extended testing/idle time). Sign out below, then sign in again to refresh it.'**
  String get profileSessionExpiredDesc;

  /// No description provided for @profileSectionF3Nation.
  ///
  /// In en, this message translates to:
  /// **'F3 NATION'**
  String get profileSectionF3Nation;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileNameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameField;

  /// No description provided for @profileHomeRegionField.
  ///
  /// In en, this message translates to:
  /// **'Home Region'**
  String get profileHomeRegionField;

  /// No description provided for @profileEmergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency info'**
  String get profileEmergencyInfo;

  /// No description provided for @profileEmergencyInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Medical + AO-site · stored on device'**
  String get profileEmergencyInfoSub;

  /// No description provided for @profileChangeRegion.
  ///
  /// In en, this message translates to:
  /// **'Change region'**
  String get profileChangeRegion;

  /// No description provided for @settingsVoiceAccessibility.
  ///
  /// In en, this message translates to:
  /// **'VOICE & ACCESSIBILITY'**
  String get settingsVoiceAccessibility;

  /// No description provided for @settingsEnableVoiceCallouts.
  ///
  /// In en, this message translates to:
  /// **'Enable Voice Callouts'**
  String get settingsEnableVoiceCallouts;

  /// No description provided for @settingsVoiceCalloutsDesc.
  ///
  /// In en, this message translates to:
  /// **'TTS for phase changes and exercises.'**
  String get settingsVoiceCalloutsDesc;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced Motion'**
  String get settingsReducedMotion;

  /// No description provided for @settingsReducedMotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Disables non-essential animations.'**
  String get settingsReducedMotionDesc;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'MUSIC'**
  String get settingsMusic;

  /// No description provided for @settingsLaunchMusic.
  ///
  /// In en, this message translates to:
  /// **'Launch music on workout start'**
  String get settingsLaunchMusic;

  /// No description provided for @settingsLaunchMusicDesc.
  ///
  /// In en, this message translates to:
  /// **'Opens your music app when you tap START WORKOUT.'**
  String get settingsLaunchMusicDesc;

  /// No description provided for @settingsMusicProvider.
  ///
  /// In en, this message translates to:
  /// **'Music Provider'**
  String get settingsMusicProvider;

  /// No description provided for @settingsPlaylistUrl.
  ///
  /// In en, this message translates to:
  /// **'Playlist URL (optional)'**
  String get settingsPlaylistUrl;

  /// No description provided for @settingsPlaylistUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a Spotify / Apple Music / YouTube link'**
  String get settingsPlaylistUrlHint;

  /// No description provided for @settingsPlaylistUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to just open the app. Paste a share link to jump straight to your beatdown playlist.'**
  String get settingsPlaylistUrlHelp;

  /// No description provided for @settingsSafety.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get settingsSafety;

  /// No description provided for @settingsEmergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency Info'**
  String get settingsEmergencyInfo;

  /// No description provided for @settingsEmergencyInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Medical + AO-site info · works without sign-in'**
  String get settingsEmergencyInfoSub;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get settingsData;

  /// No description provided for @settingsExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get settingsExportBackup;

  /// No description provided for @settingsExportBackupSub.
  ///
  /// In en, this message translates to:
  /// **'Share all sessions as a JSON file'**
  String get settingsExportBackupSub;

  /// No description provided for @settingsImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get settingsImportBackup;

  /// No description provided for @settingsImportBackupSub.
  ///
  /// In en, this message translates to:
  /// **'Paste backup JSON from clipboard'**
  String get settingsImportBackupSub;

  /// No description provided for @settingsClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty.'**
  String get settingsClipboardEmpty;

  /// No description provided for @settingsBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully!'**
  String get settingsBackupImported;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsMyF3Name.
  ///
  /// In en, this message translates to:
  /// **'My F3 Name'**
  String get settingsMyF3Name;

  /// No description provided for @settingsMyF3NameHint.
  ///
  /// In en, this message translates to:
  /// **'Your F3 handle (auto-fills the Q field)'**
  String get settingsMyF3NameHint;

  /// No description provided for @settingsBeatdownsPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 beatdown} other{{count} beatdowns}} planned'**
  String settingsBeatdownsPlanned(int count);

  /// No description provided for @settingsBeatdownsPlannedSub.
  ///
  /// In en, this message translates to:
  /// **'Every one of them, posted in the gloom.'**
  String get settingsBeatdownsPlannedSub;

  /// No description provided for @settingsExiconCount.
  ///
  /// In en, this message translates to:
  /// **'907 Exicon exercises'**
  String get settingsExiconCount;

  /// No description provided for @settingsExiconCountSub.
  ///
  /// In en, this message translates to:
  /// **'Full F3 Codex, bundled offline.'**
  String get settingsExiconCountSub;

  /// No description provided for @settingsFullyOffline.
  ///
  /// In en, this message translates to:
  /// **'Fully offline'**
  String get settingsFullyOffline;

  /// No description provided for @settingsFullyOfflineSub.
  ///
  /// In en, this message translates to:
  /// **'No account or internet required.'**
  String get settingsFullyOfflineSub;

  /// No description provided for @settingsTapToSeeWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what\'s new'**
  String get settingsTapToSeeWhatsNew;

  /// No description provided for @settingsNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get settingsNotLinked;

  /// No description provided for @settingsLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get settingsLinked;

  /// No description provided for @settingsWorkingCheckBrowser.
  ///
  /// In en, this message translates to:
  /// **'Working… (check your browser)'**
  String get settingsWorkingCheckBrowser;

  /// No description provided for @settingsSignOutRegionNote.
  ///
  /// In en, this message translates to:
  /// **'Sign out and region switching are on your Profile screen.'**
  String get settingsSignOutRegionNote;

  /// No description provided for @settingsLinksAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Links your Digital Weinke profile to your F3 Nation account (auth2.f3nation.com).'**
  String get settingsLinksAccountNote;

  /// No description provided for @settingsF3SignInErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'F3 Nation Sign-In Error'**
  String get settingsF3SignInErrorTitle;

  /// No description provided for @settingsCopyAndClose.
  ///
  /// In en, this message translates to:
  /// **'Copy & Close'**
  String get settingsCopyAndClose;

  /// No description provided for @settingsSelectTtsVoice.
  ///
  /// In en, this message translates to:
  /// **'Select TTS Voice'**
  String get settingsSelectTtsVoice;

  /// No description provided for @settingsUseDefault.
  ///
  /// In en, this message translates to:
  /// **'USE DEFAULT'**
  String get settingsUseDefault;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get settingsCancel;

  /// No description provided for @settingsTtsVoice.
  ///
  /// In en, this message translates to:
  /// **'TTS Voice'**
  String get settingsTtsVoice;

  /// No description provided for @settingsLoadingVoices.
  ///
  /// In en, this message translates to:
  /// **'Loading voices…'**
  String get settingsLoadingVoices;

  /// No description provided for @settingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsSystemDefault;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
