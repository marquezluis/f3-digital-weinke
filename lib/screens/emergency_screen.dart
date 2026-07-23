// lib/screens/emergency_screen.dart
// Emergency information — reachable with NO sign-in, NO biometric, NO network,
// from the login gate. In an emergency a bystander or medic must open this
// instantly. Data comes from the local encrypted store (EmergencyService).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_profile_service.dart';
import '../services/emergency_service.dart';
import '../theme/app_theme.dart';
import 'emergency_edit_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // Personal-medical fields only — the AO-site section is about a location,
  // not the PAX, so it's left out of a "share my emergency card" send.
  void _share(BuildContext context, EmergencyInfo i) {
    final buf = StringBuffer()..writeln('EMERGENCY INFO');
    final contact = _join([i.contactName, i.contactRelationship]);
    if (contact.isNotEmpty || i.contactPhone.isNotEmpty) {
      buf.writeln(
          'Contact: $contact${i.contactPhone.isNotEmpty ? ' (${i.contactPhone})' : ''}');
    }
    if (i.bloodType.isNotEmpty) buf.writeln('Blood type: ${i.bloodType}');
    if (i.allergies.isNotEmpty) buf.writeln('Allergies: ${i.allergies}');
    if (i.conditions.isNotEmpty) buf.writeln('Conditions: ${i.conditions}');
    if (i.medications.isNotEmpty) {
      buf.writeln('Medications: ${i.medications}');
    }
    if (i.preferredHospital.isNotEmpty) {
      buf.writeln('Preferred hospital: ${i.preferredHospital}');
    }
    if (i.organDonor) buf.writeln('Organ donor: Yes');
    Share.share(buf.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text('Emergency Info'),
        actions: [
          Consumer2<EmergencyService, AppProfileService>(
            builder: (context, svc, profile, _) {
              final i = svc.infoFor(profile.authUserId);
              if (!i.hasMedical) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share with a fellow PAX',
                onPressed: () => _share(context, i),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyEditScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<EmergencyService, AppProfileService>(
        builder: (context, svc, profile, _) {
          // Owner-scoped: never show a different PAX's medical info just
          // because this device is locked/signed-out and someone else is
          // now using it (or the current PAX signed back in as themselves).
          final i = svc.infoFor(profile.authUserId);
          final belongsToSomeoneElse = svc.info.ownerId.isNotEmpty &&
              svc.info.ownerId != profile.authUserId;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (belongsToSomeoneElse)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'This device has emergency info saved for a different '
                    'PAX. Nothing shows below until you add your own.',
                    style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              _Card(
                icon: Icons.medical_services_rounded,
                title: 'Personal Medical',
                empty: !i.hasMedical,
                emptyText:
                    'No medical info saved yet. Tap edit (top right) to add '
                    'emergency contact, blood type, allergies, conditions, '
                    'medications, and preferred hospital.',
                rows: [
                  _Row('Contact', _join([i.contactName, i.contactRelationship])),
                  _Row('Phone', i.contactPhone, isPhone: true),
                  _Row('Blood type', i.bloodType),
                  _Row('Allergies', i.allergies),
                  _Row('Conditions', i.conditions),
                  _Row('Medications', i.medications),
                  _Row('Hospital', i.preferredHospital),
                  _Row('Organ donor', i.organDonor ? 'Yes' : ''),
                ],
              ),
              const SizedBox(height: 12),
              _Card(
                icon: Icons.place_rounded,
                title: 'AO-Site Emergency',
                empty: !i.hasAoSite,
                emptyText:
                    'No AO emergency info saved yet. Add the exact site '
                    'location, nearest ER, closest AED, and EMS access notes.',
                rows: [
                  _Row('AO', i.aoName),
                  _Row('Location', i.aoLocation),
                  _Row('Nearest ER', i.nearestEr),
                  _Row('AED', i.aedLocation),
                  _Row('EMS access', i.emsAccessNotes),
                ],
              ),
              const SizedBox(height: 12),
              _Card(
                icon: Icons.phonelink_lock_rounded,
                title: 'Locked-phone access',
                empty: false,
                rows: const [],
                child: Text(
                  'If your phone is locked by iOS/Android, apps can\'t show info '
                  'on the lock screen. Also fill out your device\'s built-in '
                  'Medical ID (iOS Health) or Emergency information (Android) so '
                  'a stranger can reach it there too.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _join(List<String> parts) =>
      parts.where((s) => s.trim().isNotEmpty).join(' · ');
}

class _Row {
  final String label;
  final String value;
  final bool isPhone;
  const _Row(this.label, this.value, {this.isPhone = false});
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool empty;
  final String? emptyText;
  final List<_Row> rows;
  final Widget? child;
  const _Card({
    required this.icon,
    required this.title,
    required this.empty,
    this.emptyText,
    this.rows = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.value.trim().isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          if (child != null)
            DefaultTextStyle.merge(
              style: TextStyle(color: context.f3textSecondary, fontSize: 13),
              child: child!,
            )
          else if (empty)
            Text(emptyText ?? 'Nothing saved yet.',
                style: TextStyle(color: context.f3textSecondary, height: 1.5))
          else
            ...visible.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(r.label,
                            style: TextStyle(
                                color: context.f3textMuted, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text(
                          r.value,
                          style: TextStyle(
                              color: r.isPhone
                                  ? F3Colors.accent
                                  : context.f3textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
