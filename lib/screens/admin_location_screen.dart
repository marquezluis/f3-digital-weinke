// lib/screens/admin_location_screen.dart
// Native admin screen for editing an AO's Location — the first slice of the
// in-app admin UI, writing directly to the real F3 Nation admin API
// (`POST /v1/location`, requires editor role for the location's
// organization). Entry point is gated in Settings' "Admin Tools" section,
// which already only shows to editor/admin roles.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/f3_api_models.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../theme/app_theme.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  bool _loading = true;
  String? _error;
  List<F3Location> _locations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final token = await auth.getF3AccessToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't verify your F3 Nation sign-in.";
      });
      return;
    }
    final locations = await api.getMyLocations(token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _locations = locations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Edit AO Location'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded, color: context.f3textMuted, size: 40),
        const SizedBox(height: 12),
        Center(
          child: Text(_error!,
              style: TextStyle(color: context.f3textMuted, fontSize: 14)),
        ),
      ]);
    }
    if (_locations.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Icon(Icons.location_off_rounded, color: context.f3textMuted, size: 40),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "No locations found with editor/admin access on your account.",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.f3textMuted, fontSize: 14),
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final loc = _locations[i];
        return Container(
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.f3divider),
          ),
          child: ListTile(
            leading: Icon(Icons.location_on_rounded,
                color: loc.isActive ? F3Colors.accent : context.f3textMuted),
            title: Text(loc.name.isEmpty ? '(unnamed location)' : loc.name,
                style: TextStyle(
                    color: context.f3textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text(
              [loc.street, loc.city, loc.state]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(', '),
              style: TextStyle(color: context.f3textMuted, fontSize: 12),
            ),
            trailing: !loc.isActive
                ? Text('INACTIVE',
                    style: TextStyle(
                        color: context.f3textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700))
                : const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminEditLocationScreen(location: loc),
                ),
              );
              if (saved == true) _load();
            },
          ),
        );
      },
    );
  }
}

class AdminEditLocationScreen extends StatefulWidget {
  final F3Location location;
  const AdminEditLocationScreen({super.key, required this.location});

  @override
  State<AdminEditLocationScreen> createState() =>
      _AdminEditLocationScreenState();
}

class _AdminEditLocationScreenState extends State<AdminEditLocationScreen> {
  late final Map<String, TextEditingController> _c;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _isActive = loc.isActive;
    _c = {
      'name': TextEditingController(text: loc.name),
      'description': TextEditingController(text: loc.description ?? ''),
      'latitude': TextEditingController(text: loc.lat?.toString() ?? ''),
      'longitude': TextEditingController(text: loc.lon?.toString() ?? ''),
      'addressStreet': TextEditingController(text: loc.street ?? ''),
      'addressStreet2': TextEditingController(text: loc.addressStreet2 ?? ''),
      'addressCity': TextEditingController(text: loc.city ?? ''),
      'addressState': TextEditingController(text: loc.state ?? ''),
      'addressZip': TextEditingController(text: loc.addressZip ?? ''),
      'addressCountry': TextEditingController(text: loc.addressCountry ?? ''),
      'email': TextEditingController(text: loc.email ?? ''),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String? _orNull(String key) {
    final v = _c[key]!.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    final name = _c['name']!.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Location name is required.');
      return;
    }
    final locId = int.tryParse(widget.location.id);
    final orgId = int.tryParse(widget.location.orgId);
    if (locId == null || orgId == null) {
      setState(() => _error = "This location is missing an id the API needs — can't save.");
      return;
    }
    double? lat, lon;
    final latText = _c['latitude']!.text.trim();
    final lonText = _c['longitude']!.text.trim();
    if (latText.isNotEmpty) {
      lat = double.tryParse(latText);
      if (lat == null) {
        setState(() => _error = 'Latitude must be a number.');
        return;
      }
    }
    if (lonText.isNotEmpty) {
      lon = double.tryParse(lonText);
      if (lon == null) {
        setState(() => _error = 'Longitude must be a number.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final token = await auth.getF3AccessToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Couldn't verify your F3 Nation sign-in.";
      });
      return;
    }

    final result = await api.updateLocation(
      userAccessToken: token,
      id: locId,
      orgId: orgId,
      name: name,
      isActive: _isActive,
      description: _orNull('description'),
      latitude: lat,
      longitude: lon,
      addressStreet: _orNull('addressStreet'),
      addressStreet2: _orNull('addressStreet2'),
      addressCity: _orNull('addressCity'),
      addressState: _orNull('addressState'),
      addressZip: _orNull('addressZip'),
      addressCountry: _orNull('addressCountry'),
      email: _orNull('email'),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _saving = false;
        _error = result;
      });
      return;
    }
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.location.name} saved.')),
    );
  }

  Widget _field(String key, String label,
      {int maxLines = 1, TextInputType? kb}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        maxLines: maxLines,
        keyboardType: kb,
        style: TextStyle(color: context.f3textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.f3textSecondary, fontSize: 13),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(widget.location.name),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('SAVE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Writes directly to the F3 Nation admin API — changes are live for '
            'everyone immediately, same as editing in admin.f3nation.com.',
            style: TextStyle(color: context.f3textMuted, fontSize: 12),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: F3Colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: TextStyle(color: F3Colors.accent, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          _field('name', 'Location name'),
          _field('description', 'Description', maxLines: 3),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: Text('Active',
                style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          _field('addressStreet', 'Street address'),
          _field('addressStreet2', 'Street address 2'),
          _field('addressCity', 'City'),
          _field('addressState', 'State'),
          _field('addressZip', 'ZIP'),
          _field('addressCountry', 'Country'),
          _field('latitude', 'Latitude',
              kb: const TextInputType.numberWithOptions(signed: true, decimal: true)),
          _field('longitude', 'Longitude',
              kb: const TextInputType.numberWithOptions(signed: true, decimal: true)),
          _field('email', 'Contact email', kb: TextInputType.emailAddress),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
