// lib/screens/plan_hub_screen.dart
// The "Plan" tab: the Q's toolkit for building and running a beatdown. Hosts
// Q Mode, the Weinke builder, the Exicon library, and the Spartan Co-Q as
// pushed routes. Their state lives in services (TimerService,
// CurrentWorkoutService), so opening them fresh here preserves the running
// timer and the draft plan.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/current_workout_service.dart';
import '../theme/app_theme.dart';
import 'deck_of_pain_screen.dart';
import 'library_screen.dart';
import 'spartan_chat_screen.dart';
import 'timer_screen.dart';
import 'workout_screen.dart';

class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final draftCount = context
            .watch<CurrentWorkoutService>()
            .draftPlan
            ?.allExercises
            .length ??
        0;

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Plan'),
        backgroundColor: context.f3bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Q Mode — the primary action, big and first.
          _PrimaryCard(
            icon: Icons.play_circle_rounded,
            title: 'Q Mode',
            subtitle: 'Run the live, phase-aware beatdown timer',
            onTap: () => _push(context, const TimerScreen()),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.fitness_center_rounded,
            title: 'Build a Weinke',
            subtitle: draftCount > 0
                ? '$draftCount exercises in your current plan · tap to edit'
                : 'Generate or hand-build a beatdown plan',
            color: F3Colors.accent,
            onTap: () => _push(context, const WorkoutScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.menu_book_rounded,
            title: 'Exicon',
            subtitle: 'Search & filter the full F3 exercise library',
            color: F3Colors.catBodyweight,
            onTap: () => _push(context, const LibraryScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.shield_rounded,
            title: 'Spartan Co-Q',
            subtitle: 'AI assistant for audibles, prep & FNG names',
            color: F3Colors.catCoupon,
            onTap: () => _push(context, const SpartanChatScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.style_rounded,
            title: 'Deck of Pain',
            subtitle: 'Draw a card, do the work',
            color: const Color(0xFFE53935),
            onTap: () => _push(context, const DeckOfPainScreen()),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PrimaryCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: F3Colors.accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const Icon(Icons.play_circle_rounded, color: Colors.white, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
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
            Icon(Icons.chevron_right_rounded,
                color: context.f3textMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}
