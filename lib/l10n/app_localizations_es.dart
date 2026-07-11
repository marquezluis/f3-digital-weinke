// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Digital Weinke';

  @override
  String get appTagline =>
      'La hoja Q digital para el PAX moderno.\nCrea Weinkes, activa el modo Q, registra tu grupo — todo sin conexión, todo tuyo.';

  @override
  String get welcomeSetupProfile => 'CONFIGURA TU PERFIL';

  @override
  String get welcomeF3Name => 'Nombre F3 (opcional)';

  @override
  String get welcomeF3NameHint => 'ej. Dredd, Mayhem, Roscoe';

  @override
  String get welcomeHomeAo => 'AO de origen (opcional)';

  @override
  String get welcomeHomeAoHint => 'ej. The Patriot';

  @override
  String get welcomeRegion => 'Región (opcional)';

  @override
  String get welcomeRegionHint => 'ej. F3 Kansas City';

  @override
  String get welcomeYourRole => 'TU ROL';

  @override
  String get welcomePrivacy =>
      'Tu perfil permanece en este dispositivo. No se envía nada a ningún lado a menos que elijas compartirlo.';

  @override
  String get welcomeProtectApp => 'Proteger esta app';

  @override
  String get welcomeProtectAppDesc =>
      'Usa Face ID, huella dactilar o el PIN del dispositivo al abrir.';

  @override
  String get welcomeProtectNotAvailable =>
      'El bloqueo de dispositivo no está disponible en este equipo.';

  @override
  String get welcomeCta => 'CONFIRMAR — ¡VAMOS!';

  @override
  String get welcomeCtaLoading => 'CARGANDO...';

  @override
  String get welcomeSubtext => 'EH · MODIFICA · MOSEY';

  @override
  String get roleQName => 'Q (Líder del entrenamiento)';

  @override
  String get roleQDesc =>
      'Planeo y lidero los beatdowns. Necesito todas las herramientas para crear Weinkes.';

  @override
  String get rolePaxName => 'PAX';

  @override
  String get rolePaxDesc =>
      'Me presento y sudo. Dame el cronómetro y la biblioteca.';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get settingsAppearance => 'APARIENCIA';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAbout => 'ACERCA DE';

  @override
  String get changelogTitle => 'REGISTRO DE CAMBIOS';
}
