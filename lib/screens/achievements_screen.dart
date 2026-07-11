// lib/screens/achievements_screen.dart
// Displays achievement badges derived from local session history.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievement_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: context.f3bg,
      ),
      body: Consumer<HistoryService>(
        builder: (context, svc, _) {
          final badges = AchievementService.compute(svc.all);
          final unlocked = badges.where((b) => b.unlocked).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: F3Colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Text('🏅', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '$unlocked / ${badges.length} Unlocked',
                      style: const TextStyle(
                          color: F3Colors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Keep grinding, PAX.',
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 13),
                    ),
                  ]),
                ]),
              ),
              ...badges.map((badge) => _BadgeTile(badge: badge)),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (badge.tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silver => const Color(0xFFC0C0C0),
      AchievementTier.gold => const Color(0xFFFFD700),
    };
    final color = badge.unlocked ? tierColor : context.f3textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badge.unlocked
              ? color.withValues(alpha: 0.08)
              : context.f3card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.unlocked
                ? color.withValues(alpha: 0.4)
                : context.f3divider,
          ),
        ),
        child: Row(children: [
          Text(
            badge.emoji,
            style: TextStyle(
              fontSize: 32,
              color: badge.unlocked ? null : context.f3textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                badge.title,
                style: TextStyle(
                  color: badge.unlocked
                      ? context.f3textPrimary
                      : context.f3textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                badge.description,
                style: TextStyle(
                  color: badge.unlocked
                      ? context.f3textSecondary
                      : context.f3textMuted,
                  fontSize: 12,
                ),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              badge.tier.name.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
