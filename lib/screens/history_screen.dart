// lib/screens/history_screen.dart
// Local workout history — lists saved beatdowns, tap to view backblast.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_history.dart';
import '../services/history_service.dart';
import '../services/backblast_formatter.dart';
import '../services/settings_service.dart';
import '../services/slack_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: context.f3bg,
        actions: [
          Consumer<HistoryService>(
            builder: (context, svc, _) {
              if (svc.all.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Clear all history',
                onPressed: () => _confirmClear(context, svc),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryService>(
        builder: (context, svc, _) {
          if (svc.all.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: svc.all.length,
            itemBuilder: (context, i) {
              final entry = svc.all[i];
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text('DELETE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  HapticFeedback.mediumImpact();
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: context.f3card,
                      title: Text('Delete Session',
                          style: TextStyle(color: context.f3textPrimary)),
                      content: Text(
                        'Remove "${entry.title}"?',
                        style:
                            TextStyle(color: context.f3textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            minimumSize: const Size(80, 40),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  svc.delete(entry.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${entry.title} deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: _HistoryCard(entry: entry),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Clear History',
            style: TextStyle(color: context.f3textPrimary)),
        content: Text(
          'Delete all saved sessions? This cannot be undone.',
          style: TextStyle(color: context.f3textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: F3Colors.accent,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              Navigator.pop(context);
              svc.clear();
            },
            child:
                const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                color: F3Colors.accent.withValues(alpha: 0.5), size: 72),
            const SizedBox(height: 20),
            Text(
              'NO BEATDOWNS YET',
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a Weinke, run it, then tap\n"Save Session" to log your beatdown here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History list card ────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final WorkoutHistory entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: context.f3card,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BackblastScreen(entry: entry),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.f3divider),
            ),
            child: Row(
              children: [
                // ── Date badge ────────────────────────────────────────
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _month(entry.date),
                        style: const TextStyle(
                            color: F3Colors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1),
                      ),
                      Text(
                        '${entry.date.day}',
                        style: TextStyle(
                            color: context.f3textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1),
                      ),
                      Text(
                        '${entry.date.year}',
                        style: TextStyle(
                            color: context.f3textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // ── Info ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.f3textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      if (entry.ao.isNotEmpty)
                        Text(entry.ao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.f3textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(children: [
                        if (entry.q.isNotEmpty) ...[
                          Icon(Icons.person_rounded,
                              size: 13, color: context.f3textMuted),
                          const SizedBox(width: 4),
                          Text(entry.q,
                              style: TextStyle(
                                  color: context.f3textMuted, fontSize: 12)),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.group_rounded,
                            size: 13, color: context.f3textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.totalCount}',
                          style: TextStyle(
                              color: context.f3textMuted, fontSize: 12),
                        ),
                        if (entry.fngCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  F3Colors.phaseWarmup.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FNG ×${entry.fngCount}',
                              style: const TextStyle(
                                  color: F3Colors.phaseWarmup,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        // Rating badge
                        if (entry.rating != 0) ...[
                          const SizedBox(width: 8),
                          Icon(
                            entry.rating == 1
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_down_rounded,
                            size: 13,
                            color: entry.rating == 1
                                ? F3Colors.phaseThang
                                : context.f3textMuted,
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: context.f3textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _month(DateTime dt) {
    const months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC',
    ];
    return months[dt.month - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backblast detail screen
// ─────────────────────────────────────────────────────────────────────────────

class BackblastScreen extends StatefulWidget {
  final WorkoutHistory entry;
  const BackblastScreen({super.key, required this.entry});

  @override
  State<BackblastScreen> createState() => _BackblastScreenState();
}

class _BackblastScreenState extends State<BackblastScreen> {
  late String _backblast;
  bool _copied = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _backblast = BackblastFormatter.format(widget.entry);
  }

  Future<void> _postToSlack(WorkoutHistory entry) async {
    final webhookUrl =
        context.read<SettingsService>().slackWebhookUrl;
    if (webhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No Slack webhook configured. Add one in Settings → Slack Integration.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _posting = true);
    final error = await SlackService.postBackblast(webhookUrl, entry);
    if (!mounted) return;
    setState(() => _posting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null
            ? 'Posted to Slack!'
            : 'Slack error: $error'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _backblast));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backblast copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    HapticFeedback.lightImpact();
    await Share.share(_backblast, subject: widget.entry.title);
  }

  void _setRating(int rating) {
    final updated = widget.entry.copyWith(
      rating: widget.entry.rating == rating ? 0 : rating,
    );
    context.read<HistoryService>().update(updated);
    HapticFeedback.lightImpact();
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Delete Session',
            style: TextStyle(color: context.f3textPrimary)),
        content: Text(
          'Remove this beatdown from history?',
          style: TextStyle(color: context.f3textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: F3Colors.accent,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              context.read<HistoryService>().delete(widget.entry.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, svc, _) {
        // Always read live entry so rating updates reflect immediately.
        final entry = svc.all.firstWhere(
          (e) => e.id == widget.entry.id,
          orElse: () => widget.entry,
        );

        return Scaffold(
          backgroundColor: context.f3bg,
          appBar: AppBar(
            title:
                Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: context.f3bg,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share backblast',
                onPressed: _share,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded),
                tooltip: 'Delete session',
                onPressed: () => _delete(context),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // ── Session meta card ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(child: _MetaCard(entry: entry)),
              ),

              // ── Rate this session ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _RatingRow(
                    rating: entry.rating,
                    onRate: _setRating,
                  ),
                ),
              ),

              // ── Backblast header ──────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'BACKBLAST DRAFT',
                    style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Tap copy or share to send via Slack or email.',
                    style:
                        TextStyle(color: context.f3textSecondary, fontSize: 13),
                  ),
                ),
              ),

              // ── Backblast text ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.f3card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.f3divider),
                    ),
                    child: SelectableText(
                      _backblast,
                      style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 13,
                        height: 1.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),

              // ── Action buttons ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _share,
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('SHARE'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _copy,
                                icon: Icon(_copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded),
                                label: Text(_copied
                                    ? 'COPIED!'
                                    : 'COPY TO CLIPBOARD'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Consumer<SettingsService>(
                        builder: (_, svc, __) {
                          if (svc.slackWebhookUrl.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _posting
                                  ? null
                                  : () => _postToSlack(entry),
                              icon: _posting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                  _posting ? 'POSTING…' : 'POST TO SLACK'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4A154B),
                                side: const BorderSide(
                                    color: Color(0xFF4A154B)),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Rating row ───────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final int rating;
  final void Function(int) onRate;

  const _RatingRow({required this.rating, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          Text(
            'RATE THIS SESSION',
            style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _RatingButton(
            icon: Icons.thumb_up_rounded,
            active: rating == 1,
            activeColor: F3Colors.phaseThang,
            onTap: () => onRate(1),
          ),
          const SizedBox(width: 8),
          _RatingButton(
            icon: Icons.thumb_down_rounded,
            active: rating == -1,
            activeColor: context.f3textMuted,
            onTap: () => onRate(-1),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _RatingButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : context.f3elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : context.f3divider,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Icon(icon,
            color: active ? activeColor : context.f3textMuted, size: 20),
      ),
    );
  }
}

// ─── Meta card ────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final WorkoutHistory entry;
  const _MetaCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: F3Colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(Icons.calendar_today_rounded, 'Date', entry.shortDate),
          if (entry.ao.isNotEmpty) _Row(Icons.place_rounded, 'AO', entry.ao),
          if (entry.q.isNotEmpty) _Row(Icons.person_rounded, 'Q', entry.q),
          if (entry.pax.isNotEmpty)
            _Row(Icons.group_rounded, 'PAX', entry.paxDisplay),
          _Row(
              Icons.group_add_rounded,
              'Count',
              '${entry.totalCount}'
                  '${entry.fngCount > 0 ? " (${entry.fngCount} FNG)" : ""}'),
          if (entry.notes.isNotEmpty)
            _Row(Icons.notes_rounded, 'Notes', entry.notes),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: F3Colors.accent),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(label,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(color: context.f3textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
