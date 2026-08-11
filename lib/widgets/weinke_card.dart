// lib/widgets/weinke_card.dart
// A fixed-size, shareable "story card" for a planned Weinke — the preblast
// counterpart to BeatdownCard (which is for a completed session). Captured
// as a PNG by WeinkeCardPreviewScreen. Always rendered dark
// (F3Colors.background), independent of the app's light/dark setting.

import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../theme/app_theme.dart';

class WeinkeCard extends StatelessWidget {
  final WorkoutPlan plan;
  final String ao;
  final String time;
  final String qName;
  static const double width = 1080;
  static const double height = 1350;

  const WeinkeCard({
    super.key,
    required this.plan,
    required this.ao,
    required this.time,
    required this.qName,
  });

  String get _dayLabel {
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = plan.generatedAt;
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final aoLabel = ao.trim().isEmpty ? 'TBD' : ao.trim();
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: F3Colors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PREBLAST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'DIGITAL WEINKE',
                style: TextStyle(
                  color: F3Colors.textMuted,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            aoLabel.toUpperCase(),
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
            '$_dayLabel · ${time.trim().isEmpty ? "0530" : time.trim()}',
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
              if (qName.trim().isNotEmpty) _Chip(Icons.person_rounded, qName.trim()),
              _Chip(Icons.timer_rounded, '${plan.refinedTotalMinutes} MIN'),
              _Chip(Icons.fitness_center_rounded, '${plan.blocks.length} BLOCKS'),
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
                for (final block in plan.blocks) _BlockRow(block: block),
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
  final WorkoutBlock block;
  const _BlockRow({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forCategory(block.category.name);
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
                  '${block.exercises.map((e) => e.name).join(', ')}'
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
