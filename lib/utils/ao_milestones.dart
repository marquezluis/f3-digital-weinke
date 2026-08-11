// lib/utils/ao_milestones.dart
// AO-specific loyalty milestones (e.g. "50th post at Agoge") — extracted
// out of save_session_sheet.dart's private State so the threshold logic
// and ordinal-suffix formatting are actually unit-testable.

const List<int> aoMilestones = [10, 25, 50, 100];

/// The milestone just crossed by going from [before] to [after] posts at an
/// AO, or null if [after] doesn't land exactly on one. A session save only
/// ever increments the count by 1, so "crossed" and "equals" are the same
/// check here, but this stays explicit in case that assumption ever
/// changes (e.g. a bulk-import path that jumps counts by more than one).
int? aoMilestoneCrossed(int before, int after) {
  if (after <= before) return null;
  return aoMilestones.contains(after) ? after : null;
}

/// "1st", "2nd", "3rd", "4th", ..., "11th", "12th", "13th", "21st", ...
String ordinalSuffix(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return 'th';
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
