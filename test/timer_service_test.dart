// test/timer_service_test.dart
// Unit tests for the phase-aware TimerState and TimerService.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/timer_state.dart';
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
}
