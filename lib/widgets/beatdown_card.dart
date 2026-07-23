// lib/widgets/beatdown_card.dart
// A fixed-size, shareable "story card" summarizing a completed beatdown —
// captured as a PNG by BeatdownCardPreviewScreen. Always rendered dark
// (F3Colors.background), independent of the app's light/dark setting, since
// this is an exported image meant to look the same wherever it lands.

import 'package:flutter/material.dart';
import '../models/workout_history.dart';
import '../theme/app_theme.dart';

class BeatdownCard extends StatelessWidget {
  final WorkoutHistory entry;
  static const double width = 1080;
  static const double height = 1350;

  const BeatdownCard({super.key, required this.entry});

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
          const SizedBox(height: 36),
          Text(
            entry.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: F3Colors.textPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.shortDate,
            style: const TextStyle(
              color: F3Colors.textSecondary,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),

          // ── Meta chips ──────────────────────────────────────────────────
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              if (entry.ao.isNotEmpty) _Chip(Icons.place_rounded, entry.ao),
              if (entry.q.isNotEmpty) _Chip(Icons.person_rounded, entry.q),
              _Chip(Icons.group_rounded, '${entry.totalCount} PAX'),
              if (entry.fngCount > 0)
                _Chip(Icons.new_label_rounded, '${entry.fngCount} FNG'),
              if (entry.eventTag != null)
                _Chip(Icons.local_fire_department_rounded,
                    entry.eventTag!.displayName),
            ],
          ),
          const SizedBox(height: 40),
          Container(height: 1, color: F3Colors.divider),
          const SizedBox(height: 32),

          // ── Blocks ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final block in entry.blocks) _BlockRow(block: block),
              ],
            ),
          ),

          Container(height: 1, color: F3Colors.divider),
          const SizedBox(height: 24),

          // ── Footer ──────────────────────────────────────────────────────
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: F3Colors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: F3Colors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: F3Colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  final HistoryBlock block;
  const _BlockRow({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forCategory(block.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${block.exerciseNames.join(', ')}'
                  '${block.rounds > 1 ? '  ·  ${block.rounds} rounds' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: F3Colors.textSecondary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
