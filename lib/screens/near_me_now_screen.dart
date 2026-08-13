// lib/screens/near_me_now_screen.dart
// "F3 near me right now" — AOs whose weekly schedule has a workout starting
// soon today, sorted by distance. Reuses the same locations+schedule join
// Browse AOs already does (F3ApiService.getLocations/getLocationSchedules),
// just filtered down to "happening soon" instead of "everything."

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/f3_api_models.dart';
import '../services/f3_api_service.dart';
import '../services/geo_service.dart';
import '../theme/app_theme.dart';

const _weekdayNames = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class _NearbyPick {
  final F3Location location;
  final F3WeeklyWorkout workout;
  final int minutesUntilStart; // negative = already started
  final double? distanceMiles;
  const _NearbyPick({
    required this.location,
    required this.workout,
    required this.minutesUntilStart,
    required this.distanceMiles,
  });
}

class NearMeNowScreen extends StatefulWidget {
  const NearMeNowScreen({super.key});

  @override
  State<NearMeNowScreen> createState() => _NearMeNowScreenState();
}

class _NearMeNowScreenState extends State<NearMeNowScreen> {
  bool _loading = true;
  List<_NearbyPick> _picks = const [];
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = context.read<F3ApiService>();
    final results = await Future.wait([
      api.getLocations(),
      api.getLocationSchedules(),
    ]);
    final locations = results[0] as List<F3Location>;
    final schedules = results[1] as Map<
        String,
        ({List<F3WeeklyWorkout> schedule, String? aoName, String? aoOrgId})>;

    final position = await GeoService.getCurrentPosition();
    final now = DateTime.now();
    final todayName = _weekdayNames[now.weekday - 1];
    final nowMinutes = now.hour * 60 + now.minute;

    final picks = <_NearbyPick>[];
    for (final loc in locations) {
      final schedule = schedules[loc.id]?.schedule ?? const [];
      for (final workout in schedule) {
        if (workout.weekday.toLowerCase() != todayName) continue;
        final h = int.tryParse(
            workout.time.length >= 2 ? workout.time.substring(0, 2) : '');
        final m = int.tryParse(
            workout.time.length >= 4 ? workout.time.substring(2, 4) : '');
        if (h == null || m == null) continue;
        final startMinutes = h * 60 + m;
        final delta = startMinutes - nowMinutes;
        // "Right now" window: started up to 15 minutes ago (F3 culture —
        // showing up a few minutes into a workout is normal) through
        // starting within the next 60 minutes.
        if (delta < -15 || delta > 60) continue;
        double? distance;
        if (position != null && loc.lat != null && loc.lon != null) {
          distance = GeoService.distanceMiles(
            lat1: position.latitude,
            lon1: position.longitude,
            lat2: loc.lat!,
            lon2: loc.lon!,
          );
        }
        picks.add(_NearbyPick(
          location: loc,
          workout: workout,
          minutesUntilStart: delta,
          distanceMiles: distance,
        ));
      }
    }
    picks.sort((a, b) {
      if (a.distanceMiles != null && b.distanceMiles != null) {
        return a.distanceMiles!.compareTo(b.distanceMiles!);
      }
      if (a.distanceMiles != null) return -1;
      if (b.distanceMiles != null) return 1;
      return a.minutesUntilStart.compareTo(b.minutesUntilStart);
    });

    if (!mounted) return;
    setState(() {
      _picks = picks;
      _locationDenied = position == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('F3 Near Me Right Now'),
        backgroundColor: context.f3bg,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_locationDenied) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: F3Colors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Can't sort by distance without location access — showing everything starting soon, unsorted.",
                        style: TextStyle(
                            color: context.f3textSecondary, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_picks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(children: [
                        Icon(Icons.radar_rounded,
                            color: context.f3textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing starting in the next hour right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.f3textMuted, fontSize: 14),
                        ),
                      ]),
                    )
                  else
                    ..._picks.map((p) => _NearbyCard(pick: p)),
                ],
              ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final _NearbyPick pick;
  const _NearbyCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    final started = pick.minutesUntilStart < 0;
    final statusText = started
        ? 'Started ${-pick.minutesUntilStart} min ago'
        : pick.minutesUntilStart == 0
            ? 'Starting now'
            : 'Starts in ${pick.minutesUntilStart} min';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: started
                ? F3Colors.phaseWarmup.withValues(alpha: 0.4)
                : F3Colors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 44,
          decoration: BoxDecoration(
            color: started ? F3Colors.phaseWarmup : F3Colors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pick.location.aoName ?? pick.location.name,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('$statusText · ${pick.workout.displayTime}',
                  style: TextStyle(
                      color: started
                          ? F3Colors.phaseWarmup
                          : context.f3textSecondary,
                      fontSize: 12.5,
                      fontWeight: started ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
        if (pick.distanceMiles != null)
          Text('${pick.distanceMiles!.toStringAsFixed(1)} mi',
              style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
