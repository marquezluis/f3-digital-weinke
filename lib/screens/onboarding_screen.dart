// lib/screens/onboarding_screen.dart
// First-run intro shown once after the first F3 sign-in. Walks the PAX through
// what the app does, then offers optional setup (app-lock biometric + emergency
// info) — both skippable. Finishing marks intro-seen and drops into the shell.

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/f3_glossary_sheet.dart';
import '../widgets/onboarding_scene.dart';
import '../widgets/org_picker.dart';
import 'emergency_edit_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<({IconData icon, String title, String body, bool showGlossaryLink})>
      _intro(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (
        icon: Icons.bolt_rounded,
        title: l10n.onboardingIntro1Title,
        body: l10n.onboardingIntro1Body,
        showGlossaryLink: false,
      ),
      (
        icon: Icons.timer_rounded,
        title: l10n.onboardingIntro2Title,
        body: l10n.onboardingIntro2Body,
        showGlossaryLink: false,
      ),
      (
        icon: Icons.groups_rounded,
        title: l10n.onboardingIntro3Title,
        body: l10n.onboardingIntro3Body,
        // This page is the first one to actually use HC/Q/preblast/
        // backblast — the exact moment a glossary link is worth something,
        // instead of buried somewhere unrelated.
        showGlossaryLink: true,
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
    // Page order: intro pages, then confirm-profile (PAX-03 in the
    // official-app wireframes), then the existing setup page (last).
    final isLast = _page == intro.length + 1;
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
                        showGlossaryLink: p.showGlossaryLink,
                      )),
                  const _ConfirmProfilePage(),
                  _SetupPage(onDone: _finish),
                ],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(intro.length + 2, (i) {
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
  final bool showGlossaryLink;
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
    this.showGlossaryLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingScene(height: 190),
          const SizedBox(height: 18),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: F3Colors.accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: F3Colors.accent, size: 28),
          ),
          const SizedBox(height: 20),
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
          if (showGlossaryLink) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => showF3GlossarySheet(context),
              child: const Text('What do these words mean?'),
            ),
          ],
        ],
      ),
    );
  }
}

/// PAX-03 in the official-app wireframes: confirm the profile and home
/// region the real F3 Nation sign-in already resolved
/// (LoginGateScreen._signIn). Nothing here re-fetches anything — it
/// surfaces what sign-in already populated and lets a PAX fix the region
/// right away if it came back wrong, via the same org picker Profile's own
/// "Change region" uses.
class _ConfirmProfilePage extends StatefulWidget {
  const _ConfirmProfilePage();

  @override
  State<_ConfirmProfilePage> createState() => _ConfirmProfilePageState();
}

class _ConfirmProfilePageState extends State<_ConfirmProfilePage> {
  Future<void> _changeRegion() async {
    final api = context.read<F3ApiService>();
    final picked = await showOrgPickerSheet(context, fetchOrgs: api.getOrgs);
    if (picked == null || !mounted) return;
    api.userOrgId = picked.id;
    final profile = context.read<AppProfileService>();
    // Pass every field through explicitly — updateProfile replaces the
    // whole record, and omitting displayName/authUserId here would wipe
    // them back to the guest fallback (same bug ProfileScreen._changeRegion
    // already guards against).
    await profile.updateProfile(
      role: profile.role,
      displayName: profile.displayName,
      homeAo: profile.homeAo,
      region: picked.name,
      authUserId: profile.authUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProfileService>();
    final linked = context.watch<AuthService>().currentUser?.identities.any(
              (i) => i.provider == AuthProvider.f3nation,
            ) ??
        false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_rounded, color: F3Colors.accent, size: 56),
          const SizedBox(height: 20),
          Text("You're in",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              linked
                  ? "Here's what F3 Nation has on file. Not right? Fix your region now — your name comes from your F3 Nation profile."
                  : "Here's your local profile.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 14.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.f3card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.f3divider),
            ),
            child: Column(
              children: [
                _ConfirmRow(
                    icon: Icons.person_rounded,
                    label: 'Name',
                    value: profile.displayName.isEmpty
                        ? '—'
                        : profile.displayName),
                const SizedBox(height: 10),
                _ConfirmRow(
                    icon: Icons.map_rounded,
                    label: 'Home region',
                    value:
                        profile.region.isEmpty ? 'Not set' : profile.region),
              ],
            ),
          ),
          if (linked) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _changeRegion,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Change region'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.f3textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: context.f3textMuted, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ),
      ],
    );
  }
}

class _SetupPage extends StatefulWidget {
  final VoidCallback onDone;
  const _SetupPage({required this.onDone});

  @override
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  late final ConfettiController _confettiCtrl;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _enterApp() async {
    final reduced = context.read<SettingsService>().reducedMotion ||
        MediaQuery.of(context).disableAnimations;
    if (reduced) {
      widget.onDone();
      return;
    }
    // A brief celebratory beat before dropping into the shell — arriving
    // should feel like something, not just another settings tap.
    setState(() => _celebrating = true);
    _confettiCtrl.play();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProfileService>();
    final l10n = AppLocalizations.of(context)!;
    return Stack(alignment: Alignment.topCenter, children: [
      Padding(
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
            onPressed: _celebrating ? null : _enterApp,
            child: Text(l10n.onboardingEnterApp),
          ),
        ],
      ),
      ),
      ConfettiWidget(
        confettiController: _confettiCtrl,
        blastDirection: 1.5708, // pi/2, straight down
        numberOfParticles: 24,
        gravity: 0.25,
        emissionFrequency: 0.08,
        colors: const [F3Colors.accent, Colors.white, Colors.yellow],
      ),
    ]);
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
