// lib/models/workout_plan.dart
// Generated 50-minute F3 bootcamp plan.

import 'exercise.dart';
import 'workout_settings.dart';

/// How the Q calls the count for a block's exercises — a live call the Q
/// makes, not a fixed property of any one exercise (the same move can be
/// called differently by different Qs), so this lives on the block, not on
/// individual exercises in the Exicon.
enum CallStyle {
  onYourOwn,
  inCadence,
  onMyUp,
  onMyDown;

  String get displayName => switch (this) {
    CallStyle.onYourOwn => 'On Your Own',
    CallStyle.inCadence  => 'In Cadence',
    CallStyle.onMyUp     => 'On My Up',
    CallStyle.onMyDown   => 'On My Down',
  };

  /// Short form for the TTS callout ("...OYO, go!").
  String get calloutPhrase => switch (this) {
    CallStyle.onYourOwn => 'On your own',
    CallStyle.inCadence  => 'In cadence',
    CallStyle.onMyUp     => 'On my up',
    CallStyle.onMyDown   => 'On my down',
  };
}

/// Best-effort call style read off an exercise's own F3 Exicon description —
/// many entries explicitly say "OYO," "in cadence," "on my up," etc. Covers
/// roughly 10% of the Exicon (confirmed by scanning the bundled data); the
/// rest, and anything ambiguous ("IC or OYO" — genuinely either), return
/// null rather than guess, leaving it for the Q to set manually per exercise.
CallStyle? suggestedCallStyleFor(String description) {
  final d = description.toLowerCase();
  final hasOnMyUp = d.contains('on my up');
  final hasOnMyDown = d.contains('on my down');
  final hasIC = d.contains('in cadence') || RegExp(r'\bic\b').hasMatch(d);
  final hasOYO = d.contains('on your own') || RegExp(r'\boyo\b').hasMatch(d);

  if (hasOnMyUp && !hasOnMyDown) return CallStyle.onMyUp;
  if (hasOnMyDown && !hasOnMyUp) return CallStyle.onMyDown;
  if (hasIC && hasOYO) return null;
  if (hasIC) return CallStyle.inCadence;
  if (hasOYO) return CallStyle.onYourOwn;
  return null;
}

class WorkoutBlock {
  final String label;
  final ExerciseCategory category;
  final List<Exercise> exercises;
  final int durationMinutes;
  final String notes;
  final int rounds;
  // exerciseId → Q note (e.g. "OYO", "do in cadence", "flapjack at halfway")
  final Map<String, String> exerciseNotes;
  final CallStyle callStyle;
  // exerciseId → the Q's explicit per-exercise call style override. Takes
  // priority over [suggestedCallStyleFor] (the exercise's own Exicon text),
  // which in turn takes priority over the block's own [callStyle] default —
  // see [callStyleFor].
  final Map<String, CallStyle> exerciseCallStyles;

  const WorkoutBlock({
    required this.label,
    required this.category,
    required this.exercises,
    required this.durationMinutes,
    this.notes = '',
    this.rounds = 1,
    this.exerciseNotes = const {},
    this.callStyle = CallStyle.onYourOwn,
    this.exerciseCallStyles = const {},
  });

  String noteFor(String exerciseId) => exerciseNotes[exerciseId] ?? '';

  /// Resolves the actual call style to use for one exercise: an explicit
  /// per-exercise override the Q set, else what that exercise's own Exicon
  /// description suggests, else this block's overall default.
  CallStyle callStyleFor(String exerciseId) {
    final override = exerciseCallStyles[exerciseId];
    if (override != null) return override;
    final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;
    if (exercise != null) {
      final suggested = suggestedCallStyleFor(exercise.description);
      if (suggested != null) return suggested;
    }
    return callStyle;
  }

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
      callStyle: callStyle,
      exerciseCallStyles: exerciseCallStyles,
    );
  }

  /// Sets (or clears, if [style] is null) the Q's explicit per-exercise
  /// override — distinct from this block's own overall [callStyle].
  WorkoutBlock copyWithExerciseCallStyle(String exerciseId, CallStyle? style) {
    final updated = Map<String, CallStyle>.from(exerciseCallStyles);
    if (style == null) {
      updated.remove(exerciseId);
    } else {
      updated[exerciseId] = style;
    }
    return WorkoutBlock(
      label: label,
      category: category,
      exercises: exercises,
      durationMinutes: durationMinutes,
      notes: notes,
      rounds: rounds,
      exerciseNotes: exerciseNotes,
      callStyle: callStyle,
      exerciseCallStyles: updated,
    );
  }

  WorkoutBlock copyWithExercises(List<Exercise> newExercises,
          {int? durationMinutes}) =>
      WorkoutBlock(
        label: label,
        category: category,
        exercises: newExercises,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        notes: notes,
        rounds: rounds,
        exerciseNotes: exerciseNotes,
        callStyle: callStyle,
        exerciseCallStyles: exerciseCallStyles,
      );

  /// Duration scaled to a new exercise count, holding per-exercise time
  /// constant (so adding/removing exercises moves the plan's total time).
  /// Falls back to ~5 min/exercise when the block was previously empty.
  int scaledDurationFor(int newExerciseCount) {
    final oldCount = exercises.length;
    final perExercise = oldCount > 0 ? durationMinutes / oldCount : 5.0;
    return (perExercise * newExerciseCount).round();
  }

  /// A refined minutes estimate that uses real per-exercise timing
  /// (`secondsPerSet`, set on custom/Q-written exercises) where available,
  /// instead of the generic block-level [durationMinutes] split evenly
  /// across exercises. Display-only — doesn't change the timer's actual
  /// phase countdown, which still runs off [durationMinutes].
  int get refinedMinutes {
    if (exercises.isEmpty) return durationMinutes * rounds;
    final withTiming = exercises.where((e) => e.secondsPerSet != null);
    if (withTiming.isEmpty) return durationMinutes * rounds;
    final perExerciseSecs = durationMinutes * 60 / exercises.length;
    final totalSecs = exercises.fold<double>(
        0, (sum, e) => sum + (e.secondsPerSet ?? perExerciseSecs));
    return ((totalSecs / 60) * rounds).round();
  }

  WorkoutBlock copyWithLabel(String newLabel) => WorkoutBlock(
        label: newLabel,
        category: category,
        exercises: exercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: rounds,
        exerciseNotes: exerciseNotes,
        callStyle: callStyle,
        exerciseCallStyles: exerciseCallStyles,
      );

  WorkoutBlock copyWithRounds(int newRounds) => WorkoutBlock(
        label: label,
        category: category,
        exercises: exercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: newRounds,
        exerciseNotes: exerciseNotes,
        callStyle: callStyle,
        exerciseCallStyles: exerciseCallStyles,
      );

  WorkoutBlock copyWithCallStyle(CallStyle newStyle) => WorkoutBlock(
        label: label,
        category: category,
        exercises: exercises,
        durationMinutes: durationMinutes,
        notes: notes,
        rounds: rounds,
        exerciseNotes: exerciseNotes,
        callStyle: newStyle,
        exerciseCallStyles: exerciseCallStyles,
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
      blocks.fold(0, (sum, b) => sum + b.durationMinutes * b.rounds);

  int get totalMinutes => nonExercisePhaseMinutes + exerciseMinutes;

  /// [totalMinutes], but using each block's [WorkoutBlock.refinedMinutes]
  /// where custom exercises carry real per-set timing — a more accurate
  /// budget-bar estimate without changing the timer's own countdown logic.
  int get refinedTotalMinutes =>
      nonExercisePhaseMinutes +
      blocks.fold(0, (sum, b) => sum + b.refinedMinutes);

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
