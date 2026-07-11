// test/exercise_service_test.dart
// Unit tests for Exercise model, ExerciseService, and WorkoutGenerator.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_settings.dart';
import 'package:f3_nation_app/services/exercise_service.dart';
import 'package:f3_nation_app/services/workout_generator.dart';

void main() {
  // ── ExerciseCategory ──────────────────────────────────────────────────────
  group('ExerciseCategory', () {
    test('fromString parses all values', () {
      expect(ExerciseCategory.fromString('warmup'), ExerciseCategory.warmup);
      expect(ExerciseCategory.fromString('coupon'), ExerciseCategory.coupon);
      expect(ExerciseCategory.fromString('mary'), ExerciseCategory.mary);
      expect(ExerciseCategory.fromString('bodyweight'),
          ExerciseCategory.bodyweight);
      expect(
          ExerciseCategory.fromString('unknown'), ExerciseCategory.bodyweight);
    });

    test('displayName returns F3-standard phase names', () {
      expect(ExerciseCategory.warmup.displayName, 'Warm-O-Rama');
      expect(ExerciseCategory.bodyweight.displayName, 'Bodyweight');
      expect(ExerciseCategory.coupon.displayName, 'Coupon');
      expect(ExerciseCategory.mary.displayName, 'Mary');
    });
  });

  // ── Intensity ─────────────────────────────────────────────────────────────
  group('Intensity', () {
    test('fromString parses all values', () {
      expect(Intensity.fromString('beginner'), Intensity.beginner);
      expect(Intensity.fromString('intermediate'), Intensity.intermediate);
      expect(Intensity.fromString('advanced'), Intensity.advanced);
      expect(Intensity.fromString('unknown'), Intensity.intermediate);
    });
  });

  // ── Exercise.fromJson ─────────────────────────────────────────────────────
  group('Exercise.fromJson', () {
    test('parses a complete record', () {
      final json = {
        'id': 'test-001',
        'name': 'Merkin',
        'description': 'A push-up in F3 lingo.',
        'aliases': ['push-up'],
        'category': 'bodyweight',
        'equipment': 'none',
        'intensity': 'intermediate',
      };
      final ex = Exercise.fromJson(json);
      expect(ex.id, 'test-001');
      expect(ex.name, 'Merkin');
      expect(ex.category, ExerciseCategory.bodyweight);
      expect(ex.equipment, Equipment.none);
      expect(ex.intensity, Intensity.intermediate);
      expect(ex.aliases, ['push-up']);
    });

    test('handles missing optional fields gracefully', () {
      final ex = Exercise.fromJson({'id': 'x', 'name': 'Test'});
      expect(ex.description, '');
      expect(ex.aliases, isEmpty);
      expect(ex.category, ExerciseCategory.bodyweight);
      expect(ex.intensity, Intensity.intermediate);
    });
  });

  // ── WorkoutGenerator ──────────────────────────────────────────────────────
  group('WorkoutGenerator — mixed mode', () {
    late ExerciseService service;

    setUp(() => service = _buildSyntheticService());

    test('generates 4 blocks totaling 50 minutes (mixed)', () {
      final plan = WorkoutGenerator(service).generate();
      // mixed = 4 blocks: warmup, bw, coupon, mary
      // (bw + coupon counted as 2 blocks = total 4)
      expect(plan.blocks.length, 4);
      expect(plan.totalMinutes, 50);
    });

    test('keeps requested duration when mixed thang has odd minutes', () {
      const settings = WorkoutSettings(durationMinutes: 45);
      final plan = WorkoutGenerator(service).generate(settings);
      expect(plan.totalMinutes, 45);
    });

    test('warmup block is always first', () {
      final plan = WorkoutGenerator(service).generate();
      expect(plan.blocks.first.category, ExerciseCategory.warmup);
    });

    test('mary block is always last', () {
      final plan = WorkoutGenerator(service).generate();
      expect(plan.blocks.last.category, ExerciseCategory.mary);
    });

    test('exercises within a block are unique', () {
      final plan = WorkoutGenerator(service).generate();
      for (final block in plan.blocks) {
        final ids = block.exercises.map((e) => e.id).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'Duplicate in block ${block.label}');
      }
    });

    test('successive plans differ (randomness)', () {
      final gen = WorkoutGenerator(service);
      final plans = List.generate(6, (_) => gen.generate());
      final first = plans.first.allExercises.map((e) => e.id).toSet();
      final anyDiffers = plans
          .skip(1)
          .any((p) => p.allExercises.map((e) => e.id).toSet() != first);
      expect(anyDiffers, isTrue);
    });
  });

  group('WorkoutGenerator — coupon modes', () {
    late ExerciseService service;
    setUp(() => service = _buildSyntheticService());

    test('noCoupons mode has no coupon exercises', () {
      const settings = WorkoutSettings(couponMode: CouponMode.noCoupons);
      final plan = WorkoutGenerator(service).generate(settings);
      final hasCoupons =
          plan.allExercises.any((e) => e.equipment == Equipment.coupon);
      expect(hasCoupons, isFalse);
    });

    test('coupons mode has only coupon thang block', () {
      const settings = WorkoutSettings(couponMode: CouponMode.coupons);
      final plan = WorkoutGenerator(service).generate(settings);
      final thangBlocks =
          plan.blocks.where((b) => b.label.contains('Thang')).toList();
      expect(thangBlocks.length, 1);
      expect(thangBlocks.first.category, ExerciseCategory.coupon);
    });
  });

  group('WorkoutGenerator — formats', () {
    late ExerciseService service;
    setUp(() => service = _buildSyntheticService());

    test('AMRAP format labels the thang and keeps requested duration', () {
      const settings = WorkoutSettings(format: WorkoutFormat.amrap);
      final plan = WorkoutGenerator(service).generate(settings);
      expect(
        plan.blocks.where((b) => b.label.contains('AMRAP')).length,
        greaterThan(0),
      );
      expect(plan.totalMinutes, settings.durationMinutes);
    });

    test('simple Q mode reduces mixed block movement count', () {
      const settings = WorkoutSettings(simpleQMode: true);
      final plan = WorkoutGenerator(service).generate(settings);
      final thangBlocks =
          plan.blocks.where((b) => b.label.contains('Thang')).toList();
      expect(thangBlocks, hasLength(2));
      expect(thangBlocks.every((b) => b.exercises.length <= 3), isTrue);
    });
  });

  group('WorkoutGenerator — swapExercise', () {
    late ExerciseService service;
    setUp(() => service = _buildSyntheticService());

    test('returns a different exercise for the same category', () {
      final plan = WorkoutGenerator(service).generate();
      final original = plan.allExercises.first;
      final generator = WorkoutGenerator(service);
      final swapped = generator.swapExercise(original, plan);
      // With 8 exercises per category, a swap should always succeed.
      expect(swapped.id, isNot(equals(original.id)));
      expect(swapped.category, original.category);
    });

    test('returns original exercise when no replacement exists', () {
      final service = ExerciseService()
        ..injectForTesting([
          const Exercise(
            id: 'only-one',
            name: 'Solo Merkin',
            description: 'Test',
            aliases: [],
            category: ExerciseCategory.bodyweight,
            equipment: Equipment.none,
            intensity: Intensity.intermediate,
          ),
        ]);
      final original = service.all.single;
      final plan = WorkoutGenerator(service).generate(
        const WorkoutSettings(couponMode: CouponMode.noCoupons),
      );
      final swapped = WorkoutGenerator(service).swapExercise(original, plan);
      expect(swapped, same(original));
    });
  });
}

// ─── Synthetic ExerciseService (no asset loading) ─────────────────────────────

ExerciseService _buildSyntheticService() {
  final service = ExerciseService();
  final exercises = <Exercise>[];
  int counter = 0;
  for (final cat in ExerciseCategory.values) {
    for (final intensity in Intensity.values) {
      for (int i = 0; i < 3; i++) {
        counter++;
        exercises.add(Exercise(
          id: 'test-$counter',
          name: '${cat.displayName} ${intensity.displayName} $i',
          description: 'Test',
          aliases: [],
          category: cat,
          equipment: cat == ExerciseCategory.coupon
              ? Equipment.coupon
              : Equipment.none,
          intensity: intensity,
        ));
      }
    }
  }
  service.injectForTesting(exercises);
  return service;
}
