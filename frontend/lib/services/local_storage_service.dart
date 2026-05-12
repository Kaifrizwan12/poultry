import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/auth/models/user_model.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;

  static const _kToken          = 'auth_token';
  static const _kExpiry         = 'auth_expiry';
  static const _kUser           = 'auth_user';
  static const _kRemember       = 'remember_me';
  static const _kFarmType       = 'farm_type';
  static const _kRefresh        = 'refresh_token';
  static const _kFarmId         = 'farm_id';
  // Allows temporary offline access after a prior successful login.
  // Cleared on explicit logout; intentionally NOT cleared on token expiry.
  static const _kOfflineAllowed = 'session:offline_allowed';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Exposes the raw prefs instance so helper services (OfflineCacheService,
  /// OfflineQueueService) can share the same singleton without a second init.
  static SharedPreferences get prefs => _prefs;

  // ── Token ────────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token, String expiresAt) async {
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kExpiry, expiresAt);
    if (kDebugMode) {
      developer.log(
        'Auth token saved — Bearer $token',
        name: 'LocalStorageService',
      );
    }
  }

  static String? token()  => _prefs.getString(_kToken);
  static String? expiry() => _prefs.getString(_kExpiry);

  static bool isTokenExpired() {
    final exp = _prefs.getString(_kExpiry);
    if (exp == null || exp.isEmpty) return true;
    try {
      return DateTime.now().isAfter(DateTime.parse(exp));
    } catch (_) {
      return true;
    }
  }

  // ── User ─────────────────────────────────────────────────────────────────────

  static Future<void> saveUser(UserModel u) async {
    await _prefs.setString(_kUser, jsonEncode(u.toMap()));
  }

  static UserModel? cachedUser() {
    final s = _prefs.getString(_kUser);
    if (s == null) return null;
    try {
      return UserModel.fromMap(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Misc ─────────────────────────────────────────────────────────────────────

  static Future<void> setRememberMe(bool v) => _prefs.setBool(_kRemember, v);
  static bool rememberMe() => _prefs.getBool(_kRemember) ?? false;

  static Future<void> saveFarmType(String ft) =>
      _prefs.setString(_kFarmType, ft);
  static String? farmType() => _prefs.getString(_kFarmType);

  static Future<void> saveRefreshToken(String t) =>
      _prefs.setString(_kRefresh, t);
  static String? refreshToken() => _prefs.getString(_kRefresh);

  static Future<void> saveFarmId(String id) => _prefs.setString(_kFarmId, id);
  static String? farmId() => _prefs.getString(_kFarmId);

  // ── Offline session ───────────────────────────────────────────────────────────

  static Future<void> setOfflineAllowed(bool v) =>
      _prefs.setBool(_kOfflineAllowed, v);
  static bool offlineAllowed() => _prefs.getBool(_kOfflineAllowed) ?? false;

  // ── Clear ────────────────────────────────────────────────────────────────────

  /// Full sign-out wipe. Also clears the offline-allowed flag so the user
  /// must authenticate online before going offline again.
  static Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_kToken),
      _prefs.remove(_kExpiry),
      _prefs.remove(_kUser),
      _prefs.remove(_kRefresh),
      _prefs.remove(_kFarmId),
      _prefs.remove(_kOfflineAllowed),
    ]);
  }
}
