// lib/screens/schedule_screen.dart
// Tier 1 of the "unified app" loop: the weekly schedule of upcoming beatdowns
// for the signed-in PAX's region, with HC (sign up), take-Q, and preblast
// actions. Reads/writes the F3 Nation API; requires F3 login for the write
// actions (self-signup uses the user's own token, no editor role needed).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_models.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_pill.dart';
import '../widgets/month_calendar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = true;
  List<F3EventInstance> _events = []; // today + next 7 days, for the agenda

  String? _aoFilter;
  String? _typeFilter;

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // Null = default agenda (next 7 days); set once a calendar date is tapped.
  DateTime? _selectedDay;
  bool _loadingCalendar = false;
  List<F3EventInstance> _calendarEvents = []; // whichever month is displayed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadCalendarMonth();
    });
  }

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
    final events = await api.getUpcomingBeatdowns(
        userAccessToken: token, userId: userId);
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
    setState(() {
      _events = windowed;
      _loading = false;
    });
  }

  List<String> get _aoOptions => _events
      .map((e) => e.orgName)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get _typeOptions => _events
      .map((e) => e.eventTypeName)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<F3EventInstance> get _filteredEvents => _events.where((e) {
        if (_aoFilter != null && e.orgName != _aoFilter) return false;
        if (_typeFilter != null && e.eventTypeName != _typeFilter) {
          return false;
        }
        return true;
      }).toList();

  bool get _hasActiveFilters => _aoFilter != null || _typeFilter != null;

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
              onRefresh: () =>
                  Future.wait([_load(), _loadCalendarMonth()]),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))),
                    ),
                  const Divider(height: 32, thickness: 1),
                  if (_selectedDay != null)
                    _buildSelectedDaySection(context)
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
            const Icon(Icons.view_agenda_rounded, size: 13, color: F3Colors.accent),
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
                              color:
                                  context.f3textMuted.withValues(alpha: 0.6),
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
                    height: 1,
                    color: context.f3divider.withValues(alpha: 0.5)),
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
                    style:
                        TextStyle(color: context.f3textMuted, fontSize: 12)),
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
      return short ? l10n.scheduleTodayShort : '${l10n.scheduleTodayFull} · ${_fmtDate(day)}';
    }
    if (offsetFromToday == 1) {
      return short ? l10n.scheduleTomorrowShort : '${l10n.scheduleTomorrowFull} · ${_fmtDate(day)}';
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
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _aoFilter = null;
                _typeFilter = null;
              }),
              child: Text(l10n.scheduleClearAll),
            ),
          ],
        ]),
      ),
    );
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
                  Text(event.orgName ?? event.locationName ?? l10n.scheduleBeatdownFallback,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.startTime != null) event.startTime,
                      event.hasQ
                          ? l10n.scheduleQLabel(event.qF3Name ?? l10n.scheduleQSet)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Future<void> _run(Future<String?> Function(int eiId, int uid, String token) op,
      String okMsg) async {
    final id = widget.event.numericId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final c = await _creds();
      if (c.token == null || c.uid == null) {
        setState(() => _flash = AppLocalizations.of(context)!.scheduleSignInFirst);
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
      (id, uid, token) => context.read<F3ApiService>().signUpForEvent(
          eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleHcSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      setState(() => _attending = true);
      _scheduleReminders();
    }
  }

  Future<void> _unhc() async {
    await _run(
      (id, uid, token) => context.read<F3ApiService>().withdrawFromEvent(
          eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleUnhcSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      setState(() => _attending = false);
      final id = widget.event.numericId;
      if (id != null) NotificationService().cancelEventReminders(id);
    }
  }

  Future<void> _takeQ() async {
    await _run(
      (id, uid, token) => context.read<F3ApiService>().takeQ(
          eventInstanceId: id, userId: uid),
      AppLocalizations.of(context)!.scheduleTakeQSuccess,
    );
    if (_flash != null && !_flash!.toLowerCase().contains('fail')) {
      _scheduleReminders(isQ: true);
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
      hasPreblast: (widget.event.preblast ?? '').isNotEmpty,
    );
  }

  Future<void> _postPreblast() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: widget.event.preblast ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text(l10n.schedulePostPreblast),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          style: TextStyle(color: context.f3textPrimary),
          decoration: InputDecoration(hintText: l10n.schedulePreblastHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.scheduleCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: Text(l10n.schedulePost)),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final api = context.read<F3ApiService>();
    final id = widget.event.numericId;
    final eventOrgId = widget.event.orgId;
    final c = await _creds();
    if (id == null || eventOrgId == null || c.token == null) {
      setState(() => _flash = l10n.scheduleSignInToPostPreblast);
      return;
    }
    setState(() => _busy = true);
    final d = widget.event.date;
    final startDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final err = await api.postPreblast(
        eventInstanceId: id,
        orgId: '$eventOrgId',
        startDate: startDate,
        preblast: text);
    if (mounted) {
      setState(() {
        _busy = false;
        _flash = err ?? l10n.schedulePreblastPosted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = widget.event;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: context.f3divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text(e.orgName ?? e.locationName ?? l10n.scheduleBeatdownFallback,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
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
          const SizedBox(height: 16),
          if ((e.preblast ?? '').isNotEmpty) ...[
            Text(l10n.schedulePreblastHeader,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(e.preblast!,
                style: TextStyle(
                    color: context.f3textSecondary, fontSize: 14, height: 1.4)),
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
              if (!e.hasQ) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _postPreblast,
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: Text((e.preblast ?? '').isEmpty
                      ? l10n.schedulePostPreblast
                      : l10n.scheduleEditPreblast),
                ),
              ),
            ]),
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
