// lib/services/feed_service.dart
// Builds the Community activity feed (Community v1.0) by merging data the
// app already has: saved beatdowns, achievement unlocks, and hard commits.
// Stateless — call build() with whatever's current in the relevant services.

import '../models/feed_item.dart';
import '../models/region_models.dart';
import '../models/workout_history.dart';
import 'achievement_service.dart';

class FeedService {
  /// Builds a chronological (newest-first) feed. If [aoFilter] is given,
  /// only entries for that AO are included (case-insensitive); hard commits
  /// are matched by resolving [hardCommits] against [aos].
  static List<FeedItem> build({
    required List<WorkoutHistory> history,
    List<HardCommit> hardCommits = const [],
    List<AreaOfOperations> aos = const [],
    String? aoFilter,
  }) {
    final filter = aoFilter?.toLowerCase();
    final items = <FeedItem>[];

    final sessions =
        history.where((h) => !h.isTemplate && h.completed).toList();
    for (final s in sessions) {
      if (filter != null && s.ao.toLowerCase() != filter) continue;
      final subtitleParts = [
        '${s.totalCount} PAX',
        if (s.fngCount > 0) '${s.fngCount} FNG',
      ];
      items.add(FeedItem(
        type: FeedItemType.backblast,
        date: s.date,
        title: s.q.isNotEmpty ? '${s.q} posted a backblast' : 'Backblast posted',
        subtitle: subtitleParts.join(' · '),
        aoName: s.ao,
        photoPath: s.photoPaths.isNotEmpty ? s.photoPaths.first : null,
        rating: s.rating,
      ));
    }

    if (filter == null) {
      final unlockDates = AchievementService.unlockDates(history);
      final achievements = {
        for (final a in AchievementService.compute(history)) a.id: a,
      };
      unlockDates.forEach((id, date) {
        final a = achievements[id];
        if (a == null) return;
        items.add(FeedItem(
          type: FeedItemType.achievement,
          date: date,
          title: 'Achievement unlocked: ${a.title}',
          subtitle: a.description,
          emoji: a.emoji,
        ));
      });
    }

    for (final hc in hardCommits) {
      final aoName = aos
          .where((ao) => ao.id == hc.aoId)
          .map((ao) => ao.name)
          .firstOrNull;
      if (filter != null && aoName?.toLowerCase() != filter) continue;
      final subtitleParts = [
        '${hc.paxNames.length} HC',
        if (hc.q.isNotEmpty) 'Q: ${hc.q}',
      ];
      items.add(FeedItem(
        type: FeedItemType.hardCommit,
        date: hc.date,
        title: 'Hard Commit posted',
        subtitle: subtitleParts.join(' · '),
        aoName: aoName,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}
