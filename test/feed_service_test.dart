// test/feed_service_test.dart
// Unit tests for FeedService.build — the Community v1.0 activity feed.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/feed_item.dart';
import 'package:f3_nation_app/models/region_models.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/feed_service.dart';

void main() {
  group('FeedService.build', () {
    test('includes a backblast item per completed, non-template session', () {
      final items = FeedService.build(history: [
        WorkoutHistory(
          id: '1',
          title: 'Beatdown',
          date: DateTime(2026, 1, 1),
          ao: 'The Ruckus',
          q: 'PermVac',
          pax: ['Tackle', 'Moneyball'],
          fngCount: 1,
        ),
        WorkoutHistory(
          id: 'tmpl',
          title: 'Saved Template',
          date: DateTime(2026, 1, 2),
          isTemplate: true,
        ),
      ]);

      final backblasts = items.where((i) => i.type == FeedItemType.backblast);
      expect(backblasts.length, 1);
      expect(backblasts.first.title, contains('PermVac'));
      expect(backblasts.first.subtitle, contains('3 PAX'));
      expect(backblasts.first.subtitle, contains('1 FNG'));
    });

    test('includes achievement-unlock items reconstructed from history', () {
      final items = FeedService.build(history: [
        WorkoutHistory(id: '1', title: 'Beatdown', date: DateTime(2026, 1, 1)),
      ]);

      final achievementTitles =
          items.where((i) => i.type == FeedItemType.achievement).map((i) => i.title);
      expect(achievementTitles, contains(contains('First Beatdown')));
    });

    test('includes hard commits and resolves their AO name', () {
      final items = FeedService.build(
        history: const [],
        aos: const [AreaOfOperations(id: 'ao1', name: 'The Ruckus')],
        hardCommits: [
          HardCommit(
            id: 'hc1',
            aoId: 'ao1',
            date: DateTime(2026, 1, 5),
            paxNames: ['Tackle', 'Moneyball'],
            q: 'PermVac',
          ),
        ],
      );

      final hc = items.firstWhere((i) => i.type == FeedItemType.hardCommit);
      expect(hc.aoName, 'The Ruckus');
      expect(hc.subtitle, contains('2 HC'));
      expect(hc.subtitle, contains('Q: PermVac'));
    });

    test('sorts newest first across all item types', () {
      final items = FeedService.build(
        history: [
          WorkoutHistory(id: '1', title: 'Beatdown', date: DateTime(2026, 1, 1)),
          WorkoutHistory(id: '2', title: 'Beatdown', date: DateTime(2026, 3, 1)),
        ],
        aos: const [AreaOfOperations(id: 'ao1', name: 'The Ruckus')],
        hardCommits: [
          HardCommit(id: 'hc1', aoId: 'ao1', date: DateTime(2026, 2, 1)),
        ],
      );

      for (var i = 0; i < items.length - 1; i++) {
        expect(items[i].date.isBefore(items[i + 1].date), isFalse);
      }
    });

    test('an AO filter excludes achievements — they are not AO-specific', () {
      final items = FeedService.build(
        history: [
          WorkoutHistory(
            id: '1',
            title: 'Beatdown',
            date: DateTime(2026, 1, 1),
            ao: 'The Ruckus',
          ),
        ],
        aoFilter: 'the ruckus',
      );

      expect(items.any((i) => i.type == FeedItemType.achievement), isFalse);
      expect(items.single.type, FeedItemType.backblast);
    });

    test('an AO filter excludes backblasts and hard commits from other AOs', () {
      final items = FeedService.build(
        history: [
          WorkoutHistory(
            id: '1',
            title: 'Beatdown',
            date: DateTime(2026, 1, 1),
            ao: 'Iron Mountain',
          ),
        ],
        aoFilter: 'the ruckus',
      );

      expect(items, isEmpty);
    });
  });

  group('FeedItem.id', () {
    test('is stable across separately-built instances of the same item', () {
      final a = FeedItem(
        type: FeedItemType.backblast,
        date: DateTime(2026, 1, 1),
        title: 'PermVac posted a backblast',
        subtitle: '5 PAX',
      );
      final b = FeedItem(
        type: FeedItemType.backblast,
        date: DateTime(2026, 1, 1),
        title: 'PermVac posted a backblast',
        subtitle: '5 PAX',
      );
      // Reactions are keyed by this id, and feed items are recomputed fresh
      // on every rebuild rather than persisted — a salute has to survive
      // that, so two builds of "the same" item must agree on an id even
      // though they're different object instances.
      expect(a.id, b.id);
    });

    test('differs when type, date, or title differ', () {
      final base = FeedItem(
        type: FeedItemType.backblast,
        date: DateTime(2026, 1, 1),
        title: 'Backblast posted',
        subtitle: '',
      );
      expect(
        base.id,
        isNot(FeedItem(
          type: FeedItemType.achievement,
          date: DateTime(2026, 1, 1),
          title: 'Backblast posted',
          subtitle: '',
        ).id),
      );
      expect(
        base.id,
        isNot(FeedItem(
          type: FeedItemType.backblast,
          date: DateTime(2026, 1, 2),
          title: 'Backblast posted',
          subtitle: '',
        ).id),
      );
      expect(
        base.id,
        isNot(FeedItem(
          type: FeedItemType.backblast,
          date: DateTime(2026, 1, 1),
          title: 'A different title',
          subtitle: '',
        ).id),
      );
    });
  });
}
