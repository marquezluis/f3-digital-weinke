// test/streak_calculator_test.dart
// Unit tests for the consecutive-week streak logic. The core regression
// this guards against: a perfectly consistent PAX's streak used to zero out
// every Monday morning until they posted again, because the old logic
// always started its walk at "now" without checking whether this week had
// a session yet.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/utils/streak_calculator.dart';

WorkoutHistory _session(DateTime date) => WorkoutHistory(
      id: date.toIso8601String(),
      title: 'Beatdown',
      date: date,
    );

void main() {
  group('streakInfo', () {
    test('no sessions at all is StreakStatus.none', () {
      final result = streakInfo(const []);
      expect(result.weeks, 0);
      expect(result.status, StreakStatus.none);
    });

    test('a session this week is secured', () {
      final now = DateTime(2026, 8, 12); // Wednesday
      final result = streakInfo([_session(now)], now);
      expect(result.weeks, 1);
      expect(result.status, StreakStatus.secured);
    });

    test(
        'REGRESSION: a consistent streak with nothing posted yet this week is '
        'at-risk, not silently reset to zero', () {
      final now = DateTime(2026, 8, 12); // Wednesday, no session yet this week
      final sessions = [
        _session(DateTime(2026, 8, 5)), // last week
        _session(DateTime(2026, 7, 29)), // the week before
        _session(DateTime(2026, 7, 22)), // and before that
      ];
      final result = streakInfo(sessions, now);
      expect(result.weeks, 3);
      expect(result.status, StreakStatus.atRisk);
    });

    test('a real gap breaks the streak entirely, not just marks it at-risk', () {
      final now = DateTime(2026, 8, 12); // Wednesday
      final sessions = [
        // Nothing this week, nothing last week — a genuine gap, not just
        // "haven't posted yet this week".
        _session(DateTime(2026, 7, 22)),
        _session(DateTime(2026, 7, 15)),
      ];
      final result = streakInfo(sessions, now);
      expect(result.weeks, 0);
      expect(result.status, StreakStatus.none);
    });

    test('counts multiple consecutive weeks correctly when this week is secured', () {
      final now = DateTime(2026, 8, 12); // Wednesday
      final sessions = [
        _session(now),
        _session(DateTime(2026, 8, 5)),
        _session(DateTime(2026, 7, 29)),
      ];
      final result = streakInfo(sessions, now);
      expect(result.weeks, 3);
      expect(result.status, StreakStatus.secured);
    });

    test('multiple sessions in the same week only count once', () {
      final now = DateTime(2026, 8, 12); // Wednesday
      final sessions = [
        _session(now),
        _session(now.subtract(const Duration(days: 1))),
      ];
      final result = streakInfo(sessions, now);
      expect(result.weeks, 1);
    });
  });

  group('daysLeftInWeek', () {
    test('Monday has 7 days left (inclusive)', () {
      expect(daysLeftInWeek(DateTime(2026, 8, 10)), 7); // Monday
    });

    test('Sunday has 1 day left', () {
      expect(daysLeftInWeek(DateTime(2026, 8, 16)), 1); // Sunday
    });

    test('Wednesday has 5 days left', () {
      expect(daysLeftInWeek(DateTime(2026, 8, 12)), 5); // Wednesday
    });
  });

  group('isoWeekKey', () {
    test('same week produces the same key regardless of weekday', () {
      expect(
        isoWeekKey(DateTime(2026, 8, 10)), // Monday
        isoWeekKey(DateTime(2026, 8, 16)), // Sunday, same ISO week
      );
    });

    test('adjacent weeks produce different keys', () {
      expect(
        isoWeekKey(DateTime(2026, 8, 10)),
        isNot(isoWeekKey(DateTime(2026, 8, 17))),
      );
    });
  });
}
