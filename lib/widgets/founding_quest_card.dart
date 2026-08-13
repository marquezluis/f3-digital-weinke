// lib/widgets/founding_quest_card.dart
// A guided "first week" checklist for brand-new PAX — three concrete,
// already-tracked milestones, no new state beyond first_launch_date (see
// SettingsService). Shows during days 1-7; once the window passes without
// finishing, it just stops appearing rather than nagging forever. Completing
// all three inside the window earns a one-time "Founding PAX" badge state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_profile_service.dart';
import '../services/history_service.dart';
import '../services/region_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class _QuestStep {
  final String label;
  final bool done;
  const _QuestStep(this.label, this.done);
}

class FoundingQuestCard extends StatelessWidget {
  const FoundingQuestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final firstLaunch = settings.firstLaunchDate;
    if (firstLaunch == null) return const SizedBox.shrink();

    final daysSince = DateTime.now().difference(firstLaunch).inDays;
    final profile = context.watch<AppProfileService>();
    final history = context.watch<HistoryService>();
    final region = context.watch<RegionService>();

    final steps = [
      _QuestStep('Set your home AO and region',
          profile.homeAo.isNotEmpty || profile.region.isNotEmpty),
      _QuestStep('Log your first beatdown', history.all.isNotEmpty),
      _QuestStep('Add someone to your Brotherhood',
          region.aos.isNotEmpty || region.pax.isNotEmpty),
    ];
    final doneCount = steps.where((s) => s.done).length;
    final allDone = doneCount == steps.length;

    // Window closed without finishing — stop showing, don't nag forever.
    if (!allDone && daysSince > 7) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone
            ? F3Colors.phaseCOT.withValues(alpha: 0.10)
            : context.f3card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allDone
              ? F3Colors.phaseCOT.withValues(alpha: 0.35)
              : context.f3divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              allDone ? Icons.military_tech_rounded : Icons.flag_rounded,
              color: allDone ? F3Colors.phaseCOT : F3Colors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                allDone
                    ? 'FOUNDING PAX — EARNED'
                    : 'YOUR FIRST WEEK (${7 - daysSince} day${7 - daysSince == 1 ? '' : 's'} left)',
                style: TextStyle(
                  color: allDone ? F3Colors.phaseCOT : context.f3textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text('$doneCount/${steps.length}',
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(
                    s.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: s.done ? F3Colors.phaseCOT : context.f3textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.label,
                        style: TextStyle(
                          color: s.done
                              ? context.f3textSecondary
                              : context.f3textPrimary,
                          fontSize: 13,
                          decoration:
                              s.done ? TextDecoration.lineThrough : null,
                        )),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}
