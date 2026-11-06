// lib/screens/resources_hub_screen.dart
// The "Resources" tab (RES-01..06 in the official-app wireframes): Q Tools,
// The Codex (Exicon + Lexicon), QSource, and App Help, grouped under one
// hub — replaces the former "Plan" tab, which only ever exposed a subset of
// this (Q Mode, Weinke, Exicon, Deck of Pain) under a less specific label.
// Q Builder was previously built but unreachable from anywhere in the
// app — wiring it in here is a real fix, not just a relabel.
//
// Deliberately NOT built: e-books (Freed to Lead) — this app has no rights
// to redistribute that content. App Help below is a real static screen,
// not a dead link, but intentionally light — there's no support ticketing
// system behind it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/current_workout_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/q_mode_transition.dart';
import '../widgets/f3_glossary_sheet.dart';
import 'deck_of_pain_screen.dart';
import 'library_screen.dart';
import 'q_builder_screen.dart';
import 'qsource_screen.dart';
import 'timer_screen.dart';
import 'workout_screen.dart';

class ResourcesHubScreen extends StatelessWidget {
  const ResourcesHubScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _pushQMode(BuildContext context) {
    final reducedMotion = context.read<SettingsService>().reducedMotion;
    Navigator.push(context,
        qModeRoute(const TimerScreen(), reducedMotion: reducedMotion));
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
        title: const Text('Resources'),
        backgroundColor: context.f3bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Q Mode — the primary action, big and first.
          _PrimaryCard(
            title: 'Q Mode',
            subtitle: 'Run the live, phase-aware beatdown timer',
            onTap: () => _pushQMode(context),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Q TOOLS'),
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
            icon: Icons.auto_awesome_rounded,
            title: 'Q Builder',
            subtitle: 'Structure, tips, and prep for your next Q',
            color: F3Colors.catMary,
            onTap: () => _push(context, const QBuilderScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.style_rounded,
            title: 'Deck of Pain',
            subtitle: 'Draw a card, do the work',
            color: const Color(0xFFE53935),
            onTap: () => _push(context, const DeckOfPainScreen()),
          ),
          const SizedBox(height: 20),
          _SectionLabel('THE CODEX'),
          _ToolCard(
            icon: Icons.menu_book_rounded,
            title: 'Exicon',
            subtitle: 'Search & filter the full F3 exercise library',
            color: F3Colors.catBodyweight,
            onTap: () => _push(context, const LibraryScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.translate_rounded,
            title: 'Lexicon',
            subtitle: 'F3 lingo, decoded',
            color: F3Colors.catCoupon,
            onTap: () => showF3GlossarySheet(context),
          ),
          const SizedBox(height: 20),
          _SectionLabel('QSOURCE'),
          _ToolCard(
            icon: Icons.school_rounded,
            title: 'QSource',
            subtitle: 'Leadership curriculum & session formats',
            color: F3Colors.phaseDisclaimer,
            onTap: () => _push(context, const QSourceScreen()),
          ),
          const SizedBox(height: 20),
          _SectionLabel('APP HELP'),
          _ToolCard(
            icon: Icons.help_outline_rounded,
            title: 'Help & About',
            subtitle: 'Where to find things, and who built this',
            color: context.f3textMuted,
            onTap: () => _push(context, const _AppHelpScreen()),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text,
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PrimaryCard(
      {required this.title, required this.subtitle, required this.onTap});

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
            Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
          ]),
        ),
      ),
    );
  }
}

class _AppHelpScreen extends StatelessWidget {
  const _AppHelpScreen();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.map_rounded, 'Finding an AO',
          'Map/Cal tab → Map view. Search or filter by workout type.'),
      (Icons.event_rounded, 'HC\'ing or taking Q',
          'Map/Cal tab → Calendar view → tap a beatdown → HC or Take Q.'),
      (Icons.menu_book_rounded, 'Looking up an exercise',
          'Resources tab → The Codex → Exicon. Search by name or alias.'),
      (Icons.badge_rounded, 'Editing your F3 Nation profile',
          'Profile tab → Edit (pencil icon).'),
      (Icons.medical_services_rounded, 'Emergency contact info',
          'Profile tab → Emergency Info. Stored on this device only, '
              'never synced.'),
    ];
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Help & About'),
        backgroundColor: context.f3bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (icon, title, body) in items) ...[
            Material(
              color: context.f3card,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: F3Colors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  color: context.f3textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(body,
                              style: TextStyle(
                                  color: context.f3textSecondary,
                                  fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Center(
            child: Text('Digital Weinke — an unofficial utility built by PAX, for PAX.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.f3textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
