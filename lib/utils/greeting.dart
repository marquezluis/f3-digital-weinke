// lib/utils/greeting.dart
// Shared time-of-day greeting so Home and Settings speak with one voice.

import '../l10n/app_localizations.dart';

/// Localized time-of-day greeting. Pass the screen's AppLocalizations.
String greetingFor(AppLocalizations l10n, [DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 5) return l10n.greetingGloom;
  if (hour < 12) return l10n.greetingMorning;
  if (hour < 17) return l10n.greetingAfternoon;
  return l10n.greetingEvening;
}
