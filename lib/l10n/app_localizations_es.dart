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

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get greetingGloom => 'Abraza la penumbra';

  @override
  String get welcomeSignInF3 => 'Inicia sesión con F3 Nation';

  @override
  String get welcomeSignInF3Sub =>
      'Trae tu perfil PAX — nombre F3, región, avatar — directo de F3 Nation. Sin escribir nada.';

  @override
  String get welcomeSetupManually => 'O CONFIGURA MANUALMENTE';

  @override
  String get navHome => 'Inicio';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSchedule => 'Horario';

  @override
  String get navCommunity => 'Comunidad';

  @override
  String get navYou => 'Tú';

  @override
  String get navSpartanCoQ => 'Spartan Co-Q';

  @override
  String get loginGateForF3Nation => 'PARA F3 NATION';

  @override
  String get loginGateSubtitle =>
      'Inicia sesión con tu cuenta de F3 Nation para continuar.';

  @override
  String get loginGateSigningIn => 'Iniciando sesión…';

  @override
  String get loginGateSignIn => 'Inicia sesión con F3 Nation';

  @override
  String get loginGateEmergencyInfo => 'Información de emergencia';

  @override
  String get localLoginTagline => 'F3 NATION · SPARTAN UP';

  @override
  String localLoginWelcomeBack(String name) {
    return 'Bienvenido de nuevo, $name.';
  }

  @override
  String get localLoginProtects =>
      'Este bloqueo local protege tu sesión de F3 Nation en este dispositivo.';

  @override
  String get localLoginUnlocking => 'DESBLOQUEANDO...';

  @override
  String get localLoginUnlockApp => 'DESBLOQUEAR APP';

  @override
  String get localLoginEmergencyInfo => 'INFORMACIÓN DE EMERGENCIA';

  @override
  String get localLoginCanceled =>
      'El desbloqueo se canceló o no está disponible. Usa Face ID, huella dactilar o el PIN de tu dispositivo para continuar.';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingIntro1Title => 'Crea un Beatdown';

  @override
  String get onboardingIntro1Body =>
      'Genera o crea a mano un Weinke con el Exicon completo de F3, con Spartan AI como tu Co-Q para audibles y preparación.';

  @override
  String get onboardingIntro2Title => 'Dirige el Q';

  @override
  String get onboardingIntro2Body =>
      'Un cronómetro en vivo y con fases te guía durante el beatdown, y luego lo convierte en un backblast que puedes compartir.';

  @override
  String get onboardingIntro3Title => 'Conéctate a F3 Nation';

  @override
  String get onboardingIntro3Body =>
      'Haz HC en beatdowns, toma el Q, publica preblasts y backblasts, y encuentra AOs cerca de ti — todo vinculado a tu cuenta F3.';

  @override
  String get onboardingSetupTitle => 'Configuración opcional';

  @override
  String get onboardingSetupSubtitle =>
      'Puedes hacer esto ahora o después desde Ajustes.';

  @override
  String get onboardingPermissionsNotice =>
      'Te pediremos acceso a tu ubicación (para encontrar AOs cerca de ti) y permiso de notificaciones (para recordatorios de HC/Q) la primera vez que uses esas funciones.';

  @override
  String get onboardingAppLockTitle => 'Bloqueo de la app';

  @override
  String get onboardingAppLockEnabled =>
      'Activado — se requiere biometría para abrir';

  @override
  String get onboardingAppLockSubtitle =>
      'Requerir biometría o PIN para abrir la app';

  @override
  String get onboardingEmergencyTitle => 'Información de emergencia';

  @override
  String get onboardingEmergencySubtitle =>
      'Información médica y del AO, en tu dispositivo';

  @override
  String get onboardingEnterApp => 'Entrar a la app';

  @override
  String get homeWelcomeFallback => 'Bienvenido';

  @override
  String get homeSyitg => 'SYITG — Nos vemos en la penumbra.';

  @override
  String get homeQuickActions => 'ACCIONES RÁPIDAS';

  @override
  String get homeGenerateBeatdown => 'Generar Beatdown';

  @override
  String get homeGenerateBeatdownSub => 'Plan aleatorio del Exicon completo';

  @override
  String get homeQFieldGuide => 'Guía de campo del Q';

  @override
  String get homeQFieldGuideSub =>
      'Preparación · cadencia · COT · backblast · QSource';

  @override
  String get homeBeatdownHistory => 'Historial de Beatdowns';

  @override
  String get homeBeatdownHistoryEmpty =>
      'Aún no hay sesiones — guarda tu primer beatdown';

  @override
  String homeBeatdownHistorySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0 · toca para ver y compartir el backblast';
  }

  @override
  String get homeBrowseAos => 'Explorar AOs';

  @override
  String get homeBrowseAosSub => 'Encuentra AOs de F3 Nation cerca de ti';

  @override
  String homeCurrentWeinke(int count) {
    return 'WEINKE ACTUAL — $count ejercicios';
  }

  @override
  String get homeQuickStart => 'INICIO RÁPIDO';

  @override
  String get homeResume => 'REANUDAR';

  @override
  String get homeRandom => 'ALEATORIO';

  @override
  String get homeLastPlan => 'ÚLTIMO PLAN';

  @override
  String get homeLastBeatdown => 'ÚLTIMO BEATDOWN';

  @override
  String get homeBeatdownFallback => 'Beatdown';

  @override
  String homeExercisesCount(int count) {
    return '$count ejercicios';
  }

  @override
  String get homeExerciseOfDay => 'EJERCICIO DEL DÍA';

  @override
  String get homeWeekStreakLabel => 'SEMANAS SEGUIDAS';

  @override
  String get homeStreakDesc =>
      'Semanas consecutivas con un beatdown completado';

  @override
  String homeStatsLed(int paxCount, int beatdownCount) {
    String _temp0 = intl.Intl.pluralLogic(
      beatdownCount,
      locale: localeName,
      other: '$beatdownCount beatdowns',
      one: '1 beatdown',
    );
    return 'Has liderado a $paxCount PAX en $_temp0';
  }

  @override
  String homeStatsUniquePax(int count) {
    return '$count PAX únicos';
  }

  @override
  String get homeCoreValuesTitle => 'LAS TRES F';

  @override
  String get homeCoreFitness => 'FITNESS';

  @override
  String get homeCoreFitnessDesc =>
      'Entrenamientos al aire libre, gratuitos y liderados entre pares, para hombres.';

  @override
  String get homeCoreFellowship => 'FELLOWSHIP';

  @override
  String get homeCoreFellowshipDesc =>
      'Comunidad forjada a través del esfuerzo compartido.';

  @override
  String get homeCoreFaith => 'FAITH';

  @override
  String get homeCoreFaithDesc =>
      'Crecimiento espiritual a través de la responsabilidad mutua.';

  @override
  String get homeUpcomingBeatdowns => 'TUS PRÓXIMOS BEATDOWNS';

  @override
  String get homeNothingHcd =>
      'Aún no has hecho HC ni Q — busca un beatdown en Horario.';

  @override
  String homeHcdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiciste HC para $count beatdowns',
      one: 'Hiciste HC para 1 beatdown',
    );
    return '$_temp0';
  }

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeTomorrow => 'Mañana';

  @override
  String get homeYoureQ => 'Eres el Q';

  @override
  String get scheduleTitle => 'Horario';

  @override
  String get scheduleJumpToday => 'Ir a hoy';

  @override
  String get scheduleNext7Days => 'PRÓXIMOS 7 DÍAS';

  @override
  String get scheduleUpcomingFiltered => 'PRÓXIMOS';

  @override
  String get scheduleTapDateHint =>
      'Toca una fecha en el calendario de arriba para ver solo ese día.';

  @override
  String get scheduleNoMatches => 'Sin coincidencias';

  @override
  String get scheduleNothingScheduled => 'Nada programado';

  @override
  String get scheduleFilterAo => 'AO';

  @override
  String get scheduleFilterType => 'Tipo';

  @override
  String get scheduleFilterByAo => 'Filtrar por AO';

  @override
  String get scheduleFilterByType => 'Filtrar por tipo';

  @override
  String get scheduleFilterAll => 'Todos';

  @override
  String get scheduleFilterMine => 'Mío';

  @override
  String get scheduleFilterMineTitle => 'Filtrar por participación';

  @override
  String get scheduleFilterMineHc => 'Hice HC';

  @override
  String get scheduleFilterMineQ => 'Soy el Q';

  @override
  String get scheduleFilterMineHcOrQ => 'Hice HC o soy el Q';

  @override
  String get scheduleClearAll => 'Borrar todo';

  @override
  String get scheduleThisWeek => 'Esta semana';

  @override
  String get scheduleLoadingEllipsis => 'Cargando…';

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
  String get scheduleNothingThisDay => 'Nada programado este día.';

  @override
  String get scheduleTodayFull => 'HOY';

  @override
  String get scheduleTomorrowFull => 'MAÑANA';

  @override
  String get scheduleTodayShort => 'Hoy';

  @override
  String get scheduleTomorrowShort => 'Mañana';

  @override
  String get scheduleQNeeded => 'Falta un Q';

  @override
  String scheduleQLabel(String name) {
    return 'Q: $name';
  }

  @override
  String get scheduleQSet => 'asignado';

  @override
  String scheduleHcCount(int count) {
    return '$count HC';
  }

  @override
  String get scheduleWhosIn => 'QUIÉN VA';

  @override
  String get scheduleDirectionsTooltip => 'Cómo llegar a este AO';

  @override
  String get scheduleShareTooltip => 'Compartir este entrenamiento';

  @override
  String get scheduleCloseTooltip => 'Cerrar';

  @override
  String get scheduleShareTagline =>
      'Compartido desde Digital Weinke — la app de F3 Nation';

  @override
  String get scheduleApiNotConfiguredTitle =>
      'La API de F3 Nation no está configurada';

  @override
  String get scheduleApiNotConfiguredSub =>
      'Esta versión no está conectada a la API de F3 Nation.';

  @override
  String get scheduleSignInFirst => 'Primero inicia sesión con F3 Nation.';

  @override
  String get scheduleHcSuccess => 'Hiciste HC — nos vemos en la penumbra.';

  @override
  String get scheduleUnhcSuccess =>
      'Cancelaste tu HC. Esperamos verte la próxima vez.';

  @override
  String get scheduleTakeQSuccess => 'Tomaste el Q. Hora de crear un Weinke.';

  @override
  String get scheduleDropQSuccess =>
      'Dejaste el Q. Sigues con HC para el beatdown.';

  @override
  String get schedulePostPreblast => 'Publicar Preblast';

  @override
  String get scheduleEditPreblast => 'Editar Preblast';

  @override
  String get schedulePreblastHeader => 'PREBLAST';

  @override
  String get schedulePreblastUnavailable =>
      'Publicado, pero el texto no está disponible ahora mismo.';

  @override
  String get scheduleSignInToHc =>
      'Inicia sesión con F3 Nation (en Ajustes) para hacer HC o tomar el Q.';

  @override
  String get scheduleHcImIn => 'HC — Cuenta conmigo';

  @override
  String get scheduleUnHc => 'Cancelar HC';

  @override
  String get scheduleTakeQ => 'Tomar el Q';

  @override
  String get scheduleDropQ => 'Dejar el Q';

  @override
  String get schedulePreblastHint =>
      'El plan, el tema, coupons, qué esperar...';

  @override
  String get schedulePreblastPlanLabel => 'El Plan';

  @override
  String get schedulePreblastPlanHint =>
      'Calentamiento, THE THANG, Mary — ¿qué vas a dirigir?';

  @override
  String get schedulePreblastVq => 'Es mi primera vez siendo Q aquí (VQ)';

  @override
  String get schedulePreblastCoupon => 'Se necesita coupon';

  @override
  String get schedulePreblastCouponNotesHint =>
      'ej. trae el tuyo, o toma uno en la bandera';

  @override
  String get schedulePreblastAutoFilled =>
      'Rellenado automáticamente desde este entrenamiento — fecha, hora, Q y HCs se agregan automáticamente.';

  @override
  String get scheduleBuildWeinke => 'Construir mi Weinke';

  @override
  String get scheduleCancel => 'Cancelar';

  @override
  String get schedulePost => 'Publicar';

  @override
  String get scheduleSignInToPostPreblast =>
      'Inicia sesión para publicar un preblast.';

  @override
  String get schedulePreblastPosted => 'Preblast publicado.';

  @override
  String get schedulePreblastAutoUpdated => 'Preblast actualizado.';

  @override
  String get scheduleBeatdownFallback => 'Beatdown';

  @override
  String get browseAosTitle => 'Explorar AOs';

  @override
  String get browseAosSearchHint => 'Buscar AOs';

  @override
  String get browseAosRefreshLocation => 'Actualizar mi ubicación';

  @override
  String get browseAosLocationError =>
      'No se pudo obtener tu ubicación — mostrando AOs en orden alfabético.';

  @override
  String get browseAosStateFilter => 'Estado';

  @override
  String get browseAosRegionFilter => 'Región';

  @override
  String get browseAosDayFilter => 'Día';

  @override
  String get browseAosClearAll => 'Borrar todo';

  @override
  String get browseAosNoAosFound => 'No se encontraron AOs';

  @override
  String get browseAosCouldntLoad =>
      'No se pudieron cargar los AOs — desliza para actualizar.';

  @override
  String get browseAosNoMatches =>
      'Ningún AO coincide con tu búsqueda/filtros.';

  @override
  String get browseAosZoomForMore => 'Aleja el mapa para ver más';

  @override
  String get browseAosNoBeatdownsScheduled =>
      'Aún no hay beatdowns programados';

  @override
  String get browseAosApiNotConfiguredTitle =>
      'La API de F3 Nation no está configurada';

  @override
  String get browseAosApiNotConfiguredSub =>
      'Esta versión no está conectada a la API de F3 Nation, así que los datos de AOs no están disponibles.';

  @override
  String get browseAosRegion => 'REGIÓN';

  @override
  String get browseAosAddress => 'DIRECCIÓN';

  @override
  String get browseAosNotes => 'NOTAS';

  @override
  String get browseAosSchedule => 'HORARIO';

  @override
  String get browseAosOpenInMaps => 'Abrir en Maps';

  @override
  String get browseAosSeeBeatdowns => 'Ver entrenamientos';

  @override
  String get browseAosFilterByState => 'Filtrar por estado';

  @override
  String get browseAosFilterByRegion => 'Filtrar por región';

  @override
  String get browseAosFilterByDay => 'Filtrar por día de entrenamiento';

  @override
  String browseAosShowOnMap(String name) {
    return 'Mostrar $name en el mapa';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileChangePhoto => 'Cambiar foto';

  @override
  String get profileChooseFromLibrary => 'Elegir de la galería';

  @override
  String get profileTakePhoto => 'Tomar una foto';

  @override
  String profilePhotoFailed(String error) {
    return 'Error con la foto: $error';
  }

  @override
  String get profileSignInFirstToast =>
      'Primero inicia sesión con F3 Nation, luego desliza para actualizar aquí.';

  @override
  String get profileEditTitle => 'Editar perfil de F3 Nation';

  @override
  String get profileF3NameField => 'Nombre F3';

  @override
  String get profileFirstNameField => 'Nombre';

  @override
  String get profileLastNameField => 'Apellido';

  @override
  String get profileEmailField => 'Correo electrónico';

  @override
  String get profilePhoneField => 'Teléfono';

  @override
  String get profileSave => 'Guardar';

  @override
  String get profileSignOutTitle => '¿Cerrar sesión?';

  @override
  String get profileSignOutBody =>
      'Esto cierra tu sesión de F3 Nation y regresa a la pantalla de inicio de sesión.';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileNotLinked => 'No vinculado a F3 Nation';

  @override
  String get profileNotLinkedDesc =>
      'Inicia sesión desde Ajustes para obtener tu perfil, región e información de emergencia.';

  @override
  String get profileSessionExpired => 'La sesión de F3 Nation expiró';

  @override
  String get profileSessionExpiredDesc =>
      'Tu sesión dejó de funcionar (esto pasa después de mucho tiempo de pruebas/inactividad). Cierra sesión abajo y vuelve a iniciar sesión para renovarla.';

  @override
  String get profileSectionF3Nation => 'F3 NATION';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileNameField => 'Nombre';

  @override
  String get profileHomeRegionField => 'Región de origen';

  @override
  String get profileEmergencyInfo => 'Información de emergencia';

  @override
  String get profileEmergencyInfoSub =>
      'Información médica y del AO · guardada en el dispositivo';

  @override
  String get profileChangeRegion => 'Cambiar región';

  @override
  String get settingsVoiceAccessibility => 'VOZ Y ACCESIBILIDAD';

  @override
  String get settingsEnableVoiceCallouts => 'Activar avisos de voz';

  @override
  String get settingsVoiceCalloutsDesc =>
      'TTS para cambios de fase y ejercicios.';

  @override
  String get settingsReducedMotion => 'Movimiento reducido';

  @override
  String get settingsReducedMotionDesc =>
      'Desactiva las animaciones no esenciales.';

  @override
  String get settingsMusic => 'MÚSICA';

  @override
  String get settingsLaunchMusic => 'Abrir música al iniciar el entrenamiento';

  @override
  String get settingsLaunchMusicDesc =>
      'Abre tu app de música al tocar EMPEZAR ENTRENAMIENTO.';

  @override
  String get settingsMusicProvider => 'Servicio de música';

  @override
  String get settingsPlaylistUrl =>
      'URL de la lista de reproducción (opcional)';

  @override
  String get settingsPlaylistUrlHint =>
      'Pega un enlace de Spotify / Apple Music / YouTube';

  @override
  String get settingsPlaylistUrlHelp =>
      'Déjalo en blanco para solo abrir la app. Pega un enlace para ir directo a tu lista de reproducción.';

  @override
  String get settingsSafety => 'SEGURIDAD';

  @override
  String get settingsEmergencyInfo => 'Información de emergencia';

  @override
  String get settingsEmergencyInfoSub =>
      'Información médica y del AO · funciona sin iniciar sesión';

  @override
  String get settingsData => 'DATOS';

  @override
  String get settingsExportBackup => 'Exportar respaldo';

  @override
  String get settingsExportBackupSub =>
      'Comparte todas las sesiones como un archivo JSON';

  @override
  String get settingsImportBackup => 'Importar respaldo';

  @override
  String get settingsImportBackupSub =>
      'Pega el JSON del respaldo desde el portapapeles';

  @override
  String get settingsClipboardEmpty => 'El portapapeles está vacío.';

  @override
  String get settingsBackupImported => '¡Respaldo importado correctamente!';

  @override
  String settingsImportFailed(String error) {
    return 'Error al importar: $error';
  }

  @override
  String get settingsMyF3Name => 'Mi nombre F3';

  @override
  String get settingsMyF3NameHint =>
      'Tu apodo F3 (autocompleta el campo del Q)';

  @override
  String settingsBeatdownsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beatdowns',
      one: '1 beatdown',
    );
    return '$_temp0 planeados';
  }

  @override
  String get settingsBeatdownsPlannedSub =>
      'Todos y cada uno, publicados en la penumbra.';

  @override
  String get settingsExiconCount => '907 ejercicios del Exicon';

  @override
  String get settingsExiconCountSub =>
      'Codex completo de F3, incluido sin conexión.';

  @override
  String get settingsFullyOffline => 'Totalmente sin conexión';

  @override
  String get settingsFullyOfflineSub => 'No requiere cuenta ni internet.';

  @override
  String get settingsTapToSeeWhatsNew => 'Toca para ver las novedades';

  @override
  String get settingsNotLinked => 'No vinculado';

  @override
  String get settingsLinked => 'Vinculado';

  @override
  String get settingsWorkingCheckBrowser => 'Procesando… (revisa tu navegador)';

  @override
  String get settingsSignOutRegionNote =>
      'Cerrar sesión y cambiar de región están en tu pantalla de Perfil.';

  @override
  String get settingsLinksAccountNote =>
      'Vincula tu perfil de Digital Weinke con tu cuenta de F3 Nation (auth2.f3nation.com).';

  @override
  String get settingsF3SignInErrorTitle =>
      'Error al iniciar sesión con F3 Nation';

  @override
  String get settingsCopyAndClose => 'Copiar y cerrar';

  @override
  String get settingsSelectTtsVoice => 'Seleccionar voz TTS';

  @override
  String get settingsUseDefault => 'USAR PREDETERMINADA';

  @override
  String get settingsCancel => 'CANCELAR';

  @override
  String get settingsTtsVoice => 'Voz TTS';

  @override
  String get settingsLoadingVoices => 'Cargando voces…';

  @override
  String get settingsSystemDefault => 'Predeterminada del sistema';
}
