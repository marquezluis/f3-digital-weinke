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
}
