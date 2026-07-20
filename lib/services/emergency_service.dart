// lib/services/emergency_service.dart
// Local, encrypted store for emergency info. Deliberately NOT synced to any
// server (sensitive PHI) — it lives only in the device's secure storage and is
// readable from the login gate without signing in.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@immutable
class EmergencyInfo {
  // Personal medical
  final String contactName;
  final String contactRelationship;
  final String contactPhone;
  final String bloodType;
  final String allergies;
  final String conditions;
  final String medications;
  final String preferredHospital;
  final bool organDonor;
  // AO-site
  final String aoName;
  final String aoLocation; // address / GPS / what3words
  final String nearestEr;
  final String aedLocation;
  final String emsAccessNotes;

  // Whose data this is (AppProfileService.authUserId at save time — a local
  // guest UUID pre-link, or the real F3 numeric id once signed in). Lets the
  // service tell "still me, just locked" apart from "a different person is
  // using this device now" so one PAX's medical info never displays as if
  // it belonged to whoever is currently signed in. Empty means legacy data
  // saved before this field existed — treated as always-current so nobody's
  // existing info silently vanishes.
  final String ownerId;

  const EmergencyInfo({
    this.contactName = '',
    this.contactRelationship = '',
    this.contactPhone = '',
    this.bloodType = '',
    this.allergies = '',
    this.conditions = '',
    this.medications = '',
    this.preferredHospital = '',
    this.organDonor = false,
    this.aoName = '',
    this.aoLocation = '',
    this.nearestEr = '',
    this.aedLocation = '',
    this.emsAccessNotes = '',
    this.ownerId = '',
  });

  bool get hasMedical =>
      [contactName, contactPhone, bloodType, allergies, conditions, medications, preferredHospital]
          .any((s) => s.trim().isNotEmpty) ||
      organDonor;

  bool get hasAoSite =>
      [aoName, aoLocation, nearestEr, aedLocation, emsAccessNotes]
          .any((s) => s.trim().isNotEmpty);

  EmergencyInfo copyWith(Map<String, dynamic> f) => EmergencyInfo(
        contactName: f['contactName'] ?? contactName,
        contactRelationship: f['contactRelationship'] ?? contactRelationship,
        contactPhone: f['contactPhone'] ?? contactPhone,
        bloodType: f['bloodType'] ?? bloodType,
        allergies: f['allergies'] ?? allergies,
        conditions: f['conditions'] ?? conditions,
        medications: f['medications'] ?? medications,
        preferredHospital: f['preferredHospital'] ?? preferredHospital,
        organDonor: f['organDonor'] ?? organDonor,
        aoName: f['aoName'] ?? aoName,
        aoLocation: f['aoLocation'] ?? aoLocation,
        nearestEr: f['nearestEr'] ?? nearestEr,
        aedLocation: f['aedLocation'] ?? aedLocation,
        emsAccessNotes: f['emsAccessNotes'] ?? emsAccessNotes,
        ownerId: f['ownerId'] ?? ownerId,
      );

  Map<String, dynamic> toJson() => {
        'contactName': contactName,
        'contactRelationship': contactRelationship,
        'contactPhone': contactPhone,
        'bloodType': bloodType,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
        'preferredHospital': preferredHospital,
        'organDonor': organDonor,
        'aoName': aoName,
        'aoLocation': aoLocation,
        'nearestEr': nearestEr,
        'aedLocation': aedLocation,
        'emsAccessNotes': emsAccessNotes,
        'ownerId': ownerId,
      };

  factory EmergencyInfo.fromJson(Map<String, dynamic> j) => EmergencyInfo(
        contactName: j['contactName'] ?? '',
        contactRelationship: j['contactRelationship'] ?? '',
        contactPhone: j['contactPhone'] ?? '',
        bloodType: j['bloodType'] ?? '',
        allergies: j['allergies'] ?? '',
        conditions: j['conditions'] ?? '',
        medications: j['medications'] ?? '',
        preferredHospital: j['preferredHospital'] ?? '',
        organDonor: j['organDonor'] ?? false,
        aoName: j['aoName'] ?? '',
        aoLocation: j['aoLocation'] ?? '',
        nearestEr: j['nearestEr'] ?? '',
        aedLocation: j['aedLocation'] ?? '',
        emsAccessNotes: j['emsAccessNotes'] ?? '',
        ownerId: j['ownerId'] ?? '',
      );
}

class EmergencyService extends ChangeNotifier {
  static const _key = 'emergency_info_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  EmergencyInfo _info = const EmergencyInfo();

  /// Raw stored data regardless of owner — only the editor should use this
  /// (it needs to see existing values to prefill the form for re-saving
  /// under the new owner). Anything display-only should use [infoFor].
  EmergencyInfo get info => _info;

  /// The data if it belongs to [currentOwnerId] (or was saved before
  /// ownership tracking existed), else a blank [EmergencyInfo] — so a
  /// locked/logged-out screen never displays a *different* PAX's medical
  /// info as though it were the current device user's. Pass the current
  /// `AppProfileService.authUserId` (works whether or not anyone's actually
  /// signed in to F3 Nation — it's a local id either way).
  EmergencyInfo infoFor(String currentOwnerId) {
    if (_info.ownerId.isEmpty || _info.ownerId == currentOwnerId) return _info;
    return const EmergencyInfo();
  }

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        _info = EmergencyInfo.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      // Corrupt/unreadable — fall back to empty rather than blocking access.
    }
  }

  Future<void> save(EmergencyInfo info) async {
    _info = info;
    notifyListeners();
    await _storage.write(key: _key, value: jsonEncode(info.toJson()));
  }
}
