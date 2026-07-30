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
    final currentIdx = _phases.indexOf(state.currentPhase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Segment blocks ────────────────────────────────────────────────
        Row(
          children: _phases.map((phase) {
            final idx = _phases.indexOf(phase);
            final isCurrent = idx == currentIdx;
            // Phases before the current one are simply done, phases after
            // haven't started — only the current phase's fraction needs the
            // real (possibly extended/custom-Thang) duration, which is why
            // this reads state.phaseProgress rather than re-deriving
            // boundaries from the phases' default enum durations (that
            // silently disagreed with the actual timer once a plan's Thang
            // block, or an extension, differed from the 50-minute default).
            double fillFraction;
            if (state.isFinished || idx < currentIdx) {
              fillFraction = 1.0;
            } else if (isCurrent) {
              fillFraction = state.phaseProgress.clamp(0.0, 1.0);
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
}
