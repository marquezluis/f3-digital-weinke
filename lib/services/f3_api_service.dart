// lib/services/f3_api_service.dart
// F3 Nation REST API client. All methods return null/empty on failure so
// callers can fall back to local data without crashing.
//
// The API key is baked in at build time via --dart-define=F3_API_KEY=...
// It is never stored on-device or exposed through any UI.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/f3_api_models.dart';

class F3ApiService extends ChangeNotifier {
  static const _base = 'https://api.f3nation.com';
  static const _client = 'f3-digital-weinke';

  // Compile-time constants injected via --dart-define
  static const _apiKey = String.fromEnvironment('F3_API_KEY');
  static const _orgIdEnv = String.fromEnvironment('F3_API_ORG_ID');

  String? get orgId => _orgIdEnv.isNotEmpty ? _orgIdEnv : null;

  bool get isConfigured => _apiKey.isNotEmpty;

  F3UserProfile? _myProfile;
  F3UserProfile? get myProfile => _myProfile;

  // No-op — kept so main.dart callers don't need to change
  Future<void> load() async {}

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
    final path = orgId != null
        ? '/v1/event-instance/calendar-home-schedule?orgId=$orgId'
        : '/v1/event-instance/calendar-home-schedule';
    final data = await _getList(path);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<F3EventInstance>> getOpenQSlots() async {
    final path = orgId != null
        ? '/v1/event-instance/without-q?orgId=$orgId'
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

  // ── Slack messaging ───────────────────────────────────────────────────────

  /// Posts a message to a region's Slack channel via the F3 Nation Slack app.
  /// [regionOrgId] is the org ID for the region (from F3_API_ORG_ID dart-define).
  /// [channelId]   is the Slack channel ID (e.g. C0XXXXXXXX), user-configured.
  /// Returns null on success, or an error string on failure.
  Future<String?> postSlackMessage({
    required String regionOrgId,
    required String channelId,
    required String text,
  }) async {
    if (!isConfigured) return 'F3 Nation API key not configured.';
    try {
      final res = await http
          .post(
            Uri.parse('$_base/v1/slack/message'),
            headers: _headers,
            body: json.encode({
              'regionOrgId': regionOrgId,
              'slackChannelId': channelId,
              'text': text,
              'mrkdwn': true,
              'username': 'Digital Weinke',
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return 'API error ${res.statusCode}: ${res.body}';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // ── Health check ─────────────────────────────────────────────────────────

  Future<bool> ping() async {
    final data = await _get('/v1/ping');
    return data != null;
  }
}
