// lib/utils/date_format.dart
// Shared, locale-aware date formatting — most screens independently
// reimplemented their own hardcoded, English-only `const months = [...]`
// array (activity_feed_screen, brotherhood_screen x3, heatmap_screen x2,
// settings_screen, home_screen, history_screen, weinke_exporter...), each
// with slightly different exact output. Beyond the duplication, the
// hardcoded arrays meant Spanish/French PAX still saw English month names
// on every one of those screens even with their language set correctly
// everywhere else. Uses `intl`'s locale data instead of a private array.

import 'package:intl/intl.dart';

/// "Aug" — a bare month abbreviation, e.g. for calendar/heatmap column
/// headers.
String monthAbbrev(DateTime d, String localeCode) =>
    DateFormat('MMM', localeCode).format(d);

/// "August" — the full, unabbreviated month name, e.g. for a calendar
/// header or a monthly recap card.
String fullMonth(DateTime d, String localeCode) =>
    DateFormat('MMMM', localeCode).format(d);

/// "Aug 12" — the most common short form used across cards/lists.
String shortMonthDay(DateTime d, String localeCode) =>
    DateFormat('MMM d', localeCode).format(d);

/// "Aug 12, 2026" — used wherever the year matters (backups, history).
String shortMonthDayYear(DateTime d, String localeCode) =>
    DateFormat('MMM d, y', localeCode).format(d);

/// "Wed Aug 12 2026" — the full weekday+date form.
String weekdayMonthDayYear(DateTime d, String localeCode) =>
    DateFormat('EEE MMM d y', localeCode).format(d);

/// "Wed Aug 12" — same as [weekdayMonthDayYear] without the year, for
/// contexts where the date is always understood to be this year (e.g. an
/// upcoming-beatdown preview).
String weekdayMonthDay(DateTime d, String localeCode) =>
    DateFormat('EEE MMM d', localeCode).format(d);

/// "Monday, Aug 02" — full weekday name, zero-padded day. Used for
/// generated preblast/backblast text, where the original hand-rolled
/// formatting always zero-padded the day.
String fullWeekdayMonthDay(DateTime d, String localeCode) =>
    DateFormat('EEEE, MMM dd', localeCode).format(d);
