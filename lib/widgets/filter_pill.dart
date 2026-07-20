// lib/widgets/filter_pill.dart
// A small rounded filter chip used for AO/type/date/state/weekday pickers —
// shared by Schedule and Browse AOs so both filter bars look identical.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const FilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? F3Colors.accent.withValues(alpha: 0.12) : context.f3card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? F3Colors.accent : context.f3divider),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: TextStyle(
                    color: active ? F3Colors.accent : context.f3textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 4),
            if (active && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 18, color: F3Colors.accent),
              )
            else
              Icon(Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: active ? F3Colors.accent : context.f3textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Bottom-sheet single-choice picker with an "All" option at the top —
/// returns the chosen value, `''` for "All" (caller maps that to null), or
/// null if the sheet was dismissed without a choice.
Future<String?> showFilterPickerSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String? current,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: context.f3card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(title,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          ListTile(
            title: Text('All', style: TextStyle(color: context.f3textPrimary)),
            trailing: current == null
                ? const Icon(Icons.check_rounded, color: F3Colors.accent)
                : null,
            onTap: () => Navigator.pop(sheetContext, ''),
          ),
          for (final option in options)
            ListTile(
              title:
                  Text(option, style: TextStyle(color: context.f3textPrimary)),
              trailing: current == option
                  ? const Icon(Icons.check_rounded, color: F3Colors.accent)
                  : null,
              onTap: () => Navigator.pop(sheetContext, option),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
