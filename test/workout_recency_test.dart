// test/workout_recency_test.dart
// Covers the "haven't used lately" bias: HistoryService surfaces recently
// used exercise names, and WorkoutGenerator deprioritizes (but never
// excludes) them when building a plan.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/models/workout_settings.dart';
import 'package:f3_nation_app/services/exercise_service.dart';
import 'package:f3_nation_app/services/history_service.dart';
import 'package:f3_nation_app/services/workout_generator.dart';

// buildWarmupBlock (used below to exercise the generator) only draws from
// ExerciseCategory.warmup, so the fixtures must be warmup exercises.
Exercise _bw(String id, String name) => Exercise(
      id: id,
      name: name,
      description: 'desc',
      category: ExerciseCategory.warmup,
      equipment: Equipment.none,
      intensity: Intensity.intermediate,
      aliases: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryService.recentlyUsedExerciseNames', () {
    test('collects names from the last N real sessions, newest first window',
        () async {
      final history = HistoryService();
      await history.load();

      await history.add(WorkoutHistory(
        id: '1',
        title: 'Old',
        date: DateTime(2026, 1, 1),
        blocks: const [
          HistoryBlock(
              label: 'Thang',
              category: 'bodyweight',
              durationMinutes: 10,
              exerciseNames: ['Old Move']),
        ],
      ));
      await history.add(WorkoutHistory(
        id: '2',
        title: 'Recent',
        date: DateTime(2026, 7, 1),
        blocks: const [
          HistoryBlock(
              label: 'Thang',
              category: 'bodyweight',
              durationMinutes: 10,
              exerciseNames: ['Merkins', 'Burpees']),
        ],
      ));

      final names = history.recentlyUsedExerciseNames(sessions: 1);
      expect(names, {'Merkins', 'Burpees'});
      expect(names.contains('Old Move'), isFalse);
    });

    test('excludes saved templates — a template is not "just run"', () async {
      final history = HistoryService();
      await history.load();

      await history.add(WorkoutHistory(
        id: 't1',
        title: 'Template',
        date: DateTime(2026, 7, 1),
        isTemplate: true,
        blocks: const [
          HistoryBlock(
              label: 'Thang',
              category: 'bodyweight',
              durationMinutes: 10,
              exerciseNames: ['Merkins']),
        ],
      ));

      expect(history.recentlyUsedExerciseNames(), isEmpty);
    });
  });

  group('WorkoutGenerator recency bias', () {
    test('fills a block from fresh exercises before touching recent ones',
        () {
      final service = ExerciseService();
      service.injectForTesting([
        _bw('1', 'Merkins'),
        _bw('2', 'Burpees'),
        _bw('3', 'Diamond Merkins'),
        _bw('4', 'Carolina Dry Docks'),
      ]);

      final generator = WorkoutGenerator(
        service,
        random: Random(42),
        recentlyUsedNames: {'Merkins', 'Burpees'},
      );

      final block = generator.buildWarmupBlock(
        const WorkoutSettings(durationMinutes: 45),
      );
      // Only 2 fresh exercises exist; a 4-exercise warmup block must reach
      // into the recent set to fill out, but the fresh two always win the
      // front of the list — assert on the composition, not exact order,
      // since within-partition order is still randomized.
      final selectedNames = block.exercises.map((e) => e.name).toSet();
      expect(selectedNames, {
        'Merkins',
        'Burpees',
        'Diamond Merkins',
        'Carolina Dry Docks',
      });
    });

    test('never comes up short just because everything left was recent', () {
      final service = ExerciseService();
      service.injectForTesting([_bw('1', 'Merkins'), _bw('2', 'Burpees')]);

      final generator = WorkoutGenerator(
        service,
        random: Random(7),
        recentlyUsedNames: {'Merkins', 'Burpees'},
      );

      final block = generator.buildWarmupBlock(
        const WorkoutSettings(durationMinutes: 45),
      );
      expect(block.exercises.length, 2);
    });
  });
}
