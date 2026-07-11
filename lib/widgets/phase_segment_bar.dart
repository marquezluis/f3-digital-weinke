// lib/widgets/phase_segment_bar.dart
// Visual progress bar showing all 5 F3 bootcamp phases with current position.

import 'package:flutter/material.dart';
import '../models/timer_state.dart';
import '../theme/app_theme.dart';

class PhaseSegmentBar extends StatelessWidget {
  final TimerState state;
  final void Function(BootcampPhase)? onPhaseTap;
  const PhaseSegmentBar({super.key, required this.state, this.onPhaseTap});

  static const _phases = BootcampPhase.values;

  @override
  Widget build(BuildContext context) {
    // Seconds elapsed in the full session
    final elapsed =
        TimerState.totalBootcampSeconds - state.totalRemainingSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Segment blocks ────────────────────────────────────────────────
        Row(
          children: _phases.map((phase) {
            final phaseStart = _phaseStart(phase);
            final phaseEnd = phaseStart + phase.durationSeconds;
            final isCurrent = phase == state.currentPhase;
            final isDone = elapsed >= phaseEnd;

            double fillFraction;
            if (isDone) {
              fillFraction = 1.0;
            } else if (isCurrent) {
              final withinPhase = elapsed - phaseStart;
              fillFraction =
                  (withinPhase / phase.durationSeconds).clamp(0.0, 1.0);
            } else {
              fillFraction = 0.0;
            }

            return Expanded(
              flex: phase.durationMinutes,
              child: GestureDetector(
                onLongPress: onPhaseTap != null && !isCurrent
                    ? () => onPhaseTap!(phase)
                    : null,
                child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fill bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          // Track
                          Container(
                            height: 5,
                            color: phase.color.withValues(alpha: 0.2),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: fillFraction,
                            child: Container(
                              height: 5,
                              color: phase.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Phase label — only show when current or on wide enough flex
                    if (isCurrent || phase.durationMinutes >= 7)
                      Text(
                        phase.durationMinutes >= 10
                            ? phase.displayName
                            : '${phase.durationMinutes}m',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? phase.color : context.f3textMuted,
                          fontSize: 9,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static int _phaseStart(BootcampPhase phase) {
    int start = 0;
    for (final p in BootcampPhase.values) {
      if (p == phase) break;
      start += p.durationSeconds;
    }
    return start;
  }
}
