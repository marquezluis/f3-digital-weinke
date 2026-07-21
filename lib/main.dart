// lib/main.dart
// Digital Weinke — F3 Nation local-first bootcamp planner.
// Entry point: loads exercise data and settings, then launches the app.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'services/app_profile_service.dart';
import 'services/auth_service.dart';
import 'services/current_workout_service.dart';
import 'services/emergency_service.dart';
import 'services/exercise_service.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'services/f3_api_service.dart';
import 'services/region_service.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';
import 'services/spartan_service.dart';
import 'config/app_config.dart';
import 'screens/shell_screen.dart';
import 'screens/local_login_screen.dart';
import 'screens/login_gate_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/schedule_screen.dart' show MineFilter;
import 'models/auth_models.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Baked in at build time via --dart-define(-from-file). Empty by default —
  // SentryFlutter.init() no-ops with an empty DSN, so this is safe to leave
  // unset until a Sentry project exists.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 0.2;
    },
    appRunner: _runApp,
  );
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: F3Colors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize local notifications (no-op if permission not granted yet).
  await NotificationService().init();

  final exerciseService = ExerciseService();
  await exerciseService.load();

  final settingsService = SettingsService();
  await settingsService.load();
  SpartanService.instance.init(kGeminiApiKey);

  final appProfileService = AppProfileService();
  await appProfileService.load();

  final authService = LocalAuthService();
  await authService.load();

  final historyService = HistoryService();
  await historyService.load();

  final regionService = RegionService();
  await regionService.load();

  final f3ApiService = F3ApiService();
  await f3ApiService.load();

  runApp(DigitalWeinke(
    exerciseService: exerciseService,
    appProfileService: appProfileService,
    authService: authService,
    settingsService: settingsService,
    historyService: historyService,
    regionService: regionService,
    f3ApiService: f3ApiService,
  ));
}

class DigitalWeinke extends StatelessWidget {
  final ExerciseService exerciseService;
  final AppProfileService appProfileService;
  final AuthService authService;
  final SettingsService settingsService;
  final HistoryService historyService;
  final RegionService regionService;
  final F3ApiService f3ApiService;

  const DigitalWeinke({
    super.key,
    required this.exerciseService,
    required this.appProfileService,
    required this.authService,
    required this.settingsService,
    required this.historyService,
    required this.regionService,
    required this.f3ApiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ExerciseService now extends ChangeNotifier (custom exercises notify).
        ChangeNotifierProvider<ExerciseService>.value(value: exerciseService),
        ChangeNotifierProvider<AppProfileService>.value(
            value: appProfileService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<HistoryService>.value(value: historyService),
        ChangeNotifierProvider<RegionService>.value(value: regionService),
        ChangeNotifierProvider<F3ApiService>.value(value: f3ApiService),
        ChangeNotifierProvider<TimerService>(create: (_) => TimerService()),
        ChangeNotifierProvider<CurrentWorkoutService>(
          create: (_) => CurrentWorkoutService(),
        ),
        ChangeNotifierProvider<EmergencyService>(
          create: (_) => EmergencyService()..load(),
        ),
        ChangeNotifierProvider<ValueNotifier<int>>(
          create: (_) => ValueNotifier<int>(0),
        ),
        // Home's upcoming-beatdowns card sets this before switching to the
        // Schedule tab, so an already-live Schedule instance (kept alive in
        // ShellScreen's IndexedStack) can pre-apply the filter.
        ChangeNotifierProvider<ValueNotifier<MineFilter?>>(
          create: (_) => ValueNotifier<MineFilter?>(null),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, child) => MaterialApp(
          title: 'Digital Weinke',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
        child: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _handlingSessionInvalid = false;
  Timer? _deltaCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deltaCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
      // Covers a long foreground session without ever re-backgrounding —
      // conservative interval since this is a foreground-only poll, not a
      // free background push.
      _deltaCheckTimer?.cancel();
      _deltaCheckTimer = Timer.periodic(
          const Duration(minutes: 25), (_) => _onAppResumed());
    } else {
      _deltaCheckTimer?.cancel();
      _deltaCheckTimer = null;
    }
  }

  /// Foreground-only delta check (new Q assignment / still-unposted
  /// backblast) — see NotificationService.checkForDeltasAndNotify for the
  /// explicit limitation this has. No dedicated session-revalidation call
  /// here: a dead session surfaces reactively via F3ApiService.sessionInvalid
  /// the moment this fetch (or any other screen's) 401s.
  Future<void> _onAppResumed() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final hasF3 = auth.currentUser?.identities
            .any((i) => i.provider == AuthProvider.f3nation) ??
        false;
    if (!hasF3) return;
    final token = await auth.getF3AccessToken();
    if (token == null) return;

    final userId = int.tryParse(profile.authUserId);
    final events =
        await api.getUpcomingBeatdowns(userAccessToken: token, userId: userId);
    final qEvents = <int, String>{
      for (final e in events)
        if (e.userIsQ && e.numericId != null)
          e.numericId!: e.orgName ?? e.locationName ?? 'a beatdown',
    };

    var unpostedTitles = <int, String>{};
    final orgId = api.orgId;
    if (orgId != null && profile.authUserId.isNotEmpty) {
      final unposted = await api.getPastQsWithoutBackblast(
        userId: profile.authUserId,
        regionOrgId: orgId,
        userAccessToken: token,
      );
      unpostedTitles = {
        for (final e in unposted)
          if (e.numericId != null)
            e.numericId!: e.orgName ?? e.locationName ?? 'a beatdown',
      };
    }

    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: qEvents.keys.toSet(),
      currentQEventTitles: qEvents,
      currentUnpostedBackblastIds: unpostedTitles.keys.toSet(),
      currentUnpostedBackblastTitles: unpostedTitles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProfileService, AuthService, F3ApiService>(
      builder: (context, profile, auth, f3Api, _) {
        final hasF3 = auth.currentUser?.identities
                .any((i) => i.provider == AuthProvider.f3nation) ??
            false;

        // A confirmed-dead F3 session (revoked/expired refresh token — a
        // real 401 from an authenticated call, never a network failure; see
        // F3ApiService._markSessionInvalid). Unlink once, then fall through
        // to the same login gate !hasF3 already routes to.
        if (f3Api.sessionInvalid && !_handlingSessionInvalid) {
          _handlingSessionInvalid = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await auth.unlinkF3Nation();
            f3Api.clearSessionInvalid();
            _handlingSessionInvalid = false;
          });
        }

        // SSO-required: without an F3 Nation session, the only way in is the
        // login gate (which still exposes Emergency info with no sign-in).
        if (!hasF3 || f3Api.sessionInvalid) {
          _unlocked = false; // re-lock the local app-lock on next sign-in
          return const LoginGateScreen();
        }

        // First run after sign-in: intro + optional setup (biometric/emergency).
        if (!profile.introSeen) {
          return const OnboardingScreen();
        }

        // Optional local app-lock (biometric/PIN) layered on top of SSO.
        if (profile.appLockEnabled && !_unlocked) {
          return LocalLoginScreen(
            onUnlocked: () => setState(() => _unlocked = true),
          );
        }

        return const ShellScreen();
      },
    );
  }
}
