// lib/screens/welcome_fork_screen.dart
// The very first screen for a signed-out visitor (FNG-01 in the official
// F3 Nation app's wireframes): "I'm new to F3" vs "I already post with
// F3." Replaces jumping straight into LoginGateScreen's sign-in UI, which
// made no distinction between the two — a brand-new visitor and a
// returning PAX have different first questions ("what even is this?" vs
// "let me sign in").
//
// PAX path: pushes the existing LoginGateScreen unchanged — that screen
// already does F3 SSO sign-in and resolves the signed-in PAX's home region
// as part of _signIn() (PAX-03's "confirm home region" happens there,
// automatically, from the real F3 Nation profile — no separate
// confirmation step invented, since the API already returns an
// authoritative answer).
// FNG path: pushes FngWelcomeScreen (browse map → lingo card →
// notification prefs → an honest placeholder, since F3 Nation's API has
// no account-creation or region-approval endpoint for this app to call).

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'fng_welcome_screen.dart';
import 'login_gate_screen.dart';

class WelcomeForkScreen extends StatelessWidget {
  const WelcomeForkScreen({super.key});

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
              Text('The Q\'s cheat sheet — digitized.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.f3textSecondary, fontSize: 15)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginGateScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('I already post with F3'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FngWelcomeScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.f3textPrimary,
                  side: BorderSide(color: context.f3divider),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('I\'m new to F3'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
