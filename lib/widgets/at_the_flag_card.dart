// lib/widgets/at_the_flag_card.dart
// "I'm at the flag" — a one-tap personal check-in for today. Explicitly NOT
// a broadcast: there's no relay to other PAX's devices, this only shows on
// this PAX's own Home screen. Real value is reducing friction on logging
// attendance in the moment, rather than reconstructing it later when saving
// a backblast.
//
// Strongest signal first: if the signed-in user already HC'd or took Q for a
// real event today (via Schedule), that's an unambiguous, GPS-free fact —
// tapping the button just checks in immediately, no sheet, no questions.
// Only when no such commitment exists does this fall back to a best-effort
// GPS suggestion: matching the device's current location against real F3
// Nation AO coordinates (already fetched for Browse AOs / F3 Near Me Right
// Now) and, when possible, today's real scheduled event instance at that AO
// — so a check-in can carry a real eventInstanceId, not just a typed name.
// Never blocks manual entry: a denied/slow/failed lookup just means no
// suggestion shows.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/geo_service.dart';
import '../services/region_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

String _shortTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '$h12:${d.minute.toString().padLeft(2, '0')} $period';
}

class _NearbySuggestion {
  final String aoName;
  final double milesAway;
  final String? eventInstanceId;
  const _NearbySuggestion({
    required this.aoName,
    required this.milesAway,
    this.eventInstanceId,
  });
}

class AtTheFlagCard extends StatefulWidget {
  const AtTheFlagCard({super.key});

  @override
  State<AtTheFlagCard> createState() => _AtTheFlagCardState();
}

class _AtTheFlagCardState extends State<AtTheFlagCard> {
  bool _checking = false;

  Future<void> _checkIn(BuildContext context) async {
    final settings = context.read<SettingsService>();
    final api = context.read<F3ApiService>();
    final auth = context.read<AuthService>();
    final profile = context.read<AppProfileService>();
    final region = context.read<RegionService>();

    // Strongest possible signal: already HC'd or Q'd for a real event today
    // (e.g. via Schedule) — unambiguous and GPS-free, so just use it. No
    // sheet, no picking, no permission dance.
    setState(() => _checking = true);
    final committed = await _findCommittedEventToday(api, auth, profile);
    if (!context.mounted) return;
    setState(() => _checking = false);
    if (committed != null) {
      await settings.checkInAtTheFlag(committed.aoName,
          eventInstanceId: committed.eventInstanceId);
      return;
    }

    final result = await showModalBottomSheet<_NearbySuggestion?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CheckInSheet(
        yourAos: region.aos.map((ao) => ao.name).toList(),
        lookup: () => _findNearbySuggestion(api, auth, profile),
      ),
    );
    if (result != null && result.aoName.isNotEmpty) {
      await settings.checkInAtTheFlag(result.aoName,
          eventInstanceId: result.eventInstanceId);
    }
  }

  /// Today's real event instance the signed-in user is already HC'd or Q'd
  /// for (userAttending/userIsQ on F3EventInstance, from Schedule's own
  /// calendar-home-schedule fetch) — a real commitment, not a guess. Returns
  /// null on any failure or if there simply isn't one; first match wins on
  /// the rare case of more than one (not worth a picker for).
  static Future<_NearbySuggestion?> _findCommittedEventToday(
    F3ApiService api,
    AuthService auth,
    AppProfileService profile,
  ) async {
    try {
      final userId = int.tryParse(profile.authUserId);
      if (userId == null) return null;
      final token = await auth.getF3AccessToken();
      final events = await api
          .getUpcomingBeatdowns(userAccessToken: token, userId: userId)
          .timeout(const Duration(seconds: 6));
      final today = DateTime.now();
      for (final e in events) {
        if (e.date.year != today.year ||
            e.date.month != today.month ||
            e.date.day != today.day) {
          continue;
        }
        if (!e.userAttending && !e.userIsQ) continue;
        final name = e.orgName ?? e.locationName;
        if (name == null || name.isEmpty) continue;
        return _NearbySuggestion(aoName: name, milesAway: 0, eventInstanceId: e.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort: device position -> nearest real F3 Nation AO within ~0.3mi
  /// -> today's real scheduled event instance at that AO, if any. Returns
  /// null on any failure/timeout/denial rather than throwing — this is a
  /// convenience suggestion, never a requirement to check in.
  static Future<_NearbySuggestion?> _findNearbySuggestion(
    F3ApiService api,
    AuthService auth,
    AppProfileService profile,
  ) async {
    try {
      // Permission is normally already decided by the time this opens (see
      // GeoService.primePermissionIfUndetermined, run on every app open) —
      // this timeout only has to cover a real GPS fix, not someone actively
      // answering the OS permission dialog right now.
      final position = await GeoService.getCurrentPosition()
          .timeout(const Duration(seconds: 6));
      if (position == null) return null;

      final locations = await api.getLocations();
      F3Location? nearest;
      double nearestMiles = double.infinity;
      for (final loc in locations) {
        if (loc.lat == null || loc.lon == null) continue;
        final miles = GeoService.distanceMiles(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: loc.lat!,
          lon2: loc.lon!,
        );
        // Tight radius on purpose — a beatdown site is a parking lot or
        // park, not a whole neighborhood. Avoids suggesting the wrong AO
        // just because it's the closest one in a dense area.
        if (miles <= 0.3 && miles < nearestMiles) {
          nearest = loc;
          nearestMiles = miles;
        }
      }
      if (nearest == null) return null;
      final nearestName = nearest.aoName ?? nearest.name;

      // Cross-reference today's real schedule so the check-in can carry a
      // real eventInstanceId, not just a name — "attached to the calendar."
      String? eventInstanceId;
      final token = await auth.getF3AccessToken();
      final userId = int.tryParse(profile.authUserId);
      if (userId != null) {
        final events = await api.getUpcomingBeatdowns(
            userAccessToken: token, userId: userId);
        final today = DateTime.now();
        for (final e in events) {
          if (e.date.year != today.year ||
              e.date.month != today.month ||
              e.date.day != today.day) {
            continue;
          }
          final eventAo = (e.locationName ?? e.orgName ?? '').toLowerCase();
          if (eventAo.isEmpty) continue;
          if (eventAo == nearestName.toLowerCase() ||
              eventAo == nearest.name.toLowerCase()) {
            eventInstanceId = e.id;
            break;
          }
        }
      }

      return _NearbySuggestion(
        aoName: nearestName,
        milesAway: nearestMiles,
        eventInstanceId: eventInstanceId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final aoName = settings.atTheFlagAo;
    final since = settings.atTheFlagSince;
    final linkedToSchedule = settings.atTheFlagEventInstanceId != null;

    if (aoName == null || since == null) {
      return OutlinedButton.icon(
        onPressed: _checking ? null : () => _checkIn(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: F3Colors.accent,
          side: BorderSide(color: F3Colors.accent.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: _checking
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: F3Colors.accent),
              )
            : const Icon(Icons.location_on_rounded, size: 18),
        label: const Text("I'm at the flag"),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: F3Colors.phaseWarmup.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.phaseWarmup.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(
          linkedToSchedule ? Icons.event_available_rounded : Icons.location_on_rounded,
          color: F3Colors.phaseWarmup,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('At $aoName since ${_shortTime(since)}',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: context.f3textMuted, size: 18),
          tooltip: 'Clear check-in',
          onPressed: () => context.read<SettingsService>().clearAtTheFlag(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

class _CheckInSheet extends StatefulWidget {
  final List<String> yourAos;
  final Future<_NearbySuggestion?> Function() lookup;
  const _CheckInSheet({required this.yourAos, required this.lookup});

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  late final TextEditingController _controller;
  _NearbySuggestion? _suggestion;
  bool _lookedUp = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    widget.lookup().then((s) {
      if (!mounted) return;
      setState(() {
        _suggestion = s;
        _lookedUp = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("I'm at the flag",
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Just for you — no one else sees this, it just saves you retyping the AO later.',
              style: TextStyle(color: context.f3textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_suggestion != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _suggestion),
                  icon: Icon(
                    _suggestion!.eventInstanceId != null
                        ? Icons.event_available_rounded
                        : Icons.my_location_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _suggestion!.eventInstanceId != null
                        ? "You're at ${_suggestion!.aoName} — today's beatdown"
                        : "You're near ${_suggestion!.aoName} (${_suggestion!.milesAway.toStringAsFixed(1)} mi)",
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (!_lookedUp) ...[
              Row(children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.f3textMuted),
                ),
                const SizedBox(width: 8),
                Text('Checking your location…',
                    style: TextStyle(color: context.f3textMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
            ],
            if (widget.yourAos.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.yourAos
                    .map((name) => ActionChip(
                          label: Text(name),
                          onPressed: () => Navigator.pop(
                              context, _NearbySuggestion(aoName: name, milesAway: 0)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: widget.yourAos.isEmpty && _suggestion == null,
              style: TextStyle(color: context.f3textPrimary),
              decoration: const InputDecoration(
                labelText: 'Or type an AO name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(
                  context, _NearbySuggestion(aoName: v.trim(), milesAway: 0)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context,
                    _NearbySuggestion(aoName: _controller.text.trim(), milesAway: 0)),
                child: const Text("CHECK IN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
