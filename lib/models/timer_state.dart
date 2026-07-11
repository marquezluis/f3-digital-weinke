// lib/models/timer_state.dart
// Phase-aware F3 bootcamp timer model.
//
// Official F3 50-minute timeline (5:30–6:20 AM):
//   5:30–5:31  Disclaimer   1 min
//   5:31–5:38  Warm-O-Rama  7 min
//   5:38–6:10  The Thang   32 min
//   6:10–6:16  Mary         6 min
//   6:16–6:20  COT          4 min
//                         ───────
//   TOTAL                  50 min

import 'package:flutter/material.dart';

enum TimerStatus { idle, running, paused, finished }

enum BootcampPhase {
  disclaimer,
  warmup,
  thang,
  mary,
  cot;

  String get displayName {
    switch (this) {
      case BootcampPhase.disclaimer:
        return 'DISCLAIMER';
      case BootcampPhase.warmup:
        return 'WARM-O-RAMA';
      case BootcampPhase.thang:
        return 'THE THANG';
      case BootcampPhase.mary:
        return 'MARY';
      case BootcampPhase.cot:
        return 'COT';
    }
  }

  String get subtitle {
    switch (this) {
      case BootcampPhase.disclaimer:
        return '1 min · Legal disclaimer';
      case BootcampPhase.warmup:
        return '7 min · Dynamic stretching';
      case BootcampPhase.thang:
        return '32 min · Main workout';
      case BootcampPhase.mary:
        return '6 min · Core work';
      case BootcampPhase.cot:
        return '4 min · Circle of Trust';
    }
  }

  int get durationMinutes {
    switch (this) {
      case BootcampPhase.disclaimer:
        return 1;
      case BootcampPhase.warmup:
        return 7;
      case BootcampPhase.thang:
        return 32;
      case BootcampPhase.mary:
        return 6;
      case BootcampPhase.cot:
        return 4;
    }
  }

  int get durationSeconds => durationMinutes * 60;

  BootcampPhase? get next {
    const phases = BootcampPhase.values;
    final idx = phases.indexOf(this);
    return idx < phases.length - 1 ? phases[idx + 1] : null;
  }

  Color get color {
    switch (this) {
      case BootcampPhase.disclaimer:
        return const Color(0xFF7B8EAA);
      case BootcampPhase.warmup:
        return const Color(0xFF4CAF50);
      case BootcampPhase.thang:
        return const Color(0xFFEE6059);
      case BootcampPhase.mary:
        return const Color(0xFF9C6FE0);
      case BootcampPhase.cot:
        return const Color(0xFFFFD54F);
    }
  }
}

/// Immutable snapshot of the timer at any tick.
class TimerState {
  static const int totalBootcampSeconds = 50 * 60;
  static const int initialPhaseSeconds = 1 * 60;

  final BootcampPhase currentPhase;
  final int phaseRemainingSeconds; // seconds left in this phase
  final int totalRemainingSeconds; // seconds left in entire 50-min session
  final TimerStatus status;

  const TimerState({
    this.currentPhase = BootcampPhase.disclaimer,
    this.phaseRemainingSeconds = initialPhaseSeconds,
    this.totalRemainingSeconds = totalBootcampSeconds,
    this.status = TimerStatus.idle,
  });

  TimerState copyWith({
    BootcampPhase? currentPhase,
    int? phaseRemainingSeconds,
    int? totalRemainingSeconds,
    TimerStatus? status,
  }) {
    return TimerState(
      currentPhase: currentPhase ?? this.currentPhase,
      phaseRemainingSeconds:
          phaseRemainingSeconds ?? this.phaseRemainingSeconds,
      totalRemainingSeconds:
          totalRemainingSeconds ?? this.totalRemainingSeconds,
      status: status ?? this.status,
    );
  }

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;
  bool get isFinished => status == TimerStatus.finished;

  /// Progress within the current phase: 0.0 → 1.0.
  double get phaseProgress {
    final total = currentPhase.durationSeconds;
    if (total == 0) return 1.0;
    return 1.0 - (phaseRemainingSeconds / total);
  }

  /// Progress across the full 50-minute session: 0.0 → 1.0.
  double get totalProgress =>
      1.0 - (totalRemainingSeconds / totalBootcampSeconds);

  String get formattedPhaseRemaining => _fmt(phaseRemainingSeconds);
  String get formattedTotalRemaining => _fmt(totalRemainingSeconds);

  static String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
