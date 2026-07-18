// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Digital Weinke';

  @override
  String get appTagline =>
      'La feuille Q numérique pour le PAX moderne.\nCrée des Weinkes, lance le mode Q, suis ton groupe — tout hors ligne, tout à toi.';

  @override
  String get welcomeSetupProfile => 'CONFIGURER TON PROFIL';

  @override
  String get welcomeF3Name => 'Nom F3 (optionnel)';

  @override
  String get welcomeF3NameHint => 'ex. Dredd, Mayhem, Roscoe';

  @override
  String get welcomeHomeAo => 'AO principal (optionnel)';

  @override
  String get welcomeHomeAoHint => 'ex. The Patriot';

  @override
  String get welcomeRegion => 'Région (optionnel)';

  @override
  String get welcomeRegionHint => 'ex. F3 Kansas City';

  @override
  String get welcomeYourRole => 'TON RÔLE';

  @override
  String get welcomePrivacy =>
      'Ton profil reste sur cet appareil. Rien n\'est envoyé nulle part sauf si tu choisis de le partager.';

  @override
  String get welcomeProtectApp => 'Protéger cette app';

  @override
  String get welcomeProtectAppDesc =>
      'Utilise Face ID, l\'empreinte digitale ou le code PIN à l\'ouverture.';

  @override
  String get welcomeProtectNotAvailable =>
      'Le verrouillage de l\'appareil n\'est pas disponible sur cet appareil.';

  @override
  String get welcomeCta => 'C\'EST PARTI — ALLONS-Y !';

  @override
  String get welcomeCtaLoading => 'CHARGEMENT...';

  @override
  String get welcomeSubtext => 'EH · MODIFIER · MOSEY';

  @override
  String get roleQName => 'Q (Responsable de l\'entraînement)';

  @override
  String get roleQDesc =>
      'Je planifie et dirige les beatdowns. J\'ai besoin de tous les outils pour créer des Weinkes.';

  @override
  String get rolePaxName => 'PAX';

  @override
  String get rolePaxDesc =>
      'Je me présente et je transpire. Donne-moi le minuteur et la bibliothèque.';

  @override
  String get settingsTitle => 'PARAMÈTRES';

  @override
  String get settingsAppearance => 'APPARENCE';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsAbout => 'À PROPOS';

  @override
  String get changelogTitle => 'JOURNAL DES MODIFICATIONS';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get greetingGloom => 'Embrasse la pénombre';

  @override
  String get welcomeSignInF3 => 'Se connecter avec F3 Nation';

  @override
  String get welcomeSignInF3Sub =>
      'Récupère ton profil PAX — nom F3, région, avatar — directement depuis F3 Nation. Sans rien taper.';

  @override
  String get welcomeSetupManually => 'OU CONFIGURER MANUELLEMENT';
}
