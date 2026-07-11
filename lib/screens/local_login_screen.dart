// lib/screens/local_login_screen.dart
// Returning-user local unlock screen while OAuth/account auth is not ready.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_profile_service.dart';
import '../services/local_app_lock_service.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: F3Colors.background,
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
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'DIGITAL ',
                      style: TextStyle(
                        color: F3Colors.textPrimary,
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
                const Text(
                  'F3 NATION · SPARTAN UP',
                  style: TextStyle(
                    color: F3Colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, $name.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: F3Colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: F3Colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: F3Colors.divider),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_rounded,
                          color: F3Colors.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is local device protection, not an online account. OAuth can be added later without changing this screen.',
                          style: TextStyle(
                            color: F3Colors.textSecondary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
