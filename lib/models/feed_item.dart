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
}
