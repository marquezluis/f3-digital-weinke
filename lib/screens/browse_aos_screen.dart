// lib/screens/browse_aos_screen.dart
// Browse F3 Nation AOs pulled from the live API, optionally sorted by
// distance from the device's current location. Read-only — no writes to
// F3 Nation, so this is safe to ship without any of the auth/permission
// caveats that apply to the future "publish backblast" feature.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/f3_api_models.dart';
import '../services/f3_api_service.dart';
import '../services/geo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_pill.dart';

/// Hard cap on markers drawn at once — a safety net for whatever's in the
/// viewport at very low zoom (zoomed out to see a whole state/country).
/// Rendering the full unfiltered nationwide set (~3,100 AOs) as Marker
/// widgets simultaneously is what was freezing the screen before.
const _maxVisibleMarkers = 200;

/// What the map auto-fits to around the device's GPS position when no
/// filters are active.
const _nearbyRadiusMiles = 10.0;

const _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class BrowseAosScreen extends StatefulWidget {
  const BrowseAosScreen({super.key});

  @override
  State<BrowseAosScreen> createState() => _BrowseAosScreenState();
}

class _BrowseAosScreenState extends State<BrowseAosScreen> {
  final _searchCtrl = TextEditingController();
  final _mapController = MapController();

  // What's currently on-screen in the map viewport — markers are limited to
  // this (intersected with the search/filter results) instead of dragging
  // every matching AO nationwide onto the map at once. Zooming out grows
  // this, which is what reveals more pins.
  LatLngBounds? _visibleBounds;
  Timer? _boundsDebounce;
  bool _mapReady = false;

  bool _loading = true;
  bool _locating = false;
  String? _locationError;
  List<F3Location> _locations = [];
  Position? _position;
  String _query = '';

  String? _stateFilter;
  String? _weekdayFilter;
  String? _regionFilter;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _boundsDebounce?.cancel();
    super.dispose();
  }

  /// Debounced so a drag/zoom gesture (which fires this on every frame)
  /// doesn't trigger a setState + marker-list rebuild dozens of times a
  /// second — only once movement settles.
  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _visibleBounds = camera.visibleBounds);
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = context.read<F3ApiService>();
    final results = await Future.wait([
      api.getLocations(),
      api.getLocationSchedules(),
    ]);
    final locations = results[0] as List<F3Location>;
    final schedules = results[1]
        as Map<String, ({List<F3WeeklyWorkout> schedule, String? aoName})>;
    final merged = locations.map((loc) {
      final s = schedules[loc.id];
      return loc.withSchedule(s?.schedule ?? const [], aoName: s?.aoName);
    }).toList();
    if (!mounted) return;
    setState(() {
      _locations = merged;
      _loading = false;
    });
    _findMe();
  }

  // Cascading: picking a region narrows the state list to states that
  // region actually has AOs in, and vice versa.
  List<String> get _stateOptions {
    final base = _regionFilter == null
        ? _locations
        : _locations.where((l) => l.regionName == _regionFilter);
    return base
        .map((l) => l.state)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _regionOptions {
    final base = _stateFilter == null
        ? _locations
        : _locations.where((l) => l.state == _stateFilter);
    return base
        .map((l) => l.regionName)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _weekdayOptions => _weekdays
      .where((day) => _locations.any((l) =>
          l.schedule.any((w) => w.weekday.toLowerCase() == day)))
      .map((day) => day[0].toUpperCase() + day.substring(1))
      .toList();

  bool get _hasActiveFilters =>
      _stateFilter != null || _weekdayFilter != null || _regionFilter != null;

  Future<void> _findMe() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final position = await GeoService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _position = position;
      _locating = false;
      if (position == null) {
        _locationError =
            'Couldn\'t get your location — showing AOs alphabetically instead.';
      }
    });
    _refitMap();
  }

  double? _distanceMiles(F3Location loc) {
    final position = _position;
    if (position == null || loc.lat == null || loc.lon == null) return null;
    return GeoService.distanceMiles(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: loc.lat!,
      lon2: loc.lon!,
    );
  }

  List<F3Location> get _filtered {
    var list = _locations;
    if (_query.isNotEmpty) {
      list = list
          .where((loc) => loc.name.toLowerCase().contains(_query))
          .toList();
    }
    if (_stateFilter != null) {
      list = list.where((loc) => loc.state == _stateFilter).toList();
    }
    if (_regionFilter != null) {
      list = list.where((loc) => loc.regionName == _regionFilter).toList();
    }
    if (_weekdayFilter != null) {
      final day = _weekdayFilter!.toLowerCase();
      list = list
          .where((loc) =>
              loc.schedule.any((w) => w.weekday.toLowerCase() == day))
          .toList();
    }
    final sorted = [...list];
    if (_position != null) {
      sorted.sort((a, b) {
        final da = _distanceMiles(a);
        final db = _distanceMiles(b);
        if (da == null && db == null) return a.name.compareTo(b.name);
        if (da == null) return 1; // no coordinates (roving AO) sorts last
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    }
    return sorted;
  }

  /// AOs with real coordinates, in the same order as the filtered/sorted
  /// list — this order is what the numbered badges (list ⇄ map pin) key off.
  /// Roving AOs (no lat/lon) are excluded here but still show in the list
  /// below, just without a number.
  List<F3Location> get _mappable =>
      _filtered.where((l) => l.lat != null && l.lon != null).toList();

  /// 1-based badge number for [loc], or null if it has no coordinates (so
  /// it isn't on the map at all).
  int? _mapNumber(F3Location loc) {
    final index = _mappable.indexWhere((l) => l.id == loc.id);
    return index == -1 ? null : index + 1;
  }

  void _focusOnMap(F3Location loc) {
    if (loc.lat == null || loc.lon == null) return;
    _mapController.move(LatLng(loc.lat!, loc.lon!), 15);
  }

  static LatLngBounds _boundsForRadiusMiles(LatLng center, double miles) {
    final meters = miles * 1609.344;
    const d = Distance();
    return LatLngBounds.fromPoints([
      d.offset(center, meters, 0),
      d.offset(center, meters, 90),
      d.offset(center, meters, 180),
      d.offset(center, meters, 270),
    ]);
  }

  /// Moves the map to match what's actually relevant right now: with no
  /// filters active, that's a `_nearbyRadiusMiles` circle around the device
  /// (the "what's around me" view); with filters active, it's every
  /// matching AO's combined extent (there's no real state/region boundary
  /// polygon data available from the API, so "fit to the matching AOs'
  /// bounding box" is the practical stand-in for "show its perimeter").
  void _refitMap() {
    if (!_mapReady) return;
    final position = _position;
    if (_hasActiveFilters) {
      final pts = _mappable.map((l) => LatLng(l.lat!, l.lon!)).toList();
      if (pts.isEmpty) return;
      // A filter that matches AOs clustered tightly together (or just one)
      // produces a near-zero-size bounding box — fitting to that without a
      // maxZoom cap sends the camera to an extreme zoom with no tiles
      // available at all, which is what was rendering as a blank map.
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.all(32),
        maxZoom: 13,
      ));
    } else if (position != null) {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: _boundsForRadiusMiles(
            LatLng(position.latitude, position.longitude), _nearbyRadiusMiles),
        padding: const EdgeInsets.all(16),
        maxZoom: 13,
      ));
    }
  }

  /// Recenter on the device's GPS position: instant if we already have a
  /// recent fix (no reason to make the user wait on a fresh GPS request
  /// just to re-look at where they already know they are), otherwise
  /// kicks off a real location request — [_findMe] calls [_refitMap] once
  /// that resolves.
  void _recenterOnMe() {
    if (_position != null) {
      _refitMap();
    } else {
      _findMe();
    }
  }

  Future<void> _openInMaps(F3Location loc) async {
    if (loc.lat == null || loc.lon == null) return;
    final uri = Uri.parse('geo:${loc.lat},${loc.lon}?q=${loc.lat},${loc.lon}(${Uri.encodeComponent(loc.name)})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDetails(F3Location loc) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.f3card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _AoDetailSheet(location: loc, onOpenMaps: () => _openInMaps(loc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<F3ApiService>();

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Browse AOs'),
        backgroundColor: context.f3bg,
        actions: [
          IconButton(
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: 'Refresh my location',
            onPressed: _locating ? null : _findMe,
          ),
        ],
      ),
      body: !api.isConfigured
          ? const _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'F3 Nation API not configured',
              subtitle:
                  'This build isn\'t connected to the F3 Nation API, so AO data isn\'t available.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: context.f3textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search AOs',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: context.f3card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (_locations.isNotEmpty) _buildFilterBar(context),
                  if (!_loading && _mappable.isNotEmpty) _buildMap(context),
                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          color: context.f3textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                            ? _EmptyState(
                                icon: Icons.location_off_rounded,
                                title: 'No AOs found',
                                subtitle: _locations.isEmpty
                                    ? 'Couldn\'t load AOs — pull to refresh.'
                                    : 'No AOs match your search/filters.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: _filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final loc = _filtered[index];
                                  final distance = _distanceMiles(loc);
                                  return _AoTile(
                                    location: loc,
                                    distanceMiles: distance,
                                    mapNumber: _mapNumber(loc),
                                    onTap: () => _openDetails(loc),
                                    onTapNumber: () => _focusOnMap(loc),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
    );
  }

  /// AOs to actually draw as [Marker]s: whatever's inside the current map
  /// viewport (so zooming out reveals more, zooming in/panning narrows it),
  /// capped as a safety net, nearest-first, in case the viewport itself is
  /// huge (zoomed way out) and still contains hundreds of matches.
  List<F3Location> _visibleMarkersFor(List<F3Location> mappable) {
    final bounds = _visibleBounds;
    var visible = bounds == null
        ? mappable
        : mappable
            .where((l) => bounds.contains(LatLng(l.lat!, l.lon!)))
            .toList();
    if (visible.length > _maxVisibleMarkers) {
      final first = visible.first;
      final center = bounds?.center ??
          (_position != null
              ? LatLng(_position!.latitude, _position!.longitude)
              : LatLng(first.lat!, first.lon!));
      final byDistance = [...visible]
        ..sort((a, b) => const Distance()
            .distance(center, LatLng(a.lat!, a.lon!))
            .compareTo(
                const Distance().distance(center, LatLng(b.lat!, b.lon!))));
      visible = byDistance.take(_maxVisibleMarkers).toList();
    }
    return visible;
  }

  Widget _buildMap(BuildContext context) {
    final mappable = _mappable;
    final position = _position;
    final center = position != null
        ? LatLng(position.latitude, position.longitude)
        : LatLng(mappable.first.lat!, mappable.first.lon!);
    final visible = _visibleMarkersFor(mappable);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: position != null ? 12 : 10,
                  onMapReady: () {
                    _mapReady = true;
                    setState(
                        () => _visibleBounds = _mapController.camera.visibleBounds);
                    _refitMap();
                  },
                  onPositionChanged: _onMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.digitalweinke.f3_nation_app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (position != null)
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      for (final loc in visible)
                        Marker(
                          point: LatLng(loc.lat!, loc.lon!),
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            onTap: () => _openDetails(loc),
                            child: Container(
                              decoration: BoxDecoration(
                                color: F3Colors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_mapNumber(loc)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () =>
                            launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                ],
              ),
              if (mappable.length > visible.length)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Zoom out for more',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: context.f3card,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _recenterOnMe,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _locating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: F3Colors.accent, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          FilterPill(
            label: _stateFilter ?? 'State',
            active: _stateFilter != null,
            onTap: () async {
              final picked = await showFilterPickerSheet(context,
                  title: 'Filter by state',
                  options: _stateOptions,
                  current: _stateFilter);
              if (picked == null) return;
              setState(() {
                _stateFilter = picked.isEmpty ? null : picked;
                // Drop the region filter if it no longer has any AOs in the
                // newly-chosen state, so the two never silently AND into an
                // always-empty result.
                if (_regionFilter != null &&
                    !_regionOptions.contains(_regionFilter)) {
                  _regionFilter = null;
                }
              });
              _refitMap();
            },
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: _regionFilter ?? 'Region',
            active: _regionFilter != null,
            onTap: () async {
              final picked = await showFilterPickerSheet(context,
                  title: 'Filter by region',
                  options: _regionOptions,
                  current: _regionFilter);
              if (picked == null) return;
              setState(() {
                _regionFilter = picked.isEmpty ? null : picked;
                if (_stateFilter != null &&
                    !_stateOptions.contains(_stateFilter)) {
                  _stateFilter = null;
                }
              });
              _refitMap();
            },
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: _weekdayFilter ?? 'Day',
            active: _weekdayFilter != null,
            onTap: () async {
              final picked = await showFilterPickerSheet(context,
                  title: 'Filter by workout day',
                  options: _weekdayOptions,
                  current: _weekdayFilter);
              if (picked == null) return;
              setState(
                  () => _weekdayFilter = picked.isEmpty ? null : picked);
              _refitMap();
            },
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _stateFilter = null;
                  _regionFilter = null;
                  _weekdayFilter = null;
                });
                _refitMap();
              },
              child: const Text('Clear all'),
            ),
          ],
        ]),
      ),
    );
  }
}

class _AoTile extends StatelessWidget {
  final F3Location location;
  final double? distanceMiles;
  final int? mapNumber;
  final VoidCallback? onTap;
  final VoidCallback? onTapNumber;

  const _AoTile({
    required this.location,
    required this.distanceMiles,
    required this.onTap,
    this.mapNumber,
    this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: [
              GestureDetector(
                onTap: mapNumber != null ? onTapNumber : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: mapNumber != null
                      ? Text(
                          '$mapNumber',
                          style: const TextStyle(
                            color: F3Colors.accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : const Icon(Icons.shield_rounded,
                          color: F3Colors.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        color: context.f3textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (location.description != null &&
                        location.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          location.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.f3textSecondary, fontSize: 12),
                        ),
                      ),
                    if (location.schedule.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          location.schedule
                              .map((w) =>
                                  '${w.displayWeekday} ${w.displayTime}${w.eventTypeName != null ? ' · ${w.eventTypeName}' : ''}')
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: F3Colors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'No beatdowns scheduled yet',
                          style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              if (distanceMiles != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${distanceMiles!.toStringAsFixed(1)} mi',
                    style: const TextStyle(
                      color: F3Colors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: context.f3textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown on tapping an AO — mirrors the fields the F3 Nation admin's
/// AOs/Locations/Events tables show (region, address, weekly schedule),
/// plus the AO's and region's own org ids for cross-referencing elsewhere
/// (e.g. a Slack channel-id lookup).
class _AoDetailSheet extends StatelessWidget {
  final F3Location location;
  final VoidCallback onOpenMaps;
  const _AoDetailSheet({required this.location, required this.onOpenMaps});

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6)),
          ),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(color: context.f3textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressParts = [
      if (location.street != null && location.street!.isNotEmpty)
        location.street,
      if (location.city != null && location.city!.isNotEmpty) location.city,
      if (location.state != null && location.state!.isNotEmpty)
        location.state,
    ].join(', ');

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
          Text(location.aoName ?? location.name,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (location.regionName != null)
            _row(context, 'REGION', location.regionName!),
          if (addressParts.isNotEmpty) _row(context, 'ADDRESS', addressParts),
          if (location.description != null &&
              location.description!.isNotEmpty)
            _row(context, 'NOTES', location.description!),
          if (location.schedule.isNotEmpty)
            _row(
              context,
              'SCHEDULE',
              location.schedule
                  .map((w) =>
                      '${w.displayWeekday} ${w.displayTime}${w.eventTypeName != null ? ' · ${w.eventTypeName}' : ''}')
                  .join('\n'),
            )
          else
            _row(context, 'SCHEDULE', 'No beatdowns scheduled yet'),
          const SizedBox(height: 8),
          if (location.lat != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenMaps,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Open in Maps'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.f3textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.f3textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
