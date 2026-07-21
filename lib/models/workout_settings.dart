// lib/models/workout_settings.dart
// User-configurable workout generation settings.

import 'exercise.dart';

/// Controls how coupons appear in the generated Weinke.
enum CouponMode {
  noCoupons,         // bodyweight only
  coupons,           // coupon block only (replaces bodyweight block)
  mixed,             // both, as two separate labeled blocks (Bodyweight / Coupons)
  mixedInterleaved;  // both, shuffled together into one block

  String get displayName {
    switch (this) {
      case CouponMode.noCoupons:        return 'No Coupons';
      case CouponMode.coupons:          return 'Coupons Only';
      case CouponMode.mixed:            return 'Mixed — Separate Blocks';
      case CouponMode.mixedInterleaved: return 'Mixed — Same Block';
    }
  }
}

enum BeatdownTheme {
  fullBody,
  legDay,
  upperBody,
  heavyCore,
  murphPrep,
  couponGrinder,
  militaryPT,
}

enum WorkoutFormat {
  circuit,
  amrap,
  tabata,
  dora,
  qRescue;

  String get displayName {
    switch (this) {
      case WorkoutFormat.circuit:  return 'Circuit';
      case WorkoutFormat.amrap:    return 'AMRAP';
      case WorkoutFormat.tabata:   return 'Tabata';
      case WorkoutFormat.dora:     return 'Dora';
      case WorkoutFormat.qRescue:  return 'Q-Rescue';
    }
  }
}

class WorkoutSettings {
  final CouponMode couponMode;
  final Set<Intensity> intensities; // which intensity levels to include
  final bool emergencyMaryAvailable;
  final int durationMinutes;
  final BeatdownTheme theme;
  final WorkoutFormat format;
  final bool simpleQMode;
  final int numberOfCircuits;
  final int restBetweenCircuitsMinutes;
  final Set<String> blacklistedIds;

  const WorkoutSettings({
    this.couponMode = CouponMode.mixed,
    this.intensities = const {
      Intensity.beginner,
      Intensity.intermediate,
      Intensity.advanced,
    },
    this.emergencyMaryAvailable = true,
    this.durationMinutes = 50,
    this.theme = BeatdownTheme.fullBody,
    this.format = WorkoutFormat.circuit,
    this.simpleQMode = false,
    this.numberOfCircuits = 1,
    this.restBetweenCircuitsMinutes = 1,
    this.blacklistedIds = const {},
  });

  WorkoutSettings copyWith({
    CouponMode? couponMode,
    Set<Intensity>? intensities,
    bool? emergencyMaryAvailable,
    int? durationMinutes,
    BeatdownTheme? theme,
    WorkoutFormat? format,
    bool? simpleQMode,
    int? numberOfCircuits,
    int? restBetweenCircuitsMinutes,
    Set<String>? blacklistedIds,
  }) {
    return WorkoutSettings(
      couponMode: couponMode ?? this.couponMode,
      intensities: intensities ?? this.intensities,
      emergencyMaryAvailable:
          emergencyMaryAvailable ?? this.emergencyMaryAvailable,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      theme: theme ?? this.theme,
      format: format ?? this.format,
      simpleQMode: simpleQMode ?? this.simpleQMode,
      numberOfCircuits: numberOfCircuits ?? this.numberOfCircuits,
      restBetweenCircuitsMinutes:
          restBetweenCircuitsMinutes ?? this.restBetweenCircuitsMinutes,
      blacklistedIds: blacklistedIds ?? this.blacklistedIds,
    );
  }

  /// True if exercises requiring a coupon should be included.
  bool get includeCoupons =>
      couponMode == CouponMode.coupons ||
      couponMode == CouponMode.mixed ||
      couponMode == CouponMode.mixedInterleaved;

  /// True if bodyweight (non-coupon) thang exercises should be included.
  bool get includeBodyweight =>
      couponMode == CouponMode.noCoupons ||
      couponMode == CouponMode.mixed ||
      couponMode == CouponMode.mixedInterleaved;
}
