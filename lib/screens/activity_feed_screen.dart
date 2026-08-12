// lib/screens/activity_feed_screen.dart
// Community v1.0 — a chronological feed over data the app already has:
// posted backblasts (with Pic-o-Rama photos), achievement unlocks, and
// hard commits. No new backend; see docs/community-v1-proposal.md.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/feed_item.dart';
import '../services/feed_reaction_service.dart';
import '../services/history_service.dart';
import '../services/region_service.dart';
import '../services/feed_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text(
          'ACTIVITY FEED',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        backgroundColor: context.f3bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer2<HistoryService, RegionService>(
        builder: (context, history, region, _) {
          final items = FeedService.build(
            history: history.all,
            hardCommits: region.hardCommits,
            aos: region.aos,
          );

          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, color: context.f3textMuted, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing here yet — post a backblast, log a hard commit,'
                      ' or unlock an achievement to see it show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.f3textSecondary, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: items.length,
            itemBuilder: (context, index) => _FeedTile(item: items[index]),
          );
        },
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final FeedItem item;
  const _FeedTile({required this.item});

  IconData get _icon => switch (item.type) {
        FeedItemType.backblast => Icons.fact_check_rounded,
        FeedItemType.achievement => Icons.emoji_events_rounded,
        FeedItemType.hardCommit => Icons.how_to_reg_rounded,
      };

  Color _iconColor() => switch (item.type) {
        FeedItemType.backblast => F3Colors.accent,
        FeedItemType.achievement => const Color(0xFFFFD700),
        FeedItemType.hardCommit => F3Colors.phaseWarmup,
      };

  @override
  Widget build(BuildContext context) {
    final dateAndAo = [
      shortMonthDay(item.date, Localizations.localeOf(context).languageCode),
      if (item.aoName != null && item.aoName!.isNotEmpty) item.aoName!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.emoji != null)
            Text(item.emoji!, style: const TextStyle(fontSize: 20))
          else
            Icon(_icon, color: _iconColor(), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: context.f3textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.rating != 0) ...[
                      const SizedBox(width: 6),
                      Icon(
                        item.rating == 1 ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                        size: 14,
                        color: item.rating == 1 ? F3Colors.phaseThang : context.f3textMuted,
                      ),
                    ],
                  ],
                ),
                Text(
                  '$dateAndAo · ${item.subtitle}',
                  style: TextStyle(color: context.f3textSecondary, fontSize: 12),
                ),
                if (item.photoPath != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.photoPath!),
                      height: 96,
                      width: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                _SaluteButton(feedItemId: item.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A personal acknowledgment toggle, not a shared reaction count — this is a
/// single-user local app, so there's no honest way to show "N people
/// saluted this". Scoped to its own Consumer so tapping it only rebuilds
/// this row, not the whole feed list.
class _SaluteButton extends StatelessWidget {
  final String feedItemId;
  const _SaluteButton({required this.feedItemId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedReactionService>(
      builder: (context, reactions, _) {
        final saluted = reactions.isSaluted(feedItemId);
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => reactions.toggle(feedItemId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  saluted ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                  size: 16,
                  color: saluted ? F3Colors.accent : context.f3textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  saluted ? 'Saluted' : 'Salute',
                  style: TextStyle(
                    color: saluted ? F3Colors.accent : context.f3textMuted,
                    fontSize: 12,
                    fontWeight: saluted ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
