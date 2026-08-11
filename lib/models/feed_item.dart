// lib/models/feed_item.dart
// A single entry in the Community activity feed — Community v1.0.
// Assembled entirely from data the app already has locally (HistoryService,
// RegionService, AchievementService); no new backend or persistence.
// See docs/community-v1-proposal.md for the phased plan this fits into.

enum FeedItemType { backblast, achievement, hardCommit }

class FeedItem {
  final FeedItemType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final String? aoName;
  final String? emoji;
  final String? photoPath;
  final int rating;

  const FeedItem({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.aoName,
    this.emoji,
    this.photoPath,
    this.rating = 0,
  });

  /// Feed items are recomputed fresh from HistoryService/RegionService on
  /// every build rather than persisted, so there's no stored id to key a
  /// reaction against — this derives a stable one from content that doesn't
  /// change once an item exists (same session → same id every rebuild).
  String get id => '${type.name}_${date.toIso8601String()}_$title';
}
