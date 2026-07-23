// test/workout_plan_call_style_test.dart
// Unit tests for per-exercise call style resolution: suggestedCallStyleFor
// (derived from an exercise's own Exicon description) and
// WorkoutBlock.callStyleFor (override > suggested > block default).
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_plan.dart';

Exercise _ex(String id, String description) => Exercise(
      id: id,
      name: id,
      description: description,
      aliases: const [],
      category: ExerciseCategory.bodyweight,
      equipment: Equipment.none,
      intensity: Intensity.intermediate,
    );

void main() {
  group('suggestedCallStyleFor', () {
    test('detects explicit OYO', () {
      expect(suggestedCallStyleFor('This exercise is OYO for 10 reps.'),
          CallStyle.onYourOwn);
    });

    test('detects "on your own" spelled out', () {
      expect(suggestedCallStyleFor('Performed on your own pace.'),
          CallStyle.onYourOwn);
    });

    test('detects "in cadence"', () {
      expect(suggestedCallStyleFor('Alternate side to side in cadence.'),
          CallStyle.inCadence);
    });

    test('detects standalone IC', () {
      expect(suggestedCallStyleFor('Do a full IC count, then flapjack.'),
          CallStyle.inCadence);
    });

    test('detects "on my up"', () {
      expect(suggestedCallStyleFor('Q calls on my up for each rep.'),
          CallStyle.onMyUp);
    });

    test('detects "on my down"', () {
      expect(suggestedCallStyleFor('Q calls on my down for each rep.'),
          CallStyle.onMyDown);
    });

    test('returns null when ambiguous ("IC or OYO")', () {
      expect(suggestedCallStyleFor('IC or OYO.'), isNull);
    });

    test('returns null with no signal at all', () {
      expect(
          suggestedCallStyleFor('Mosey to the flag and back.'), isNull);
    });

    test('does not false-positive on unrelated words containing "ic"', () {
      expect(suggestedCallStyleFor('A classic exercise, very basic.'), isNull);
    });
  });

  group('WorkoutBlock.callStyleFor', () {
    test('falls back to the block default with no signal or override', () {
      final block = WorkoutBlock(
        label: 'THE THANG',
        category: ExerciseCategory.bodyweight,
        exercises: [_ex('e1', 'Mosey to the flag and back.')],
        durationMinutes: 20,
        callStyle: CallStyle.onMyUp,
      );
      expect(block.callStyleFor('e1'), CallStyle.onMyUp);
    });

    test('uses the exercise\'s own suggested style over the block default', () {
      final block = WorkoutBlock(
        label: 'THE THANG',
        category: ExerciseCategory.bodyweight,
        exercises: [_ex('e1', 'Performed in cadence.')],
        durationMinutes: 20,
        callStyle: CallStyle.onYourOwn,
      );
      expect(block.callStyleFor('e1'), CallStyle.inCadence);
    });

    test('an explicit per-exercise override wins over everything', () {
      final block = WorkoutBlock(
        label: 'THE THANG',
        category: ExerciseCategory.bodyweight,
        exercises: [_ex('e1', 'Performed in cadence.')],
        durationMinutes: 20,
        callStyle: CallStyle.onYourOwn,
      ).copyWithExerciseCallStyle('e1', CallStyle.onMyDown);
      expect(block.callStyleFor('e1'), CallStyle.onMyDown);
    });

    test('clearing an override (null) falls back through the chain again', () {
      final withOverride = WorkoutBlock(
        label: 'THE THANG',
        category: ExerciseCategory.bodyweight,
        exercises: [_ex('e1', 'Performed in cadence.')],
        durationMinutes: 20,
      ).copyWithExerciseCallStyle('e1', CallStyle.onMyDown);
      final cleared = withOverride.copyWithExerciseCallStyle('e1', null);
      expect(cleared.callStyleFor('e1'), CallStyle.inCadence);
    });
  });
}
