// lib/screens/achievements_screen.dart
// Displays achievement badges derived from local session history.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';
import '../models/custom_achievement.dart';
import '../services/achievement_service.dart';
import '../services/custom_achievement_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'achievement_card_preview_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: context.f3bg,
        actions: [
          IconButton(
            tooltip: 'Add custom achievement',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddCustomSheet(context),
          ),
        ],
      ),
      body: Consumer2<HistoryService, CustomAchievementService>(
        builder: (context, svc, customSvc, _) {
          final badges = [
            ...AchievementService.compute(svc.all),
            ...AchievementService.computeCustom(svc.all, customSvc.all),
          ];
          // Only covers built-in badges (custom ones have no reconstructable
          // history-based unlock date) — the share card handles a missing
          // date fine, it just omits the "EARNED ..." line.
          final unlockDates = AchievementService.unlockDates(svc.all);
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
              // Site-Q custom achievements are a real differentiator that
              // otherwise only surfaces via a small AppBar icon — nothing
              // ever actively prompts a Q to go create one.
              if (customSvc.all.isEmpty) ...[
                _CustomAchievementNudge(
                    onTap: () => _showAddCustomSheet(context)),
                const SizedBox(height: 16),
              ],
              ...badges.map((badge) => _BadgeTile(
                    badge: badge,
                    earnedDate: unlockDates[badge.id],
                    onDelete: badge.isCustom
                        ? () => _confirmRemoveCustomAchievement(
                            context, customSvc, badge)
                        : null,
                  )),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmRemoveCustomAchievement(
    BuildContext context, CustomAchievementService customSvc, Achievement badge) async {
  HapticFeedback.mediumImpact();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.f3card,
      title: Text('Remove achievement?',
          style: TextStyle(color: dialogContext.f3textPrimary)),
      content: Text(badge.title,
          style: TextStyle(color: dialogContext.f3textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  customSvc.remove(badge.id);
}

void _showAddCustomSheet(BuildContext context) {
  final customSvc = context.read<CustomAchievementService>();
  final titleCtrl = TextEditingController();
  final aoCtrl = TextEditingController();
  final valueCtrl = TextEditingController(text: '5');
  var thresholdType = CustomAchievementThreshold.totalSessions;
  // Real AO names the PAX has actually logged — a free-text mismatch here
  // (e.g. "Agoge" vs. "The Agoge") means the threshold silently never fires,
  // with no error shown anywhere, so offer the known-good set instead of a
  // blank field whenever there's history to draw from.
  final knownAos = context
      .read<HistoryService>()
      .all
      .map((h) => h.ao.trim())
      .where((ao) => ao.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  var selectedAo = knownAos.isNotEmpty ? knownAos.first : null;
  if (selectedAo != null) aoCtrl.text = selectedAo;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.f3card,
    builder: (sheetContext) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Custom Achievement',
                style: TextStyle(
                    color: ctx.f3textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomAchievementThreshold>(
              initialValue: thresholdType,
              decoration: const InputDecoration(labelText: 'Based on'),
              items: CustomAchievementThreshold.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setSheetState(() => thresholdType = v);
              },
            ),
            if (thresholdType == CustomAchievementThreshold.sessionsAtAo) ...[
              const SizedBox(height: 12),
              if (knownAos.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedAo,
                  decoration: const InputDecoration(labelText: 'AO name'),
                  items: knownAos
                      .map((ao) => DropdownMenuItem(value: ao, child: Text(ao)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setSheetState(() {
                      selectedAo = v;
                      aoCtrl.text = v;
                    });
                  },
                )
              else
                TextField(
                  controller: aoCtrl,
                  decoration: const InputDecoration(labelText: 'AO name'),
                ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target count'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final value = int.tryParse(valueCtrl.text.trim()) ?? 0;
                  if (title.isEmpty || value <= 0) return;
                  await customSvc.add(
                    title: title,
                    thresholdType: thresholdType,
                    thresholdValue: value,
                    aoFilter:
                        thresholdType == CustomAchievementThreshold.sessionsAtAo
                            ? aoCtrl.text
                            : null,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  ).then((_) {
    titleCtrl.dispose();
    aoCtrl.dispose();
    valueCtrl.dispose();
  });
}

class _CustomAchievementNudge extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomAchievementNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: F3Colors.accent.withValues(alpha: 0.3),
                style: BorderStyle.solid),
          ),
          child: Row(children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: F3Colors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create a custom achievement',
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('Site-Q perk — set your own goal for your AO',
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
          ]),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement badge;
  final DateTime? earnedDate;
  final VoidCallback? onDelete;
  const _BadgeTile({required this.badge, this.earnedDate, this.onDelete});

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
              // A locked badge only ever told you the finish line, never
              // how close you actually were — that's the whole gap between
              // "surprise reward" and "active pull".
              if (!badge.unlocked &&
                  badge.currentProgress != null &&
                  badge.targetProgress != null &&
                  badge.targetProgress! > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: badge.currentProgress! / badge.targetProgress!,
                    minHeight: 4,
                    backgroundColor: context.f3divider,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${badge.currentProgress}/${badge.targetProgress}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
          if (badge.unlocked)
            IconButton(
              tooltip: 'Share as image',
              icon: Icon(Icons.ios_share_rounded, size: 18, color: color),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AchievementCardPreviewScreen(
                    badge: badge,
                    earnedDate: earnedDate,
                  ),
                ),
              ),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Remove custom achievement',
              icon: Icon(Icons.close_rounded,
                  size: 18, color: context.f3textMuted),
              onPressed: onDelete,
            ),
        ]),
      ),
    );
  }
}
