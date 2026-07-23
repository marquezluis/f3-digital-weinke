// lib/screens/schedule_screen.dart
// Tier 1 of the "unified app" loop: the weekly schedule of upcoming beatdowns
// for the signed-in PAX's region, with HC (sign up), take-Q, and preblast
// actions. Reads/writes the F3 Nation API; requires F3 login for the write
// actions (self-signup uses the user's own token, no editor role needed).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_models.dart';
import '../models/f3_api_models.dart';
import '../models/workout_plan.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/notification_service.dart';
import '../services/weinke_exporter.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_pill.dart';
import '../widgets/month_calendar.dart';
import 'workout_screen.dart';

/// "Involvement" filter — whether the signed-in PAX is HC'd, Q'ing, or
/// either. Public (not `_`-prefixed) so Home's upcoming-beatdowns card can
/// reference it when pre-setting the filter via the shared ValueNotifier.
enum MineFilter { hc, q, hcOrQ }

class ScheduleScreen extends StatefulWidget {
  // Pre-sets the AO filter and jumps straight to the filtered agenda —
  // used by Browse AOs' "See beatdowns" button.
  final String? initialAoFilter;

  const ScheduleScreen({super.key, this.initialAoFilter});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = true;
  List<F3EventInstance> _events = []; // today + next 7 days, for the agenda
  // The same fetch as _events but kept un-trimmed (the API already returns
  // up to 200 upcoming events with no end-date filter) — lets a filtered
  // view show weeks out instead of only what fits in the next 7 days.
  List<F3EventInstance> _allUpcoming = [];

  String? _aoFilter;
  String? _typeFilter;
  MineFilter? _mineFilter;

  @override
  void initState() {
    _aoFilter = widget.initialAoFilter;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadCalendarMonth();
    });
    // Schedule lives in ShellScreen's IndexedStack (kept alive across tab
    // switches, initState never refires) — Home's "see all" link sets this
    // notifier instead of a constructor param so it still reaches an
    // already-live Schedule instance.
    context
        .read<ValueNotifier<MineFilter?>>()
        .addListener(_onMineFilterRequested);
  }

  @override
  void dispose() {
    context
        .read<ValueNotifier<MineFilter?>>()
        .removeListener(_onMineFilterRequested);
    super.dispose();
  }

  void _onMineFilterRequested() {
    final notifier = context.read<ValueNotifier<MineFilter?>>();
    final requested = notifier.value;
    if (requested == null) return;
    setState(() => _mineFilter = requested);
    notifier.value =
        null; // consume once — don't re-apply on a later tab switch
  }

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // Null = default agenda (next 7 days); set once a calendar date is tapped.
  DateTime? _selectedDay;
  bool _loadingCalendar = false;
  List<F3EventInstance> _calendarEvents = []; // whichever month is displayed

  /// "Today" action: jumps the calendar back to the current month and clears
  /// any selected date, returning to the default 7-day agenda.
  void _resetToToday() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final monthChanged = currentMonth != _calendarMonth;
    setState(() {
      _calendarMonth = currentMonth;
      _selectedDay = null;
    });
    if (monthChanged) _loadCalendarMonth();
  }

  /// Fetches everything from the 1st of [_calendarMonth] through a generous
  /// forward window, then keeps only that month client-side — the API has
  /// no explicit end-date filter, so over-fetch-and-trim is the same
  /// pattern already used for the list view's 7-day window. Past months
  /// work too (deliberately, so a backblast can still be added for a day
  /// that already happened).
  Future<void> _loadCalendarMonth() async {
    setState(() => _loadingCalendar = true);
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final token = await auth.getF3AccessToken();
    final userId = int.tryParse(profile.authUserId);
    final events = await api.getUpcomingBeatdowns(
      userAccessToken: token,
      userId: userId,
      from: DateTime(_calendarMonth.year, _calendarMonth.month, 1),
      limit: 300,
    );
    if (!mounted) return;
    final monthEnd = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
    final windowed = events.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.isBefore(monthEnd);
    }).toList();
    setState(() {
      _calendarEvents = windowed;
      _loadingCalendar = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _calendarMonth =
          DateTime(_calendarMonth.year, _calendarMonth.month + delta);
      _selectedDay = null;
    });
    _loadCalendarMonth();
  }

  Map<DateTime, int> get _calendarEventCounts {
    final counts = <DateTime, int>{};
    for (final e in _calendarEvents) {
      final d = MonthCalendar.normalize(e.date);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return counts;
  }

  List<F3EventInstance> get _selectedDayEvents {
    final day = _selectedDay;
    if (day == null) return [];
    final target = MonthCalendar.normalize(day);
    return _calendarEvents
        .where((e) => MonthCalendar.normalize(e.date) == target)
        .toList();
  }

  /// Tapping the already-selected date deselects it (back to the default
  /// 7-day agenda) — the same gesture that opened it closes it. Deselecting
  /// means "back to today," so it also snaps the calendar month back (via
  /// _resetToToday) — otherwise the agenda shows the current week while the
  /// grid above is left stranded on whatever month you'd navigated to.
  void _selectDay(DateTime day) {
    final normalized = MonthCalendar.normalize(day);
    final isDeselecting = _selectedDay != null &&
        MonthCalendar.normalize(_selectedDay!) == normalized;
    if (isDeselecting) {
      _resetToToday();
      return;
    }
    setState(() => _selectedDay = normalized);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final token = await auth.getF3AccessToken();
    final userId = int.tryParse(profile.authUserId);
    final events =
        await api.getUpcomingBeatdowns(userAccessToken: token, userId: userId);
    if (!mounted) return;
    // Recurring series now generate instances a year+ out — Schedule only
    // shows today through the next 7 days. Today's events stay even once
    // their time has passed (someone may still need to HC/take-Q after the
    // fact), so this is a date-only cutoff, not a time-of-day one.
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final windowEnd = todayStart.add(const Duration(days: 8));
    final windowed = events.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(todayStart) && d.isBefore(windowEnd);
    }).toList();
    // A filtered view (AO/type/mine) can otherwise show whatever the
    // ~200-event over-fetch happens to reach — for a sparse AO that could be
    // years out. Cap the filtered source to a sane forward window; the plain
    // 7-day agenda above is unaffected since it reads _events, not this.
    final filteredCap = todayStart.add(const Duration(days: 90));
    final capped = events.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.isBefore(filteredCap);
    }).toList();
    setState(() {
      _events = windowed;
      _allUpcoming = capped;
      _loading = false;
    });
  }

  List<String> get _aoOptions => _allUpcoming
      .map((e) => e.orgName)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get _typeOptions => _allUpcoming
      .map((e) => e.eventTypeName)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  bool _matchesFilters(F3EventInstance e) {
    if (_aoFilter != null && e.orgName != _aoFilter) return false;
    if (_typeFilter != null && e.eventTypeName != _typeFilter) return false;
    switch (_mineFilter) {
      case null:
        break;
      case MineFilter.hc:
        if (!e.userAttending) return false;
      case MineFilter.q:
        if (!e.userIsQ) return false;
      case MineFilter.hcOrQ:
        if (!e.userAttending && !e.userIsQ) return false;
    }
    return true;
  }

  List<F3EventInstance> get _filteredEvents =>
      _events.where(_matchesFilters).toList();

  // Same filter, applied to the un-trimmed fetch — used once a filter is
  // active, so the result isn't artificially capped to the next 7 days.
  List<F3EventInstance> get _filteredUpcoming =>
      _allUpcoming.where(_matchesFilters).toList();

  bool get _hasActiveFilters =>
      _aoFilter != null || _typeFilter != null || _mineFilter != null;

  Future<void> _pickFromList(
      {required String title,
      required List<String> options,
      required String? current,
      required ValueChanged<String?> onPicked}) async {
    final picked = await showFilterPickerSheet(context,
        title: title, options: options, current: current);
    if (picked == null) return; // dismissed without a choice
    onPicked(picked.isEmpty ? null : picked);
  }

  Future<void> _openEvent(F3EventInstance event) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.f3card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventDetailSheet(event: event),
    );
    _load(); // refresh counts after any action
    _loadCalendarMonth();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<F3ApiService>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(l10n.scheduleTitle),
        backgroundColor: context.f3bg,
        actions: [
          IconButton(
            tooltip: l10n.scheduleJumpToday,
            icon: const Icon(Icons.today_rounded),
            onPressed: _resetToToday,
          ),
        ],
      ),
      body: !api.isConfigured
          ? _Empty(
              icon: Icons.cloud_off_rounded,
              title: l10n.scheduleApiNotConfiguredTitle,
              subtitle: l10n.scheduleApiNotConfiguredSub)
          : RefreshIndicator(
              onRefresh: () => Future.wait([_load(), _loadCalendarMonth()]),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                children: [
                  MonthCalendar(
                    month: _calendarMonth,
                    selectedDate: _selectedDay,
                    eventCounts: _calendarEventCounts,
                    onDaySelected: _selectDay,
                    onPreviousMonth: () => _changeMonth(-1),
                    onNextMonth: () => _changeMonth(1),
                  ),
                  if (_loadingCalendar)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    ),
                  const Divider(height: 32, thickness: 1),
                  if (_selectedDay != null)
                    _buildSelectedDaySection(context)
                  else if (_hasActiveFilters)
                    _buildFilteredAgenda(context)
                  else
                    _buildWeekAgenda(context),
                ],
              ),
            ),
    );
  }

  /// Default state (no date tapped): the next 7 days, one section each,
  /// shown whether or not that specific day has anything scheduled.
  Widget _buildWeekAgenda(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
          child: Row(children: [
            const Icon(Icons.view_agenda_rounded,
                size: 13, color: F3Colors.accent),
            const SizedBox(width: 6),
            Text(l10n.scheduleNext7Days,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(
            l10n.scheduleTapDateHint,
            style: TextStyle(color: context.f3textMuted, fontSize: 12),
          ),
        ),
        if (_events.isNotEmpty) _buildFilterBar(context),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...List.generate(7, (i) {
            final day = todayStart.add(Duration(days: i));
            final dayEvents = _filteredEvents
                .where((e) =>
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day)
                .toList();
            final isLast = i == 6;
            // Empty days collapse to a single muted row — writing out a
            // full "Nothing scheduled" block for most of a sparse week
            // was the clutter.
            final block = dayEvents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      SizedBox(
                        width: 90,
                        child: Text(_dayLabel(day, i, short: true),
                            style: TextStyle(
                                color: context.f3textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        child: Text(
                          _hasActiveFilters
                              ? l10n.scheduleNoMatches
                              : l10n.scheduleNothingScheduled,
                          style: TextStyle(
                              color: context.f3textMuted.withValues(alpha: 0.6),
                              fontSize: 12),
                        ),
                      ),
                    ]),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayLabel(day, i),
                          style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        ...dayEvents.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _EventCard(
                                  event: e, onTap: () => _openEvent(e)),
                            )),
                      ],
                    ),
                  );
            // A subtle divider between each day keeps a sparse week from
            // reading as one undifferentiated block of text.
            return Column(children: [
              block,
              if (!isLast)
                Divider(
                    height: 1, color: context.f3divider.withValues(alpha: 0.5)),
            ]);
          }),
      ],
    );
  }

  /// An AO or type filter is active: instead of the fixed 7-day window,
  /// show every match from the same over-fetched upcoming-events batch,
  /// grouped by date — however many weeks out that goes. The default
  /// unfiltered agenda (_buildWeekAgenda) is untouched by this.
  Widget _buildFilteredAgenda(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final matches = _filteredUpcoming;
    final byDay = <DateTime, List<F3EventInstance>>{};
    for (final e in matches) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      (byDay[d] ??= []).add(e);
    }
    final days = byDay.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
          child: Row(children: [
            const Icon(Icons.filter_alt_rounded,
                size: 13, color: F3Colors.accent),
            const SizedBox(width: 6),
            Text(l10n.scheduleUpcomingFiltered,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(l10n.scheduleTapDateHint,
              style: TextStyle(color: context.f3textMuted, fontSize: 12)),
        ),
        if (_allUpcoming.isNotEmpty) _buildFilterBar(context),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(l10n.scheduleNoMatches,
                  style: TextStyle(color: context.f3textMuted, fontSize: 13)),
            ),
          )
        else
          ...days.map((day) {
            final dayEvents = byDay[day]!;
            final isLast = day == days.last;
            final offset = day.difference(todayStart).inDays;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dayLabel(day, offset),
                      style: TextStyle(
                          color: context.f3textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    ...dayEvents.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child:
                              _EventCard(event: e, onTap: () => _openEvent(e)),
                        )),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1, color: context.f3divider.withValues(alpha: 0.5)),
            ]);
          }),
      ],
    );
  }

  /// A calendar date was tapped: show just that day, with a way back to the
  /// default 7-day agenda (tapping the same date again does the same thing).
  Widget _buildSelectedDaySection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final day = _selectedDay!;
    final dayEvents = _selectedDayEvents;
    final subtitle = _loadingCalendar
        ? l10n.scheduleLoadingEllipsis
        : dayEvents.isEmpty
            ? l10n.scheduleNothingScheduled
            : l10n.scheduleBeatdownCount(dayEvents.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayLabel(day, null),
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: context.f3textMuted, fontSize: 12)),
              ],
            ),
            TextButton.icon(
              onPressed: _resetToToday,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(l10n.scheduleThisWeek),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: context.f3divider.withValues(alpha: 0.5)),
        const SizedBox(height: 14),
        if (_loadingCalendar)
          const Center(child: CircularProgressIndicator())
        else if (dayEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.scheduleNothingThisDay,
                style: TextStyle(color: context.f3textMuted)),
          )
        else
          ...dayEvents.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EventCard(event: e, onTap: () => _openEvent(e)),
              )),
      ],
    );
  }

  String _dayLabel(DateTime day, int? offsetFromToday, {bool short = false}) {
    final l10n = AppLocalizations.of(context)!;
    if (offsetFromToday == 0) {
      return short
          ? l10n.scheduleTodayShort
          : '${l10n.scheduleTodayFull} · ${_fmtDate(day)}';
    }
    if (offsetFromToday == 1) {
      return short
          ? l10n.scheduleTomorrowShort
          : '${l10n.scheduleTomorrowFull} · ${_fmtDate(day)}';
    }
    // Locale-aware weekday names via intl rather than a hand-translated
    // array — DateFormat already knows every supported locale's weekday
    // names.
    final locale = l10n.localeName;
    if (short) return '${DateFormat('E', locale).format(day)} ${_fmtDate(day)}';
    return '${DateFormat('EEEE', locale).format(day).toUpperCase()} · ${_fmtDate(day)}';
  }

  String _fmtDate(DateTime d) =>
      '${d.month}/${d.day}${d.year != DateTime.now().year ? '/${d.year}' : ''}';

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          FilterPill(
            label: _aoFilter ?? l10n.scheduleFilterAo,
            active: _aoFilter != null,
            onTap: () => _pickFromList(
              title: l10n.scheduleFilterByAo,
              options: _aoOptions,
              current: _aoFilter,
              onPicked: (v) => setState(() => _aoFilter = v),
            ),
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: _typeFilter ?? l10n.scheduleFilterType,
            active: _typeFilter != null,
            onTap: () => _pickFromList(
              title: l10n.scheduleFilterByType,
              options: _typeOptions,
              current: _typeFilter,
              onPicked: (v) => setState(() => _typeFilter = v),
            ),
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: _mineFilterLabel(l10n),
            active: _mineFilter != null,
            onTap: _pickMineFilter,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _aoFilter = null;
                _typeFilter = null;
                _mineFilter = null;
              }),
              child: Text(l10n.scheduleClearAll),
            ),
          ],
        ]),
      ),
    );
  }

  String _mineFilterLabel(AppLocalizations l10n) {
    switch (_mineFilter) {
      case null:
        return l10n.scheduleFilterMine;
      case MineFilter.hc:
        return l10n.scheduleFilterMineHc;
      case MineFilter.q:
        return l10n.scheduleFilterMineQ;
      case MineFilter.hcOrQ:
        return l10n.scheduleFilterMineHcOrQ;
    }
  }

  /// Not a data-driven string list like AO/Type, so this doesn't reuse
  /// showFilterPickerSheet (shared with Browse AOs) — a small dedicated
  /// sheet for this one enum-shaped filter.
  Future<void> _pickMineFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<MineFilter?>(
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
              child: Text(l10n.scheduleFilterMineTitle,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            ListTile(
              title: Text(l10n.scheduleFilterAll,
                  style: TextStyle(color: context.f3textPrimary)),
              trailing: _mineFilter == null
                  ? const Icon(Icons.check_rounded, color: F3Colors.accent)
                  : null,
              onTap: () => Navigator.pop(sheetContext, null),
            ),
            for (final option in MineFilter.values)
              ListTile(
                title: Text(
                  switch (option) {
                    MineFilter.hc => l10n.scheduleFilterMineHc,
                    MineFilter.q => l10n.scheduleFilterMineQ,
                    MineFilter.hcOrQ => l10n.scheduleFilterMineHcOrQ,
                  },
                  style: TextStyle(color: context.f3textPrimary),
                ),
                trailing: _mineFilter == option
                    ? const Icon(Icons.check_rounded, color: F3Colors.accent)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _mineFilter = picked);
  }
}

class _EventCard extends StatelessWidget {
  final F3EventInstance event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: context.f3card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_month(event.date, l10n.localeName),
                    style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                Text('${event.date.day}',
                    style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      event.orgName ??
                          event.locationName ??
                          l10n.scheduleBeatdownFallback,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.startTime != null) event.startTime,
                      event.hasQ
                          ? l10n.scheduleQLabel(
                              event.qF3Name ?? l10n.scheduleQSet)
                          : l10n.scheduleQNeeded,
                    ].join(' · '),
                    style: TextStyle(
                        color: event.hasQ
                            ? context.f3textSecondary
                            : F3Colors.accent,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if ((event.hcCount ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(l10n.scheduleHcCount(event.hcCount ?? 0),
                    style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            Icon(Icons.chevron_right_rounded,
                color: context.f3textMuted, size: 20),
          ]),
        ),
      ),
    );
  }

  String _month(DateTime d, String locale) =>
      DateFormat('MMM', locale).format(d).toUpperCase();
}

/// Detail sheet: shows preblast + HC count and the action buttons (HC / take Q
/// / post preblast), gated on F3 login.
class _EventDetailSheet extends StatefulWidget {
  final F3EventInstance event;
  const _EventDetailSheet({required this.event});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  bool _busy = false;
  String? _flash;
  late bool _attending = widget.event.userAttending;
  List<F3AttendanceRecord>? _attendance; // null while loading
  F3Location? _location; // null while loading or if unresolved
  // The event, refined as richer data comes in (a freshly-fetched preblast
  // text, or one just posted). Starts as whatever Schedule's list fetch had.
  late F3EventInstance _event = widget.event;
  bool _loadingPreblast = false;
  // The last submitted preblast draft (plan/coupon/VQ) — kept so an HC/Q
  // change can silently re-assemble and re-post with fresh counts/names
  // without re-prompting the Q to retype what they already wrote.
  _PreblastDraft? _lastDraft;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _loadLocation();
    _refreshPreblastIfNeeded();
  }

  /// calendar-home-schedule (Schedule's main fetch) only ever sends a
  /// `hasPreblast` boolean, never the actual text — so if the server says a
  /// preblast exists but we don't have its text yet, fetch the one event
  /// that actually carries it.
  Future<void> _refreshPreblastIfNeeded() async {
    final id = _event.numericId;
    if (id == null ||
        !_event.hasPreblast ||
        (_event.preblast ?? '').isNotEmpty) {
      return;
    }
    setState(() => _loadingPreblast = true);
    final fresh = await context.read<F3ApiService>().getEventInstanceById(id);
    if (!mounted) return;
    setState(() {
      _loadingPreblast = false;
      if (fresh != null) {
        _event = _event.copyWith(
          preblast: fresh.preblast,
          hasPreblast: fresh.hasPreblast,
        );
      }
    });
  }

  Future<void> _loadAttendance() async {
    final id = widget.event.numericId;
    if (id == null) return;
    final records =
        await context.read<F3ApiService>().getAttendanceForEvent(id);
    if (mounted) setState(() => _attendance = records);
  }

  Future<void> _loadLocation() async {
    final orgId = widget.event.orgId;
    if (orgId == null) return;
    final locations = await context.read<F3ApiService>().getAoLocations();
    if (mounted) setState(() => _location = locations[orgId]);
  }

  Future<void> _getDirections() async {
    final loc = _location;
    if (loc == null) return;
    final Uri uri;
    if (loc.lat != null && loc.lon != null) {
      uri = Uri.parse(
          'geo:${loc.lat},${loc.lon}?q=${loc.lat},${loc.lon}(${Uri.encodeComponent(loc.aoName ?? loc.name)})');
    } else {
      final address = [loc.street, loc.city, loc.state]
          .where((s) => (s ?? '').isNotEmpty)
          .join(', ');
      if (address.isEmpty) return;
      uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _share() {
    final e = _event;
    final l10n = AppLocalizations.of(context)!;
    final where = e.orgName ?? e.locationName ?? l10n.scheduleBeatdownFallback;
    final lines = [
      where,
      [
        '${e.date.month}/${e.date.day}',
        if (e.startTime != null) e.startTime,
      ].join(' · '),
      e.hasQ
          ? l10n.scheduleQLabel(e.qF3Name ?? l10n.scheduleQSet)
          : l10n.scheduleQNeeded,
      if ((e.preblast ?? '').isNotEmpty) ...['', e.preblast!],
      '',
      l10n.scheduleShareTagline,
    ];
    Share.share(lines.join('\n'), subject: where);
  }

  bool get _linked =>
      context.read<AuthService>().currentUser?.identities.any(
            (i) => i.provider == AuthProvider.f3nation,
          ) ??
      false;

  Future<({String? token, int? uid, String? org})> _creds() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final token = await auth.getF3AccessToken();
    return (
      token: token,
      uid: int.tryParse(profile.authUserId),
      org: api.orgId,
    );
  }

  Future<void> _run(
      Future<String?> Function(int eiId, int uid, String token) op,
      String okMsg) async {
    final id = widget.event.numericId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final c = await _creds();
      if (c.token == null || c.uid == null) {
        setState(
            () => _flash = AppLocalizations.of(context)!.scheduleSignInFirst);
        return;
      }
      final err = await op(id, c.uid!, c.token!);
      setState(() => _flash = err ?? okMsg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hc() async {
    await _run(
      (id, uid, token) => context
          .read<F3ApiService>()
          .signUpForEvent(eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleHcSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      setState(() => _attending = true);
      _scheduleReminders();
      await _autoRepostPreblastIfNeeded();
    }
  }

  Future<void> _unhc() async {
    await _run(
      (id, uid, token) => context
          .read<F3ApiService>()
          .withdrawFromEvent(eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleUnhcSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      setState(() => _attending = false);
      final id = widget.event.numericId;
      if (id != null) NotificationService().cancelEventReminders(id);
      await _autoRepostPreblastIfNeeded();
    }
  }

  Future<void> _takeQ() async {
    await _run(
      (id, uid, token) =>
          context.read<F3ApiService>().takeQ(eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleTakeQSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      _scheduleReminders(isQ: true);
      await _autoRepostPreblastIfNeeded();
    }
  }

  /// Steps down from Q only — stays HC'd. Distinct from [_unhc], which drops
  /// attendance entirely (and the Q along with it, since it deletes the
  /// whole attendance record).
  Future<void> _dropQ() async {
    await _run(
      (id, uid, token) => context
          .read<F3ApiService>()
          .removeQ(eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleDropQSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      final id = widget.event.numericId;
      if (id != null) NotificationService().cancelEventReminders(id);
      await _autoRepostPreblastIfNeeded();
    }
  }

  /// Immediate reminder scheduling right after HC/take-Q, so it doesn't wait
  /// for Home's next reconcile pass to pick it up.
  void _scheduleReminders({bool? isQ}) {
    final id = widget.event.numericId;
    if (id == null) return;
    NotificationService().scheduleEventReminders(
      eventId: id,
      eventDateTime: widget.event.dateTime,
      title: widget.event.orgName ??
          widget.event.locationName ??
          AppLocalizations.of(context)!.scheduleBeatdownFallback,
      isQ: isQ ?? widget.event.userIsQ,
      hasPreblast: _event.hasPreblast,
    );
  }

  /// Best-effort recovery of the Q's plan/coupon text from an already-posted
  /// preblast — used when [_lastDraft] is empty (card opened fresh this
  /// session, nothing submitted through the composer yet) but a preblast
  /// already exists. Parses the fixed format [_assemblePreblast] itself
  /// produces, so this only ever needs to stay in sync with that function.
  _PreblastDraft? _parseDraftFromText(String? text) {
    if (text == null || text.isEmpty) return null;
    const planMarker = 'THE PLAN: ';
    const couponMarker = '\nCOUPON: ';
    final planIdx = text.indexOf(planMarker);
    final couponIdx = text.indexOf(couponMarker);
    if (planIdx == -1 || couponIdx == -1 || couponIdx < planIdx) return null;
    final plan = text.substring(planIdx + planMarker.length, couponIdx).trim();
    if (plan.isEmpty) return null;
    final couponLine = text.substring(couponIdx + couponMarker.length).trim();
    final couponNeeded = couponLine.startsWith('Yes');
    var couponNotes = '';
    if (couponNeeded) {
      final dashIdx = couponLine.indexOf('—');
      if (dashIdx != -1) couponNotes = couponLine.substring(dashIdx + 1).trim();
    }
    return _PreblastDraft(
      plan: plan,
      vq: text.contains('Event Tag: VQ'),
      couponNeeded: couponNeeded,
      couponNotes: couponNotes,
    );
  }

  /// Silently re-assembles and re-posts the preblast after an HC/Q change —
  /// only the auto-filled fields (Q, HC count, HC names) actually need to
  /// change; the Q's own plan/coupon text is carried over from [_lastDraft]
  /// (or recovered via [_parseDraftFromText]) rather than re-prompted for.
  /// No-ops if there's no preblast yet, or if the plan text can't be
  /// recovered at all — this is a convenience on top of the real "Edit
  /// Preblast" flow, never a replacement for it.
  Future<void> _autoRepostPreblastIfNeeded() async {
    if (!_event.hasPreblast) return;
    final draft = _lastDraft ?? _parseDraftFromText(_event.preblast);
    if (draft == null) return;
    final id = _event.numericId;
    final eventOrgId = _event.orgId;
    if (id == null || eventOrgId == null) return;
    final c = await _creds();
    if (c.token == null) return;

    await _loadAttendance(); // fresh HC/Q list before reassembling
    if (!mounted) return;
    final freshAttendance = _attendance ?? const [];
    // Empty string, not null, when nobody's currently Q — Drop Q with no
    // replacement yet should say so, not silently keep the last Q's name.
    var currentQ = '';
    for (final a in freshAttendance) {
      if (a.isQ) {
        currentQ = a.f3Name ?? '';
        break;
      }
    }
    final myName = context.read<AppProfileService>().displayName;
    final text = _assemblePreblast(
      event: _event,
      attendance: freshAttendance,
      myF3Name: myName,
      draft: draft,
      qNameOverride: currentQ,
    );
    final d = _event.date;
    final startDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final err = await context.read<F3ApiService>().postPreblast(
          eventInstanceId: id,
          orgId: '$eventOrgId',
          startDate: startDate,
          preblast: text,
        );
    if (!mounted || err != null) return;
    setState(() {
      _event = _event.copyWith(preblast: text, hasPreblast: true);
      _lastDraft = draft;
      final base = _flash;
      final suffix = AppLocalizations.of(context)!.schedulePreblastAutoUpdated;
      _flash = (base == null || base.isEmpty) ? suffix : '$base — $suffix';
    });
  }

  /// Opens the Weinke builder linked to this event; if the Q taps "Use as
  /// Preblast" there, comes straight back into the preblast composer with
  /// the plan already summarized into the Plan field and Coupon pre-set
  /// from whatever's actually in the plan — nothing to retype.
  Future<void> _buildWeinke() async {
    final plan = await Navigator.push<WorkoutPlan>(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutScreen(forPreblast: true)),
    );
    if (plan == null || !mounted) return;
    await _postPreblast(
      initialPlan: WeinkeExporter.planSummaryOnly(plan),
      initialCouponNeeded: WeinkeExporter.hasCoupon(plan),
    );
  }

  Future<void> _postPreblast(
      {String? initialPlan, bool initialCouponNeeded = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final e = _event;
    final myName = context.read<AppProfileService>().displayName;
    final draft = await showModalBottomSheet<_PreblastDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PreblastComposerSheet(
        event: e,
        attendance: _attendance ?? const [],
        myF3Name: myName,
        initialPlan: initialPlan ?? (e.preblast ?? ''),
        initialCouponNeeded: initialCouponNeeded,
      ),
    );
    if (draft == null || draft.plan.trim().isEmpty || !mounted) return;

    final api = context.read<F3ApiService>();
    final id = e.numericId;
    final eventOrgId = e.orgId;
    final c = await _creds();
    if (id == null || eventOrgId == null || c.token == null) {
      setState(() => _flash = l10n.scheduleSignInToPostPreblast);
      return;
    }
    setState(() => _busy = true);
    final d = e.date;
    final startDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final text = _assemblePreblast(
      event: e,
      attendance: _attendance ?? const [],
      myF3Name: myName,
      draft: draft,
    );
    final err = await api.postPreblast(
        eventInstanceId: id,
        orgId: '$eventOrgId',
        startDate: startDate,
        preblast: text);
    if (mounted) {
      setState(() {
        _busy = false;
        _flash = err ?? l10n.schedulePreblastPosted;
        // Reflect the post immediately — calendar-home-schedule's next
        // refetch still won't carry the text (only `hasPreblast`), so
        // without this the button silently reverts to "Post Preblast".
        if (err == null) {
          _event = _event.copyWith(preblast: text, hasPreblast: true);
          _lastDraft = draft;
        }
      });
    }
    // A posted preblast means the Q is running this beatdown — set their
    // reminder automatically instead of requiring a separate self-HC, same
    // as HC/take-Q already do.
    if (err == null) _scheduleReminders(isQ: true);
  }

  /// Assembles the real F3 Nation preblast format (matches what slackbot
  /// produces) from auto-filled event data plus the Q's own free-text
  /// inputs — the Q only ever has to type the plan and, optionally, coupon
  /// notes; everything else (date/time/where/Q/HC list) is already known.
  /// Note: F3's Slack preblast also includes a "#ao-slug" channel reference
  /// under "Where" — there's no channel-slug field available client-side, so
  /// this only prints the AO/location name.
  String _assemblePreblast({
    required F3EventInstance event,
    required List<F3AttendanceRecord> attendance,
    required String myF3Name,
    required _PreblastDraft draft,
    // Overrides the event.qF3Name/myF3Name fallback below with the actual
    // current Q from freshly-loaded attendance — event.qF3Name is a snapshot
    // from whenever this event was last fetched and goes stale the moment
    // Take Q/Drop Q changes who's actually Q'd (used by the auto-repost
    // path, which always has fresh attendance in hand; the manual composer
    // leaves this null and keeps the original fallback, since a human
    // actively posting/editing implies real intent either way).
    String? qNameOverride,
  }) {
    final where = event.orgName ?? event.locationName ?? 'the AO';
    final q = qNameOverride ??
        ((event.qF3Name?.isNotEmpty ?? false) ? event.qF3Name! : myF3Name);
    final hcNames = attendance.map((a) => '@${a.f3Name ?? '?'}').join(' ');
    final buf = StringBuffer()
      ..writeln('Preblast: $where')
      ..writeln('Date: ${DateFormat('EEE, MMMM d').format(event.date)}');
    if ((event.startTime ?? '').isNotEmpty) {
      buf.writeln('Time: ${event.startTime}');
    }
    buf
      ..writeln('Where: $where')
      ..writeln('Event Type: ${event.eventTypeName ?? 'Bootcamp'}');
    if (draft.vq) buf.writeln('Event Tag: VQ');
    if (q.isNotEmpty) buf.writeln('Q: @$q');
    buf.writeln('HC Count: ${attendance.length}');
    if (hcNames.isNotEmpty) buf.writeln('HCs: $hcNames');
    buf
      ..writeln()
      ..writeln('THE PLAN: ${draft.plan.trim()}')
      ..writeln(
          'COUPON: ${draft.couponNeeded ? 'Yes${draft.couponNotes.trim().isNotEmpty ? ' — ${draft.couponNotes.trim()}' : ''}' : 'No'}');
    return buf.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = _event;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: context.f3divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: l10n.scheduleCloseTooltip,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    e.orgName ??
                        e.locationName ??
                        l10n.scheduleBeatdownFallback,
                    style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
              if (_location != null) ...[
                Tooltip(
                  message: l10n.scheduleDirectionsTooltip,
                  child: IconButton(
                    onPressed: _getDirections,
                    icon: const Icon(Icons.directions_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Tooltip(
                message: l10n.scheduleShareTooltip,
                child: IconButton(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              '${e.date.month}/${e.date.day}',
              if (e.startTime != null) e.startTime,
              e.hasQ
                  ? l10n.scheduleQLabel(e.qF3Name ?? l10n.scheduleQSet)
                  : l10n.scheduleQNeeded,
              if ((e.hcCount ?? 0) > 0) l10n.scheduleHcCount(e.hcCount ?? 0),
            ].join(' · '),
            style: TextStyle(color: context.f3textSecondary, fontSize: 13),
          ),
          if ((_attendance ?? const []).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l10n.scheduleWhosIn,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _attendance!.map((a) {
                final name = a.f3Name ?? '?';
                final label = a.isQ
                    ? '$name (Q)'
                    : a.isCoQ
                        ? '$name (Co-Q)'
                        : name;
                return Chip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: a.isQ || a.isCoQ
                      ? F3Colors.accent.withValues(alpha: 0.15)
                      : context.f3card,
                  side: BorderSide(color: context.f3divider),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          if (e.hasPreblast) ...[
            Text(l10n.schedulePreblastHeader,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            if ((e.preblast ?? '').isNotEmpty)
              ConstrainedBox(
                // A long preblast scrolls in its own box instead of
                // growing the whole card — keeps the card's own
                // drag-to-dismiss usable regardless of text length.
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.28,
                ),
                child: SingleChildScrollView(
                  child: Text(e.preblast!,
                      style: TextStyle(
                          color: context.f3textSecondary,
                          fontSize: 14,
                          height: 1.4)),
                ),
              )
            else if (_loadingPreblast)
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: context.f3textMuted),
              )
            else
              Text(l10n.schedulePreblastUnavailable,
                  style: TextStyle(color: context.f3textMuted, fontSize: 13)),
            const SizedBox(height: 16),
          ],
          if (!_linked)
            Text(l10n.scheduleSignInToHc,
                style: TextStyle(color: context.f3textMuted, fontSize: 12))
          else ...[
            SizedBox(
              width: double.infinity,
              child: _attending
                  ? OutlinedButton.icon(
                      onPressed: _busy ? null : _unhc,
                      icon: const Icon(Icons.person_remove_rounded, size: 18),
                      label: Text(l10n.scheduleUnHc),
                    )
                  : ElevatedButton.icon(
                      onPressed: _busy ? null : _hc,
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: Text(l10n.scheduleHcImIn),
                    ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              if (!e.hasQ)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _takeQ,
                    icon: const Icon(Icons.sports_rounded, size: 18),
                    label: Text(l10n.scheduleTakeQ),
                  ),
                ),
              if (e.userIsQ)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _dropQ,
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        size: 18),
                    label: Text(l10n.scheduleDropQ),
                  ),
                ),
              if (!e.hasQ || e.userIsQ) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _postPreblast,
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: Text(e.hasPreblast
                      ? l10n.scheduleEditPreblast
                      : l10n.schedulePostPreblast),
                ),
              ),
            ]),
            if (e.userIsQ) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _buildWeinke,
                  icon: const Icon(Icons.fitness_center_rounded, size: 18),
                  label: Text(l10n.scheduleBuildWeinke),
                ),
              ),
            ],
          ],
          if (_flash != null) ...[
            const SizedBox(height: 12),
            Text(_flash!,
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

// ── Structured preblast composer ────────────────────────────────────────────
// The Q only has to type the plan (and, optionally, coupon notes) — every
// other field the real F3 Nation preblast format requires (date, time,
// where, event type, Q, HC list) is already known from the event and its
// live attendance, so it's shown read-only and assembled automatically.

class _PreblastDraft {
  final String plan;
  final bool vq;
  final bool couponNeeded;
  final String couponNotes;
  const _PreblastDraft({
    required this.plan,
    required this.vq,
    required this.couponNeeded,
    required this.couponNotes,
  });
}

class _PreblastComposerSheet extends StatefulWidget {
  final F3EventInstance event;
  final List<F3AttendanceRecord> attendance;
  final String myF3Name;
  final String initialPlan;
  final bool initialCouponNeeded;

  const _PreblastComposerSheet({
    required this.event,
    required this.attendance,
    required this.myF3Name,
    required this.initialPlan,
    this.initialCouponNeeded = false,
  });

  @override
  State<_PreblastComposerSheet> createState() => _PreblastComposerSheetState();
}

class _PreblastComposerSheetState extends State<_PreblastComposerSheet> {
  late final _planCtrl = TextEditingController(text: widget.initialPlan);
  late final _couponNotesCtrl = TextEditingController();
  bool _vq = false;
  late bool _couponNeeded = widget.initialCouponNeeded;

  @override
  void dispose() {
    _planCtrl.dispose();
    _couponNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = widget.event;
    final where = e.orgName ?? e.locationName ?? l10n.scheduleBeatdownFallback;
    final q = (e.qF3Name?.isNotEmpty ?? false) ? e.qF3Name! : widget.myF3Name;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: context.f3divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.schedulePostPreblast,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(l10n.schedulePreblastAutoFilled,
                style: TextStyle(color: context.f3textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.f3elevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                [
                  where,
                  DateFormat('EEE, MMMM d').format(e.date),
                  if ((e.startTime ?? '').isNotEmpty) e.startTime,
                  'Q: ${q.isEmpty ? '—' : q}',
                  l10n.scheduleHcCount(widget.attendance.length),
                ].join(' · '),
                style:
                    TextStyle(color: context.f3textSecondary, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.schedulePreblastPlanLabel,
                style: TextStyle(
                    color: context.f3textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _planCtrl,
              maxLines: 5,
              autofocus: true,
              style: TextStyle(color: context.f3textPrimary),
              decoration: InputDecoration(
                hintText: l10n.schedulePreblastPlanHint,
                filled: true,
                fillColor: context.f3elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _vq,
              onChanged: (v) => setState(() => _vq = v ?? false),
              title: Text(l10n.schedulePreblastVq,
                  style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              value: _couponNeeded,
              onChanged: (v) => setState(() => _couponNeeded = v ?? false),
              title: Text(l10n.schedulePreblastCoupon,
                  style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_couponNeeded) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _couponNotesCtrl,
                style: TextStyle(color: context.f3textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.schedulePreblastCouponNotesHint,
                  filled: true,
                  fillColor: context.f3elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.scheduleCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _PreblastDraft(
                        plan: _planCtrl.text,
                        vq: _vq,
                        couponNeeded: _couponNeeded,
                        couponNotes: _couponNotesCtrl.text,
                      ),
                    ),
                    child: Text(l10n.schedulePost),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Empty(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: context.f3textMuted, size: 48),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}
