// lib/widgets/exercise_detail_sheet.dart
// Full-detail bottom sheet for a single exercise.
// Shows description, aliases, category, intensity, and "Add to Weinke" block picker.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../services/current_workout_service.dart';
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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: F3Colors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: F3Colors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Row(children: [
                    CategoryChip(category: ex.category, small: true),
                    const SizedBox(width: 8),
                    IntensityBadge(intensity: ex.intensity),
                    if (ex.equipment == Equipment.coupon) ...[
                      const SizedBox(width: 8),
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
                    ],
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
                        style: const TextStyle(
                            color: F3Colors.textMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ],
                  if (ex.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(ex.description,
                        style: const TextStyle(
                            color: F3Colors.textSecondary,
                            fontSize: 15,
                            height: 1.6)),
                  ],
                  if (draft != null) ...[
                    const SizedBox(height: 24),
                    const Text('ADD TO WEINKE',
                        style: TextStyle(
                            color: F3Colors.textMuted,
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
                                alreadyIn ? F3Colors.textMuted : blockColor,
                            side: BorderSide(
                                color: alreadyIn
                                    ? F3Colors.divider
                                    : blockColor.withValues(alpha: 0.5)),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Generate a Weinke on the Weinke tab to add exercises directly.',
                      style: TextStyle(
                          color: F3Colors.textMuted,
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
