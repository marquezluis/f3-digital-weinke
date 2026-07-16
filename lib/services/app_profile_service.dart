// lib/services/app_profile_service.dart
// Local app profile state. This is intentionally small now, but it gives us a
// clean path for future sign-in, PAX/Q roles, and optional cloud profile
// loading while keeping today's app local-first.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole {
  pax,
  q,
  siteQ;

  String get displayName {
    switch (this) {
      case AppRole.pax:
        return 'PAX';
      case AppRole.q:
        return 'Q';
      case AppRole.siteQ:
        return 'Site Q';
    }
  }

  String get description {
    switch (this) {
      case AppRole.pax:
        return 'Post, track attendance, and find the next beatdown.';
      case AppRole.q:
        return 'Build Weinkes, run Q Mode, and create backblasts.';
      case AppRole.siteQ:
        return 'Manage AOs, HCs, attendance, and PAX follow-up.';
    }
  }
}

class AppProfileService extends ChangeNotifier {
  static const _keyWelcomeComplete = 'welcome_complete';
  static const _keyDisplayName = 'profile_display_name';
  static const _keyHomeAo = 'profile_home_ao';
  static const _keyRegion = 'profile_region';
  static const _keyRole = 'profile_role';
  static const _keyAuthUserId = 'profile_auth_user_id';
  static const _keyAppLockEnabled = 'profile_app_lock_enabled';
  static const _keyAvatarUrl = 'profile_avatar_url';

  SharedPreferences? _prefs;
  bool _welcomeComplete = false;
  String _displayName = '';
  String _homeAo = '';
  String _region = '';
  AppRole _role = AppRole.q;
  String _authUserId = '';
  bool _appLockEnabled = false;
  String _avatarUrl = '';

  bool get welcomeComplete => _welcomeComplete;
  String get displayName => _displayName;
  String get homeAo => _homeAo;
  String get region => _region;
  AppRole get role => _role;
  String get authUserId => _authUserId;
  bool get appLockEnabled => _appLockEnabled;
  String get avatarUrl => _avatarUrl;

  Map<String, dynamic> toJson() => {
        'welcomeComplete': _welcomeComplete,
        'displayName': _displayName,
        'homeAo': _homeAo,
        'region': _region,
        'role': _role.name,
        'authUserId': _authUserId,
        'appLockEnabled': _appLockEnabled,
        'avatarUrl': _avatarUrl,
      };

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _welcomeComplete = _prefs!.getBool(_keyWelcomeComplete) ?? false;
    _displayName = _prefs!.getString(_keyDisplayName) ?? '';
    _homeAo = _prefs!.getString(_keyHomeAo) ?? '';
    _region = _prefs!.getString(_keyRegion) ?? '';
    _authUserId = _prefs!.getString(_keyAuthUserId) ?? '';
    _appLockEnabled = _prefs!.getBool(_keyAppLockEnabled) ?? false;
    _avatarUrl = _prefs!.getString(_keyAvatarUrl) ?? '';
    final roleName = _prefs!.getString(_keyRole);
    _role = AppRole.values.firstWhere(
      (role) => role.name == roleName,
      orElse: () => AppRole.q,
    );
    notifyListeners();
  }

  /// Merges fields from the signed-in user's F3 Nation profile into the
  /// local profile. Only non-empty values overwrite; local-only fields
  /// (home AO, role, app lock) are never touched — F3 Nation doesn't own
  /// those. Called after OAuth sign-in and on Settings open when linked.
  Future<void> applyF3Profile({
    String? f3Name,
    String? region,
    String? avatarUrl,
    String? f3UserId,
  }) async {
    var changed = false;
    if (f3Name != null && f3Name.isNotEmpty && f3Name != _displayName) {
      _displayName = f3Name;
      changed = true;
    }
    if (region != null && region.isNotEmpty && region != _region) {
      _region = region;
      changed = true;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != _avatarUrl) {
      _avatarUrl = avatarUrl;
      changed = true;
    }
    if (f3UserId != null && f3UserId.isNotEmpty && f3UserId != _authUserId) {
      _authUserId = f3UserId;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.setString(_keyDisplayName, _displayName),
      _prefs!.setString(_keyRegion, _region),
      _prefs!.setString(_keyAvatarUrl, _avatarUrl),
      _prefs!.setString(_keyAuthUserId, _authUserId),
    ]);
  }

  Future<void> completeWelcome({
    required AppRole role,
    String displayName = '',
    String homeAo = '',
    String region = '',
    String authUserId = '',
    bool appLockEnabled = false,
  }) async {
    await updateProfile(
      role: role,
      displayName: displayName,
      homeAo: homeAo,
      region: region,
      authUserId: authUserId,
      appLockEnabled: appLockEnabled,
      welcomeComplete: true,
    );
  }

  Future<void> updateProfile({
    required AppRole role,
    String displayName = '',
    String homeAo = '',
    String region = '',
    String authUserId = '',
    bool? appLockEnabled,
    bool? welcomeComplete,
  }) async {
    _role = role;
    _displayName = displayName.trim();
    _homeAo = homeAo.trim();
    _region = region.trim();
    _authUserId = authUserId;
    if (appLockEnabled != null) _appLockEnabled = appLockEnabled;
    if (welcomeComplete != null) _welcomeComplete = welcomeComplete;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.setBool(_keyWelcomeComplete, _welcomeComplete),
      _prefs!.setString(_keyDisplayName, _displayName),
      _prefs!.setString(_keyHomeAo, _homeAo),
      _prefs!.setString(_keyRegion, _region),
      _prefs!.setString(_keyRole, _role.name),
      _prefs!.setString(_keyAuthUserId, _authUserId),
      _prefs!.setBool(_keyAppLockEnabled, _appLockEnabled),
    ]);
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyAppLockEnabled, value);
  }

  Future<void> importJson(Map<String, dynamic> json) async {
    final roleName = json['role'] as String?;
    final role = AppRole.values.firstWhere(
      (item) => item.name == roleName,
      orElse: () => AppRole.q,
    );
    await updateProfile(
      role: role,
      displayName: json['displayName'] as String? ?? '',
      homeAo: json['homeAo'] as String? ?? '',
      region: json['region'] as String? ?? '',
      authUserId: json['authUserId'] as String? ?? '',
      appLockEnabled: json['appLockEnabled'] as bool?,
      welcomeComplete: json['welcomeComplete'] as bool? ?? true,
    );
  }

  Future<void> resetWelcome() async {
    _welcomeComplete = false;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyWelcomeComplete, false);
  }
}
