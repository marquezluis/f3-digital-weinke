// lib/screens/onboarding_screen.dart
// First-run intro shown once after the first F3 sign-in. Walks the PAX through
// what the app does, then offers optional setup (app-lock biometric + emergency
// info) — both skippable. Finishing marks intro-seen and drops into the shell.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_profile_service.dart';
import '../theme/app_theme.dart';
import 'emergency_edit_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<({IconData icon, String title, String body})> _intro(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (
        icon: Icons.bolt_rounded,
        title: l10n.onboardingIntro1Title,
        body: l10n.onboardingIntro1Body,
      ),
      (
        icon: Icons.timer_rounded,
        title: l10n.onboardingIntro2Title,
        body: l10n.onboardingIntro2Body,
      ),
      (
        icon: Icons.groups_rounded,
        title: l10n.onboardingIntro3Title,
        body: l10n.onboardingIntro3Body,
      ),
    ];
  }

  Future<void> _finish() async {
    await context.read<AppProfileService>().markIntroSeen();
    // The app root watches AppProfileService and rebuilds into the shell.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intro = _intro(context);
    final isLast = _page == intro.length; // last page = the setup page
    return Scaffold(
      backgroundColor: context.f3bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(AppLocalizations.of(context)!.onboardingSkip,
                    style: TextStyle(color: context.f3textMuted)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ...intro.map((p) => _IntroPage(
                        icon: p.icon,
                        title: p.title,
                        body: p.body,
                      )),
                  _SetupPage(onDone: _finish),
                ],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(intro.length + 1, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? F3Colors.accent : context.f3divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: F3Colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: Text(AppLocalizations.of(context)!.onboardingNext),
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _IntroPage(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: F3Colors.accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: F3Colors.accent, size: 46),
          ),
          const SizedBox(height: 28),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final VoidCallback onDone;
  const _SetupPage({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProfileService>();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.onboardingSetupTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(l10n.onboardingSetupSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: F3Colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: F3Colors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.onboardingPermissionsNotice,
                    style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SetupTile(
            icon: Icons.fingerprint_rounded,
            title: l10n.onboardingAppLockTitle,
            subtitle: profile.appLockEnabled
                ? l10n.onboardingAppLockEnabled
                : l10n.onboardingAppLockSubtitle,
            trailing: profile.appLockEnabled
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.green)
                : null,
            onTap: profile.appLockEnabled
                ? null
                : () => profile.setAppLockEnabled(true),
          ),
          const SizedBox(height: 10),
          _SetupTile(
            icon: Icons.emergency_rounded,
            title: l10n.onboardingEmergencyTitle,
            subtitle: l10n.onboardingEmergencySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyEditScreen()),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: F3Colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: onDone,
            child: Text(l10n.onboardingEnterApp),
          ),
        ],
      ),
    );
  }
}

class _SetupTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SetupTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.f3card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(children: [
            Icon(icon, color: F3Colors.accent, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
          ]),
        ),
      ),
    );
  }
}
