// lib/screens/heatmap_screen.dart
// Activity heatmap calendar — shows workout frequency for the past 52 weeks.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Activity Heatmap'),
        backgroundColor: context.f3bg,
      ),
      body: Consumer<HistoryService>(
        builder: (context, svc, _) {
          return _HeatmapView(history: svc.all);
        },
      ),
    );
  }
}

class _HeatmapView extends StatelessWidget {
  final List history;

  const _HeatmapView({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build a map of date → count for the last 52 weeks (364 days).
    final counts = <String, int>{};
    for (final item in history) {
      final d = (item as dynamic).date as DateTime;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // The grid starts from 52 weeks ago (Monday), ends today.
    final gridStart = _mostRecentMonday(now.subtract(const Duration(days: 364)));
    final totalDays = now.difference(gridStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final months = <String>[];
    final monthCols = <int>[];
    String? lastMonth;
    for (int col = 0; col < totalWeeks; col++) {
      final weekStart = gridStart.add(Duration(days: col * 7));
      final monthLabel = _monthLabel(weekStart);
      if (monthLabel != lastMonth) {
        months.add(monthLabel);
        monthCols.add(col);
        lastMonth = monthLabel;
      }
    }

    final totalSessions = history.length;
    final sessionsThisYear = history.where((h) {
      final d = (h as dynamic).date as DateTime;
      return d.year == now.year;
    }).length;
    final activeDays = counts.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stats
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(children: [
            _StatCell('$totalSessions', 'All Time', F3Colors.accent),
            _StatCell('$sessionsThisYear', 'This Year', F3Colors.phaseThang),
            _StatCell('$activeDays', 'Active Days', F3Colors.catBodyweight),
          ]),
        ),
        const SizedBox(height: 20),
        Text(
          'PAST 52 WEEKS',
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(children: [
          Text('Less', style: TextStyle(color: context.f3textMuted, fontSize: 10)),
          const SizedBox(width: 6),
          ...List.generate(5, (i) => Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: _heatColor(context, i, 0, 4),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
          const SizedBox(width: 6),
          Text('More', style: TextStyle(color: context.f3textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        // Heatmap grid — scrollable horizontally
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels
              SizedBox(
                height: 16,
                child: Stack(
                  children: monthCols.asMap().entries.map((entry) {
                    final col = entry.value;
                    return Positioned(
                      left: col * 14.0,
                      child: Text(
                        months[entry.key],
                        style: TextStyle(
                            color: context.f3textMuted, fontSize: 9),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(totalWeeks, (col) {
                  return Column(
                    children: List.generate(7, (row) {
                      final day = gridStart.add(Duration(days: col * 7 + row));
                      if (day.isAfter(now)) {
                        return const SizedBox(width: 12, height: 12,
                            child: Padding(padding: EdgeInsets.all(1)));
                      }
                      final key =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final count = counts[key] ?? 0;
                      final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);
                      return Tooltip(
                        message: count > 0
                            ? '$count session${count == 1 ? '' : 's'} · ${_fullDate(day)}'
                            : _fullDate(day),
                        child: Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: _heatColor(context, count, 0, maxCount),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Day-of-week labels
              Column(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) =>
                  SizedBox(
                    height: 14,
                    child: Text(d,
                        style: TextStyle(
                            color: context.f3textMuted, fontSize: 9)),
                  )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Monthly breakdown bar chart
        Text(
          'SESSIONS BY MONTH',
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        _MonthlyBarChart(history: history, now: now),
      ],
    );
  }

  Color _heatColor(BuildContext context, int count, int min, int max, {Color? zeroColor}) {
    if (count == 0) return zeroColor ?? context.f3card;
    if (max == 0) return F3Colors.accent.withValues(alpha: 0.3);
    final ratio = (count - min) / (max - min).clamp(1, 999);
    return Color.lerp(
      F3Colors.accent.withValues(alpha: 0.2),
      F3Colors.accent,
      ratio,
    )!;
  }

  DateTime _mostRecentMonday(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }

  String _fullDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(color: context.f3textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List history;
  final DateTime now;
  const _MonthlyBarChart({required this.history, required this.now});

  @override
  Widget build(BuildContext context) {
    // Last 12 months
    final months = <String, int>{};
    for (int i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      months[key] = 0;
    }
    for (final item in history) {
      final d = (item as dynamic).date as DateTime;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (months.containsKey(key)) {
        months[key] = (months[key] ?? 0) + 1;
      }
    }

    final maxVal = months.values.fold(0, (a, b) => a > b ? a : b);
    final entries = months.entries.toList();
    const monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((entry) {
          final count = entry.value;
          final monthNum = int.tryParse(entry.key.split('-')[1]) ?? 1;
          final heightRatio = maxVal == 0 ? 0.0 : count / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text('$count',
                        style: const TextStyle(
                            color: F3Colors.accent, fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: heightRatio == 0 ? 0.04 : heightRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: count > 0
                              ? F3Colors.accent
                              : context.f3divider,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthNames[monthNum],
                    style: TextStyle(
                        color: context.f3textMuted, fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
