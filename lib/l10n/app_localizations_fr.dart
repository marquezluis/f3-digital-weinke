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

  @override
  String get navHome => 'Accueil';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSchedule => 'Horaire';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get navYou => 'Toi';

  @override
  String get navSpartanCoQ => 'Spartan Co-Q';

  @override
  String get loginGateForF3Nation => 'POUR F3 NATION';

  @override
  String get loginGateSubtitle =>
      'Connecte-toi avec ton compte F3 Nation pour continuer.';

  @override
  String get loginGateSigningIn => 'Connexion en cours…';

  @override
  String get loginGateSignIn => 'Se connecter avec F3 Nation';

  @override
  String get loginGateEmergencyInfo => 'Informations d\'urgence';

  @override
  String get localLoginTagline => 'F3 NATION · SPARTAN UP';

  @override
  String localLoginWelcomeBack(String name) {
    return 'Bon retour, $name.';
  }

  @override
  String get localLoginProtects =>
      'Ce verrouillage local protège ta session F3 Nation sur cet appareil.';

  @override
  String get localLoginUnlocking => 'DÉVERROUILLAGE...';

  @override
  String get localLoginUnlockApp => 'DÉVERROUILLER L\'APP';

  @override
  String get localLoginEmergencyInfo => 'INFORMATIONS D\'URGENCE';

  @override
  String get localLoginCanceled =>
      'Le déverrouillage a été annulé ou n\'est pas disponible. Utilise Face ID, l\'empreinte digitale ou le code PIN de ton appareil pour continuer.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingIntro1Title => 'Crée un Beatdown';

  @override
  String get onboardingIntro1Body =>
      'Génère ou crée à la main un Weinke à partir de l\'Exicon complet de F3, avec Spartan AI comme Co-Q pour les audibles et la préparation.';

  @override
  String get onboardingIntro2Title => 'Dirige le Q';

  @override
  String get onboardingIntro2Body =>
      'Un minuteur en direct, conscient des phases, te guide pendant le beatdown, puis le transforme en backblast que tu peux partager.';

  @override
  String get onboardingIntro3Title => 'Connecte-toi à F3 Nation';

  @override
  String get onboardingIntro3Body =>
      'Fais HC pour des beatdowns, prends le Q, publie des preblasts et des backblasts, et trouve des AO près de chez toi — tout lié à ton compte F3.';

  @override
  String get onboardingSetupTitle => 'Configuration facultative';

  @override
  String get onboardingSetupSubtitle =>
      'Tu peux le faire maintenant ou plus tard depuis les Paramètres.';

  @override
  String get onboardingPermissionsNotice =>
      'Nous demanderons l\'accès à ta position (pour trouver des AO près de toi) et l\'autorisation de notifications (pour les rappels HC/Q) la première fois que tu utiliseras ces fonctions.';

  @override
  String get onboardingAppLockTitle => 'Verrouillage de l\'app';

  @override
  String get onboardingAppLockEnabled =>
      'Activé — biométrie requise pour ouvrir';

  @override
  String get onboardingAppLockSubtitle =>
      'Exiger la biométrie ou le code PIN pour ouvrir l\'app';

  @override
  String get onboardingEmergencyTitle => 'Informations d\'urgence';

  @override
  String get onboardingEmergencySubtitle =>
      'Infos médicales et sur l\'AO, sur ton appareil';

  @override
  String get onboardingEnterApp => 'Entrer dans l\'app';

  @override
  String get homeWelcomeFallback => 'Bienvenue';

  @override
  String get homeSyitg => 'SYITG — On se voit dans la pénombre.';

  @override
  String get homeQuickActions => 'ACTIONS RAPIDES';

  @override
  String get homeGenerateBeatdown => 'Générer un Beatdown';

  @override
  String get homeGenerateBeatdownSub =>
      'Plan aléatoire à partir de l\'Exicon complet';

  @override
  String get homeQFieldGuide => 'Guide de terrain du Q';

  @override
  String get homeQFieldGuideSub =>
      'Préparation · cadence · COT · backblast · QSource';

  @override
  String get homeBeatdownHistory => 'Historique des Beatdowns';

  @override
  String get homeBeatdownHistoryEmpty =>
      'Pas encore de séance — enregistre ton premier beatdown';

  @override
  String homeBeatdownHistorySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '1 séance',
    );
    return '$_temp0 · touche pour voir et partager le backblast';
  }

  @override
  String get homeBrowseAos => 'Explorer les AO';

  @override
  String get homeBrowseAosSub => 'Trouve des AO F3 Nation près de chez toi';

  @override
  String homeCurrentWeinke(int count) {
    return 'WEINKE ACTUEL — $count exercices';
  }

  @override
  String get homeQuickStart => 'DÉMARRAGE RAPIDE';

  @override
  String get homeResume => 'REPRENDRE';

  @override
  String get homeRandom => 'ALÉATOIRE';

  @override
  String get homeLastPlan => 'DERNIER PLAN';

  @override
  String get homeLastBeatdown => 'DERNIER BEATDOWN';

  @override
  String get homeBeatdownFallback => 'Beatdown';

  @override
  String homeExercisesCount(int count) {
    return '$count exercices';
  }

  @override
  String get homeExerciseOfDay => 'EXERCICE DU JOUR';

  @override
  String get homeWeekStreakLabel => 'SEMAINES CONSÉCUTIVES';

  @override
  String get homeStreakDesc =>
      'Semaines consécutives avec un beatdown complété';

  @override
  String homeStatsLed(int paxCount, int beatdownCount) {
    String _temp0 = intl.Intl.pluralLogic(
      beatdownCount,
      locale: localeName,
      other: '$beatdownCount beatdowns',
      one: '1 beatdown',
    );
    return 'Tu as dirigé $paxCount PAX pour $_temp0';
  }

  @override
  String homeStatsUniquePax(int count) {
    return '$count PAX uniques';
  }

  @override
  String get homeCoreValuesTitle => 'LES TROIS F';

  @override
  String get homeCoreFitness => 'FITNESS';

  @override
  String get homeCoreFitnessDesc =>
      'Entraînements en plein air, gratuits et dirigés entre pairs, pour les hommes.';

  @override
  String get homeCoreFellowship => 'FELLOWSHIP';

  @override
  String get homeCoreFellowshipDesc =>
      'Une communauté forgée par l\'effort partagé.';

  @override
  String get homeCoreFaith => 'FAITH';

  @override
  String get homeCoreFaithDesc =>
      'Croissance spirituelle par la responsabilité mutuelle.';

  @override
  String get homeUpcomingBeatdowns => 'TES PROCHAINS BEATDOWNS';

  @override
  String get homeNothingHcd =>
      'Pas encore de HC ni de Q — trouve un beatdown dans l\'Horaire.';

  @override
  String homeHcdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tu as fait HC pour $count beatdowns',
      one: 'Tu as fait HC pour 1 beatdown',
    );
    return '$_temp0';
  }

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeTomorrow => 'Demain';

  @override
  String get homeYoureQ => 'Tu es le Q';

  @override
  String get scheduleTitle => 'Horaire';

  @override
  String get scheduleJumpToday => 'Aller à aujourd\'hui';

  @override
  String get scheduleNext7Days => 'LES 7 PROCHAINS JOURS';

  @override
  String get scheduleTapDateHint =>
      'Touche une date sur le calendrier ci-dessus pour voir seulement ce jour.';

  @override
  String get scheduleNoMatches => 'Aucun résultat';

  @override
  String get scheduleNothingScheduled => 'Rien de prévu';

  @override
  String get scheduleFilterAo => 'AO';

  @override
  String get scheduleFilterType => 'Type';

  @override
  String get scheduleFilterByAo => 'Filtrer par AO';

  @override
  String get scheduleFilterByType => 'Filtrer par type';

  @override
  String get scheduleClearAll => 'Tout effacer';

  @override
  String get scheduleThisWeek => 'Cette semaine';

  @override
  String get scheduleLoadingEllipsis => 'Chargement…';

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
  String get scheduleNothingThisDay => 'Rien de prévu ce jour-là.';

  @override
  String get scheduleTodayFull => 'AUJOURD\'HUI';

  @override
  String get scheduleTomorrowFull => 'DEMAIN';

  @override
  String get scheduleTodayShort => 'Aujourd\'hui';

  @override
  String get scheduleTomorrowShort => 'Demain';

  @override
  String get scheduleQNeeded => 'Q recherché';

  @override
  String scheduleQLabel(String name) {
    return 'Q : $name';
  }

  @override
  String get scheduleQSet => 'assigné';

  @override
  String scheduleHcCount(int count) {
    return '$count HC';
  }

  @override
  String get scheduleApiNotConfiguredTitle =>
      'L\'API F3 Nation n\'est pas configurée';

  @override
  String get scheduleApiNotConfiguredSub =>
      'Cette version n\'est pas connectée à l\'API F3 Nation.';

  @override
  String get scheduleSignInFirst => 'Connecte-toi d\'abord à F3 Nation.';

  @override
  String get scheduleHcSuccess =>
      'Tu as fait HC — on se voit dans la pénombre.';

  @override
  String get scheduleUnhcSuccess =>
      'HC annulé. On espère te revoir la prochaine fois.';

  @override
  String get scheduleTakeQSuccess =>
      'Tu as pris le Q. Il est temps de créer un Weinke.';

  @override
  String get schedulePostPreblast => 'Publier le Preblast';

  @override
  String get scheduleEditPreblast => 'Modifier le Preblast';

  @override
  String get schedulePreblastHeader => 'PREBLAST';

  @override
  String get scheduleSignInToHc =>
      'Connecte-toi à F3 Nation (dans Paramètres) pour faire HC ou prendre le Q.';

  @override
  String get scheduleHcImIn => 'HC — J\'en suis';

  @override
  String get scheduleUnHc => 'Annuler HC';

  @override
  String get scheduleTakeQ => 'Prendre le Q';

  @override
  String get schedulePreblastHint =>
      'Le plan, le thème, les coupons, à quoi s\'attendre...';

  @override
  String get scheduleCancel => 'Annuler';

  @override
  String get schedulePost => 'Publier';

  @override
  String get scheduleSignInToPostPreblast =>
      'Connecte-toi pour publier un preblast.';

  @override
  String get schedulePreblastPosted => 'Preblast publié.';

  @override
  String get scheduleBeatdownFallback => 'Beatdown';

  @override
  String get browseAosTitle => 'Explorer les AO';

  @override
  String get browseAosSearchHint => 'Rechercher des AO';

  @override
  String get browseAosRefreshLocation => 'Actualiser ma position';

  @override
  String get browseAosLocationError =>
      'Impossible d\'obtenir ta position — affichage des AO par ordre alphabétique.';

  @override
  String get browseAosStateFilter => 'État';

  @override
  String get browseAosRegionFilter => 'Région';

  @override
  String get browseAosDayFilter => 'Jour';

  @override
  String get browseAosClearAll => 'Tout effacer';

  @override
  String get browseAosNoAosFound => 'Aucun AO trouvé';

  @override
  String get browseAosCouldntLoad =>
      'Impossible de charger les AO — tire pour actualiser.';

  @override
  String get browseAosNoMatches =>
      'Aucun AO ne correspond à ta recherche/tes filtres.';

  @override
  String get browseAosZoomForMore => 'Dézoome pour en voir plus';

  @override
  String get browseAosNoBeatdownsScheduled => 'Pas encore de beatdown prévu';

  @override
  String get browseAosApiNotConfiguredTitle =>
      'L\'API F3 Nation n\'est pas configurée';

  @override
  String get browseAosApiNotConfiguredSub =>
      'Cette version n\'est pas connectée à l\'API F3 Nation, donc les données des AO ne sont pas disponibles.';

  @override
  String get browseAosRegion => 'RÉGION';

  @override
  String get browseAosAddress => 'ADRESSE';

  @override
  String get browseAosNotes => 'NOTES';

  @override
  String get browseAosSchedule => 'HORAIRE';

  @override
  String get browseAosOpenInMaps => 'Ouvrir dans Maps';

  @override
  String get browseAosFilterByState => 'Filtrer par état';

  @override
  String get browseAosFilterByRegion => 'Filtrer par région';

  @override
  String get browseAosFilterByDay => 'Filtrer par jour d\'entraînement';

  @override
  String browseAosShowOnMap(String name) {
    return 'Afficher $name sur la carte';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileChangePhoto => 'Changer la photo';

  @override
  String get profileChooseFromLibrary => 'Choisir depuis la galerie';

  @override
  String get profileTakePhoto => 'Prendre une photo';

  @override
  String profilePhotoFailed(String error) {
    return 'Échec de la photo : $error';
  }

  @override
  String get profileSignInFirstToast =>
      'Connecte-toi d\'abord à F3 Nation, puis tire pour actualiser ici.';

  @override
  String get profileEditTitle => 'Modifier le profil F3 Nation';

  @override
  String get profileF3NameField => 'Nom F3';

  @override
  String get profileFirstNameField => 'Prénom';

  @override
  String get profileLastNameField => 'Nom de famille';

  @override
  String get profileEmailField => 'E-mail';

  @override
  String get profilePhoneField => 'Téléphone';

  @override
  String get profileSave => 'Enregistrer';

  @override
  String get profileSignOutTitle => 'Se déconnecter ?';

  @override
  String get profileSignOutBody =>
      'Cela te déconnecte de F3 Nation et retourne à l\'écran de connexion.';

  @override
  String get profileCancel => 'Annuler';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileNotLinked => 'Non lié à F3 Nation';

  @override
  String get profileNotLinkedDesc =>
      'Connecte-toi depuis les Paramètres pour récupérer ton profil, ta région et tes informations d\'urgence.';

  @override
  String get profileSessionExpired => 'La session F3 Nation a expiré';

  @override
  String get profileSessionExpiredDesc =>
      'Ta connexion a cessé de fonctionner (cela arrive après une longue période de tests/inactivité). Déconnecte-toi ci-dessous, puis reconnecte-toi pour la renouveler.';

  @override
  String get profileSectionF3Nation => 'F3 NATION';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileNameField => 'Nom';

  @override
  String get profileHomeRegionField => 'Région d\'origine';

  @override
  String get profileEmergencyInfo => 'Informations d\'urgence';

  @override
  String get profileEmergencyInfoSub =>
      'Infos médicales et sur l\'AO · stockées sur l\'appareil';

  @override
  String get profileChangeRegion => 'Changer de région';

  @override
  String get settingsVoiceAccessibility => 'VOIX ET ACCESSIBILITÉ';

  @override
  String get settingsEnableVoiceCallouts => 'Activer les annonces vocales';

  @override
  String get settingsVoiceCalloutsDesc =>
      'TTS pour les changements de phase et les exercices.';

  @override
  String get settingsReducedMotion => 'Mouvement réduit';

  @override
  String get settingsReducedMotionDesc =>
      'Désactive les animations non essentielles.';

  @override
  String get settingsMusic => 'MUSIQUE';

  @override
  String get settingsLaunchMusic =>
      'Lancer la musique au début de l\'entraînement';

  @override
  String get settingsLaunchMusicDesc =>
      'Ouvre ton app de musique quand tu touches DÉMARRER L\'ENTRAÎNEMENT.';

  @override
  String get settingsMusicProvider => 'Service de musique';

  @override
  String get settingsPlaylistUrl => 'URL de la playlist (optionnel)';

  @override
  String get settingsPlaylistUrlHint =>
      'Colle un lien Spotify / Apple Music / YouTube';

  @override
  String get settingsPlaylistUrlHelp =>
      'Laisse vide pour simplement ouvrir l\'app. Colle un lien pour aller directement à ta playlist de beatdown.';

  @override
  String get settingsSafety => 'SÉCURITÉ';

  @override
  String get settingsEmergencyInfo => 'Informations d\'urgence';

  @override
  String get settingsEmergencyInfoSub =>
      'Infos médicales et sur l\'AO · fonctionne sans connexion';

  @override
  String get settingsData => 'DONNÉES';

  @override
  String get settingsExportBackup => 'Exporter la sauvegarde';

  @override
  String get settingsExportBackupSub =>
      'Partage toutes les séances sous forme de fichier JSON';

  @override
  String get settingsImportBackup => 'Importer une sauvegarde';

  @override
  String get settingsImportBackupSub =>
      'Colle le JSON de sauvegarde depuis le presse-papiers';

  @override
  String get settingsClipboardEmpty => 'Le presse-papiers est vide.';

  @override
  String get settingsBackupImported => 'Sauvegarde importée avec succès !';

  @override
  String settingsImportFailed(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get settingsMyF3Name => 'Mon nom F3';

  @override
  String get settingsMyF3NameHint =>
      'Ton surnom F3 (remplit automatiquement le champ du Q)';

  @override
  String settingsBeatdownsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beatdowns',
      one: '1 beatdown',
    );
    return '$_temp0 planifiés';
  }

  @override
  String get settingsBeatdownsPlannedSub =>
      'Chacun d\'entre eux, publié dans la pénombre.';

  @override
  String get settingsExiconCount => '907 exercices de l\'Exicon';

  @override
  String get settingsExiconCountSub => 'Codex F3 complet, inclus hors ligne.';

  @override
  String get settingsFullyOffline => 'Entièrement hors ligne';

  @override
  String get settingsFullyOfflineSub => 'Aucun compte ni internet requis.';

  @override
  String get settingsTapToSeeWhatsNew => 'Touche pour voir les nouveautés';

  @override
  String get settingsNotLinked => 'Non lié';

  @override
  String get settingsLinked => 'Lié';

  @override
  String get settingsWorkingCheckBrowser =>
      'En cours… (vérifie ton navigateur)';

  @override
  String get settingsSignOutRegionNote =>
      'La déconnexion et le changement de région se trouvent sur ton écran Profil.';

  @override
  String get settingsLinksAccountNote =>
      'Lie ton profil Digital Weinke à ton compte F3 Nation (auth2.f3nation.com).';

  @override
  String get settingsF3SignInErrorTitle => 'Erreur de connexion F3 Nation';

  @override
  String get settingsCopyAndClose => 'Copier et fermer';

  @override
  String get settingsSelectTtsVoice => 'Sélectionner la voix TTS';

  @override
  String get settingsUseDefault => 'UTILISER PAR DÉFAUT';

  @override
  String get settingsCancel => 'ANNULER';

  @override
  String get settingsTtsVoice => 'Voix TTS';

  @override
  String get settingsLoadingVoices => 'Chargement des voix…';

  @override
  String get settingsSystemDefault => 'Par défaut du système';
}
