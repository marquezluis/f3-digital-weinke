// lib/widgets/founding_quest_card.dart
// A guided "first week" checklist for brand-new PAX — three concrete,
// already-tracked milestones, no new state beyond first_launch_date (see
// SettingsService). Shows during days 1-7; once the window passes without
// finishing, it just stops appearing rather than nagging forever. Completing
// all three inside the window earns a one-time "Founding PAX" badge state.

import 'package:confetti/confetti.dart';
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

class FoundingQuestCard extends StatefulWidget {
  const FoundingQuestCard({super.key});

  @override
  State<FoundingQuestCard> createState() => _FoundingQuestCardState();
}

class _FoundingQuestCardState extends State<FoundingQuestCard> {
  late final ConfettiController _confettiCtrl;
  // Guards against scheduling the post-frame celebration more than once per
  // widget lifetime — SettingsService.foundingQuestCelebrated is the real
  // source of truth (persisted, so it survives across app restarts too),
  // but it flips asynchronously, and several frames can render in the gap
  // before that write lands.
  bool _celebrationScheduled = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

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

    // First time seeing all 3 steps done — celebrate exactly once. Not
    // "just built in the earned state" (e.g. reopening the app days later),
    // which reads foundingQuestCelebrated as already true and skips this.
    if (allDone && !settings.foundingQuestCelebrated && !_celebrationScheduled) {
      _celebrationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.read<SettingsService>().reducedMotion) {
          _confettiCtrl.play();
        }
        context.read<SettingsService>().markFoundingQuestCelebrated();
      });
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _buildCard(context, allDone, daysSince, doneCount, steps),
        ConfettiWidget(
          confettiController: _confettiCtrl,
          blastDirection: 1.5708, // pi/2, straight down
          numberOfParticles: 30,
          gravity: 0.25,
          emissionFrequency: 0.08,
          colors: const [F3Colors.accent, Colors.white, Colors.yellow],
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, bool allDone, int daysSince,
      int doneCount, List<_QuestStep> steps) {
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
