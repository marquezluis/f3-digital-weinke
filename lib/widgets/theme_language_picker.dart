// lib/widgets/theme_language_picker.dart
// Shared theme + language pickers — used in Settings, and on the login
// gate (the very first screen a non-English speaker sees) so switching
// out of English doesn't require getting through an all-English sign-in
// flow first.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemePicker extends StatelessWidget {
  final ThemeMode current;
  final void Function(ThemeMode) onSelect;

  const ThemePicker({super.key, required this.current, required this.onSelect});

  static const _options = [
    (ThemeMode.dark,   Icons.dark_mode_rounded,       'Dark'),
    (ThemeMode.light,  Icons.light_mode_rounded,      'Light'),
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (mode, icon, label) = opt;
        final selected = mode == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? F3Colors.accent.withValues(alpha: 0.14) : context.f3card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? F3Colors.accent : context.f3divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon,
                      color: selected ? F3Colors.accent : context.f3textSecondary,
                      size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                        color: selected ? F3Colors.accent : context.f3textSecondary,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LanguagePicker extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;

  const LanguagePicker({super.key, required this.current, required this.onSelect});

  static const _options = [
    ('en', '🇺🇸', 'English'),
    ('es', '🇻🇪', 'Español'),
    ('fr', '🇫🇷', 'Français'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (code, flag, label) = opt;
        final selected = code == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(code),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? F3Colors.accent.withValues(alpha: 0.14)
                      : context.f3card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? F3Colors.accent : context.f3divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? F3Colors.accent
                          : context.f3textSecondary,
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
