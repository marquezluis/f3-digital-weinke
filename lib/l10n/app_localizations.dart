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
