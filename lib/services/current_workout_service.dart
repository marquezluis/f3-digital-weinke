// lib/services/current_workout_service.dart
// Shared state between the Weinke (draft/planning) and Live (active) screens.
//
// Workflow:
//   1. Q uses Weinke tab to draft a plan (draftPlan).
//   2. Q taps "Start Workout" → draftPlan is copied to livePlan and the app
//      navigates to the Live tab.
//   3. Live screen reads livePlan (never auto-generates its own).
//   4. Q can swap individual exercises on either screen; swaps are isolated to
//      the respective plan.
//   5. "New Beatdown" on the Weinke screen clears draftPlan (livePlan is
//      untouched so an in-progress session is not disrupted).
//   6. "Regenerate" reshuffles the current draftPlan exercises without
//      touching livePlan.
//
// currentExerciseIndex tracks the manually-advanced exercise index within
// the current phase on the Live screen.  It is reset to 0 when a new livePlan
// is accepted or when the phase changes.

import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';

class CurrentWorkoutService extends ChangeNotifier {
  WorkoutPlan? _draftPlan;
  WorkoutPlan? _livePlan;
  int _currentExerciseIndex = 0;

  // ── Getters ──────────────────────────────────────────────────────────────────

  WorkoutPlan? get draftPlan => _draftPlan;
  WorkoutPlan? get livePlan => _livePlan;
  int get currentExerciseIndex => _currentExerciseIndex;

  bool get hasLivePlan => _livePlan != null;
  bool get hasDraftPlan => _draftPlan != null;

  // ── Draft (Weinke) mutations ──────────────────────────────────────────────────

  /// Replace the entire draft plan (new generation or regeneration).
  void setDraftPlan(WorkoutPlan plan) {
    _draftPlan = plan;
    notifyListeners();
  }

  /// Swap a single exercise in the draft plan.
  void swapDraftExercise(WorkoutPlan updatedPlan) {
    _draftPlan = updatedPlan;
    notifyListeners();
  }

  /// Update the rounds count for a specific block in the draft plan.
  void setDraftBlockRounds(int blockIndex, int rounds) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    newBlocks[blockIndex] = newBlocks[blockIndex].copyWithRounds(rounds);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Set how the Q calls the count for a block (In Cadence / OYO / etc.).
  void setDraftBlockCallStyle(int blockIndex, CallStyle style) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    newBlocks[blockIndex] = newBlocks[blockIndex].copyWithCallStyle(style);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Sets (or clears, if [style] is null) the Q's explicit call-style
  /// override for one exercise — distinct from the block's own overall
  /// [setDraftBlockCallStyle] default.
  void setExerciseCallStyleInDraftBlock(
      int blockIndex, String exerciseId, CallStyle? style) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    newBlocks[blockIndex] =
        newBlocks[blockIndex].copyWithExerciseCallStyle(exerciseId, style);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Rename a block in the draft plan.
  void renameDraftBlock(int blockIndex, String newLabel) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    newBlocks[blockIndex] = newBlocks[blockIndex].copyWithLabel(newLabel);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Clear the draft plan entirely (New Beatdown — start fresh).
  void clearDraft() {
    _draftPlan = null;
    notifyListeners();
  }

  /// Remove one exercise from a block in the draft plan.
  void removeExerciseFromDraftBlock(int blockIndex, String exerciseId) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    final block = newBlocks[blockIndex];
    final updated = block.exercises.where((e) => e.id != exerciseId).toList();
    newBlocks[blockIndex] = block.copyWithExercises(updated,
        durationMinutes: block.scaledDurationFor(updated.length));
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Duplicate an exercise at [exerciseIndex] within a block (appended after it).
  void duplicateExerciseInDraftBlock(int blockIndex, int exerciseIndex) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    final block = newBlocks[blockIndex];
    if (exerciseIndex < 0 || exerciseIndex >= block.exercises.length) return;
    final copy = block.exercises[exerciseIndex];
    final updated = List<Exercise>.from(block.exercises)
      ..insert(exerciseIndex + 1, copy);
    newBlocks[blockIndex] = block.copyWithExercises(updated,
        durationMinutes: block.scaledDurationFor(updated.length));
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Set or clear a Q note for a specific exercise in a block.
  void setExerciseNoteInDraftBlock(int blockIndex, String exerciseId, String note) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    newBlocks[blockIndex] = newBlocks[blockIndex].copyWithExerciseNote(exerciseId, note);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Move an exercise within a block (for drag-to-reorder).
  void reorderExerciseInDraftBlock(int blockIndex, int oldIndex, int newIndex) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    final block = newBlocks[blockIndex];
    final exercises = List<Exercise>.from(block.exercises);
    if (newIndex > oldIndex) newIndex--;
    final ex = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, ex);
    newBlocks[blockIndex] = block.copyWithExercises(exercises);
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  /// Append an exercise to a specific block in the draft plan.
  void addExerciseToDraftBlock(int blockIndex, Exercise exercise) {
    if (_draftPlan == null) return;
    final newBlocks = List<WorkoutBlock>.from(_draftPlan!.blocks);
    if (blockIndex < 0 || blockIndex >= newBlocks.length) return;
    final block = newBlocks[blockIndex];
    if (block.exercises.any((e) => e.id == exercise.id)) return;
    final updated = List<Exercise>.from(block.exercises)..add(exercise);
    newBlocks[blockIndex] = block.copyWithExercises(updated,
        durationMinutes: block.scaledDurationFor(updated.length));
    _draftPlan = WorkoutPlan(
      id: _draftPlan!.id,
      generatedAt: _draftPlan!.generatedAt,
      blocks: newBlocks,
      settings: _draftPlan!.settings,
    );
    notifyListeners();
  }

  // ── Live (timer) mutations ────────────────────────────────────────────────────

  /// Accept the current draft plan as the live plan; resets exercise index.
  /// Call this when Q taps "Start Workout" on the Weinke screen.
  void acceptDraftAsLive() {
    if (_draftPlan == null) return;
    _livePlan = _draftPlan;
    _currentExerciseIndex = 0;
    notifyListeners();
  }

  /// Swap a single exercise in the live plan (mid-workout swap).
  void swapLiveExercise(WorkoutPlan updatedPlan) {
    _livePlan = updatedPlan;
    notifyListeners();
  }

  /// Go back to the previous exercise within the current phase.
  /// Returns true if successful, false if already at the beginning.
  bool previousExercise() {
    if (_currentExerciseIndex > 0) {
      _currentExerciseIndex--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Advance to the next exercise within the current phase on the Live screen.
  /// Returns true if there was a next exercise, false if already at the end.
  bool nextExercise(int totalInPhase) {
    if (_currentExerciseIndex < totalInPhase - 1) {
      _currentExerciseIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Jump back to the first exercise of a phase (called on phase change).
  void resetExerciseIndex() {
    _currentExerciseIndex = 0;
    notifyListeners();
  }

  /// Clear the live plan (e.g., after session is saved and Q wants to start
  /// a brand-new beatdown from scratch).
  void clearLive() {
    _livePlan = null;
    _currentExerciseIndex = 0;
    notifyListeners();
  }
}
