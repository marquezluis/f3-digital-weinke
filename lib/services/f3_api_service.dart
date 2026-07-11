// lib/services/f3_api_service.dart
// F3 Nation REST API client. All methods return null/empty on failure so
// callers can fall back to local data without crashing.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/f3_api_models.dart';

class F3ApiService extends ChangeNotifier {
  static const _base = 'https://api.f3nation.com';
  static const _client = 'f3-digital-weinke';
  static const _keyApiKey = 'f3_api_key';
  static const _keyOrgId = 'f3_api_org_id';

  String? _apiKey;
  String? _orgId;
  F3UserProfile? _myProfile;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  String? get orgId => _orgId;
  F3UserProfile? get myProfile => _myProfile;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_keyApiKey);
    _orgId = prefs.getString(_keyOrgId);
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim().isEmpty ? null : key.trim();
    _myProfile = null;
    final prefs = await SharedPreferences.getInstance();
    if (_apiKey != null) {
      await prefs.setString(_keyApiKey, _apiKey!);
    } else {
      await prefs.remove(_keyApiKey);
    }
    notifyListeners();
  }

  Future<void> setOrgId(String? id) async {
    _orgId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_keyOrgId, id);
    } else {
      await prefs.remove(_keyOrgId);
    }
    notifyListeners();
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Client': _client,
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>?> _get(String path) async {
    if (!isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> _getList(String path) async {
    if (!isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is List) return body;
        if (body is Map && body['data'] is List) return body['data'] as List;
      }
    } catch (_) {}
    return null;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<F3UserProfile?> getMyProfile() async {
    final data = await _get('/v1/me/profile');
    if (data == null) return null;
    _myProfile = F3UserProfile.fromJson(data);
    notifyListeners();
    return _myProfile;
  }

  Future<F3UserProfile?> findPaxByF3Name(String f3Name) async {
    final data =
        await _get('/v1/user/f3name/${Uri.encodeComponent(f3Name)}');
    if (data == null) return null;
    return F3UserProfile.fromJson(data);
  }

  // ── Locations / AOs ───────────────────────────────────────────────────────

  Future<List<F3Location>> getLocations() async {
    final data = await _getList('/v1/location');
    if (data == null) return [];
    return data
        .map((e) => F3Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // One call that returns all regions + AOs + events for the map.
  Future<List<F3Location>> getMapLocations() async {
    final data = await _get('/v1/map/location/events-and-locations');
    if (data == null) return [];
    final list = data['locations'] as List<dynamic>? ?? [];
    return list
        .map((e) => F3Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Events / Beatdowns ────────────────────────────────────────────────────

  Future<List<F3EventInstance>> getUpcomingBeatdowns() async {
    final path = _orgId != null
        ? '/v1/event-instance/calendar-home-schedule?orgId=$_orgId'
        : '/v1/event-instance/calendar-home-schedule';
    final data = await _getList(path);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<F3EventInstance>> getOpenQSlots() async {
    final path = _orgId != null
        ? '/v1/event-instance/without-q?orgId=$_orgId'
        : '/v1/event-instance/without-q';
    final data = await _getList(path);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Orgs / Regions ────────────────────────────────────────────────────────

  Future<List<F3Org>> getOrgs() async {
    final data = await _getList('/v1/org');
    if (data == null) return [];
    return data
        .map((e) => F3Org.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Health check ─────────────────────────────────────────────────────────

  Future<bool> ping() async {
    final data = await _get('/v1/ping');
    return data != null;
  }
}
