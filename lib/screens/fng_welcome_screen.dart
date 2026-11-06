// lib/screens/fng_welcome_screen.dart
// The "I'm new to F3" path from WelcomeForkScreen (FNG-02..06 in the
// official-app wireframes): browse the map first, a lingo primer,
// notification prefs, then an honest placeholder — the F3 Nation API has
// no account-creation or region-approval endpoint, so this app can't
// fabricate either. Ends by handing off to the real PAX sign-in path
// (LoginGateScreen) for whenever they're ready, rather than dead-ending.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/f3_glossary_sheet.dart';
import 'browse_aos_screen.dart';
import 'login_gate_screen.dart';

class FngWelcomeScreen extends StatefulWidget {
  const FngWelcomeScreen({super.key});

  @override
  State<FngWelcomeScreen> createState() => _FngWelcomeScreenState();
}

class _FngWelcomeScreenState extends State<FngWelcomeScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pageCount - 1) return;
    _controller.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        backgroundColor: context.f3bg,
        title: const Text('New to F3'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _BrowseStep(onContinue: _next),
                  _LingoStep(onContinue: _next),
                  const _NotifAndPlaceholderStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? F3Colors.accent
                          : context.f3divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? extra;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.body,
    this.extra,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: F3Colors.accent, size: 56),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 14.5)),
          if (extra != null) ...[const SizedBox(height: 20), extra!],
          if (buttonLabel != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(buttonLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrowseStep extends StatelessWidget {
  final VoidCallback onContinue;
  const _BrowseStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.map_rounded,
      title: 'Find a workout near you',
      body: 'F3 is free, outdoors, and open to any man. See real AOs '
          '(workout locations) before you decide to show up.',
      buttonLabel: 'Browse the map',
      onButtonTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BrowseAosScreen())),
      extra: TextButton(
        onPressed: onContinue,
        child: Text('Continue',
            style: TextStyle(color: context.f3textMuted)),
      ),
    );
  }
}

class _LingoStep extends StatelessWidget {
  final VoidCallback onContinue;
  const _LingoStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.translate_rounded,
      title: 'F3 has its own language',
      body: 'AO, Q, Weinke, Backblast, COT — it sounds like a lot at '
          'first. The Lexicon decodes it, and it\'s always one tap away '
          'from Resources later too.',
      buttonLabel: 'Open the Lexicon',
      onButtonTap: () => showF3GlossarySheet(context),
      extra: TextButton(
        onPressed: onContinue,
        child: Text('Continue',
            style: TextStyle(color: context.f3textMuted)),
      ),
    );
  }
}

class _NotifAndPlaceholderStep extends StatefulWidget {
  const _NotifAndPlaceholderStep();

  @override
  State<_NotifAndPlaceholderStep> createState() =>
      _NotifAndPlaceholderStepState();
}

class _NotifAndPlaceholderStepState extends State<_NotifAndPlaceholderStep> {
  Future<void> _toggleNotif(bool value) async {
    final settings = context.read<SettingsService>();
    if (value) await NotificationService().requestPermissions();
    await settings.updateNotifEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final notifEnabled = context.watch<SettingsService>().notifEnabled;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          Icon(Icons.notifications_active_rounded,
              color: F3Colors.accent, size: 56),
          const SizedBox(height: 20),
          Text('Stay in the loop',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(
              'A local reminder before a planned beatdown — nothing sent '
              'off this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 14.5)),
          const SizedBox(height: 16),
          SwitchListTile(
            value: notifEnabled,
            onChanged: _toggleNotif,
            title: Text('Beatdown reminders',
                style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
            activeThumbColor: F3Colors.accent,
          ),
          const SizedBox(height: 28),
          // Honest placeholder: the F3 Nation API has neither an
          // account-creation endpoint nor a region_membership_status
          // field for this app to request approval against — see
          // docs/wireframe-mapping.md.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.f3elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.f3divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.f3textMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('No account creation here — yet',
                        style: TextStyle(
                            color: context.f3textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                    'Creating a brand-new F3 Nation account, and a region '
                    'approving you as a PAX, both happen on F3 Nation\'s '
                    'side — this app has no API access to either yet. '
                    'Once you have an F3 Nation account (ask at an AO, or '
                    'post once and your region\'s SLT usually sets one up '
                    'for you), sign in here with it.',
                    style: TextStyle(
                        color: context.f3textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginGateScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.f3textPrimary,
                side: BorderSide(color: context.f3divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('I already have an F3 Nation account'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
