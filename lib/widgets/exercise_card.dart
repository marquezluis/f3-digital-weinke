// lib/widgets/exercise_card.dart
// Expandable exercise card with swap support. Big tap targets for gloved hands.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'category_chip.dart';
import 'intensity_badge.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final bool initiallyExpanded;
  final VoidCallback? onSwap;
  final VoidCallback? onDetail;
  final VoidCallback? onDuplicate;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.initiallyExpanded = false,
    this.onSwap,
    this.onDetail,
    this.onDuplicate,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _onLongPress(BuildContext context, SettingsService svc) {
    final ex = widget.exercise;
    final isBlacklisted = svc.isBlacklisted(ex.id);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.f3divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                ex.name,
                style: TextStyle(
                  color: context.f3textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.onDuplicate != null)
              ListTile(
                leading: Icon(Icons.copy_rounded,
                    color: context.f3textSecondary),
                title: Text('Duplicate in block',
                    style: TextStyle(color: context.f3textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDuplicate!();
                },
              ),
            ListTile(
              leading: Icon(
                isBlacklisted ? Icons.block_flipped : Icons.block,
                color: isBlacklisted ? F3Colors.accent : context.f3textSecondary,
              ),
              title: Text(
                isBlacklisted
                    ? 'Remove from Blacklist'
                    : 'Blacklist — exclude from generation',
                style: TextStyle(color: context.f3textPrimary),
              ),
              subtitle: isBlacklisted
                  ? null
                  : Text(
                      'This exercise will be skipped when generating plans.',
                      style: TextStyle(color: context.f3textMuted, fontSize: 12),
                    ),
              onTap: () {
                Navigator.pop(context);
                svc.toggleBlacklist(ex.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    isBlacklisted
                        ? '${ex.name} removed from blacklist'
                        : '${ex.name} blacklisted — won\'t appear in generated plans',
                  ),
                  duration: const Duration(seconds: 2),
                ));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final catColor = F3Colors.forCategory(ex.category.name);

    return Consumer<SettingsService>(
      builder: (context, svc, _) {
        final isFav = svc.isFavorited(ex.id);
        final isBlacklisted = svc.isBlacklisted(ex.id);

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: context.f3card,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (widget.onDetail != null) {
                  widget.onDetail!();
                } else {
                  setState(() => _expanded = !_expanded);
                }
              },
              onLongPress: () => _onLongPress(context, svc),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(
                      color: isBlacklisted
                          ? context.f3textMuted.withValues(alpha: 0.4)
                          : catColor,
                      width: 4,
                    ),
                    right: BorderSide(
                      color: isBlacklisted
                          ? context.f3textMuted.withValues(alpha: 0.2)
                          : _expanded
                              ? catColor.withValues(alpha: 0.3)
                              : context.f3divider,
                    ),
                    top: BorderSide(
                      color: isBlacklisted
                          ? context.f3textMuted.withValues(alpha: 0.2)
                          : _expanded
                              ? catColor.withValues(alpha: 0.3)
                              : context.f3divider,
                    ),
                    bottom: BorderSide(
                      color: isBlacklisted
                          ? context.f3textMuted.withValues(alpha: 0.2)
                          : _expanded
                              ? catColor.withValues(alpha: 0.3)
                              : context.f3divider,
                    ),
                  ),
                ),
                child: Opacity(
                  opacity: isBlacklisted ? 0.45 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: TextStyle(
                                      color: isBlacklisted
                                          ? context.f3textMuted
                                          : context.f3textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (ex.aliases.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'AKA: ${ex.aliases.join(', ')}',
                                      style: TextStyle(
                                        color: context.f3textMuted,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (isBlacklisted)
                                    Padding(
                                      padding: EdgeInsets.only(top: 3),
                                      child: Text(
                                        'BLACKLISTED',
                                        style: TextStyle(
                                          color: context.f3textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Favorite toggle
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                svc.toggleFavorite(ex.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? F3Colors.accent
                                      : context.f3textMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            CategoryChip(category: ex.category, small: true),
                            const SizedBox(width: 6),
                            IntensityBadge(intensity: ex.intensity),
                            const SizedBox(width: 6),
                            Icon(
                              _expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: context.f3textMuted,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),

                      // ── Expanded detail ───────────────────────────────────
                      if (_expanded) ...[
                        Divider(height: 1, color: context.f3divider),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ex.description.isNotEmpty)
                                Text(
                                  ex.description,
                                  style: TextStyle(
                                    color: context.f3textSecondary,
                                    fontSize: 14,
                                    height: 1.55,
                                  ),
                                ),
                              if (ex.equipment == Equipment.coupon) ...[
                                const SizedBox(height: 10),
                                const Row(children: [
                                  Icon(Icons.fitness_center_rounded,
                                      size: 14, color: F3Colors.catCoupon),
                                  SizedBox(width: 6),
                                  Text(
                                    'Requires a coupon (weighted implement)',
                                    style: TextStyle(
                                        color: F3Colors.catCoupon,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ]),
                              ],
                              if (widget.onSwap != null) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onSwap,
                                    icon: const Icon(Icons.swap_horiz_rounded,
                                        size: 18),
                                    label:
                                        const Text('SWAP THIS EXERCISE'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.touch_app_rounded,
                                      size: 12, color: context.f3textMuted),
                                  SizedBox(width: 4),
                                  Text(
                                    'Long-press for more options',
                                    style: TextStyle(
                                        color: context.f3textMuted,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
