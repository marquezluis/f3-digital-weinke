// lib/models/workout_plan.dart
// Generated 50-minute F3 bootcamp plan.

import 'exercise.dart';
import 'workout_settings.dart';

class WorkoutBlock {
  final String label;
  final ExerciseCategory category;
  final List<Exercise> exercises;
  final int durationMinutes;
  final String notes;
  final int rounds;
  // exerciseId → Q note (e.g. "OYO", "do in cadence", "flapjack at halfway")
  final Map<String, String> exerciseNotes;

  const WorkoutBlock({
    required this.label,
    required this.category,
    required this.exercises,
    required this.durationMinutes,
    this.notes = '',
    this.rounds = 1,
    this.exerciseNotes = const {},
  });

  String noteFor(String exerciseId) => exerciseNotes[exerciseId] ?? '';

  WorkoutBlock copyWithExerciseNote(String exerciseId, String note) {
    final updated = Map<String, String>.from(exerciseNotes);
    if (note.isEmpty) {
      updated.remove(exerciseId);
    } else {
      updated[exerciseId] = note;
    }
    return WorkoutBlock(
      label: label,
      category: category,
      exercises: exercises,
      durationMinutes: durationMinutes,
      notes: notes,
      rounds: rounds,
      exerciseNotes: updated,
    );
  }

  WorkoutBlock copyWithExercises(List<Exercise> newExercises) => WorkoutBlock(
        label: label,
        category: category,
        exercises: newExercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: rounds,
        exerciseNotes: exerciseNotes,
      );

  WorkoutBlock copyWithLabel(String newLabel) => WorkoutBlock(
        label: newLabel,
        category: category,
        exercises: exercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: rounds,
        exerciseNotes: exerciseNotes,
      );

  WorkoutBlock copyWithRounds(int newRounds) => WorkoutBlock(
        label: label,
        category: category,
        exercises: exercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: newRounds,
        exerciseNotes: exerciseNotes,
      );
}

class WorkoutPlan {
  static const int nonExercisePhaseMinutes = 5; // 1 min disclaimer + 4 min COT

  final String id;
  final DateTime generatedAt;
  final List<WorkoutBlock> blocks;
  final WorkoutSettings settings;

  const WorkoutPlan({
    required this.id,
    required this.generatedAt,
    required this.blocks,
    this.settings = const WorkoutSettings(),
  });

  int get exerciseMinutes =>
      blocks.fold(0, (sum, b) => sum + b.durationMinutes);

  int get totalMinutes => nonExercisePhaseMinutes + exerciseMinutes;

  List<Exercise> get allExercises =>
      blocks.expand((b) => b.exercises).toList();

  /// Replace one exercise within the plan (used by swap logic).
  WorkoutPlan withSwappedExercise(Exercise oldEx, Exercise newEx) {
    final newBlocks = blocks.map((block) {
      final idx = block.exercises.indexWhere((e) => e.id == oldEx.id);
      if (idx == -1) return block;
      final updated = List<Exercise>.from(block.exercises)..[idx] = newEx;
      return block.copyWithExercises(updated);
    }).toList();
    return WorkoutPlan(
      id: id,
      generatedAt: generatedAt,
      blocks: newBlocks,
      settings: settings,
    );
  }
}
