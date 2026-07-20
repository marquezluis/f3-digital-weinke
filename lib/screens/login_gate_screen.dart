// lib/screens/login_gate_screen.dart
// SSO gate: the app now requires an F3 Nation sign-in. This is the first
// screen an unauthenticated user sees (there is no guest/manual path anymore).
//
// Life-safety exception: an "Emergency" button here opens the emergency info
// WITHOUT any sign-in, biometric, or network — a bystander or medic must be
// able to reach it. (The OS lock screen is a separate layer we can't override;
// the emergency screen nudges users to also fill their native Medical ID.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart' hide AppRole;
import '../theme/app_theme.dart';
import '../widgets/theme_language_picker.dart';
import 'emergency_screen.dart';

class LoginGateScreen extends StatefulWidget {
  const LoginGateScreen({super.key});

  @override
  State<LoginGateScreen> createState() => _LoginGateScreenState();
}

class _LoginGateScreenState extends State<LoginGateScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();

    try {
      final user = await auth.signInWithF3Nation();
      F3UserProfile? f3;
      final token = await auth.getF3AccessToken();
      if (token != null) {
        f3 = await api.getMyProfile(userAccessToken: token);
      }
      // Resolve the region org id right away so schedule/AO/publish calls
      // work without needing a separate Settings sync first.
      if ((f3?.homeRegionId ?? '').isNotEmpty) {
        api.userOrgId = f3!.homeRegionId;
      }
      // Prefer the freshly fetched F3 profile, then the auth user, and finally
      // fall back to whatever we already had stored — never clobber a good
      // name/region with 'PAX'/'' just because a profile fetch failed (e.g. on
      // a silent re-login where the token refresh didn't return a fresh one).
      final name = (f3?.displayName.isNotEmpty ?? false)
          ? f3!.displayName
          : (user.displayName.isNotEmpty
              ? user.displayName
              : (profile.displayName.isNotEmpty
                  ? profile.displayName
                  : 'PAX'));
      final region = (f3?.homeRegionName?.isNotEmpty ?? false)
          ? f3!.homeRegionName!
          : profile.region;
      // `user.id` is the local app account's own id (a guest UUID before
      // linking) — every F3 Nation write (HC, take-Q, preblast, Schedule's
      // calendar-home-schedule query) needs the real numeric F3 user id
      // instead, or they silently no-op/fail. Prefer the freshly fetched F3
      // profile's id; never regress to the guest id once we've had a real one.
      final authUserId = (f3?.id.isNotEmpty ?? false) ? f3!.id : profile.authUserId;
      await profile.completeWelcome(
        role: AppRole.q,
        displayName: name,
        region: region,
        authUserId: authUserId,
        appLockEnabled: profile.appLockEnabled,
      );
      if (f3?.avatarUrl != null) {
        await profile.applyF3Profile(avatarUrl: f3!.avatarUrl);
      }
      // No navigation needed: the app root (_AppEntry) watches AuthService and
      // rebuilds into the shell once the F3 identity is present.
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // ── Logo lockup (theme-aware, widget-composed) ────────────────
              Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [F3Colors.accent, Color(0xFFB5462F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: F3Colors.accent.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(
                    text: 'DIGITAL ',
                    style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2),
                  ),
                  const TextSpan(
                    text: 'WEINKE',
                    style: TextStyle(
                        color: F3Colors.accent,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.f3divider),
                    color: context.f3card,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.loginGateForF3Nation,
                    style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Language + theme, right up front — this is the very first
              // screen a non-English-speaking PAX sees, so switching out of
              // English shouldn't require getting through an all-English
              // sign-in flow (and further into Settings) first.
              Consumer<SettingsService>(
                builder: (context, settings, _) => Column(
                  children: [
                    LanguagePicker(
                      current: settings.locale.languageCode,
                      onSelect: (code) => settings.setLocale(Locale(code)),
                    ),
                    const SizedBox(height: 8),
                    ThemePicker(
                      current: settings.themeMode,
                      onSelect: (mode) => settings.setThemeMode(mode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context)!.loginGateSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.f3textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _busy ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_busy
                    ? AppLocalizations.of(context)!.loginGateSigningIn
                    : AppLocalizations.of(context)!.loginGateSignIn),
              ),
              const Spacer(),
              // Life-safety: reachable with no auth, no network.
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.emergency_rounded),
                label: Text(AppLocalizations.of(context)!.loginGateEmergencyInfo),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
