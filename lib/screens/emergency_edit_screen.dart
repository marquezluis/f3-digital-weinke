// lib/screens/emergency_edit_screen.dart
// Form to enter/edit emergency info. Saves to the local encrypted store only.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_profile_service.dart';
import '../services/emergency_service.dart';
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
    await context.read<EmergencyService>().save(info);
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Emergency info saved (on this device).')),
    );
    nav.pop();
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
          Text('Stored only on this device, encrypted. Never sent to any server.',
              style: TextStyle(color: context.f3textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          _Header('Personal Medical'),
          _field('contactName', 'Emergency contact name'),
          _field('contactRelationship', 'Relationship'),
          _field('contactPhone', 'Contact phone', kb: TextInputType.phone),
          _field('bloodType', 'Blood type'),
          _field('allergies', 'Allergies', maxLines: 2),
          _field('conditions', 'Medical conditions', maxLines: 2),
          _field('medications', 'Current medications', maxLines: 2),
          _field('preferredHospital', 'Preferred hospital'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _organDonor,
            onChanged: (v) => setState(() => _organDonor = v),
            title: Text('Organ donor',
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
