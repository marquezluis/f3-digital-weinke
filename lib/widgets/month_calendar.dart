// lib/widgets/month_calendar.dart
// A lightweight month-grid calendar (no external package) — header with
// month navigation, weekday row, and a 6-row day grid. Each day cell can
// show an event-count dot; tapping a day is left to the caller.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonthCalendar extends StatelessWidget {
  final DateTime month; // any date within the displayed month
  final DateTime? selectedDate;
  final Map<DateTime, int> eventCounts; // keys normalized to y/m/d, no time
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.eventCounts,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Sunday-first grid: back up to the most recent Sunday on/before day 1.
    final gridStart = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday % 7));
    final today = normalize(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: onPreviousMonth,
                color: context.f3textSecondary,
              ),
              Text(
                '${_monthNames[month.month - 1]} ${month.year}',
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onNextMonth,
                color: context.f3textSecondary,
              ),
            ],
          ),
        ),
        Row(
          children: _weekdayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(l,
                          style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        ...List.generate(6, (row) {
          return Row(
            children: List.generate(7, (col) {
              final day = gridStart.add(Duration(days: row * 7 + col));
              final inMonth = day.month == month.month;
              final isToday = day == today;
              final isSelected =
                  selectedDate != null && day == normalize(selectedDate!);
              final count = eventCounts[day] ?? 0;
              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Material(
                      color: isSelected
                          ? F3Colors.accent
                          : isToday
                              ? F3Colors.accent.withValues(alpha: 0.14)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: inMonth ? () => onDaySelected(day) : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: !inMonth
                                    ? context.f3textMuted.withValues(alpha: 0.4)
                                    : isSelected
                                        ? Colors.white
                                        : context.f3textPrimary,
                              ),
                            ),
                            if (count > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : F3Colors.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
