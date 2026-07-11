// lib/services/auth_service.dart
// Auth facade for the app. Today it supports local guest auth and exposes
// future Slack/email entry points without coupling UI to one backend.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/auth_models.dart';

abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isSignedIn;

  Future<void> load();
  Future<AppUser> continueAsGuest({String displayName = ''});
  Future<AppUser> signInWithSlack();
  Future<AppUser> signInWithEmail(String email);
  Future<void> signOut();
}

class LocalAuthService extends AuthService {
  static const _keyCurrentUser = 'auth_current_user_v1';
  static const _uuid = Uuid();

  SharedPreferences? _prefs;
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_keyCurrentUser);
    if (raw == null || raw.isEmpty) return;

    try {
      _currentUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _currentUser = null;
    }
    notifyListeners();
  }

  @override
  Future<AppUser> continueAsGuest({String displayName = ''}) async {
    final user = AppUser.guest(
      id: 'guest_${_uuid.v4()}',
      displayName: displayName.trim(),
    );
    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<AppUser> signInWithSlack() {
    throw const AuthUnavailableException(
      'Slack sign-in needs a backend OpenID Connect callback before it can be enabled.',
    );
  }

  @override
  Future<AppUser> signInWithEmail(String email) {
    throw const AuthUnavailableException(
      'Email sign-in needs a backend or auth provider before it can be enabled.',
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyCurrentUser);
  }

  Future<void> _setCurrentUser(AppUser user) async {
    _currentUser = user;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyCurrentUser, jsonEncode(user.toJson()));
  }
}
