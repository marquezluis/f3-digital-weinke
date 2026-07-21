// lib/services/workout_generator.dart
// Generates a balanced Digital Weinke (50-min F3 beatdown plan).
//
// Block structure matches the official F3 timeline:
//   Disclaimer   1 min   (text-only, no exercises)
//   Warm-O-Rama  7 min   3–4 warmup exercises
//   The Thang   32 min   bodyweight and/or coupon exercises (settings-driven)
//   Mary         6 min   4 core/ab exercises
//   COT          4 min   (text-only, no exercises)
//
// Coupon mode (WorkoutSettings.couponMode):
//   noCoupons → Thang is all bodyweight
//   coupons   → Thang is all coupon
//   mixed     → Thang splits ~50/50 bodyweight + coupon
//
// Intensity filter: only exercises matching the enabled intensity levels are
// drawn from.  Falls back to all intensities if the filtered pool is empty.
//
// Swap: swapExercise() replaces one exercise in an existing plan with a
// different one of the same category/equipment/intensity from the pool.

import 'dart:math';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_settings.dart';
import 'exercise_service.dart';

class WorkoutGenerator {
  final ExerciseService _service;
  final Random _rng;

  WorkoutGenerator(this._service, {Random? random}) : _rng = random ?? Random();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Build a standard 7-min Warm-O-Rama block with 4 random warmup exercises.
  WorkoutBlock buildWarmupBlock([WorkoutSettings settings = const WorkoutSettings()]) {
    return _buildBlock(
      label: 'Warm-O-Rama',
      category: ExerciseCategory.warmup,
      durationMinutes: 7,
      count: 4,
      settings: settings,
      notes: '~90 sec each. SSH, Imperial Walkers, stretching.',
    );
  }

  WorkoutPlan generate([WorkoutSettings settings = const WorkoutSettings()]) {
    final blocks = <WorkoutBlock>[];

    // Dynamic timing: 1m Disclaimer + 7m Warmup + 6m Mary + 4m COT = 18m fixed
    int thangMins = max(12, settings.durationMinutes - 18);

    // 1. Warm-O-Rama
    blocks.add(_buildBlock(
      label: 'Warm-O-Rama',
      category: ExerciseCategory.warmup,
      durationMinutes: 7,
      count: 4,
      settings: settings,
      notes: '~90 sec each. SSH, Imperial Walkers, stretching.',
    ));

    // 2. The Thang
    if (settings.theme == BeatdownTheme.murphPrep) {
      // Q Builder's strict Murph Algorithm (40% Pull, 35% Push, 25% Legs)
      blocks.add(_buildMurphThang(thangMins, settings));
    } else {
      // Circuit logic with thematic filters
      int timePerCircuit = thangMins;
      int totalRest = 0;
      if (settings.numberOfCircuits > 1) {
        totalRest = (settings.numberOfCircuits - 1) * settings.restBetweenCircuitsMinutes;
        timePerCircuit = max(1, (thangMins - totalRest) ~/ settings.numberOfCircuits);
      }

      // Generate exercises ONCE to be repeated across circuits.
      final bwExercises = _pullExercises(ExerciseCategory.bodyweight, settings, _thangExerciseCount(settings));
      final couponExercises = _pullExercises(ExerciseCategory.coupon, settings, _thangExerciseCount(settings));
      final mixedBw = _pullExercises(ExerciseCategory.bodyweight, settings, _mixedBlockExerciseCount(settings));
      final mixedCoupon = _pullExercises(ExerciseCategory.coupon, settings, _mixedBlockExerciseCount(settings));

      for (int i = 0; i < settings.numberOfCircuits; i++) {
        String circuitLabel = settings.numberOfCircuits > 1 ? ' (Circuit ${i + 1})' : '';
        
        switch (settings.couponMode) {
          case CouponMode.noCoupons:
            blocks.add(WorkoutBlock(
              label: '${_thangLabel(settings)}$circuitLabel',
              category: ExerciseCategory.bodyweight,
              durationMinutes: timePerCircuit,
              exercises: bwExercises,
              notes: _formatNotes(settings, couponBlock: false),
            ));
            break;
          case CouponMode.coupons:
            blocks.add(WorkoutBlock(
              label: '${_thangLabel(settings)}$circuitLabel',
              category: ExerciseCategory.coupon,
              durationMinutes: timePerCircuit,
              exercises: couponExercises,
              notes: _formatNotes(settings, couponBlock: true),
            ));
            break;
          case CouponMode.mixed:
            final bodyweightMinutes = timePerCircuit ~/ 2;
            final couponMinutes = timePerCircuit - bodyweightMinutes;
            blocks.add(WorkoutBlock(
              label: '${_thangLabel(settings)} — Bodyweight$circuitLabel',
              category: ExerciseCategory.bodyweight,
              durationMinutes: bodyweightMinutes,
              exercises: mixedBw,
              notes: _formatNotes(settings, couponBlock: false),
            ));
            blocks.add(WorkoutBlock(
              label: '${_thangLabel(settings)} — Coupons$circuitLabel',
              category: ExerciseCategory.coupon,
              durationMinutes: couponMinutes,
              exercises: mixedCoupon,
              notes: _formatNotes(settings, couponBlock: true),
            ));
            break;
          case CouponMode.mixedInterleaved:
            // One block, both pools shuffled together — each exercise still
            // carries its own true category (coupon vs bodyweight), only the
            // block itself needs a nominal category for color/labeling.
            final combined = [...mixedBw, ...mixedCoupon]..shuffle(_rng);
            blocks.add(WorkoutBlock(
              label: '${_thangLabel(settings)}$circuitLabel',
              category: ExerciseCategory.bodyweight,
              durationMinutes: timePerCircuit,
              exercises: combined,
              notes: _formatNotes(settings, couponBlock: true),
            ));
            break;
        }

        // Inject a rest block if there are more circuits left
        if (i < settings.numberOfCircuits - 1 && settings.restBetweenCircuitsMinutes > 0) {
          blocks.add(_buildBlock(
            label: 'Rest & Recover',
            category: ExerciseCategory.warmup, // Warmup category is safe for light stretches
            durationMinutes: settings.restBetweenCircuitsMinutes,
            count: 1, // Pull one light exercise just to keep the blood flowing
            settings: settings,
            notes: 'Hydrate, stretch, and catch your breath before the next circuit.',
          ));
        }
      }
    }

    // 3. Mary
    blocks.add(_buildBlock(
      label: 'Mary',
      category: ExerciseCategory.mary,
      durationMinutes: 6,
      count: 4,
      settings: settings,
      notes: '~90 sec each. Circle of Trust to follow.',
    ));

    return WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      generatedAt: DateTime.now(),
      blocks: blocks,
      settings: settings,
    );
  }

  /// Swap a single exercise for a different one of the same category,
  /// equipment, and intensity (if possible).  Returns the original if no
  /// replacement is available.
  Exercise swapExercise(Exercise exercise, WorkoutPlan currentPlan) {
    final usedIds = currentPlan.allExercises.map((e) => e.id).toSet();

    // Q Builder's Swap Logic: Try to downshift intensity for active recovery (e.g. Adv -> Int)
    Intensity targetIntensity = exercise.intensity;
    if (exercise.intensity == Intensity.advanced) {
      targetIntensity = Intensity.intermediate;
    } else if (exercise.intensity == Intensity.intermediate) {
      targetIntensity = Intensity.beginner;
    }

    var pool = _service
        .byCategory(exercise.category)
        .where((e) =>
            e.id != exercise.id &&
            !usedIds.contains(e.id) &&
            e.equipment == exercise.equipment &&
            e.intensity == targetIntensity)
        .toList();

    // Fallback 1: Exact matching equipment (any intensity) if recovery pool empty
    if (pool.isEmpty) {
      pool = _service
          .byCategory(exercise.category)
          .where((e) =>
              e.id != exercise.id &&
              !usedIds.contains(e.id) &&
              e.equipment == exercise.equipment)
          .toList();
    }

    // Fallback 2: Anything in category
    if (pool.isEmpty) {
      pool = _service
          .byCategory(exercise.category)
          .where((e) => e.id != exercise.id && !usedIds.contains(e.id))
          .toList();
    }

    if (pool.isEmpty) return exercise;
    pool.shuffle(_rng);
    return pool.first;
  }

  // ── Q Builder Thematic Builders ───────────────────────────────────────────────

  WorkoutBlock _buildMurphThang(int durationMinutes, WorkoutSettings settings) {
    final pool = [
      ..._filteredPool(ExerciseCategory.bodyweight, settings),
      if (settings.includeCoupons)
        ..._filteredPool(ExerciseCategory.coupon, settings)
    ];

    // Q Builder's categories mapped by naming patterns
    bool isPull(Exercise e) =>
        e.name.toLowerCase().contains('pull') ||
        e.name.toLowerCase().contains('row') ||
        e.name.toLowerCase().contains('curl');
    bool isPush(Exercise e) =>
        e.name.toLowerCase().contains('merkin') ||
        e.name.toLowerCase().contains('press') ||
        e.name.toLowerCase().contains('burpee');
    bool isLeg(Exercise e) =>
        e.name.toLowerCase().contains('squat') ||
        e.name.toLowerCase().contains('lunge');

    final pulls = pool.where(isPull).toList()..shuffle(_rng);
    final pushes = pool.where(isPush).toList()..shuffle(_rng);
    final legs = pool.where(isLeg).toList()..shuffle(_rng);

    final selected = <Exercise>[];
    selected.addAll(pulls.take(3));
    selected.addAll(pushes.take(3));
    selected.addAll(legs.take(2));

    // Fill gaps if the filter was too strict
    if (selected.length < 8) {
      final others = pool.where((e) => !selected.contains(e)).toList()
        ..shuffle(_rng);
      selected.addAll(others.take(8 - selected.length));
    }

    selected.shuffle(_rng); // Mix them up to prevent burning out 1 muscle group

    return WorkoutBlock(
      label: 'The Thang (Murph Prep)',
      category: ExerciseCategory.bodyweight,
      exercises: selected,
      durationMinutes: durationMinutes,
      notes: 'Spartan Ratio: 40% Pull, 35% Push, 25% Legs.',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _thangLabel(WorkoutSettings settings) {
    switch (settings.format) {
      case WorkoutFormat.circuit:
        return 'The Thang';
      case WorkoutFormat.amrap:
        return 'The Thang (AMRAP)';
      case WorkoutFormat.tabata:
        return 'The Thang (Tabata)';
      case WorkoutFormat.dora:
        return 'The Thang (Dora)';
      case WorkoutFormat.qRescue:
        return 'The Thang (Q Rescue)';
    }
  }

  int _thangExerciseCount(WorkoutSettings settings) {
    if (settings.simpleQMode) return 6;
    switch (settings.format) {
      case WorkoutFormat.tabata:
      case WorkoutFormat.qRescue:
        return 6;
      case WorkoutFormat.dora:
        return 5;
      case WorkoutFormat.circuit:
      case WorkoutFormat.amrap:
        return 8;
    }
  }

  int _mixedBlockExerciseCount(WorkoutSettings settings) {
    if (settings.simpleQMode) return 3;
    switch (settings.format) {
      case WorkoutFormat.dora:
      case WorkoutFormat.qRescue:
        return 3;
      case WorkoutFormat.circuit:
      case WorkoutFormat.amrap:
      case WorkoutFormat.tabata:
        return 4;
    }
  }

  String _formatNotes(WorkoutSettings settings, {required bool couponBlock}) {
    final couponNote = couponBlock ? ' Pair up if coupons are short.' : '';
    final simpleNote = settings.simpleQMode
        ? ' Keep transitions simple and demo every move.'
        : '';

    switch (settings.format) {
      case WorkoutFormat.circuit:
        return '~4 min each. Modify as needed (OYO).$couponNote$simpleNote';
      case WorkoutFormat.amrap:
        return 'Run repeatable rounds for the block. Track rounds, not perfection.$couponNote$simpleNote';
      case WorkoutFormat.tabata:
        return 'Use 40s work / 20s rest intervals. Rotate exercises every interval.$couponNote$simpleNote';
      case WorkoutFormat.dora:
        return 'Partner format: one works while one runs. Split reps and pick up the Six.$couponNote$simpleNote';
      case WorkoutFormat.qRescue:
        return 'Low-complexity rescue plan: explain fast, start moving, adjust on the fly.$couponNote$simpleNote';
    }
  }

  WorkoutBlock _buildBlock({
    required String label,
    required ExerciseCategory category,
    required int durationMinutes,
    required int count,
    required WorkoutSettings settings,
    String notes = '',
  }) {
    List<Exercise> pool = _filteredPool(category, settings);

    if (pool.isEmpty) {
      return WorkoutBlock(
        label: label,
        category: category,
        exercises: [],
        durationMinutes: durationMinutes,
        notes: '⚠ No exercises match current settings for this category.',
      );
    }

    final shuffled = List<Exercise>.from(pool)..shuffle(_rng);
    final selected = shuffled.take(count).toList();

    return WorkoutBlock(
      label: label,
      category: category,
      exercises: selected,
      durationMinutes: durationMinutes,
      notes: notes,
    );
  }

  List<Exercise> _pullExercises(ExerciseCategory category, WorkoutSettings settings, int count) {
    List<Exercise> pool = _filteredPool(category, settings);
    if (pool.isEmpty) return [];
    final shuffled = List<Exercise>.from(pool)..shuffle(_rng);
    return shuffled.take(count).toList();
  }

  List<Exercise> _filteredPool(
      ExerciseCategory category, WorkoutSettings settings) {
    List<Exercise> pool = _service.byCategory(category);

    // Apply blacklist filter
    if (settings.blacklistedIds.isNotEmpty) {
      pool = pool.where((e) => !settings.blacklistedIds.contains(e.id)).toList();
    }

    // Apply intensity filter
    if (settings.intensities.isNotEmpty &&
        settings.intensities.length < Intensity.values.length) {
      final filtered = pool
          .where((e) => settings.intensities.contains(e.intensity))
          .toList();
      if (filtered.isNotEmpty) pool = filtered;
    }

    // Apply Q Builder's Thematic Filters
    if (category == ExerciseCategory.bodyweight ||
        category == ExerciseCategory.coupon) {
      if (settings.theme == BeatdownTheme.legDay) {
        final legs = pool
            .where((e) =>
                e.name.toLowerCase().contains('squat') ||
                e.name.toLowerCase().contains('lunge') ||
                e.name.toLowerCase().contains('jump'))
            .toList();
        if (legs.isNotEmpty) pool = legs;
      } else if (settings.theme == BeatdownTheme.upperBody) {
        final upper = pool
            .where((e) =>
                e.name.toLowerCase().contains('merkin') ||
                e.name.toLowerCase().contains('press') ||
                e.name.toLowerCase().contains('pull'))
            .toList();
        if (upper.isNotEmpty) pool = upper;
      } else if (settings.theme == BeatdownTheme.heavyCore) {
        pool.addAll(_service.byCategory(
            ExerciseCategory.mary)); // Mix Mary directly into the Thang
      } else if (settings.theme == BeatdownTheme.militaryPT) {
        final military = pool
            .where((e) =>
                e.name.toLowerCase().contains('merkin') ||
                e.name.toLowerCase().contains('burpee') ||
                e.name.toLowerCase().contains('bear crawl'))
            .toList();
        if (military.isNotEmpty) pool = military;
      } else if (settings.theme == BeatdownTheme.couponGrinder &&
          category == ExerciseCategory.coupon) {
        final grinder = pool
            .where((e) =>
                e.name.toLowerCase().contains('carry') ||
                e.name.toLowerCase().contains('press') ||
                e.name.toLowerCase().contains('row'))
            .toList();
        if (grinder.isNotEmpty) pool = grinder;
      }
    }

    return pool;
  }
}
