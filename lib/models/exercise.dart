// lib/models/exercise.dart
// Core data model for a single F3 Exicon exercise.

enum ExerciseCategory {
  warmup,
  bodyweight,
  coupon,
  mary;

  static ExerciseCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'warmup':    return ExerciseCategory.warmup;
      case 'coupon':    return ExerciseCategory.coupon;
      case 'mary':      return ExerciseCategory.mary;
      default:          return ExerciseCategory.bodyweight;
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseCategory.warmup:     return 'Warm-O-Rama';
      case ExerciseCategory.bodyweight: return 'Bodyweight';
      case ExerciseCategory.coupon:     return 'Coupon';
      case ExerciseCategory.mary:       return 'Mary';
    }
  }

  /// Short label for segment bar / chips.
  String get shortName {
    switch (this) {
      case ExerciseCategory.warmup:     return 'WARM-UP';
      case ExerciseCategory.bodyweight: return 'B.W.';
      case ExerciseCategory.coupon:     return 'COUPON';
      case ExerciseCategory.mary:       return 'MARY';
    }
  }
}

enum Equipment {
  none,
  coupon;

  static Equipment fromString(String value) =>
      value == 'coupon' ? Equipment.coupon : Equipment.none;

  String get displayName => this == Equipment.coupon ? 'Coupon' : 'None';
}

/// Intensity levels — mapped from keyword scoring on description.
enum Intensity {
  beginner,
  intermediate,
  advanced;

  static Intensity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':     return Intensity.beginner;
      case 'advanced':     return Intensity.advanced;
      default:             return Intensity.intermediate;
    }
  }

  String get displayName {
    switch (this) {
      case Intensity.beginner:     return 'Beginner';
      case Intensity.intermediate: return 'Intermediate';
      case Intensity.advanced:     return 'Advanced';
    }
  }

  String get label {
    switch (this) {
      case Intensity.beginner:     return 'BEG';
      case Intensity.intermediate: return 'INT';
      case Intensity.advanced:     return 'ADV';
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final List<String> aliases;
  final ExerciseCategory category;
  final Equipment equipment;
  final Intensity intensity;
  // Only ever set on custom (Q-written) exercises — the bundled Exicon
  // doesn't need it since block duration is already split evenly across
  // whatever exercises land in it. Required when writing a custom one so
  // an unusual movement (a long hold, a distance run) doesn't silently get
  // the same generic split as a 10-rep bodyweight move.
  final int? secondsPerSet;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.aliases,
    required this.category,
    required this.equipment,
    required this.intensity,
    this.secondsPerSet,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      category: ExerciseCategory.fromString(
          json['category'] as String? ?? 'bodyweight'),
      equipment: Equipment.fromString(
          json['equipment'] as String? ?? 'none'),
      intensity: Intensity.fromString(
          json['intensity'] as String? ?? 'intermediate'),
      secondsPerSet: (json['secondsPerSet'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'aliases': aliases,
        'category': category.name,
        'equipment': equipment.name,
        'intensity': intensity.name,
        if (secondsPerSet != null) 'secondsPerSet': secondsPerSet,
      };

  /// Returns a copy with a different category — used for "swap" logic.
  Exercise withCategory(ExerciseCategory newCategory) => Exercise(
        id: id,
        name: name,
        description: description,
        aliases: aliases,
        category: newCategory,
        equipment: equipment,
        intensity: intensity,
        secondsPerSet: secondsPerSet,
      );

  @override
  String toString() =>
      'Exercise($name | ${category.displayName} | ${intensity.displayName})';
}
