// test/spartan_plan_builder_test.dart
// Unit tests for buildPlanFromSpartanBlocks — the pure conversion from
// SpartanService.generateWorkoutBlocks' JSON shape into a real WorkoutPlan.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_plan.dart';
import 'package:f3_nation_app/services/exercise_service.dart';
import 'package:f3_nation_app/services/spartan_plan_builder.dart';

ExerciseService _serviceWith(List<Exercise> exercises) =>
    ExerciseService()..injectForTesting(exercises);

const _merkin = Exercise(
  id: 'ex-merkin',
  name: 'Merkin',
  description: 'A push-up in F3 lingo.',
  aliases: ['push-up'],
  category: ExerciseCategory.bodyweight,
  equipment: Equipment.none,
  intensity: Intensity.intermediate,
);

void main() {
  group('buildPlanFromSpartanBlocks', () {
    test('builds a plan and resolves known exercises against the Exicon',
        () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Warm-O-Rama',
          'category': 'warmup',
          'rounds': 1,
          'durationMinutes': 5,
          'exercises': [
            {'name': 'Merkin'},
          ],
        },
      ], service);

      expect(plan, isNotNull);
      expect(plan!.blocks, hasLength(1));
      expect(plan.blocks.first.exercises.single, same(_merkin));
    });

    test('unresolved exercise names become a placeholder, not dropped', () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Part 1',
          'category': 'bodyweight',
          'rounds': 3,
          'durationMinutes': 10,
          'exercises': [
            {'name': 'Some Made-Up Move'},
          ],
        },
      ], service);

      final ex = plan!.blocks.first.exercises.single;
      expect(ex.name, 'Some Made-Up Move');
      expect(ex.id, startsWith('parsed-'));
    });

    test('applies a per-exercise callStyle when given', () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Warm-O-Rama',
          'category': 'warmup',
          'rounds': 1,
          'durationMinutes': 5,
          'exercises': [
            {'name': 'Merkin', 'callStyle': 'onYourOwn'},
          ],
        },
      ], service);

      final block = plan!.blocks.first;
      expect(block.callStyleFor(block.exercises.first.id),
          CallStyle.onYourOwn);
    });

    test('skips a block with no resolvable exercises', () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Empty Block',
          'category': 'warmup',
          'rounds': 1,
          'durationMinutes': 5,
          'exercises': <dynamic>[],
        },
        {
          'label': 'Mary',
          'category': 'mary',
          'rounds': 1,
          'durationMinutes': 5,
          'exercises': [
            {'name': 'Merkin'},
          ],
        },
      ], service);

      expect(plan!.blocks, hasLength(1));
      expect(plan.blocks.single.label, 'Mary');
    });

    test('returns null when there are no usable blocks at all', () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Empty',
          'category': 'warmup',
          'rounds': 1,
          'durationMinutes': 5,
          'exercises': <dynamic>[],
        },
      ], service);
      expect(plan, isNull);
    });

    test('returns null for an empty blocks list', () {
      final service = _serviceWith([_merkin]);
      expect(buildPlanFromSpartanBlocks([], service), isNull);
    });

    test('clamps out-of-range rounds and durationMinutes', () {
      final service = _serviceWith([_merkin]);
      final plan = buildPlanFromSpartanBlocks([
        {
          'label': 'Part 1',
          'category': 'bodyweight',
          'rounds': 999,
          'durationMinutes': 0,
          'exercises': [
            {'name': 'Merkin'},
          ],
        },
      ], service);

      final block = plan!.blocks.first;
      expect(block.rounds, lessThanOrEqualTo(20));
      expect(block.durationMinutes, greaterThanOrEqualTo(1));
    });
  });
}
