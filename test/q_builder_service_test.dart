// test/q_builder_service_test.dart
// Unit tests for the offline QBuilder orchestration layer.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_settings.dart';
import 'package:f3_nation_app/services/exercise_service.dart';
import 'package:f3_nation_app/services/q_builder_service.dart';

void main() {
  group('QBuilderRequest', () {
    test('maps wizard fields into workout settings', () {
      const request = QBuilderRequest(
        durationMinutes: 45,
        intensity: 'Advanced / Murph Prep',
        equipment: 'Sandbags / Rucks',
        focus: 'Advanced / Murph Prep',
        format: 'Dora',
        simpleQMode: true,
      );

      final settings = request.toSettings();

      expect(settings.durationMinutes, 45);
      expect(settings.couponMode, CouponMode.coupons);
      expect(settings.theme, BeatdownTheme.murphPrep);
      expect(settings.format, WorkoutFormat.dora);
      expect(settings.simpleQMode, isTrue);
      expect(settings.intensities, contains(Intensity.advanced));
    });
  });

  group('QBuilderService', () {
    late QBuilderService qBuilder;

    setUp(() {
      final service = ExerciseService()..injectForTesting(_exercisePool());
      qBuilder = QBuilderService(service);
    });

    test('buildBeatdown returns a plan and review', () {
      final result = qBuilder.buildBeatdown(const QBuilderRequest(
        durationMinutes: 45,
        intensity: 'Intermediate',
        equipment: 'Mixed (50/50)',
        focus: 'Full Body Grinder',
        format: 'AMRAP',
      ));

      expect(result.plan.totalMinutes, 45);
      expect(result.settings.format, WorkoutFormat.amrap);
      expect(result.review.difficultyScore, inInclusiveRange(1, 100));
      expect(result.review.highlights, isNotEmpty);
    });

    test('reviewPlan flags push-heavy imbalance', () {
      final result = qBuilder.buildBeatdown(const QBuilderRequest(
        durationMinutes: 50,
        intensity: 'Intermediate',
        equipment: 'Bodyweight Only',
        focus: 'Upper Body / Shoulders',
        format: 'Circuit',
      ));

      expect(
        result.review.warnings.map((w) => w.type),
        contains(QBuilderSignalType.safety),
      );
    });
  });
}

List<Exercise> _exercisePool() {
  final exercises = <Exercise>[
    ...List.generate(
      12,
      (i) => Exercise(
        id: 'warm-$i',
        name: 'Warmup SSH $i',
        description: 'Warmup run and mobility',
        aliases: const [],
        category: ExerciseCategory.warmup,
        equipment: Equipment.none,
        intensity: i.isEven ? Intensity.beginner : Intensity.intermediate,
      ),
    ),
    ...List.generate(
      10,
      (i) => Exercise(
        id: 'push-$i',
        name: 'Merkin Press $i',
        description: 'Push and press upper body',
        aliases: const [],
        category: ExerciseCategory.bodyweight,
        equipment: Equipment.none,
        intensity: i > 7 ? Intensity.advanced : Intensity.intermediate,
      ),
    ),
    ...List.generate(
      3,
      (i) => Exercise(
        id: 'legs-$i',
        name: 'Squat Lunge $i',
        description: 'Leg work',
        aliases: const [],
        category: ExerciseCategory.bodyweight,
        equipment: Equipment.none,
        intensity: Intensity.intermediate,
      ),
    ),
    ...List.generate(
      8,
      (i) => Exercise(
        id: 'coupon-$i',
        name: 'Coupon Row Carry $i',
        description: 'Row carry press with coupon',
        aliases: const [],
        category: ExerciseCategory.coupon,
        equipment: Equipment.coupon,
        intensity: i > 5 ? Intensity.advanced : Intensity.intermediate,
      ),
    ),
    ...List.generate(
      8,
      (i) => Exercise(
        id: 'mary-$i',
        name: 'LBC Flutter Core $i',
        description: 'Core mary',
        aliases: const [],
        category: ExerciseCategory.mary,
        equipment: Equipment.none,
        intensity: Intensity.beginner,
      ),
    ),
  ];

  return exercises;
}
