// lib/main.dart
// Digital Weinke — F3 Nation local-first bootcamp planner.
// Entry point: loads exercise data and settings, then launches the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_profile_service.dart';
import 'services/auth_service.dart';
import 'services/current_workout_service.dart';
import 'services/exercise_service.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'services/region_service.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';
import 'services/spartan_service.dart';
import 'config/app_config.dart';
import 'screens/shell_screen.dart';
import 'screens/local_login_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
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

  runApp(DigitalWeinke(
    exerciseService: exerciseService,
    appProfileService: appProfileService,
    authService: authService,
    settingsService: settingsService,
    historyService: historyService,
    regionService: regionService,
  ));
}

class DigitalWeinke extends StatelessWidget {
  final ExerciseService exerciseService;
  final AppProfileService appProfileService;
  final AuthService authService;
  final SettingsService settingsService;
  final HistoryService historyService;
  final RegionService regionService;

  const DigitalWeinke({
    super.key,
    required this.exerciseService,
    required this.appProfileService,
    required this.authService,
    required this.settingsService,
    required this.historyService,
    required this.regionService,
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
        ChangeNotifierProvider<TimerService>(create: (_) => TimerService()),
        ChangeNotifierProvider<CurrentWorkoutService>(
          create: (_) => CurrentWorkoutService(),
        ),
        ChangeNotifierProvider<ValueNotifier<int>>(
          create: (_) => ValueNotifier<int>(0),
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

class _AppEntryState extends State<_AppEntry> {
  bool _entered = false;
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProfileService>(
      builder: (context, profile, _) {
        if (!profile.welcomeComplete) {
          return WelcomeScreen(
            onComplete: () => setState(() {
              _entered = true;
              _unlocked = true;
            }),
          );
        }

        if (profile.appLockEnabled && !_unlocked) {
          return LocalLoginScreen(
            onUnlocked: () => setState(() => _unlocked = true),
          );
        }

        if (_entered || profile.welcomeComplete) {
          return const ShellScreen();
        }

        return const ShellScreen();
      },
    );
  }
}
