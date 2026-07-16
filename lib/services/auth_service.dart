// lib/services/auth_service.dart
// Auth facade for the app. Supports local guest auth plus real OAuth 2.0 /
// OIDC login against the F3 Nation auth server (auth2.f3nation.com,
// Authorization Code + PKCE), and exposes future Slack/email entry points
// without coupling UI to one backend.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  /// Signs in against the F3 Nation auth server (auth2.f3nation.com) via
  /// OAuth 2.0 Authorization Code + PKCE. Requires F3_OAUTH_CLIENT_ID to be
  /// set via --dart-define; throws [AuthUnavailableException] otherwise.
  Future<AppUser> signInWithF3Nation();

  /// Returns a valid F3 Nation access token for the signed-in user, silently
  /// refreshing it if it's expired or close to expiring. Returns null if the
  /// user has never signed in with F3 Nation.
  Future<String?> getF3AccessToken();

  /// Removes the F3 Nation link (clears stored tokens) without discarding
  /// the rest of the local profile — unlike [signOut], which clears
  /// everything, including the local guest identity.
  Future<void> unlinkF3Nation();

  Future<void> signOut();
}

class LocalAuthService extends AuthService {
  static const _keyCurrentUser = 'auth_current_user_v1';
  static const _uuid = Uuid();

  /// Whether F3 Nation sign-in is available in this build (a client ID was
  /// injected via --dart-define). UI uses this to show/hide the sign-in CTA.
  static bool get f3LoginAvailable => _f3ClientId.isNotEmpty;

  // ── F3 Nation OAuth (auth2.f3nation.com) ─────────────────────────────────
  // IMPORTANT: auth2, not auth. Per Tackle (2026-07-15): auth.f3nation.com is
  // the OLD standalone auth server — do not use it. auth2.f3nation.com is the
  // monorepo apps/auth deployment (the code this was implemented against);
  // its discovery doc confirms /api/oauth/authorize + /api/oauth/token with
  // PKCE S256. The token endpoint currently requires a client secret in
  // addition to PKCE — a public-client path for native apps is being
  // discussed with the F3 Nation team (possibly as a PR from us). Redirect
  // URI must match native config exactly (Android manifestPlaceholder / iOS
  // CFBundleURLTypes) and the value registered with the auth server.
  // Override with --dart-define=F3_AUTH_ISSUER=https://staging.auth2.f3nation.com
  // while testing against the staging client Tackle registered there.
  static const _f3Issuer = String.fromEnvironment(
    'F3_AUTH_ISSUER',
    defaultValue: 'https://auth2.f3nation.com',
  );
  static const _f3ClientId = String.fromEnvironment('F3_OAUTH_CLIENT_ID');
  static const _f3ClientSecret =
      String.fromEnvironment('F3_OAUTH_CLIENT_SECRET');
  static const _f3RedirectUri =
      'com.digitalweinke.f3nationapp:/oauth2redirect';
  static const _f3Scopes = ['openid', 'profile', 'email'];

  static const _keyF3AccessToken = 'f3_oauth_access_token';
  static const _keyF3RefreshToken = 'f3_oauth_refresh_token';
  static const _keyF3IdToken = 'f3_oauth_id_token';
  static const _keyF3Expiry = 'f3_oauth_expiry';

  final _secureStorage = const FlutterSecureStorage();
  final _appAuth = const FlutterAppAuth();

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
  Future<AppUser> signInWithF3Nation() async {
    if (_f3ClientId.isEmpty) {
      throw const AuthUnavailableException(
        'F3 Nation sign-in is not configured. Set F3_OAUTH_CLIENT_ID '
        '(and F3_OAUTH_CLIENT_SECRET, once a client is registered by the '
        'F3 Nation team) via --dart-define.',
      );
    }

    final AuthorizationTokenResponse result;
    try {
      result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              _f3ClientId,
              _f3RedirectUri,
              clientSecret:
                  _f3ClientSecret.isNotEmpty ? _f3ClientSecret : null,
              issuer: _f3Issuer,
              scopes: _f3Scopes,
            ),
          )
          // Safety net: if the browser flow dies without ever calling back
          // (e.g. a hung tab was closed), release the caller so the UI can
          // recover instead of waiting forever.
          .timeout(const Duration(minutes: 3));
    } on FlutterAppAuthUserCancelledException {
      throw const AuthUnavailableException(
        'F3 Nation sign-in was cancelled.',
      );
    } on TimeoutException {
      throw const AuthUnavailableException(
        'F3 Nation sign-in timed out after 3 minutes. Close any stuck '
        'browser tabs and try again.',
      );
    } on FlutterAppAuthPlatformException catch (e) {
      // Surface the full platform error so it can be read/screenshotted —
      // this is the diagnostic detail (error code, description, OAuth error
      // body) that a generic message would hide.
      throw AuthUnavailableException(
        'F3 Nation sign-in failed.\n\n'
        'code: ${e.code}\n'
        'message: ${e.message}\n'
        'details: ${e.platformErrorDetails}',
      );
    } catch (e) {
      throw AuthUnavailableException('F3 Nation sign-in failed:\n$e');
    }

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw const AuthUnavailableException(
        'F3 Nation sign-in did not return an access token.',
      );
    }

    await _storeF3Tokens(
      accessToken: accessToken,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiry: result.accessTokenExpirationDateTime,
    );

    final claims =
        result.idToken != null ? _decodeJwtPayload(result.idToken!) : null;
    final sub = claims?['sub'] as String? ?? '';
    final f3Identity = LinkedIdentity(
      provider: AuthProvider.f3nation,
      providerUserId: sub,
      email: claims?['email'] as String? ?? '',
    );

    // Merge into the existing local user (e.g. the guest profile created at
    // welcome) rather than replacing it — this is linking an account, not
    // starting a new one, so AppProfileService.authUserId and everything
    // keyed off the existing id must keep working.
    final base = _currentUser ??
        AppUser.guest(id: 'guest_${_uuid.v4()}');
    final user = AppUser(
      id: base.id,
      displayName:
          base.displayName.isNotEmpty ? base.displayName : (claims?['name'] as String? ?? ''),
      email: base.email.isNotEmpty ? base.email : f3Identity.email,
      isGuest: base.isGuest,
      identities: [
        ...base.identities.where((i) => i.provider != AuthProvider.f3nation),
        f3Identity,
      ],
    );
    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<String?> getF3AccessToken() async {
    final accessToken = await _secureStorage.read(key: _keyF3AccessToken);
    if (accessToken == null) return null;

    final expiryRaw = await _secureStorage.read(key: _keyF3Expiry);
    final expiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
    final needsRefresh = expiry == null ||
        expiry.isBefore(DateTime.now().add(const Duration(minutes: 1)));
    if (!needsRefresh) return accessToken;

    final refreshToken = await _secureStorage.read(key: _keyF3RefreshToken);
    if (refreshToken == null) return accessToken; // best effort, may be expired

    try {
      final result = await _appAuth.token(
        TokenRequest(
          _f3ClientId,
          _f3RedirectUri,
          clientSecret: _f3ClientSecret.isNotEmpty ? _f3ClientSecret : null,
          issuer: _f3Issuer,
          refreshToken: refreshToken,
          scopes: _f3Scopes,
        ),
      );
      final refreshed = result.accessToken;
      if (refreshed == null) return accessToken;
      await _storeF3Tokens(
        accessToken: refreshed,
        refreshToken: result.refreshToken ?? refreshToken,
        idToken: result.idToken,
        expiry: result.accessTokenExpirationDateTime,
      );
      return refreshed;
    } catch (_) {
      // Refresh failed (revoked, expired refresh token, offline, ...) — hand
      // back the stale token rather than throwing; the caller's API call
      // will fail with 401 and can prompt a fresh sign-in.
      return accessToken;
    }
  }

  @override
  Future<void> unlinkF3Nation() async {
    await _clearF3Tokens();
    if (_currentUser == null) return;
    final remaining = _currentUser!.identities
        .where((i) => i.provider != AuthProvider.f3nation)
        .toList();
    await _setCurrentUser(AppUser(
      id: _currentUser!.id,
      displayName: _currentUser!.displayName,
      email: _currentUser!.email,
      isGuest: _currentUser!.isGuest,
      identities: remaining,
    ));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyCurrentUser);
    await _clearF3Tokens();
  }

  Future<void> _clearF3Tokens() {
    return Future.wait([
      _secureStorage.delete(key: _keyF3AccessToken),
      _secureStorage.delete(key: _keyF3RefreshToken),
      _secureStorage.delete(key: _keyF3IdToken),
      _secureStorage.delete(key: _keyF3Expiry),
    ]);
  }

  Future<void> _storeF3Tokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiry,
  }) {
    return Future.wait([
      _secureStorage.write(key: _keyF3AccessToken, value: accessToken),
      if (refreshToken != null)
        _secureStorage.write(key: _keyF3RefreshToken, value: refreshToken),
      if (idToken != null)
        _secureStorage.write(key: _keyF3IdToken, value: idToken),
      if (expiry != null)
        _secureStorage.write(
          key: _keyF3Expiry,
          value: expiry.toIso8601String(),
        ),
    ]);
  }

  /// Decodes a JWT's payload segment without verifying the signature — the
  /// token was already validated by the auth server; this is only used to
  /// read display claims (sub/name/email) client-side.
  Map<String, dynamic>? _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
    try {
      return json.decode(utf8.decode(base64.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setCurrentUser(AppUser user) async {
    _currentUser = user;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyCurrentUser, jsonEncode(user.toJson()));
  }
}
