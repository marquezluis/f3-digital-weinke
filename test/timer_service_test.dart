// test/timer_service_test.dart
// Unit tests for the phase-aware TimerState and TimerService.
// Run with: flutter test

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/models/timer_state.dart';
import 'package:f3_nation_app/models/workout_plan.dart';
import 'package:f3_nation_app/services/timer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── BootcampPhase ─────────────────────────────────────────────────────────
  group('BootcampPhase', () {
    test('phase durations sum to 50 minutes', () {
      final total =
          BootcampPhase.values.fold(0, (sum, p) => sum + p.durationMinutes);
      expect(total, 50);
    });

    test('phase sequence is correct', () {
      expect(BootcampPhase.disclaimer.next, BootcampPhase.warmup);
      expect(BootcampPhase.warmup.next, BootcampPhase.thang);
      expect(BootcampPhase.thang.next, BootcampPhase.mary);
      expect(BootcampPhase.mary.next, BootcampPhase.cot);
      expect(BootcampPhase.cot.next, isNull);
    });
  });

  // ── TimerState ────────────────────────────────────────────────────────────
  group('TimerState', () {
    test('default state: idle, disclaimer phase, 50 min remaining', () {
      const state = TimerState();
      expect(state.status, TimerStatus.idle);
      expect(state.currentPhase, BootcampPhase.disclaimer);
      expect(state.totalRemainingSeconds, TimerState.totalBootcampSeconds);
      expect(state.formattedTotalRemaining, '50:00');
      expect(state.totalProgress, 0.0);
    });

    test('phaseProgress is 0.5 at half of a phase', () {
      final disclaimer = BootcampPhase.disclaimer.durationSeconds;
      final state = TimerState(
        currentPhase: BootcampPhase.disclaimer,
        phaseRemainingSeconds: disclaimer ~/ 2,
        totalRemainingSeconds: TimerState.totalBootcampSeconds,
        status: TimerStatus.running,
      );
      expect(state.phaseProgress, closeTo(0.5, 0.01));
    });

    test('formattedPhaseRemaining formats correctly', () {
      const state = TimerState(
        currentPhase: BootcampPhase.warmup,
        phaseRemainingSeconds: 125, // 2:05
        totalRemainingSeconds: 2000,
        status: TimerStatus.running,
      );
      expect(state.formattedPhaseRemaining, '02:05');
    });
  });

  // ── TimerService ──────────────────────────────────────────────────────────
  group('TimerService', () {
    late TimerService service;
    setUp(() => service = TimerService());
    tearDown(() => service.dispose());

    test('starts in idle state', () {
      expect(service.state.isIdle, isTrue);
    });

    test('start() transitions to running', () {
      service.start();
      expect(service.state.isRunning, isTrue);
    });

    test('pause() transitions running → paused', () {
      service.start();
      service.pause();
      expect(service.state.isPaused, isTrue);
    });

    test('resume() transitions paused → running', () {
      service.start();
      service.pause();
      service.resume();
      expect(service.state.isRunning, isTrue);
    });

    test('reset() returns to initial idle state', () {
      service.start();
      service.reset();
      expect(service.state.isIdle, isTrue);
      expect(service.state.currentPhase, BootcampPhase.disclaimer);
      expect(
          service.state.totalRemainingSeconds, TimerState.totalBootcampSeconds);
    });

    test('jumpToMary() sets phase to Mary and starts timer', () {
      service.jumpToMary();
      expect(service.state.currentPhase, BootcampPhase.mary);
      expect(service.state.isRunning, isTrue);
    });

    test('jumpToMary() total seconds equals Mary + COT only', () {
      service.jumpToMary();
      final expected = BootcampPhase.mary.durationSeconds +
          BootcampPhase.cot.durationSeconds;
      expect(service.state.totalRemainingSeconds, expected);
    });

    test('advancePhase() moves to next phase', () {
      service.start();
      expect(service.state.currentPhase, BootcampPhase.disclaimer);
      service.advancePhase();
      expect(service.state.currentPhase, BootcampPhase.warmup);
    });
  });

  // ── Wall-clock accuracy ────────────────────────────────────────────────────
  // These are the regression tests for the actual bug report: the previous
  // implementation decremented one second per Timer.periodic callback and
  // trusted that a callback meant exactly one real second had passed. Under
  // fakeAsync, ticks fire deterministically, so what these really verify is
  // that elapsed/remaining time is computed from wall-clock deltas (clock.now())
  // rather than an incrementally-trusted counter — the actual fix — so a
  // real run (where ticks CAN be delayed or dropped by the OS while
  // backgrounded) self-corrects the moment any tick does fire, instead of
  // silently drifting behind real elapsed time for the rest of the session.
  group('TimerService — wall-clock accuracy', () {
    test('phase and remaining time land correctly after a long elapse', () {
      fakeAsync((async) {
        final service = TimerService();
        service.start();
        // 60s Disclaimer + 90s into the 7-minute Warm-O-Rama.
        async.elapse(const Duration(seconds: 150));
        expect(service.state.currentPhase, BootcampPhase.warmup);
        expect(service.state.phaseRemainingSeconds, 7 * 60 - 90);
        expect(service.state.totalRemainingSeconds,
            TimerState.totalBootcampSeconds - 150);
        service.dispose();
      });
    });

    test('pausing excludes paused duration from elapsed time', () {
      fakeAsync((async) {
        final service = TimerService();
        service.start();
        async.elapse(const Duration(seconds: 30));
        service.pause();
        final remainingAtPause = service.state.totalRemainingSeconds;

        // Time passes while paused — must not count against the session.
        async.elapse(const Duration(minutes: 5));
        expect(service.state.totalRemainingSeconds, remainingAtPause);

        service.resume();
        async.elapse(const Duration(seconds: 15));
        expect(service.state.totalRemainingSeconds,
            TimerState.totalBootcampSeconds - 45);
        service.dispose();
      });
    });

    test('elapsedRealSeconds counts only actual running time, not pauses',
        () {
      fakeAsync((async) {
        final service = TimerService();
        service.start();
        async.elapse(const Duration(seconds: 20));
        service.pause();
        async.elapse(const Duration(minutes: 10));
        service.resume();
        async.elapse(const Duration(seconds: 10));
        expect(service.elapsedRealSeconds, 30);
        service.dispose();
      });
    });

    test('a custom (non-32-min) Thang duration still totals correctly over '
        'a full elapsed session', () {
      fakeAsync((async) {
        final service = TimerService();
        final plan = WorkoutPlan(
          id: 'p',
          generatedAt: DateTime(2026, 1, 1),
          blocks: const [
            WorkoutBlock(
              label: 'THE THANG',
              category: ExerciseCategory.bodyweight,
              exercises: [],
              durationMinutes: 20, // shorter than the 32-min default
            ),
          ],
        );
        service.resetWithPlan(plan);
        const expectedTotal =
            1 + 7 + 20 + 6 + 4; // disclaimer+warmup+thang+mary+cot, minutes
        expect(service.state.totalRemainingSeconds, expectedTotal * 60);

        service.start();
        async.elapse(const Duration(minutes: expectedTotal));
        expect(service.state.isFinished, isTrue);
        expect(service.state.totalRemainingSeconds, 0);
        service.dispose();
      });
    });

    test('extendCurrentPhase grows the total without moving already-elapsed '
        'time', () {
      fakeAsync((async) {
        final service = TimerService();
        service.start();
        async.elapse(const Duration(seconds: 30));
        service.extendCurrentPhase(60);
        // Elapsed time is unaffected; only remaining grows.
        expect(service.state.phaseRemainingSeconds, 60 - 30 + 60);
        expect(service.state.totalRemainingSeconds,
            TimerState.totalBootcampSeconds - 30 + 60);
        service.dispose();
      });
    });
  });
}
