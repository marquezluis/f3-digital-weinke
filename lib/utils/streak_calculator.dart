// lib/utils/streak_calculator.dart
// Consecutive-week streak logic, extracted out of home_screen.dart so it's
// actually unit-testable — it used to be a private function on the screen.

import '../models/workout_history.dart';

enum StreakStatus {
  /// No active streak (either no history, or a real gap somewhere).
  none,

  /// This week already has a session — the streak is safe through Sunday.
  secured,

  /// Last week (and before) is intact, but nothing logged yet this week —
  /// the streak is still alive but will break if the week ends with no
  /// session.
  atRisk,
}

typedef StreakInfo = ({int weeks, StreakStatus status});

/// Walking backwards strictly from "now" without ever checking whether this
/// week specifically has a session yet meant a perfectly consistent PAX saw
/// their streak silently zero out every Monday morning until they posted
/// again — there was no way to represent "still alive, not posted yet" as
/// anything other than "broken." This starts the walk from this week only
/// when this week already qualifies; otherwise it starts from last week, so
/// an intact streak stays visible (and markable as at-risk) right up until
/// an actual gap appears.
StreakInfo streakInfo(List<WorkoutHistory> sessions, [DateTime? now]) {
  if (sessions.isEmpty) return (weeks: 0, status: StreakStatus.none);
  final weeksWithSession = <String>{
    for (final s in sessions) isoWeekKey(s.date),
  };
  final today = now ?? DateTime.now();
  final hasThisWeek = weeksWithSession.contains(isoWeekKey(today));

  var cursor = hasThisWeek ? today : today.subtract(const Duration(days: 7));
  int streak = 0;
  while (weeksWithSession.contains(isoWeekKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  if (streak == 0) return (weeks: 0, status: StreakStatus.none);
  return (
    weeks: streak,
    status: hasThisWeek ? StreakStatus.secured : StreakStatus.atRisk,
  );
}

/// Days left (inclusive of today) before this ISO week ends Sunday night —
/// used for the at-risk streak card's urgency copy.
int daysLeftInWeek(DateTime now) => 7 - now.weekday + 1;

String isoWeekKey(DateTime d) {
  // ISO week: Monday is day 1. Use Thursday's year to handle year boundaries.
  final thursday = d.add(Duration(days: 4 - (d.weekday)));
  final firstJan = DateTime(thursday.year, 1, 1);
  final week = ((thursday.difference(firstJan).inDays) ~/ 7) + 1;
  return '${thursday.year}-$week';
}
