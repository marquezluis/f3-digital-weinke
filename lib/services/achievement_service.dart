// lib/services/achievement_service.dart
// Derives achievement badges purely from local history data.
// No persistence needed — badges are recomputed from HistoryService on demand.

import '../models/custom_achievement.dart';
import '../models/workout_history.dart';
import '../utils/streak_calculator.dart' show streakInfo;

enum AchievementTier { bronze, silver, gold }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final bool unlocked;
  // True for a Site-Q-authored achievement (custom_achievement_service.dart)
  // — lets the UI offer a delete action only built-in badges don't get.
  final bool isCustom;
  // How close a locked achievement is to unlocking (e.g. 3 of 4 weeks,
  // 7 of 10 sessions) — null for nothing meaningful to show (shouldn't
  // happen in practice, every def has a real threshold).
  final int? currentProgress;
  final int? targetProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.unlocked,
    this.isCustom = false,
    this.currentProgress,
    this.targetProgress,
  });
}

/// Running totals used to decide whether each achievement is unlocked.
/// Shared by [AchievementService.compute] (final totals) and
/// [AchievementService.unlockDates] (totals as of each session), so the
/// threshold numbers only live in one place: [_AchievementDef.isUnlocked].
class _Stats {
  int count = 0;
  int streak = 0;
  int murphCount = 0;
  int couponCount = 0;
  int uniquePax = 0;
  int totalFngs = 0;
}

class _AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  // The raw progress number and its target, not just a yes/no predicate —
  // exposing both is what lets the UI show "3/4 weeks" for a locked
  // achievement instead of only revealing it the moment it unlocks.
  final int Function(_Stats) currentValue;
  final int target;
  /// True for achievements whose unlock state depends on "now" (a current
  /// streak) rather than purely on accumulated session history — these
  /// can't be attributed to the exact session that "caused" them.
  final bool relativeToNow;

  const _AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.currentValue,
    required this.target,
    this.relativeToNow = false,
  });

  bool isUnlocked(_Stats s) => currentValue(s) >= target;
}

class AchievementService {
  static final List<_AchievementDef> _defs = [
    _AchievementDef(
      id: 'first_beatdown',
      title: 'First Beatdown',
      description: 'Complete your first session.',
      emoji: '🏁',
      tier: AchievementTier.bronze,
      currentValue: (s) => s.count,
      target: 1,
    ),
    _AchievementDef(
      id: 'iron_pax',
      title: 'Iron PAX',
      description: 'Complete 10 sessions.',
      emoji: '💪',
      tier: AchievementTier.bronze,
      currentValue: (s) => s.count,
      target: 10,
    ),
    _AchievementDef(
      id: 'centurion',
      title: 'Centurion',
      description: 'Complete 100 sessions.',
      emoji: '🏆',
      tier: AchievementTier.gold,
      currentValue: (s) => s.count,
      target: 100,
    ),
    _AchievementDef(
      id: 'streak_4',
      title: 'Consistent Q',
      description: '4-week consecutive streak.',
      emoji: '🔥',
      tier: AchievementTier.silver,
      currentValue: (s) => s.streak,
      target: 4,
      relativeToNow: true,
    ),
    _AchievementDef(
      id: 'streak_12',
      title: 'Streak Machine',
      description: '12-week consecutive streak.',
      emoji: '⚡',
      tier: AchievementTier.gold,
      currentValue: (s) => s.streak,
      target: 12,
      relativeToNow: true,
    ),
    _AchievementDef(
      id: 'murph_warrior',
      title: 'Murph Warrior',
      description: 'Complete a Murph Prep beatdown.',
      emoji: '🪖',
      tier: AchievementTier.silver,
      currentValue: (s) => s.murphCount,
      target: 1,
    ),
    _AchievementDef(
      id: 'coupon_grinder',
      title: 'Coupon Grinder',
      description: 'Complete 5 coupon sessions.',
      emoji: '🏋️',
      tier: AchievementTier.bronze,
      currentValue: (s) => s.couponCount,
      target: 5,
    ),
    _AchievementDef(
      id: 'fng_welcome',
      title: 'EH Master',
      description: 'Welcome 5 FNGs total.',
      emoji: '🤝',
      tier: AchievementTier.bronze,
      currentValue: (s) => s.totalFngs,
      target: 5,
    ),
    _AchievementDef(
      id: 'community',
      title: 'Community Builder',
      description: 'Work out with 20 different PAX.',
      emoji: '🫂',
      tier: AchievementTier.silver,
      currentValue: (s) => s.uniquePax,
      target: 20,
    ),
    _AchievementDef(
      id: 'half_century',
      title: 'Half Century',
      description: 'Complete 50 sessions.',
      emoji: '🎖️',
      tier: AchievementTier.silver,
      currentValue: (s) => s.count,
      target: 50,
    ),
  ];

  /// Compute all achievements given the current history.
  static List<Achievement> compute(List<WorkoutHistory> history) {
    final stats = _finalStats(history);
    return _defs
        .map((d) => Achievement(
              id: d.id,
              title: d.title,
              description: d.description,
              emoji: d.emoji,
              tier: d.tier,
              unlocked: d.isUnlocked(stats),
              // Clamp so a stat that's already blown past the target (e.g.
              // 12 sessions against a 10-session badge) doesn't show as
              // "12/10" once unlocked.
              currentProgress: d.currentValue(stats).clamp(0, d.target),
              targetProgress: d.target,
            ))
        .toList();
  }

  /// The date each currently-unlocked achievement was first earned, keyed by
  /// achievement id. Reconstructed by replaying sessions chronologically and
  /// noting the session at which each threshold was first crossed — used to
  /// backfill achievement-unlock entries into the activity feed without any
  /// new persistence. Streak achievements ([_AchievementDef.relativeToNow])
  /// can't be reconstructed this way (a streak is relative to today, not a
  /// fixed point in history), so if currently unlocked they're attributed to
  /// the most recent session instead of a historically-accurate date.
  static Map<String, DateTime> unlockDates(List<WorkoutHistory> history) {
    final sessions = history.where((h) => !h.isTemplate).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final dates = <String, DateTime>{};
    if (sessions.isEmpty) return dates;

    final running = _Stats();
    final paxSoFar = <String>{};
    final murphDefs = _defs.where((d) => !d.relativeToNow);
    for (final s in sessions) {
      running.count++;
      if (s.blocks.any((b) => b.label.toLowerCase().contains('murph'))) {
        running.murphCount++;
      }
      if (s.blocks.any((b) => b.category == 'coupon')) {
        running.couponCount++;
      }
      running.totalFngs += s.fngCount;
      paxSoFar.addAll(s.pax);
      running.uniquePax = paxSoFar.length;

      for (final d in murphDefs) {
        if (!dates.containsKey(d.id) && d.isUnlocked(running)) {
          dates[d.id] = s.date;
        }
      }
    }

    final finalStats = _finalStats(history);
    for (final d in _defs.where((d) => d.relativeToNow)) {
      if (d.isUnlocked(finalStats)) {
        dates[d.id] = sessions.last.date;
      }
    }
    return dates;
  }

  /// Evaluates Site-Q-authored achievements (custom_achievement_service.dart)
  /// against the same history the built-in badges use — separate from
  /// [compute] since these aren't in [_defs] (their unlock conditions are
  /// data, not compiled predicates).
  static List<Achievement> computeCustom(
    List<WorkoutHistory> history,
    List<CustomAchievement> defs,
  ) {
    final sessions = history.where((h) => !h.isTemplate).toList();
    final allPax = <String>{};
    for (final s in sessions) {
      allPax.addAll(s.pax);
    }
    final totalFngs = sessions.fold(0, (sum, s) => sum + s.fngCount);

    return defs.map((d) {
      final progress = switch (d.thresholdType) {
        CustomAchievementThreshold.totalSessions => sessions.length,
        CustomAchievementThreshold.sessionsAtAo => sessions
            .where((s) =>
                s.ao.toLowerCase() == (d.aoFilter ?? '').toLowerCase())
            .length,
        CustomAchievementThreshold.uniquePax => allPax.length,
        CustomAchievementThreshold.fngsWelcomed => totalFngs,
      };
      return Achievement(
        id: d.id,
        title: d.title,
        description: d.description,
        emoji: d.emoji,
        tier: AchievementTier.bronze,
        unlocked: progress >= d.thresholdValue,
        isCustom: true,
        currentProgress: progress.clamp(0, d.thresholdValue),
        targetProgress: d.thresholdValue,
      );
    }).toList();
  }

  static _Stats _finalStats(List<WorkoutHistory> history) {
    final sessions = history.where((h) => !h.isTemplate).toList();
    final allPax = <String>{};
    for (final s in sessions) {
      allPax.addAll(s.pax);
    }
    return _Stats()
      ..count = sessions.length
      // .weeks regardless of status — an in-progress week that hasn't been
      // posted yet doesn't retroactively un-earn the weeks already
      // completed. Shares streak_calculator.dart with Home's streak card
      // instead of an independent (and previously buggy — see there)
      // implementation.
      ..streak = streakInfo(sessions).weeks
      ..murphCount = sessions
          .where((s) => s.blocks.any((b) => b.label.toLowerCase().contains('murph')))
          .length
      ..couponCount =
          sessions.where((s) => s.blocks.any((b) => b.category == 'coupon')).length
      ..uniquePax = allPax.length
      ..totalFngs = sessions.fold(0, (sum, s) => sum + s.fngCount);
  }

}
