// lib/screens/browse_aos_screen.dart
// Browse F3 Nation AOs pulled from the live API, optionally sorted by
// distance from the device's current location. Read-only — no writes to
// F3 Nation, so this is safe to ship without any of the auth/permission
// caveats that apply to the future "publish backblast" feature.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/f3_api_models.dart';
import '../services/f3_api_service.dart';
import '../services/geo_service.dart';
import '../theme/app_theme.dart';

class BrowseAosScreen extends StatefulWidget {
  const BrowseAosScreen({super.key});

  @override
  State<BrowseAosScreen> createState() => _BrowseAosScreenState();
}

class _BrowseAosScreenState extends State<BrowseAosScreen> {
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _locating = false;
  String? _locationError;
  List<F3Location> _locations = [];
  Position? _position;
  String _query = '';

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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final locations = await context.read<F3ApiService>().getMapLocations();
    if (!mounted) return;
    setState(() {
      _locations = locations;
      _loading = false;
    });
    _findMe();
  }

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

  Future<void> _openInMaps(F3Location loc) async {
    if (loc.lat == null || loc.lon == null) return;
    final uri = Uri.parse('geo:${loc.lat},${loc.lon}?q=${loc.lat},${loc.lon}(${Uri.encodeComponent(loc.name)})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
            tooltip: 'Sort by distance',
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
                                    : 'No AOs match "$_query".',
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
                                    onTap: loc.lat != null
                                        ? () => _openInMaps(loc)
                                        : null,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AoTile extends StatelessWidget {
  final F3Location location;
  final double? distanceMiles;
  final VoidCallback? onTap;

  const _AoTile({
    required this.location,
    required this.distanceMiles,
    required this.onTap,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: F3Colors.accent, size: 22),
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
                )
              else if (onTap == null)
                Icon(Icons.route_rounded, color: context.f3textMuted, size: 18),
            ],
          ),
        ),
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
