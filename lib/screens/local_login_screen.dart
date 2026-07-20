// lib/screens/local_login_screen.dart
// Optional local biometric/PIN lock layered on top of an active F3 Nation
// SSO session (see _AppEntry in main.dart) — re-shown each time the app is
// reopened while `profile.appLockEnabled` is true.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_profile_service.dart';
import '../services/local_app_lock_service.dart';
import '../theme/app_theme.dart';
import 'emergency_screen.dart';

class LocalLoginScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LocalLoginScreen({super.key, required this.onUnlocked});

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final _lock = LocalAppLockService();
  bool _checking = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    // Intentionally no auto-prompt — user must tap UNLOCK to trigger biometric.
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = '';
    });

    final ok = await _lock.authenticate();
    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
      return;
    }

    setState(() {
      _checking = false;
      _message =
          'Unlock was canceled or unavailable. Use your device Face ID, fingerprint, or PIN to continue.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProfileService>();
    final name = profile.displayName.isEmpty ? 'PAX' : profile.displayName;

    return Scaffold(
      backgroundColor: context.f3bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: F3Colors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: F3Colors.accent,
                    size: 52,
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
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: 'WEINKE',
                      style: TextStyle(
                        color: F3Colors.accent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(
                  'F3 NATION · SPARTAN UP',
                  style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, $name.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.f3textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.f3divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_rounded,
                          color: context.f3textSecondary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This local lock protects your signed-in F3 Nation session on this device.',
                          style: TextStyle(
                            color: context.f3textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: F3Colors.phaseWarmup,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _unlock,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(_checking ? 'UNLOCKING...' : 'UNLOCK APP'),
                  ),
                ),
                const SizedBox(height: 28),
                Divider(color: context.f3divider),
                const SizedBox(height: 16),
                // Life-safety: reachable without unlocking — a bystander or
                // medic can't wait on the owner's biometric/PIN. Deliberately
                // full-width and as prominent as UNLOCK, not a minor link.
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmergencyScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    icon: const Icon(Icons.emergency_rounded),
                    label: const Text('EMERGENCY INFO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
