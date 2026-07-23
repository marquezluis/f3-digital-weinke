// test/weinke_exporter_test.dart
// Round-trip test for WeinkeExporter.planSummaryOnly / parseSummary — the
// linchpin of "rebuild the Weinke from an already-posted preblast": reliable
// only because the text is our own deterministic format, never hand-typed
// prose. Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_plan.dart';
import 'package:f3_nation_app/models/workout_settings.dart';
import 'package:f3_nation_app/services/exercise_service.dart';
import 'package:f3_nation_app/services/weinke_exporter.dart';

Exercise _ex(String id, String name, ExerciseCategory category,
        {List<String> aliases = const []}) =>
    Exercise(
      id: id,
      name: name,
      description: '',
      aliases: aliases,
      category: category,
      equipment:
          category == ExerciseCategory.coupon ? Equipment.coupon : Equipment.none,
      intensity: Intensity.intermediate,
    );

void main() {
  late ExerciseService service;

  setUp(() {
    service = ExerciseService()
      ..injectForTesting([
        _ex('ssh', 'SSH', ExerciseCategory.warmup),
        _ex('merkin', 'Merkin', ExerciseCategory.bodyweight, aliases: ['Pushup']),
        _ex('lbc', 'LBC', ExerciseCategory.mary),
      ]);
  });

  WorkoutPlan buildPlan() => WorkoutPlan(
        id: 'p1',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [
          WorkoutBlock(
            label: 'Warm-O-Rama',
            category: ExerciseCategory.warmup,
            exercises: [service.all[0]],
            durationMinutes: 7,
          ),
          WorkoutBlock(
            label: 'THE THANG — Bodyweight',
            category: ExerciseCategory.bodyweight,
            exercises: [service.all[1]],
            durationMinutes: 20,
            rounds: 3,
          ),
          WorkoutBlock(
            label: 'Mary',
            category: ExerciseCategory.mary,
            exercises: [service.all[2]],
            durationMinutes: 8,
          ),
        ],
      );

  group('planSummaryOnly / parseSummary round-trip', () {
    test('recovers block label, duration, rounds, category, and exercises', () {
      final plan = buildPlan();
      final text = WeinkeExporter.planSummaryOnly(plan);
      final parsed = WeinkeExporter.parseSummary(text, service);

      expect(parsed, isNotNull);
      expect(parsed!.blocks.length, 3);

      expect(parsed.blocks[0].label, 'Warm-O-Rama');
      expect(parsed.blocks[0].category, ExerciseCategory.warmup);
      expect(parsed.blocks[0].durationMinutes, 7);
      expect(parsed.blocks[0].rounds, 1);
      expect(parsed.blocks[0].exercises.single.name, 'SSH');

      expect(parsed.blocks[1].label, 'THE THANG — Bodyweight');
      expect(parsed.blocks[1].category, ExerciseCategory.bodyweight);
      expect(parsed.blocks[1].durationMinutes, 20);
      expect(parsed.blocks[1].rounds, 3);

      expect(parsed.blocks[2].category, ExerciseCategory.mary);
    });

    test('resolves parsed exercise names against the real catalog, not just names', () {
      final plan = buildPlan();
      final text = WeinkeExporter.planSummaryOnly(plan);
      final parsed = WeinkeExporter.parseSummary(text, service)!;

      // Real catalog entry, not a throwaway placeholder — carries its id.
      expect(parsed.blocks[1].exercises.single.id, 'merkin');
    });

    test('an unrecognized exercise name still shows up, not silently dropped', () {
      const text = '''
Warm-O-Rama (7 min) [warmup]
- Some Brand New Move Nobody Renamed Yet
''';
      final parsed = WeinkeExporter.parseSummary(text, service);
      expect(parsed, isNotNull);
      expect(parsed!.blocks.single.exercises.single.name,
          'Some Brand New Move Nobody Renamed Yet');
    });

    test('returns null for hand-typed prose with no recognizable block header', () {
      const text = 'Mosey to the flag, some burpees, merkins, and Mary at the end.';
      expect(WeinkeExporter.parseSummary(text, service), isNull);
    });

    test('is case-insensitive and alias-aware when matching exercise names', () {
      const text = '''
THE THANG — Bodyweight (20 min) [bodyweight]
- pushup
''';
      final parsed = WeinkeExporter.parseSummary(text, service)!;
      expect(parsed.blocks.single.exercises.single.id, 'merkin');
    });
  });

  group('WeinkeExporter.inferCouponMode', () {
    final coupon = _ex('sandbag', 'Sandbag Get-Up', ExerciseCategory.coupon);
    final bw = _ex('merkin2', 'Merkin', ExerciseCategory.bodyweight);

    WorkoutBlock block(String label, ExerciseCategory cat, List<Exercise> ex) =>
        WorkoutBlock(
            label: label,
            category: cat,
            exercises: ex,
            durationMinutes: 20);

    test('detects Mixed — Separate Blocks (two single-category blocks)', () {
      final plan = WorkoutPlan(
        id: 'p',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [
          block('THE THANG — Bodyweight', ExerciseCategory.bodyweight, [bw]),
          block('THE THANG — Coupons', ExerciseCategory.coupon, [coupon]),
        ],
      );
      expect(WeinkeExporter.inferCouponMode(plan), CouponMode.mixed);
    });

    test('detects Mixed — Same Block (one block with both categories)', () {
      final plan = WorkoutPlan(
        id: 'p',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [
          block('THE THANG', ExerciseCategory.bodyweight, [bw, coupon]),
        ],
      );
      expect(WeinkeExporter.inferCouponMode(plan), CouponMode.mixedInterleaved);
    });

    test('detects No Coupons (single bodyweight-only block)', () {
      final plan = WorkoutPlan(
        id: 'p',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [block('THE THANG', ExerciseCategory.bodyweight, [bw])],
      );
      expect(WeinkeExporter.inferCouponMode(plan), CouponMode.noCoupons);
    });

    test('detects Coupons Only (single coupon-only block)', () {
      final plan = WorkoutPlan(
        id: 'p',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [block('THE THANG', ExerciseCategory.coupon, [coupon])],
      );
      expect(WeinkeExporter.inferCouponMode(plan), CouponMode.coupons);
    });

    test('returns null when there is no Thang-like block at all', () {
      final plan = WorkoutPlan(
        id: 'p',
        generatedAt: DateTime(2026, 1, 1),
        blocks: [block('Warm-O-Rama', ExerciseCategory.warmup, [_ex('ssh2', 'SSH', ExerciseCategory.warmup)])],
      );
      expect(WeinkeExporter.inferCouponMode(plan), isNull);
    });
  });
}
