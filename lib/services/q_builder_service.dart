// lib/services/q_builder_service.dart
// Offline QBuilder orchestration: maps user intent into workout settings,
// generates a beatdown, and reviews it for Q-readiness.

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_settings.dart';
import 'exercise_service.dart';
import 'workout_generator.dart';

class QBuilderService {
  final WorkoutGenerator _generator;

  QBuilderService(ExerciseService exerciseService,
      {WorkoutGenerator? generator})
      : _generator = generator ?? WorkoutGenerator(exerciseService);

  QBuilderResult buildBeatdown(QBuilderRequest request) {
    final settings = request.toSettings();
    final plan = _generator.generate(settings);
    final review = reviewPlan(plan);
    return QBuilderResult(
      plan: plan,
      settings: settings,
      review: review,
    );
  }

  QBuilderReview reviewPlan(WorkoutPlan plan) {
    final exercises = plan.allExercises;
    final movementCounts = <MovementPattern, int>{
      for (final pattern in MovementPattern.values) pattern: 0,
    };
    final warnings = <QBuilderCoachingSignal>[];
    final highlights = <QBuilderCoachingSignal>[];

    for (final exercise in exercises) {
      for (final pattern in _patternsFor(exercise)) {
        movementCounts[pattern] = movementCounts[pattern]! + 1;
      }
    }

    final advancedCount =
        exercises.where((e) => e.intensity == Intensity.advanced).length;
    final couponCount =
        exercises.where((e) => e.equipment == Equipment.coupon).length;
    final emptyBlocks = plan.blocks.where((b) => b.exercises.isEmpty).toList();
    final duplicateNames = _duplicateExerciseNames(exercises);

    final difficulty = _difficultyScore(
      plan: plan,
      advancedCount: advancedCount,
      couponCount: couponCount,
    );

    if (emptyBlocks.isNotEmpty) {
      warnings.add(QBuilderCoachingSignal(
        type: QBuilderSignalType.logistics,
        message:
            '${emptyBlocks.length} block(s) have no matching exercises. Loosen filters or add Exicon data.',
      ));
    }

    if (duplicateNames.isNotEmpty) {
      warnings.add(QBuilderCoachingSignal(
        type: QBuilderSignalType.variety,
        message: 'Repeats detected: ${duplicateNames.join(', ')}.',
      ));
    }

    if (movementCounts[MovementPattern.push]! >= 5 &&
        movementCounts[MovementPattern.pull]! <= 1) {
      warnings.add(const QBuilderCoachingSignal(
        type: QBuilderSignalType.safety,
        message:
            'Push-heavy plan. Add rows, pulls, carries, or lower-body recovery.',
      ));
    }

    if (movementCounts[MovementPattern.legs]! <= 1 &&
        plan.settings.theme != BeatdownTheme.upperBody) {
      warnings.add(const QBuilderCoachingSignal(
        type: QBuilderSignalType.balance,
        message:
            'Leg volume is light. Add squats, lunges, carries, or running.',
      ));
    }

    if (advancedCount >= 6 &&
        plan.settings.intensities.contains(Intensity.beginner)) {
      warnings.add(const QBuilderCoachingSignal(
        type: QBuilderSignalType.fng,
        message:
            'Several advanced movements are included. Prepare clear modifications for FNGs.',
      ));
    }

    if (plan.totalMinutes != plan.settings.durationMinutes) {
      warnings.add(QBuilderCoachingSignal(
        type: QBuilderSignalType.pacing,
        message:
            'Plan totals ${plan.totalMinutes} minutes, but request was ${plan.settings.durationMinutes}.',
      ));
    }

    if (warnings.isEmpty) {
      highlights.add(const QBuilderCoachingSignal(
        type: QBuilderSignalType.balance,
        message: 'Balanced enough for the gloom. Demo well and keep it moving.',
      ));
    }

    if (plan.settings.simpleQMode) {
      highlights.add(const QBuilderCoachingSignal(
        type: QBuilderSignalType.fng,
        message:
            'Simple Q mode is on: fewer movements, cleaner transitions, easier cadence.',
      ));
    }

    highlights.add(QBuilderCoachingSignal(
      type: QBuilderSignalType.pacing,
      message: _pacingMessage(plan.settings.format),
    ));

    return QBuilderReview(
      difficultyScore: difficulty,
      movementCounts: movementCounts,
      warnings: warnings,
      highlights: highlights,
    );
  }

  static String _pacingMessage(WorkoutFormat format) {
    switch (format) {
      case WorkoutFormat.circuit:
        return 'Circuit pacing: keep explanations short and rotate on time.';
      case WorkoutFormat.amrap:
        return 'AMRAP pacing: count rounds and give the Six a clear target.';
      case WorkoutFormat.tabata:
        return 'Tabata pacing: let the timer lead so the Q can watch form.';
      case WorkoutFormat.dora:
        return 'Dora pacing: define reps before launch and watch partner flow.';
      case WorkoutFormat.qRescue:
        return 'Q Rescue pacing: start simple, stay loud, and adjust after lap one.';
    }
  }

  int _difficultyScore({
    required WorkoutPlan plan,
    required int advancedCount,
    required int couponCount,
  }) {
    var score = 35;
    score += (plan.settings.durationMinutes - 30).clamp(0, 30);
    score += advancedCount * 5;
    score += couponCount * 2;

    switch (plan.settings.format) {
      case WorkoutFormat.tabata:
      case WorkoutFormat.dora:
        score += 8;
      case WorkoutFormat.amrap:
      case WorkoutFormat.qRescue:
        score += 4;
      case WorkoutFormat.circuit:
        break;
    }

    switch (plan.settings.theme) {
      case BeatdownTheme.murphPrep:
      case BeatdownTheme.militaryPT:
        score += 10;
      case BeatdownTheme.couponGrinder:
      case BeatdownTheme.legDay:
        score += 6;
      case BeatdownTheme.fullBody:
      case BeatdownTheme.upperBody:
      case BeatdownTheme.heavyCore:
        break;
    }

    if (plan.settings.simpleQMode) score -= 8;
    return score.clamp(1, 100);
  }

  static List<String> _duplicateExerciseNames(List<Exercise> exercises) {
    final counts = <String, int>{};
    for (final exercise in exercises) {
      counts.update(exercise.name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList();
  }

  static Set<MovementPattern> _patternsFor(Exercise exercise) {
    final text =
        '${exercise.name} ${exercise.description} ${exercise.aliases.join(' ')}'
            .toLowerCase();
    final patterns = <MovementPattern>{};

    if (text.contains('merkin') ||
        text.contains('push') ||
        text.contains('press') ||
        text.contains('burpee')) {
      patterns.add(MovementPattern.push);
    }
    if (text.contains('pull') ||
        text.contains('row') ||
        text.contains('curl')) {
      patterns.add(MovementPattern.pull);
    }
    if (text.contains('squat') ||
        text.contains('lunge') ||
        text.contains('leg') ||
        text.contains('jump')) {
      patterns.add(MovementPattern.legs);
    }
    if (exercise.category == ExerciseCategory.mary ||
        text.contains('plank') ||
        text.contains('sit') ||
        text.contains('lbc') ||
        text.contains('core') ||
        text.contains('flutter')) {
      patterns.add(MovementPattern.core);
    }
    if (text.contains('run') ||
        text.contains('mosey') ||
        text.contains('crawl') ||
        text.contains('carry')) {
      patterns.add(MovementPattern.conditioning);
    }
    if (exercise.equipment == Equipment.coupon) {
      patterns.add(MovementPattern.coupon);
    }

    if (patterns.isEmpty) patterns.add(MovementPattern.conditioning);
    return patterns;
  }
}

class QBuilderRequest {
  final int durationMinutes;
  final String intensity;
  final String equipment;
  final String focus;
  final String format;
  final bool simpleQMode;

  const QBuilderRequest({
    required this.durationMinutes,
    required this.intensity,
    required this.equipment,
    required this.focus,
    this.format = 'Circuit',
    this.simpleQMode = false,
  });

  WorkoutSettings toSettings() {
    return WorkoutSettings(
      durationMinutes: durationMinutes,
      couponMode: _couponModeFrom(equipment),
      intensities: _intensitiesFrom(intensity),
      theme: _themeFrom(focus),
      format: _formatFrom(format),
      simpleQMode: simpleQMode,
    );
  }

  static CouponMode _couponModeFrom(String value) {
    if (value.contains('Bodyweight')) return CouponMode.noCoupons;
    if (value.contains('Required') ||
        value.contains('Sandbags') ||
        value.contains('Rucks')) {
      return CouponMode.coupons;
    }
    return CouponMode.mixed;
  }

  static Set<Intensity> _intensitiesFrom(String value) {
    if (value.contains('Beginner')) return {Intensity.beginner};
    if (value.contains('Advanced')) {
      return {Intensity.beginner, Intensity.intermediate, Intensity.advanced};
    }
    return {Intensity.beginner, Intensity.intermediate};
  }

  static BeatdownTheme _themeFrom(String value) {
    if (value.contains('Leg')) return BeatdownTheme.legDay;
    if (value.contains('Upper')) return BeatdownTheme.upperBody;
    if (value.contains('Core')) return BeatdownTheme.heavyCore;
    if (value.contains('Murph')) return BeatdownTheme.murphPrep;
    if (value.contains('Coupon')) return BeatdownTheme.couponGrinder;
    if (value.contains('Military')) return BeatdownTheme.militaryPT;
    return BeatdownTheme.fullBody;
  }

  static WorkoutFormat _formatFrom(String value) {
    if (value.contains('AMRAP')) return WorkoutFormat.amrap;
    if (value.contains('Tabata')) return WorkoutFormat.tabata;
    if (value.contains('Dora')) return WorkoutFormat.dora;
    if (value.contains('Rescue')) return WorkoutFormat.qRescue;
    return WorkoutFormat.circuit;
  }
}

class QBuilderResult {
  final WorkoutPlan plan;
  final WorkoutSettings settings;
  final QBuilderReview review;

  const QBuilderResult({
    required this.plan,
    required this.settings,
    required this.review,
  });
}

class QBuilderReview {
  final int difficultyScore;
  final Map<MovementPattern, int> movementCounts;
  final List<QBuilderCoachingSignal> warnings;
  final List<QBuilderCoachingSignal> highlights;

  const QBuilderReview({
    required this.difficultyScore,
    required this.movementCounts,
    required this.warnings,
    required this.highlights,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

class QBuilderCoachingSignal {
  final QBuilderSignalType type;
  final String message;

  const QBuilderCoachingSignal({
    required this.type,
    required this.message,
  });
}

enum QBuilderSignalType {
  balance,
  safety,
  pacing,
  fng,
  logistics,
  variety,
}

enum MovementPattern {
  push,
  pull,
  legs,
  core,
  conditioning,
  coupon,
}
