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
  // Override with --dart-define=F3_API_BASE_URL=https://staging.api.f3nation.com
  // for end-to-end testing against the staging stack (pairs with
  // F3_AUTH_ISSUER=https://staging.auth2.f3nation.com — staging-issued OAuth
  // JWTs only verify against the staging API's JWKS lookup, not prod).
  static const _base = String.fromEnvironment(
    'F3_API_BASE_URL',
    defaultValue: 'https://api.f3nation.com',
  );
  static const _client = 'f3-digital-weinke';

  // Compile-time constants injected via --dart-define
  static const _apiKey = String.fromEnvironment('F3_API_KEY');
  static const _orgIdEnv = String.fromEnvironment('F3_API_ORG_ID');

  // Set at runtime from the signed-in user's home region (via applyF3Profile).
  // Prefer it over the build-time default so each PAX gets their own region
  // for upcoming-beatdown filtering and Slack routing, instead of one org
  // baked into the build.
  String? _userOrgId;
  set userOrgId(String? value) {
    if (value == _userOrgId) return;
    _userOrgId = (value != null && value.isNotEmpty) ? value : null;
    notifyListeners();
  }

  String? get orgId =>
      _userOrgId ?? (_orgIdEnv.isNotEmpty ? _orgIdEnv : null);

  bool get isConfigured => _apiKey.isNotEmpty;

  F3UserProfile? _myProfile;
  F3UserProfile? get myProfile => _myProfile;

  // No-op — kept so main.dart callers don't need to change
  Future<void> load() async {}

  Map<String, String> _headers([String? bearerOverride]) => {
        'Authorization': 'Bearer ${bearerOverride ?? _apiKey}',
        'Client': _client,
        'Content-Type': 'application/json',
      };

  /// [bearerOverride] lets a caller authenticate as a specific signed-in user
  /// (their F3 Nation OAuth access token) instead of the app's shared API
  /// key. This matters for endpoints like /v1/me/profile: the API key
  /// resolves to whoever *owns* the key, not whichever PAX is using the app,
  /// so per-user endpoints need the user's own bearer token.
  Future<Map<String, dynamic>?> _get(String path,
      {String? bearerOverride}) async {
    if (bearerOverride == null && !isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers(bearerOverride))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> _getList(String path, {String? bearerOverride}) async {
    if (bearerOverride == null && !isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers(bearerOverride))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is List) return body;
        if (body is Map && body['data'] is List) return body['data'] as List;
        if (body is Map && body['eventInstances'] is List) {
          return body['eventInstances'] as List;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generic authenticated POST. Returns (statusCode, decodedBodyOrNull).
  /// Used by the publish flow to write event instances and attendance.
  Future<({int status, dynamic body})> _post(
    String path,
    Map<String, dynamic> payload, {
    String? bearerOverride,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: _headers(bearerOverride),
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));
      dynamic decoded;
      try {
        decoded = res.body.isNotEmpty ? json.decode(res.body) : null;
      } catch (_) {}
      return (status: res.statusCode, body: decoded);
    } catch (e) {
      return (status: -1, body: e.toString());
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Fetches the signed-in user's own profile. Pass [userAccessToken] (the
  /// F3 Nation OAuth access token from [AuthService.getF3AccessToken]) to get
  /// the actual signed-in PAX's profile — without it, this authenticates
  /// with the shared app API key and returns that key's owner instead.
  Future<F3UserProfile?> getMyProfile({String? userAccessToken}) async {
    final data =
        await _get('/v1/me/profile', bearerOverride: userAccessToken);
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
            headers: _headers(),
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

  // ── Publish flow (backblast + attendance to F3 Nation) ────────────────────
  // These write real records. Attendance type IDs (confirmed from the F3
  // Nation seed data): 1 = PAX, 2 = Q, 3 = Co-Q.

  static const int attendanceTypePax = 1;
  static const int attendanceTypeQ = 2;

  /// Past events where [userId] was Q/Co-Q, filtered server-side to those with
  /// no backblast posted yet. Requires the user's own token (protected route).
  Future<List<F3EventInstance>> getPastQsWithoutBackblast({
    required String userId,
    required String regionOrgId,
    required String userAccessToken,
  }) async {
    final data = await _getList(
      '/v1/event-instance/past-qs?userId=$userId&regionOrgId=$regionOrgId&notPostedOnly=true',
      bearerOverride: userAccessToken,
    );
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Writes the backblast text + counts onto an event instance. Pass
  /// [eventInstanceId] to update an existing one. Uses the app API key (the
  /// trusted-app write model). Returns null on success, else an error string.
  Future<String?> publishBackblast({
    int? eventInstanceId,
    required String orgId,
    required String backblast,
    required int paxCount,
    required int fngCount,
    String? eventTypeId,
  }) async {
    final payload = <String, dynamic>{
      if (eventInstanceId != null) 'id': eventInstanceId,
      'orgId': int.tryParse(orgId) ?? orgId,
      'backblast': backblast,
      'paxCount': paxCount,
      'fngCount': fngCount,
      if (eventTypeId != null) 'eventTypeId': int.tryParse(eventTypeId),
      'isActive': true,
    };
    final res = await _post('/v1/event-instance', payload);
    if (res.status == 200 || res.status == 201) return null;
    return 'Event write failed (${res.status}): ${res.body}';
  }

  /// Records actual attendance for one PAX on an event instance.
  Future<String?> recordAttendance({
    required int eventInstanceId,
    required int userId,
    required int attendanceTypeId,
  }) async {
    final res = await _post('/v1/attendance/actual', {
      'eventInstanceId': eventInstanceId,
      'userId': userId,
      'attendanceTypeIds': [attendanceTypeId],
    });
    if (res.status == 200 || res.status == 201) return null;
    return 'Attendance write failed (${res.status}): ${res.body}';
  }

  // ── Health check ─────────────────────────────────────────────────────────

  Future<bool> ping() async {
    final data = await _get('/v1/ping');
    return data != null;
  }
}
