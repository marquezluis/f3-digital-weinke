// lib/services/timer_service.dart
// Phase-aware timer for the F3 bootcamp.
//
// Anchored to wall-clock time (DateTime.now()), not to counting Timer.periodic
// callbacks. The previous implementation decremented one second per tick and
// trusted that a tick actually meant one real second had passed — which is
// not guaranteed: once the phone screen locks or the app backgrounds mid-
// workout (routine during a real live beatdown), the OS throttles or delays
// timer callbacks, and the naive counter silently drifts behind real elapsed
// time. Anchoring to a real timestamp instead means every recomputation is
// self-correcting: whenever a tick does fire, it reflects the true elapsed
// time since the anchor, not an accumulated guess.
//
// Phase durations default to the standard 50-minute F3 timeline, but The
// Thang duration is overridden by resetWithPlan() so rounds and extended
// blocks are reflected correctly.

import 'dart:async';
import 'package:clock/clock.dart';
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

  // The session's original planned total, before any extendCurrentPhase
  // calls — exposed so timer_screen can compute the halfway alert against a
  // stable baseline rather than a total that grows mid-session.
  int _initialTotalSeconds = TimerState.totalBootcampSeconds;
  int get initialTotalSeconds => _initialTotalSeconds;

  // Extra seconds added to a specific phase via extendCurrentPhase — grows
  // that phase (and every later phase's start boundary) without disturbing
  // phases already passed.
  final Map<BootcampPhase, int> _extraSecondsByPhase = {};

  // ── Wall-clock anchoring ───────────────────────────────────────────────────
  // _runStartedAt marks the real timestamp the current unbroken "running"
  // stretch began. Everything else is banked into the two accumulators below
  // whenever the clock stops running (pause, jump, finish) so resuming never
  // has to "catch up" — the next tick just resumes counting real seconds.

  DateTime? _runStartedAt;

  // Elapsed seconds for phase/progress purposes — explicitly overwritten by
  // jumpToPhase/advancePhase/previousPhase/jumpToMary (those are meant to
  // relocate where the session clock IS, not how long it's been running).
  int _sessionAccumulatedSeconds = 0;

  // Real wall-clock seconds actually spent running, regardless of phase
  // jumps — the "time actually invested" a backblast should report, distinct
  // from the planned/session total. Only reset() clears this.
  int _realAccumulatedSeconds = 0;

  int get _runningDeltaSeconds => _runStartedAt == null
      ? 0
      : clock.now().difference(_runStartedAt!).inSeconds;

  int get _sessionElapsedSeconds =>
      (_sessionAccumulatedSeconds + _runningDeltaSeconds)
          .clamp(0, _totalPlannedSeconds);

  int get elapsedRealSeconds => _realAccumulatedSeconds + _runningDeltaSeconds;

  /// Real minutes invested, rounded up, minimum 1 once any time was logged.
  int get elapsedRealMinutes => elapsedRealSeconds == 0
      ? 0
      : ((elapsedRealSeconds + 59) ~/ 60);

  TimerState get state => _state;

  int _durationForPhase(BootcampPhase phase) =>
      phase == BootcampPhase.thang ? _thangSeconds : phase.durationSeconds;

  /// A phase's duration including any extension applied via
  /// [extendCurrentPhase].
  int _fullDurationForPhase(BootcampPhase phase) =>
      _durationForPhase(phase) + (_extraSecondsByPhase[phase] ?? 0);

  int get _totalPlannedSeconds => BootcampPhase.values
      .fold(0, (sum, p) => sum + _fullDurationForPhase(p));

  /// Cumulative elapsed-seconds value at which [phase] begins.
  int _phaseStartSeconds(BootcampPhase phase) {
    var cursor = 0;
    for (final p in BootcampPhase.values) {
      if (p == phase) return cursor;
      cursor += _fullDurationForPhase(p);
    }
    return cursor;
  }

  /// Builds a fresh, correct snapshot from the current wall-clock-derived
  /// elapsed time — called on every tick and after every state-changing
  /// method, so the displayed values are always freshly computed rather than
  /// incrementally trusted.
  TimerState _buildState(TimerStatus status) {
    final elapsed = _sessionElapsedSeconds;
    final total = _totalPlannedSeconds;

    if (elapsed >= total) {
      return TimerState(
        currentPhase: BootcampPhase.cot,
        phaseRemainingSeconds: 0,
        totalRemainingSeconds: 0,
        totalPlannedSeconds: total,
        currentPhaseDurationSeconds: _fullDurationForPhase(BootcampPhase.cot),
        status: TimerStatus.finished,
      );
    }

    var phase = BootcampPhase.disclaimer;
    var cursor = 0;
    for (final p in BootcampPhase.values) {
      final dur = _fullDurationForPhase(p);
      if (elapsed < cursor + dur) {
        phase = p;
        break;
      }
      cursor += dur;
    }
    final phaseDur = _fullDurationForPhase(phase);
    return TimerState(
      currentPhase: phase,
      phaseRemainingSeconds: (cursor + phaseDur - elapsed).clamp(0, phaseDur),
      totalRemainingSeconds: (total - elapsed).clamp(0, total),
      totalPlannedSeconds: total,
      currentPhaseDurationSeconds: phaseDur,
      status: status,
    );
  }

  /// Banks the current running stretch into both accumulators and stops the
  /// wall-clock anchor — call before any jump/pause so no elapsed time is
  /// silently lost or double-counted.
  void _bankRunningDelta() {
    final delta = _runningDeltaSeconds;
    _sessionAccumulatedSeconds += delta;
    _realAccumulatedSeconds += delta;
    _runStartedAt = null;
  }

  // ── Playback controls ─────────────────────────────────────────────────────

  void start() {
    if (_state.isFinished) return;
    if (_state.totalRemainingSeconds == 0) return;
    _ticker?.cancel();
    _runStartedAt = clock.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _state = _buildState(TimerStatus.running);
    _syncWakelock();
    notifyListeners();
  }

  void pause() {
    if (!_state.isRunning) return;
    _ticker?.cancel();
    _bankRunningDelta();
    _state = _buildState(TimerStatus.paused);
    _syncWakelock();
    notifyListeners();
  }

  void resume() {
    if (_state.isPaused) start();
  }

  void reset() {
    _ticker?.cancel();
    _thangSeconds = BootcampPhase.thang.durationSeconds;
    _extraSecondsByPhase.clear();
    _initialTotalSeconds = TimerState.totalBootcampSeconds;
    _sessionAccumulatedSeconds = 0;
    _realAccumulatedSeconds = 0;
    _runStartedAt = null;
    _state = const TimerState();
    _syncWakelock();
    notifyListeners();
  }

  /// Initialize the timer with plan-aware phase durations.
  /// No-op if the timer is already running (don't disrupt a live session).
  void resetWithPlan(WorkoutPlan plan) {
    if (_state.isRunning) return;
    _ticker?.cancel();
    _extraSecondsByPhase.clear();

    // Sum all Thang blocks (bodyweight + coupon) × rounds.
    final thangSecs = plan.blocks
        .where((b) =>
            b.category == ExerciseCategory.bodyweight ||
            b.category == ExerciseCategory.coupon)
        .fold(0, (sum, b) => sum + b.durationMinutes * b.rounds * 60);

    _thangSeconds = thangSecs > 0 ? thangSecs : BootcampPhase.thang.durationSeconds;
    _initialTotalSeconds = BootcampPhase.values
        .fold(0, (sum, p) => sum + _durationForPhase(p));

    _sessionAccumulatedSeconds = 0;
    _realAccumulatedSeconds = 0;
    _runStartedAt = null;
    _state = _buildState(TimerStatus.idle);
    _syncWakelock();
    notifyListeners();
  }

  /// Jump directly to any phase (long-press on segment bar).
  void jumpToPhase(BootcampPhase phase) {
    if (_state.isFinished) return;
    _ticker?.cancel();
    final wasRunning = _state.isRunning;
    _bankRunningDelta();
    _sessionAccumulatedSeconds = _phaseStartSeconds(phase);
    if (wasRunning) {
      _runStartedAt = clock.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    _state = _buildState(wasRunning ? TimerStatus.running : TimerStatus.paused);
    _syncWakelock();
    notifyListeners();
  }

  /// Add seconds to the current phase (and total) without disrupting the
  /// running clock — elapsed time is untouched, only the plan's durations
  /// (and every later phase boundary) grow.
  void extendCurrentPhase(int seconds) {
    if (_state.isFinished) return;
    final phase = _state.currentPhase;
    _extraSecondsByPhase[phase] = (_extraSecondsByPhase[phase] ?? 0) + seconds;
    _state = _buildState(_state.status);
    notifyListeners();
  }

  /// Skip directly to the Mary phase — Emergency Mary button. Always leaves
  /// the timer running, matching the original "get moving now" behavior.
  void jumpToMary() {
    _ticker?.cancel();
    _bankRunningDelta();
    _sessionAccumulatedSeconds = _phaseStartSeconds(BootcampPhase.mary);
    _runStartedAt = clock.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _state = _buildState(TimerStatus.running);
    _syncWakelock();
    notifyListeners();
  }

  /// Manually advance to the next phase (Q wants to move on early). Any time
  /// left in the current phase is given up, same as before — the session
  /// gets shorter, it doesn't bank the leftover time elsewhere.
  void advancePhase() {
    final next = _state.currentPhase.next;
    if (next == null) {
      _finish();
      return;
    }
    jumpToPhase(next);
  }

  /// Manually go back to the previous phase. Reproduces the original's
  /// exact arithmetic: subtracts the previous phase's full duration from
  /// wherever the elapsed clock currently sits, rather than snapping to a
  /// clean boundary — so going back mid-phase lands the same place it always
  /// did.
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
    final wasRunning = _state.isRunning;
    _bankRunningDelta();
    _sessionAccumulatedSeconds =
        (_sessionAccumulatedSeconds - _fullDurationForPhase(prev))
            .clamp(0, _totalPlannedSeconds);
    if (wasRunning) {
      _runStartedAt = clock.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    _state = _buildState(wasRunning ? TimerStatus.running : TimerStatus.paused);
    _syncWakelock();
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _tick() {
    if (_sessionElapsedSeconds >= _totalPlannedSeconds) {
      _finish();
      return;
    }
    _state = _buildState(TimerStatus.running);
    notifyListeners();
  }

  void _finish() {
    _ticker?.cancel();
    _bankRunningDelta();
    _sessionAccumulatedSeconds = _totalPlannedSeconds;
    _state = TimerState(
      currentPhase: BootcampPhase.cot,
      phaseRemainingSeconds: 0,
      totalRemainingSeconds: 0,
      totalPlannedSeconds: _totalPlannedSeconds,
      currentPhaseDurationSeconds: _fullDurationForPhase(BootcampPhase.cot),
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
