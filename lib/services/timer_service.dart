// lib/services/timer_service.dart
// Phase-aware countdown timer for the F3 bootcamp.
//
// Phase durations default to the standard 50-minute F3 timeline, but The Thang
// duration is overridden by resetWithPlan() so rounds and extended blocks are
// reflected in the live countdown.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/exercise.dart';
import '../models/timer_state.dart';
import '../models/workout_plan.dart';

class TimerService extends ChangeNotifier {
  TimerState _state = const TimerState();
  Timer? _ticker;

  // Thang duration can be overridden by resetWithPlan().
  int _thangSeconds = BootcampPhase.thang.durationSeconds;

  // Exposed so timer_screen can compute halfway alert correctly.
  int _initialTotalSeconds = TimerState.totalBootcampSeconds;
  int get initialTotalSeconds => _initialTotalSeconds;

  // Real wall-clock seconds the timer actually ran — accumulates one per
  // running tick, unaffected by skipping phases or extending. This is the
  // "time actually invested" a backblast should report, vs. the planned
  // total. Reset alongside the plan.
  int _elapsedRealSeconds = 0;
  int get elapsedRealSeconds => _elapsedRealSeconds;

  /// Real minutes invested, rounded up, minimum 1 once any time was logged.
  int get elapsedRealMinutes =>
      _elapsedRealSeconds == 0 ? 0 : ((_elapsedRealSeconds + 59) ~/ 60);

  TimerState get state => _state;

  int _durationForPhase(BootcampPhase phase) =>
      phase == BootcampPhase.thang ? _thangSeconds : phase.durationSeconds;

  // ── Playback controls ─────────────────────────────────────────────────────

  void start() {
    if (_state.isFinished) return;
    if (_state.totalRemainingSeconds == 0) return;
    _state = _state.copyWith(status: TimerStatus.running);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _syncWakelock();
    notifyListeners();
  }

  void pause() {
    if (!_state.isRunning) return;
    _ticker?.cancel();
    _state = _state.copyWith(status: TimerStatus.paused);
    _syncWakelock();
    notifyListeners();
  }

  void resume() {
    if (_state.isPaused) start();
  }

  void reset() {
    _ticker?.cancel();
    _thangSeconds = BootcampPhase.thang.durationSeconds;
    _initialTotalSeconds = TimerState.totalBootcampSeconds;
    _elapsedRealSeconds = 0;
    _state = const TimerState();
    _syncWakelock();
    notifyListeners();
  }

  /// Initialize the timer with plan-aware phase durations.
  /// No-op if the timer is already running (don't disrupt a live session).
  void resetWithPlan(WorkoutPlan plan) {
    if (_state.isRunning) return;
    _ticker?.cancel();

    // Sum all Thang blocks (bodyweight + coupon) × rounds.
    final thangSecs = plan.blocks
        .where((b) =>
            b.category == ExerciseCategory.bodyweight ||
            b.category == ExerciseCategory.coupon)
        .fold(0, (sum, b) => sum + b.durationMinutes * b.rounds * 60);

    _thangSeconds = thangSecs > 0 ? thangSecs : BootcampPhase.thang.durationSeconds;

    final total = BootcampPhase.values
        .fold(0, (sum, p) => sum + _durationForPhase(p));

    _initialTotalSeconds = total;

    _elapsedRealSeconds = 0;
    _state = TimerState(
      currentPhase: BootcampPhase.disclaimer,
      phaseRemainingSeconds: _durationForPhase(BootcampPhase.disclaimer),
      totalRemainingSeconds: total,
      status: TimerStatus.idle,
    );
    _syncWakelock();
    notifyListeners();
  }

  /// Jump directly to any phase (long-press on segment bar).
  void jumpToPhase(BootcampPhase phase) {
    if (_state.isFinished) return;
    _ticker?.cancel();
    int remaining = _durationForPhase(phase);
    BootcampPhase? next = phase.next;
    while (next != null) {
      remaining += _durationForPhase(next);
      next = next.next;
    }
    _state = TimerState(
      currentPhase: phase,
      phaseRemainingSeconds: _durationForPhase(phase),
      totalRemainingSeconds: remaining,
      status: _state.isRunning ? TimerStatus.running : TimerStatus.paused,
    );
    if (_state.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    _syncWakelock();
    notifyListeners();
  }

  /// Add seconds to the current phase (and total) without disrupting the tick.
  void extendCurrentPhase(int seconds) {
    if (_state.isFinished) return;
    _state = _state.copyWith(
      phaseRemainingSeconds: _state.phaseRemainingSeconds + seconds,
      totalRemainingSeconds: _state.totalRemainingSeconds + seconds,
    );
    notifyListeners();
  }

  /// Skip directly to the Mary phase — Emergency Mary button.
  void jumpToMary() {
    _ticker?.cancel();
    final marySeconds =
        BootcampPhase.mary.durationSeconds + BootcampPhase.cot.durationSeconds;
    _state = TimerState(
      currentPhase: BootcampPhase.mary,
      phaseRemainingSeconds: BootcampPhase.mary.durationSeconds,
      totalRemainingSeconds: marySeconds,
      status: TimerStatus.running,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _syncWakelock();
    notifyListeners();
  }

  /// Manually advance to the next phase (Q wants to move on early).
  void advancePhase() {
    final next = _state.currentPhase.next;
    if (next == null) {
      _finish();
      return;
    }
    _ticker?.cancel();
    final newTotal =
        _state.totalRemainingSeconds - _state.phaseRemainingSeconds;
    _state = TimerState(
      currentPhase: next,
      phaseRemainingSeconds: _durationForPhase(next),
      totalRemainingSeconds: newTotal > 0 ? newTotal : _durationForPhase(next),
      status: _state.isRunning ? TimerStatus.running : TimerStatus.paused,
    );
    if (_state.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    _syncWakelock();
    notifyListeners();
  }

  /// Manually go back to the previous phase.
  void previousPhase() {
    BootcampPhase prev;
    switch (_state.currentPhase) {
      case BootcampPhase.warmup:
        prev = BootcampPhase.disclaimer;
        break;
      case BootcampPhase.thang:
        prev = BootcampPhase.warmup;
        break;
      case BootcampPhase.mary:
        prev = BootcampPhase.thang;
        break;
      case BootcampPhase.cot:
        prev = BootcampPhase.mary;
        break;
      default:
        return;
    }
    _ticker?.cancel();
    final newTotal = _state.totalRemainingSeconds + _durationForPhase(prev);
    _state = TimerState(
      currentPhase: prev,
      phaseRemainingSeconds: _durationForPhase(prev),
      totalRemainingSeconds: newTotal,
      status: _state.isRunning ? TimerStatus.running : TimerStatus.paused,
    );
    if (_state.isRunning) {
      start();
    } else {
      _syncWakelock();
      notifyListeners();
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _tick() {
    _elapsedRealSeconds++;
    final newPhase = _state.phaseRemainingSeconds - 1;
    final newTotal = _state.totalRemainingSeconds - 1;

    if (newTotal <= 0) {
      _finish();
      return;
    }

    if (newPhase <= 0) {
      final next = _state.currentPhase.next;
      if (next == null) {
        _finish();
        return;
      }
      _state = TimerState(
        currentPhase: next,
        phaseRemainingSeconds: _durationForPhase(next),
        totalRemainingSeconds: newTotal,
        status: TimerStatus.running,
      );
    } else {
      _state = _state.copyWith(
        phaseRemainingSeconds: newPhase,
        totalRemainingSeconds: newTotal,
      );
    }
    notifyListeners();
  }

  void _finish() {
    _ticker?.cancel();
    _state = _state.copyWith(
      phaseRemainingSeconds: 0,
      totalRemainingSeconds: 0,
      status: TimerStatus.finished,
    );
    _syncWakelock();
    notifyListeners();
  }

  void _syncWakelock() {
    final call =
        _state.isRunning ? WakelockPlus.enable() : WakelockPlus.disable();
    unawaited(call.catchError((_) {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(WakelockPlus.disable().catchError((_) {}));
    super.dispose();
  }
}
