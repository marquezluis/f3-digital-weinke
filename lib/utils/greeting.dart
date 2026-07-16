// lib/utils/greeting.dart
// Shared time-of-day greeting so Home and Settings speak with one voice.

String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 5) return 'Embrace the gloom';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
