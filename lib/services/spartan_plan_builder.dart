// lib/services/spartan_plan_builder.dart
// Converts SpartanService.generateWorkoutBlocks' structured JSON into a real
// WorkoutPlan — separated from spartan_service.dart so this pure conversion
// logic is testable without a network call or an API key.

import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'exercise_service.dart';
import 'weinke_exporter.dart';

/// Resolves each exercise name against the real Exicon the same way a
/// parsed preblast does (see [WeinkeExporter.resolveExercise]) — known
/// exercises keep their real data, unknown ones become a lightweight
/// placeholder rather than being dropped. Returns null if nothing usable
/// came back (e.g. the request wasn't a workout at all).
WorkoutPlan? buildPlanFromSpartanBlocks(
  List<dynamic> blocksJson,
  ExerciseService service,
) {
  final blocks = <WorkoutBlock>[];

  for (final raw in blocksJson) {
    if (raw is! Map) continue;
    final label = (raw['label'] as String?)?.trim();
    if (label == null || label.isEmpty) continue;

    final category =
        ExerciseCategory.fromString(raw['category'] as String? ?? '');
    final rounds = ((raw['rounds'] as num?)?.toInt() ?? 1).clamp(1, 20);
    final durationMinutes =
        ((raw['durationMinutes'] as num?)?.toInt() ?? 5).clamp(1, 60);
    final exercisesJson = raw['exercises'] as List<dynamic>? ?? const [];

    final exercises = <Exercise>[];
    final callStyles = <String, CallStyle>{};
    for (final exRaw in exercisesJson) {
      if (exRaw is! Map) continue;
      final name = (exRaw['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final exercise = WeinkeExporter.resolveExercise(name, service);
      exercises.add(exercise);
      final callStyle = callStyleFromString(exRaw['callStyle'] as String?);
      if (callStyle != null) callStyles[exercise.id] = callStyle;
    }
    if (exercises.isEmpty) continue;

    blocks.add(WorkoutBlock(
      label: label,
      category: category,
      exercises: exercises,
      durationMinutes: durationMinutes,
      rounds: rounds,
      exerciseCallStyles: callStyles,
    ));
  }

  if (blocks.isEmpty) return null;
  return WorkoutPlan(
    id: const Uuid().v4(),
    generatedAt: DateTime.now(),
    blocks: blocks,
  );
}
