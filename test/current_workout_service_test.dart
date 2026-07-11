// test/current_workout_service_test.dart
// Unit tests for CurrentWorkoutService — the shared draft/live plan bridge.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/services/current_workout_service.dart';
import 'package:f3_nation_app/models/workout_plan.dart';
import 'package:f3_nation_app/models/exercise.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

WorkoutPlan _makePlan(String id) => WorkoutPlan(
      id: id,
      generatedAt: DateTime(2025, 1, 1),
      blocks: [
        const WorkoutBlock(
          label: 'Warm-O-Rama',
          category: ExerciseCategory.warmup,
          durationMinutes: 7,
          exercises: [
            Exercise(
              id: 'ex-1',
              name: 'SSH',
              description: 'Side Straddle Hop',
              aliases: [],
              category: ExerciseCategory.warmup,
              equipment: Equipment.none,
              intensity: Intensity.beginner,
            ),
          ],
        ),
        const WorkoutBlock(
          label: 'The Thang',
          category: ExerciseCategory.bodyweight,
          durationMinutes: 32,
          exercises: [
            Exercise(
              id: 'ex-2',
              name: 'Merkin',
              description: 'Push-up',
              aliases: [],
              category: ExerciseCategory.bodyweight,
              equipment: Equipment.none,
              intensity: Intensity.intermediate,
            ),
            Exercise(
              id: 'ex-3',
              name: 'Squat',
              description: 'Air Squat',
              aliases: [],
              category: ExerciseCategory.bodyweight,
              equipment: Equipment.none,
              intensity: Intensity.beginner,
            ),
          ],
        ),
        const WorkoutBlock(
          label: 'Mary',
          category: ExerciseCategory.mary,
          durationMinutes: 6,
          exercises: [
            Exercise(
              id: 'ex-4',
              name: 'LBC',
              description: 'Little Baby Crunches',
              aliases: [],
              category: ExerciseCategory.mary,
              equipment: Equipment.none,
              intensity: Intensity.beginner,
            ),
          ],
        ),
      ],
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CurrentWorkoutService', () {
    late CurrentWorkoutService svc;

    setUp(() => svc = CurrentWorkoutService());
    tearDown(() => svc.dispose());

    // ── Initial state ──────────────────────────────────────────────────────

    test('initial state has no draft or live plan', () {
      expect(svc.draftPlan, isNull);
      expect(svc.livePlan, isNull);
      expect(svc.hasDraftPlan, isFalse);
      expect(svc.hasLivePlan, isFalse);
      expect(svc.currentExerciseIndex, 0);
    });

    // ── Draft mutations ────────────────────────────────────────────────────

    test('setDraftPlan stores plan and notifies', () {
      bool notified = false;
      svc.addListener(() => notified = true);

      final plan = _makePlan('draft-1');
      svc.setDraftPlan(plan);

      expect(svc.draftPlan, plan);
      expect(svc.hasDraftPlan, isTrue);
      expect(notified, isTrue);
    });

    test('clearDraft removes draft plan without touching live', () {
      svc.setDraftPlan(_makePlan('draft-1'));
      svc.acceptDraftAsLive();
      svc.clearDraft();

      expect(svc.draftPlan, isNull);
      expect(svc.hasDraftPlan, isFalse);
      // Live plan unaffected
      expect(svc.livePlan, isNotNull);
    });

    test('swapDraftExercise updates draft plan', () {
      final original = _makePlan('draft-1');
      svc.setDraftPlan(original);

      final updated = _makePlan('draft-1-swapped');
      svc.swapDraftExercise(updated);

      expect(svc.draftPlan, updated);
    });

    // ── Draft → Live promotion ─────────────────────────────────────────────

    test('acceptDraftAsLive copies draft to live and resets index', () {
      final plan = _makePlan('plan-abc');
      svc.setDraftPlan(plan);
      // Advance exercise index first
      svc.nextExercise(3);
      expect(svc.currentExerciseIndex, 1);

      svc.acceptDraftAsLive();

      expect(svc.livePlan, plan);
      expect(svc.hasLivePlan, isTrue);
      expect(svc.currentExerciseIndex, 0); // reset
    });

    test('acceptDraftAsLive does nothing if no draft', () {
      svc.acceptDraftAsLive();
      expect(svc.livePlan, isNull);
    });

    test('draft and live plans are independent after accept', () {
      final original = _makePlan('plan-1');
      svc.setDraftPlan(original);
      svc.acceptDraftAsLive();

      final newDraft = _makePlan('plan-2');
      svc.setDraftPlan(newDraft);

      // Live plan should still point to original
      expect(svc.livePlan?.id, 'plan-1');
      expect(svc.draftPlan?.id, 'plan-2');
    });

    // ── Live exercise navigation ───────────────────────────────────────────

    test('nextExercise increments index when not at end', () {
      svc.setDraftPlan(_makePlan('p'));
      svc.acceptDraftAsLive();

      final advanced = svc.nextExercise(3);
      expect(advanced, isTrue);
      expect(svc.currentExerciseIndex, 1);
    });

    test('nextExercise returns false when at last exercise', () {
      svc.setDraftPlan(_makePlan('p'));
      svc.acceptDraftAsLive();
      svc.nextExercise(3); // 0 → 1
      svc.nextExercise(3); // 1 → 2
      final advanced = svc.nextExercise(3); // already at last
      expect(advanced, isFalse);
      expect(svc.currentExerciseIndex, 2);
    });

    test('resetExerciseIndex goes back to 0', () {
      svc.setDraftPlan(_makePlan('p'));
      svc.acceptDraftAsLive();
      svc.nextExercise(5);
      svc.nextExercise(5);
      expect(svc.currentExerciseIndex, 2);

      svc.resetExerciseIndex();
      expect(svc.currentExerciseIndex, 0);
    });

    // ── Live plan mutations ────────────────────────────────────────────────

    test('swapLiveExercise updates live plan', () {
      svc.setDraftPlan(_makePlan('p'));
      svc.acceptDraftAsLive();

      final updated = _makePlan('p-swapped');
      svc.swapLiveExercise(updated);
      expect(svc.livePlan?.id, 'p-swapped');
    });

    test('clearLive removes live plan and resets index', () {
      svc.setDraftPlan(_makePlan('p'));
      svc.acceptDraftAsLive();
      svc.nextExercise(5);

      svc.clearLive();
      expect(svc.livePlan, isNull);
      expect(svc.currentExerciseIndex, 0);
    });
  });
}
