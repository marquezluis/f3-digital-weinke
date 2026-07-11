// lib/services/timer_service.dart
// Phase-aware countdown timer for the F3 50-minute bootcamp.
//
// Phases advance automatically:
//   Disclaimer (1 min) → Warm-O-Rama (7 min) → The Thang (32 min)
//   → Mary (6 min) → COT (4 min) → finished
//
// Emergency Mary: skip immediately to the Mary phase mid-session.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/timer_state.dart';

class TimerService extends ChangeNotifier {
  TimerState _state = const TimerState();
  Timer? _ticker;

  TimerState get state => _state;

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
    _state = const TimerState();
    _syncWakelock();
    notifyListeners();
  }

  /// Jump directly to any phase (long-press on segment bar).
  void jumpToPhase(BootcampPhase phase) {
    if (_state.isFinished) return;
    _ticker?.cancel();
    int remaining = phase.durationSeconds;
    BootcampPhase? next = phase.next;
    while (next != null) {
      remaining += next.durationSeconds;
      next = next.next;
    }
    _state = TimerState(
      currentPhase: phase,
      phaseRemainingSeconds: phase.durationSeconds,
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
    // Calculate total remaining as Mary + COT only.
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
    // Subtract remaining phase time from total to keep them in sync.
    final newTotal =
        _state.totalRemainingSeconds - _state.phaseRemainingSeconds;
    _state = TimerState(
      currentPhase: next,
      phaseRemainingSeconds: next.durationSeconds,
      totalRemainingSeconds: newTotal > 0 ? newTotal : next.durationSeconds,
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
        return; // Already at disclaimer
    }
    _ticker?.cancel();
    final newTotal = _state.totalRemainingSeconds + prev.durationSeconds;
    _state = TimerState(
      currentPhase: prev,
      phaseRemainingSeconds: prev.durationSeconds,
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
    final newPhase = _state.phaseRemainingSeconds - 1;
    final newTotal = _state.totalRemainingSeconds - 1;

    if (newTotal <= 0) {
      _finish();
      return;
    }

    if (newPhase <= 0) {
      // Phase boundary — auto-advance.
      final next = _state.currentPhase.next;
      if (next == null) {
        _finish();
        return;
      }
      _state = TimerState(
        currentPhase: next,
        phaseRemainingSeconds: next.durationSeconds,
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
