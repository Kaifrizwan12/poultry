import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/auth/models/user_model.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;
  static const _kToken = 'auth_token';
  static const _kExpiry = 'auth_expiry';
  static const _kUser = 'auth_user';
  static const _kRemember = 'remember_me';
  static const _kFarmType = 'farm_type';
  static const _kRefresh = 'refresh_token';
  static const _kFarmId = 'farm_id';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token, String expiresAt) async {
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kExpiry, expiresAt);
    if (kDebugMode) {
      developer.log(
        'Auth token saved for Postman testing: Bearer $token',
        name: 'LocalStorageService',
      );
      print('Auth token saved for Postman testing: Bearer $token');
    }
  }

  static String? token() => _prefs.getString(_kToken);
  static String? expiry() => _prefs.getString(_kExpiry);

  static Future<void> saveUser(UserModel u) async {
    await _prefs.setString(_kUser, jsonEncode(u.toMap()));
  }

  static UserModel? cachedUser() {
    final s = _prefs.getString(_kUser);
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return UserModel.fromMap(m);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setRememberMe(bool v) => _prefs.setBool(_kRemember, v);
  static bool rememberMe() => _prefs.getBool(_kRemember) ?? false;

  static Future<void> saveFarmType(String ft) =>
      _prefs.setString(_kFarmType, ft);
  static String? farmType() => _prefs.getString(_kFarmType);

  static Future<void> saveRefreshToken(String token) =>
      _prefs.setString(_kRefresh, token);
  static String? refreshToken() => _prefs.getString(_kRefresh);

  static Future<void> saveFarmId(String id) => _prefs.setString(_kFarmId, id);
  static String? farmId() => _prefs.getString(_kFarmId);

  static Future<void> clearAll() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kExpiry);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kFarmId);
  }

  static bool isTokenExpired() {
    final expiry = _prefs.getString(_kExpiry);
    if (expiry == null || expiry.isEmpty) return true;
    try {
      return DateTime.now().isAfter(DateTime.parse(expiry));
    } catch (_) {
      return true;
    }
  }
}
