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
    } catch (_) {
    }
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
        if (body is Map && body['events'] is List) {
          return body['events'] as List;
        }
      }
    } catch (_) {
    }
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

  /// Updates the signed-in PAX's own F3 Nation user record. Uses the app's
  /// trusted API key (`POST /v1/user`), not the user's own token — Tackle's
  /// guidance: `/v1/me/profile` (PATCH) is user-token self-service, but a
  /// third-party app should write through its own trusted key instead. Only
  /// non-null fields are sent, so callers can update just what changed.
  /// Returns null on success, else an error string.
  Future<String?> updateUserProfile({
    required int userId,
    String? f3Name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      if (f3Name != null) 'f3Name': f3Name,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
    final res = await _post('/v1/user', payload);
    if (res.status == 200 || res.status == 201) return null;
    return 'Profile update failed (${res.status}): ${res.body}';
  }

  Future<F3UserProfile?> findPaxByF3Name(String f3Name) async {
    final data =
        await _get('/v1/user/f3name/${Uri.encodeComponent(f3Name)}');
    if (data == null) return null;
    return F3UserProfile.fromJson(data);
  }

  // ── Locations / AOs ───────────────────────────────────────────────────────

  /// All active AOs nationwide (Browse AOs is a national/GPS-sorted browse,
  /// not scoped to the signed-in user's region). The response is wrapped in
  /// a `locations` key, not a bare list or `data`/`eventInstances`/`events`.
  Future<List<F3Location>> getLocations() async {
    final data = await _get('/v1/location?pageSize=5000');
    if (data == null) return [];
    final list = data['locations'] as List<dynamic>? ?? [];
    return list
        .map((e) => F3Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recurring weekly workout series, keyed by `locationId` — sourced from
  /// `GET /v1/event` (the recurring-series entity; distinct from
  /// `/v1/event-instance`, which is one dated occurrence). This is the same
  /// data the F3 Nation admin's "Events" table shows (AO, Location, Day of
  /// Week). Also carries each location's AO display name, which
  /// `/v1/location` itself doesn't expose.
  Future<Map<String, ({List<F3WeeklyWorkout> schedule, String? aoName})>>
      getLocationSchedules() async {
    final data = await _get('/v1/event?pageSize=10000');
    if (data == null) return {};
    final events = data['events'] as List<dynamic>? ?? [];
    final result = <String, ({List<F3WeeklyWorkout> schedule, String? aoName})>{};
    for (final e in events) {
      if (e is! Map) continue;
      final locationId = e['locationId']?.toString();
      final weekday = e['dayOfWeek']?.toString();
      final time = e['startTime']?.toString();
      if (locationId == null || weekday == null || time == null) continue;
      final types = e['eventTypes'];
      String? typeName;
      if (types is List && types.isNotEmpty && types.first is Map) {
        typeName = (types.first as Map)['eventTypeName']?.toString();
      }
      final parents = e['parents'];
      String? aoName;
      if (parents is List && parents.isNotEmpty && parents.first is Map) {
        aoName = (parents.first as Map)['parentName']?.toString();
      }
      final existing = result[locationId];
      final schedule = [
        ...?existing?.schedule,
        F3WeeklyWorkout(weekday: weekday, time: time, eventTypeName: typeName),
      ];
      result[locationId] =
          (schedule: schedule, aoName: aoName ?? existing?.aoName);
    }
    return result;
  }

  // ── Events / Beatdowns ────────────────────────────────────────────────────

  /// [userId] is required by the API (`regionOrgId` + `userId` together
  /// select the signed-in PAX's calendar) — without it the endpoint 400s
  /// and this silently falls back to an empty list. Recurring series now
  /// generate instances far into the future (seen out past a year), so this
  /// pins `startDate` to [from] (date-only — still includes that day's
  /// events even if their time already passed) to avoid pulling and paging
  /// through a huge, mostly-irrelevant backlog. Defaults to today for the
  /// Schedule list view; the calendar view passes the viewed month's start
  /// (including past months, so backblasts can still be added after the
  /// fact for days that already happened).
  Future<List<F3EventInstance>> getUpcomingBeatdowns(
      {String? userAccessToken, int? userId, DateTime? from, int limit = 200}) async {
    if (orgId == null || userId == null) return [];
    final d = from ?? DateTime.now();
    final startDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final path =
        '/v1/event-instance/calendar-home-schedule?regionOrgId=$orgId&userId=$userId&startDate=$startDate&limit=$limit';
    final data = await _getList(path, bearerOverride: userAccessToken);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<F3EventInstance>> getOpenQSlots() async {
    final path = orgId != null
        ? '/v1/event-instance/without-q?regionOrgId=$orgId'
        : '/v1/event-instance/without-q';
    final data = await _getList(path);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Orgs / Regions ────────────────────────────────────────────────────────

  /// All regions nationwide (492 as of 2026-07 — small enough to load in one
  /// call and search client-side; the endpoint defaults to `pageSize=10`
  /// without this override).
  Future<List<F3Org>> getOrgs() async {
    final data = await _getList('/v1/org?pageSize=5000');
    if (data == null) return [];
    return data
        .map((e) => F3Org.fromJson(e as Map<String, dynamic>))
        .toList();
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
  /// [eventInstanceId] to update an existing one — in that case [orgId] must
  /// be that event's own AO-level org (never the signed-in user's region, or
  /// the write reassigns the event to the region). Leave [eventInstanceId]
  /// null to create a brand-new unscheduled event, in which case [orgId] is
  /// the AO to create it under. [startDate] (`YYYY-MM-DD`) is required by the
  /// API in both cases. Uses the app API key (the trusted-app write model).
  /// Returns null on success, else an error string.
  Future<String?> publishBackblast({
    int? eventInstanceId,
    required String orgId,
    required String startDate,
    required String backblast,
    required int paxCount,
    required int fngCount,
    String? eventTypeId,
  }) async {
    final payload = <String, dynamic>{
      if (eventInstanceId != null) 'id': eventInstanceId,
      'orgId': int.tryParse(orgId) ?? orgId,
      'startDate': startDate,
      'backblast': backblast,
      'backblastTs': DateTime.now().millisecondsSinceEpoch,
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

  // ── Schedule / signups (Tier 1) ───────────────────────────────────────────

  /// HC / sign up the signed-in PAX for an upcoming beatdown (planned
  /// attendance). Self-signup is allowed with the user's own token — no editor
  /// role needed. Returns null on success, else an error string.
  Future<String?> signUpForEvent({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _post(
      '/v1/attendance',
      {
        'eventInstanceId': eventInstanceId,
        'userId': userId,
        'attendanceTypeIds': [attendanceTypePax],
      },
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Sign-up failed (${res.status}): ${res.body}';
  }

  /// Remove the signed-in PAX's planned attendance (un-HC).
  Future<String?> withdrawFromEvent({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _post(
      '/v1/attendance/remove-planned',
      {'eventInstanceId': eventInstanceId, 'userId': userId},
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Withdraw failed (${res.status}): ${res.body}';
  }

  /// Take the Q for an open event.
  Future<String?> takeQ({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _post(
      '/v1/attendance/take-q',
      {'eventInstanceId': eventInstanceId, 'userId': userId},
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Take-Q failed (${res.status}): ${res.body}';
  }

  /// Post/update the preblast (the plan announced before a beatdown). [orgId]
  /// must be the event's own AO-level org, not the signed-in user's region —
  /// sending the region org here reassigns the event to it. [startDate]
  /// (`YYYY-MM-DD`) is required by the API even on an update of an existing
  /// event.
  Future<String?> postPreblast({
    required int eventInstanceId,
    required String orgId,
    required String startDate,
    required String preblast,
  }) async {
    final res = await _post('/v1/event-instance', {
      'id': eventInstanceId,
      'orgId': int.tryParse(orgId) ?? orgId,
      'startDate': startDate,
      'preblast': preblast,
      'preblastTs': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
    });
    if (res.status == 200 || res.status == 201) return null;
    return 'Preblast failed (${res.status}): ${res.body}';
  }

  // ── Health check ─────────────────────────────────────────────────────────

  Future<bool> ping() async {
    final data = await _get('/v1/ping');
    return data != null;
  }
}
