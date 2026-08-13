// lib/screens/emergency_edit_screen.dart
// Form to enter/edit emergency info. Always saves to the local encrypted
// store; contact name/phone/notes additionally best-effort sync with F3
// Nation's own user record when signed in (see EmergencyService's header
// comment for which fields and why only those three).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/emergency_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class EmergencyEditScreen extends StatefulWidget {
  const EmergencyEditScreen({super.key});

  @override
  State<EmergencyEditScreen> createState() => _EmergencyEditScreenState();
}

class _EmergencyEditScreenState extends State<EmergencyEditScreen> {
  late final Map<String, TextEditingController> _c;
  bool _organDonor = false;

  @override
  void initState() {
    super.initState();
    // Owner-scoped prefill: if this device's data belongs to a different
    // local/F3 identity than whoever is using it now, start blank rather
    // than silently editing (and re-saving under the new owner) a stranger's
    // medical info.
    final i = context
        .read<EmergencyService>()
        .infoFor(context.read<AppProfileService>().authUserId);
    _organDonor = i.organDonor;
    _c = {
      'contactName': TextEditingController(text: i.contactName),
      'contactRelationship':
          TextEditingController(text: i.contactRelationship),
      'contactPhone': TextEditingController(text: i.contactPhone),
      'syncNotes': TextEditingController(text: i.syncNotes),
      'bloodType': TextEditingController(text: i.bloodType),
      'allergies': TextEditingController(text: i.allergies),
      'conditions': TextEditingController(text: i.conditions),
      'medications': TextEditingController(text: i.medications),
      'preferredHospital': TextEditingController(text: i.preferredHospital),
      'aoName': TextEditingController(text: i.aoName),
      'aoLocation': TextEditingController(text: i.aoLocation),
      'nearestEr': TextEditingController(text: i.nearestEr),
      'aedLocation': TextEditingController(text: i.aedLocation),
      'emsAccessNotes': TextEditingController(text: i.emsAccessNotes),
    };

    // Best-effort prefill of the AO-site fields, life-safety form so worth
    // saving the retype: prefer today's "I'm at the flag" AO, else the
    // PAX's home AO, then try to resolve a real street address for it from
    // F3 Nation's own location data. Never overwrites data already saved.
    if (_c['aoName']!.text.isEmpty) {
      final settings = context.read<SettingsService>();
      final profile = context.read<AppProfileService>();
      final aoName = settings.atTheFlagAo ?? profile.homeAo;
      if (aoName.isNotEmpty) {
        _c['aoName']!.text = aoName;
        if (_c['aoLocation']!.text.isEmpty) _resolveAoAddress(aoName);
      }
    }

    // Best-effort prefill of the F3-Nation-synced fields from the PAX's own
    // profile — same "never overwrite what's already saved locally" rule as
    // the AO-address prefill above.
    if (_c['contactName']!.text.isEmpty ||
        _c['contactPhone']!.text.isEmpty ||
        _c['syncNotes']!.text.isEmpty ||
        _c['bloodType']!.text.isEmpty ||
        _c['allergies']!.text.isEmpty ||
        _c['conditions']!.text.isEmpty ||
        _c['medications']!.text.isEmpty ||
        _c['preferredHospital']!.text.isEmpty ||
        !_organDonor) {
      _prefillFromF3Profile();
    }
  }

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

  Future<void> _prefillFromF3Profile() async {
    try {
      final auth = context.read<AuthService>();
      if (!_isLinked(auth)) return;
      final token = await auth.getF3AccessToken();
      if (token == null || !mounted) return;
      final profile =
          await context.read<F3ApiService>().getMyProfile(userAccessToken: token);
      if (profile == null || !mounted) return;
      if (_c['contactName']!.text.isEmpty &&
          (profile.emergencyContact ?? '').isNotEmpty) {
        _c['contactName']!.text = profile.emergencyContact!;
      }
      if (_c['contactPhone']!.text.isEmpty &&
          (profile.emergencyPhone ?? '').isNotEmpty) {
        _c['contactPhone']!.text = profile.emergencyPhone!;
      }
      if (_c['syncNotes']!.text.isEmpty &&
          (profile.emergencyNotes ?? '').isNotEmpty) {
        _c['syncNotes']!.text = profile.emergencyNotes!;
      }
      if (_c['bloodType']!.text.isEmpty && (profile.bloodType ?? '').isNotEmpty) {
        _c['bloodType']!.text = profile.bloodType!;
      }
      if (_c['allergies']!.text.isEmpty && (profile.allergies ?? '').isNotEmpty) {
        _c['allergies']!.text = profile.allergies!;
      }
      if (_c['conditions']!.text.isEmpty &&
          (profile.medicalConditions ?? '').isNotEmpty) {
        _c['conditions']!.text = profile.medicalConditions!;
      }
      if (_c['medications']!.text.isEmpty &&
          (profile.medications ?? '').isNotEmpty) {
        _c['medications']!.text = profile.medications!;
      }
      if (_c['preferredHospital']!.text.isEmpty &&
          (profile.preferredHospital ?? '').isNotEmpty) {
        _c['preferredHospital']!.text = profile.preferredHospital!;
      }
      if (!_organDonor && profile.organDonor == true && mounted) {
        setState(() => _organDonor = true);
      }
    } catch (_) {
      // Best-effort only — fields just stay as they were for manual entry.
    }
  }

  Future<void> _resolveAoAddress(String aoName) async {
    try {
      final locations = await context.read<F3ApiService>().getLocations();
      for (final loc in locations) {
        final name = loc.aoName ?? loc.name;
        if (name.toLowerCase() != aoName.toLowerCase()) continue;
        final parts = [loc.street, loc.city, loc.state]
            .where((p) => p != null && p.isNotEmpty)
            .join(', ');
        if (parts.isNotEmpty && mounted && _c['aoLocation']!.text.isEmpty) {
          _c['aoLocation']!.text = parts;
        }
        break;
      }
    } catch (_) {
      // Best-effort only — the field just stays blank for manual entry.
    }
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final info = EmergencyInfo(
      contactName: _c['contactName']!.text.trim(),
      contactRelationship: _c['contactRelationship']!.text.trim(),
      contactPhone: _c['contactPhone']!.text.trim(),
      syncNotes: _c['syncNotes']!.text.trim(),
      bloodType: _c['bloodType']!.text.trim(),
      allergies: _c['allergies']!.text.trim(),
      conditions: _c['conditions']!.text.trim(),
      medications: _c['medications']!.text.trim(),
      preferredHospital: _c['preferredHospital']!.text.trim(),
      organDonor: _organDonor,
      aoName: _c['aoName']!.text.trim(),
      aoLocation: _c['aoLocation']!.text.trim(),
      nearestEr: _c['nearestEr']!.text.trim(),
      aedLocation: _c['aedLocation']!.text.trim(),
      emsAccessNotes: _c['emsAccessNotes']!.text.trim(),
      ownerId: context.read<AppProfileService>().authUserId,
    );
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final authUserId = context.read<AppProfileService>().authUserId;
    await context.read<EmergencyService>().save(info);
    unawaited(_pushSyncedFields(
      auth: auth,
      api: api,
      authUserId: authUserId,
      contactName: info.contactName,
      contactPhone: info.contactPhone,
      syncNotes: info.syncNotes,
      bloodType: info.bloodType,
      allergies: info.allergies,
      conditions: info.conditions,
      medications: info.medications,
      preferredHospital: info.preferredHospital,
      organDonor: info.organDonor,
    ));
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Emergency info saved (on this device).')),
    );
    nav.pop();
  }

  /// Best-effort push of the F3-Nation-synced fields — never blocks the save
  /// or surfaces a failure to the user; a life-safety form shouldn't stall
  /// or error out on a flaky connection when the data it actually needs is
  /// already safely on-device.
  Future<void> _pushSyncedFields({
    required AuthService auth,
    required F3ApiService api,
    required String authUserId,
    required String contactName,
    required String contactPhone,
    required String syncNotes,
    required String bloodType,
    required String allergies,
    required String conditions,
    required String medications,
    required String preferredHospital,
    required bool organDonor,
  }) async {
    try {
      if (!_isLinked(auth)) return;
      final userId = int.tryParse(authUserId);
      if (userId == null) return;
      await api.updateUserProfile(
        userId: userId,
        emergencyContact: contactName,
        emergencyPhone: contactPhone,
        emergencyNotes: syncNotes,
      );

      // The less-common fields go in `meta` instead of real columns (per
      // Tackle, 2026-08-13) — only through the user's own token, since
      // that's the only endpoint that merges into meta rather than
      // overwriting it (see updateMyMeta). Only non-empty fields are sent,
      // and organDonor only when there's other medical data too, so a
      // blank/untouched form never pushes a false that could stomp a real
      // "yes" saved elsewhere (e.g. a future F3 Me UI for this).
      final meta = <String, dynamic>{
        if (bloodType.isNotEmpty) 'blood_type': bloodType,
        if (allergies.isNotEmpty) 'allergies': allergies,
        if (conditions.isNotEmpty) 'medical_conditions': conditions,
        if (medications.isNotEmpty) 'medications': medications,
        if (preferredHospital.isNotEmpty) 'preferred_hospital': preferredHospital,
        if (organDonor ||
            bloodType.isNotEmpty ||
            allergies.isNotEmpty ||
            conditions.isNotEmpty ||
            medications.isNotEmpty ||
            preferredHospital.isNotEmpty)
          'organ_donor': organDonor,
      };
      if (meta.isEmpty) return;
      final token = await auth.getF3AccessToken();
      if (token == null) return;
      await api.updateMyMeta(userAccessToken: token, meta: meta);
    } catch (_) {
      // Best-effort only.
    }
  }

  Widget _field(String key, String label, {int maxLines = 1, TextInputType? kb}) {
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
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text('Edit Emergency Info'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
              'Fields marked (synced) sync to your F3 Nation profile — '
              'contact name/phone as real profile fields, the rest as '
              'freeform notes any F3 Nation app can read. Everything else '
              'on this screen stays on this device only, encrypted.',
              style: TextStyle(color: context.f3textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          _Header('Personal Medical'),
          _field('contactName', 'Emergency contact name (synced)'),
          _field('contactRelationship', 'Relationship'),
          _field('contactPhone', 'Contact phone (synced)',
              kb: TextInputType.phone),
          _field('syncNotes', 'Notes (synced)', maxLines: 2),
          _field('bloodType', 'Blood type (synced)'),
          _field('allergies', 'Allergies (synced)', maxLines: 2),
          _field('conditions', 'Medical conditions (synced)', maxLines: 2),
          _field('medications', 'Current medications (synced)', maxLines: 2),
          _field('preferredHospital', 'Preferred hospital (synced)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _organDonor,
            onChanged: (v) => setState(() => _organDonor = v),
            title: Text('Organ donor (synced)',
                style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          _Header('AO-Site Emergency'),
          _field('aoName', 'AO name'),
          _field('aoLocation', 'Exact location (address / GPS / what3words)',
              maxLines: 2),
          _field('nearestEr', 'Nearest ER'),
          _field('aedLocation', 'Closest AED location'),
          _field('emsAccessNotes', 'EMS access notes (gate codes, entrance)',
              maxLines: 2),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      );
}
