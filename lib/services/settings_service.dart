// lib/services/settings_service.dart
// Persists WorkoutSettings via shared_preferences.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout_settings.dart';
import 'music_launcher.dart';
import 'spartan_service.dart';

enum AppRole { pax, q }

class SettingsService extends ChangeNotifier {
  static const _keyCouponMode      = 'coupon_mode';
  static const _keyIntensities     = 'intensities';
  static const _keyGeminiApi       = 'gemini_api_key';
  static const _keyAppRole         = 'app_role';
  static const _keyVoiceEnabled    = 'voice_enabled';
  static const _keyReducedMotion   = 'reduced_motion';
  static const _keySlackWebhook    = 'slack_webhook_url';
  static const _keySlackChannelId  = 'slack_channel_id';
  static const _keyNotifEnabled    = 'notif_enabled';
  static const _keyNotifWeekday    = 'notif_weekday';
  static const _keyNotifHour       = 'notif_hour';
  static const _keyNotifMinute     = 'notif_minute';
  static const _keyBlacklist       = 'blacklisted_exercises';
  static const _keyFavorites       = 'favorited_exercises';
  static const _keyMusicProvider   = 'music_provider';
  static const _keyMusicPlaylist   = 'music_playlist_url';
  static const _keyMusicEnabled    = 'music_enabled';
  static const _keyMyF3Name        = 'my_f3_name';
  static const _keyTtsVoice        = 'tts_voice';
  static const _keyThemeMode       = 'theme_mode';
  static const _keyLocale          = 'locale';

  WorkoutSettings _settings = const WorkoutSettings();
  WorkoutSettings get settings => _settings;

  String _geminiApiKey = '';
  String get geminiApiKey => _geminiApiKey;

  AppRole _appRole = AppRole.q;
  AppRole get appRole => _appRole;

  bool _voiceEnabled = false;
  bool get voiceEnabled => _voiceEnabled;

  bool _reducedMotion = false;
  bool get reducedMotion => _reducedMotion;

  String _slackWebhookUrl = '';
  String get slackWebhookUrl => _slackWebhookUrl;

  String _slackChannelId = '';
  String get slackChannelId => _slackChannelId;

  bool _notifEnabled = false;
  bool get notifEnabled => _notifEnabled;

  int _notifWeekday = 6; // Saturday
  int get notifWeekday => _notifWeekday;

  int _notifHour = 5;
  int get notifHour => _notifHour;

  int _notifMinute = 30;
  int get notifMinute => _notifMinute;

  Set<String> _blacklist = {};
  Set<String> _favorites = {};

  bool isBlacklisted(String id) => _blacklist.contains(id);
  bool isFavorited(String id) => _favorites.contains(id);

  String _myF3Name = '';
  String get myF3Name => _myF3Name;

  String _ttsVoice = '';
  String get ttsVoice => _ttsVoice;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // Music
  bool _musicEnabled = false;
  bool get musicEnabled => _musicEnabled;

  MusicProvider _musicProvider = MusicProvider.spotify;
  MusicProvider get musicProvider => _musicProvider;

  String _musicPlaylistUrl = '';
  String get musicPlaylistUrl => _musicPlaylistUrl;

  /// Load persisted settings; call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Coupon mode
    final couponStr = prefs.getString(_keyCouponMode);
    final couponMode = CouponMode.values.firstWhere(
      (m) => m.name == couponStr,
      orElse: () => CouponMode.mixed,
    );

    // Intensity set
    final intList = prefs.getStringList(_keyIntensities);
    final intensities = intList == null
        ? {Intensity.beginner, Intensity.intermediate, Intensity.advanced}
        : intList
            .map((s) => Intensity.values.firstWhere(
                  (i) => i.name == s,
                  orElse: () => Intensity.intermediate,
                ))
            .toSet();

    _settings = WorkoutSettings(
      couponMode: couponMode,
      intensities: intensities,
    );

    _geminiApiKey = prefs.getString(_keyGeminiApi) ?? '';
    _appRole = AppRole.values.firstWhere(
        (e) => e.name == prefs.getString(_keyAppRole),
        orElse: () => AppRole.q);

    _voiceEnabled    = prefs.getBool(_keyVoiceEnabled) ?? false;
    _reducedMotion   = prefs.getBool(_keyReducedMotion) ?? false;
    _slackWebhookUrl  = prefs.getString(_keySlackWebhook) ?? '';
    _slackChannelId   = prefs.getString(_keySlackChannelId) ?? '';
    _notifEnabled    = prefs.getBool(_keyNotifEnabled) ?? false;
    _notifWeekday    = prefs.getInt(_keyNotifWeekday) ?? 6;
    _notifHour       = prefs.getInt(_keyNotifHour) ?? 5;
    _notifMinute     = prefs.getInt(_keyNotifMinute) ?? 30;
    _blacklist       = Set<String>.from(prefs.getStringList(_keyBlacklist) ?? []);
    _favorites       = Set<String>.from(prefs.getStringList(_keyFavorites) ?? []);

    _myF3Name         = prefs.getString(_keyMyF3Name) ?? '';
    _ttsVoice         = prefs.getString(_keyTtsVoice) ?? '';

    final themeModeStr = prefs.getString(_keyThemeMode) ?? 'dark';
    _themeMode = switch (themeModeStr) {
      'light'  => ThemeMode.light,
      'system' => ThemeMode.system,
      _        => ThemeMode.dark,
    };
    final localeStr = prefs.getString(_keyLocale) ?? 'en';
    _locale = Locale(localeStr);

    _musicEnabled     = prefs.getBool(_keyMusicEnabled) ?? false;
    _musicPlaylistUrl = prefs.getString(_keyMusicPlaylist) ?? '';
    _musicProvider    = MusicProvider.values.firstWhere(
      (p) => p.name == prefs.getString(_keyMusicProvider),
      orElse: () => MusicProvider.spotify,
    );

    SpartanService.instance.init(_geminiApiKey);

    notifyListeners();
  }

  /// Persist and broadcast new settings.
  Future<void> update(WorkoutSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCouponMode, newSettings.couponMode.name);
    await prefs.setStringList(
      _keyIntensities,
      newSettings.intensities.map((i) => i.name).toList(),
    );
  }

  Future<void> updateApiKey(String key) async {
    _geminiApiKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApi, key);
  }

  Future<void> setMyF3Name(String name) async {
    _myF3Name = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyF3Name, name);
  }

  Future<void> setTtsVoice(String voiceName) async {
    _ttsVoice = voiceName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTtsVoice, voiceName);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.system => 'system',
      _                => 'dark',
    };
    await prefs.setString(_keyThemeMode, str);
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusicEnabled, value);
  }

  Future<void> setMusicProvider(MusicProvider provider) async {
    _musicProvider = provider;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMusicProvider, provider.name);
  }

  Future<void> setMusicPlaylistUrl(String url) async {
    _musicPlaylistUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMusicPlaylist, url);
  }

  Future<void> updateRole(AppRole role) async {
    _appRole = role;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppRole, role.name);
  }

  Future<void> updateVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceEnabled, value);
  }

  Future<void> updateReducedMotion(bool value) async {
    _reducedMotion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, value);
  }

  Future<void> updateSlackWebhookUrl(String url) async {
    _slackWebhookUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySlackWebhook, url);
  }

  Future<void> updateSlackChannelId(String channelId) async {
    _slackChannelId = channelId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySlackChannelId, channelId);
  }

  Future<void> updateNotifEnabled(bool value) async {
    _notifEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifEnabled, value);
  }

  Future<void> updateNotifSchedule({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    _notifWeekday = weekday;
    _notifHour    = hour;
    _notifMinute  = minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotifWeekday, weekday);
    await prefs.setInt(_keyNotifHour, hour);
    await prefs.setInt(_keyNotifMinute, minute);
  }

  Future<void> toggleBlacklist(String id) async {
    if (_blacklist.contains(id)) {
      _blacklist.remove(id);
    } else {
      _blacklist.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBlacklist, _blacklist.toList());
  }

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, _favorites.toList());
  }
}
