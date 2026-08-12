// lib/widgets/exercise_detail_sheet.dart
// Full-detail bottom sheet for a single exercise.
// Shows description, aliases, category, intensity, and "Add to Weinke" block picker.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/exercise.dart';
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import 'category_chip.dart';
import 'intensity_badge.dart';

class ExerciseDetailSheet extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailSheet({super.key, required this.exercise});

  static void show(BuildContext context, Exercise exercise) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final catColor = F3Colors.forCategory(ex.category.name);
    final workoutSvc = context.read<CurrentWorkoutService>();
    final draft = workoutSvc.draftPlan;
    final isOfficial = context.watch<ExerciseService>().isOfficial(ex);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: context.f3divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
                    CategoryChip(category: ex.category, small: true),
                    IntensityBadge(intensity: ex.intensity),
                    if (ex.equipment == Equipment.coupon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: F3Colors.catCoupon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.fitness_center_rounded,
                              size: 12, color: F3Colors.catCoupon),
                          SizedBox(width: 4),
                          Text('COUPON',
                              style: TextStyle(
                                  color: F3Colors.catCoupon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOfficial ? F3Colors.phaseWarmup : context.f3textMuted)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            isOfficial
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            size: 12,
                            color: isOfficial
                                ? F3Colors.phaseWarmup
                                : context.f3textMuted),
                        const SizedBox(width: 4),
                        Text(isOfficial ? 'OFFICIAL' : 'PENDING',
                            style: TextStyle(
                                color: isOfficial
                                    ? F3Colors.phaseWarmup
                                    : context.f3textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(ex.name,
                      style: TextStyle(
                          color: catColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  if (ex.aliases.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('AKA: ${ex.aliases.join(' · ')}',
                        style: TextStyle(
                            color: context.f3textMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ],
                  // Prefer the curated, plain-language explanation when we
                  // have one — the official Exicon description is often
                  // dense/jargon-heavy prose that's exactly what's confusing
                  // about an exercise nobody on this team has actually run
                  // before. Still shown underneath for the full detail.
                  if (ex.simpleExplanation != null) ...[
                    const SizedBox(height: 16),
                    Text(ex.simpleExplanation!,
                        style: TextStyle(
                            color: context.f3textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.6)),
                  ],
                  if (ex.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(ex.description,
                        style: TextStyle(
                            color: context.f3textSecondary,
                            fontSize: 15,
                            height: 1.6)),
                  ],
                  if (ex.videoLink != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(ex.videoLink!);
                        var launched = false;
                        if (uri != null) {
                          try {
                            launched = await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } catch (_) {
                            launched = false;
                          }
                        }
                        if (!launched && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Couldn't open the demo video.")),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: const Text('WATCH DEMO'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: catColor,
                        side: BorderSide(color: catColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                  if (ex.modification != null) ...[
                    const SizedBox(height: 12),
                    _DetailNote(
                      icon: Icons.tune_rounded,
                      label: 'MODIFICATION',
                      text: ex.modification!,
                      color: F3Colors.accent,
                    ),
                  ],
                  if (ex.safetyCue != null) ...[
                    const SizedBox(height: 8),
                    _DetailNote(
                      icon: Icons.shield_rounded,
                      label: 'SAFETY CUE',
                      text: ex.safetyCue!,
                      color: catColor,
                    ),
                  ],
                  if (draft != null) ...[
                    const SizedBox(height: 24),
                    Text('ADD TO WEINKE',
                        style: TextStyle(
                            color: context.f3textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...draft.blocks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final block = entry.value;
                      final alreadyIn =
                          block.exercises.any((e) => e.id == ex.id);
                      final blockColor =
                          F3Colors.forCategory(block.category.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          onPressed: alreadyIn
                              ? null
                              : () {
                                  workoutSvc.addExerciseToDraftBlock(i, ex);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        '${ex.name} added to ${block.label}'),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                          icon: Icon(
                              alreadyIn
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 16),
                          label: Text(
                            alreadyIn
                                ? '${block.label} — already added'
                                : block.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                alreadyIn ? context.f3textMuted : blockColor,
                            side: BorderSide(
                                color: alreadyIn
                                    ? context.f3divider
                                    : blockColor.withValues(alpha: 0.5)),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 24),
                    Text(
                      'Generate a Weinke on the Weinke tab to add exercises directly.',
                      style: TextStyle(
                          color: context.f3textMuted,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailNote extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  const _DetailNote({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
