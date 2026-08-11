// lib/widgets/achievement_card.dart
// A fixed-size, shareable "story card" for an unlocked achievement —
// captured as a PNG by AchievementCardPreviewScreen. Always rendered dark
// (F3Colors.background), independent of the app's light/dark setting, same
// as BeatdownCard — this is an exported image meant to look the same
// wherever it lands, not a themed in-app widget.

import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';

class AchievementCard extends StatelessWidget {
  final Achievement badge;
  final DateTime? earnedDate;
  static const double width = 1080;
  static const double height = 1080;

  const AchievementCard({super.key, required this.badge, this.earnedDate});

  Color get _tierColor => switch (badge.tier) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silver => const Color(0xFFC0C0C0),
        AchievementTier.gold => const Color(0xFFFFD700),
      };

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]} ${months[d.month - 1]} ${d.day} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(56),
      decoration: const BoxDecoration(color: F3Colors.background),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 10,
                height: 44,
                decoration: BoxDecoration(
                  color: F3Colors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'DIGITAL WEINKE',
                style: TextStyle(
                  color: F3Colors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // ── Badge ───────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tierColor.withValues(alpha: 0.12),
                      border: Border.all(color: _tierColor, width: 4),
                    ),
                    child: Text(badge.emoji, style: const TextStyle(fontSize: 120)),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _tierColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      badge.tier.name.toUpperCase(),
                      style: TextStyle(
                        color: _tierColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    badge.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: F3Colors.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: F3Colors.textSecondary,
                      fontSize: 26,
                    ),
                  ),
                  if (earnedDate != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'EARNED ${_formatDate(earnedDate!).toUpperCase()}',
                      style: const TextStyle(
                        color: F3Colors.textMuted,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────────
          Container(height: 1, color: F3Colors.divider),
          const SizedBox(height: 24),
          const Text(
            'F3 — FITNESS · FELLOWSHIP · FAITH',
            style: TextStyle(
              color: F3Colors.textMuted,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
