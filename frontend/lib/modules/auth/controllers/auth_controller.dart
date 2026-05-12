import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/services/local_storage_service.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Three-state authentication used by [AuthGuard] and [main].
enum AuthState {
  /// Token is valid and the backend is reachable.
  onlineAuthenticated,

  /// Token is expired / missing but the device has a prior valid session and
  /// the backend is currently unreachable – safe to show cached data.
  offlineAuthenticated,

  /// No valid session exists. The user must log in online.
  signedOut,
}

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();
  bool loading = false;
  String? errorMessage;

  // ── Validators ───────────────────────────────────────────────────────────────

  bool _validEmail(String e) =>
      RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(e);

  bool _validPassword(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'\d').hasMatch(p);

  bool _validName(String n) => n.trim().length >= 2;

  String? validateEmail(String e) {
    if (e.isEmpty) return 'Enter your email';
    return _validEmail(e) ? null : 'Enter a valid email';
  }

  String? validateLoginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password' : null;

  String? validatePassword(String p) {
    if (p.isEmpty) return 'Enter a password';
    if (p.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Include an uppercase letter';
    if (!RegExp(r'\d').hasMatch(p)) return 'Include a number';
    return null;
  }

  String? validateName(String n) {
    if (n.trim().isEmpty) return 'Enter your name';
    return _validName(n) ? null : 'Name must be at least 2 characters';
  }

  // ── Login / Register ─────────────────────────────────────────────────────────

  Future<bool> login(String email, String password,
      {bool remember = false}) async {
    if (!_validEmail(email) || password.isEmpty) return false;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _service.login(email, password);
      final token = res['token'] as String?;
      if (token != null) {
        await LocalStorageService.saveToken(token, '${res['expiresAt'] ?? ''}');
        final rt = res['refreshToken'] as String?;
        if (rt != null) await LocalStorageService.saveRefreshToken(rt);
        final user = res['user'];
        if (user is Map<String, dynamic>) {
          await LocalStorageService.saveUser(UserModel.fromMap(user));
          final farmId = user['farmId'] as String?;
          if (farmId != null) await LocalStorageService.saveFarmId(farmId);
        }
        await LocalStorageService.setRememberMe(remember);
        // Mark device as previously authenticated so offline access is allowed.
        await LocalStorageService.setOfflineAllowed(true);
        errorMessage = null;
        loading = false;
        notifyListeners();
        // Kick off background sync now that we have a valid session.
        OfflineSyncService.instance.start();
        return true;
      }
      errorMessage = (res['error'] as String?) ?? 'Login failed';
    } catch (e) {
      errorMessage = e.toString();
    }
    loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    final name     = payload['name']     as String? ?? '';
    final email    = payload['email']    as String? ?? '';
    final password = payload['password'] as String? ?? '';
    final farmType = payload['farmType'] as String?;
    if (!_validName(name) || !_validEmail(email) ||
        !_validPassword(password)  || farmType == null) {
      return false;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _service.register(payload);
      final token = res['token'] as String?;
      if (token != null) {
        await LocalStorageService.saveToken(token, '${res['expiresAt'] ?? ''}');
        final rt = res['refreshToken'] as String?;
        if (rt != null) await LocalStorageService.saveRefreshToken(rt);
        final user = res['user'];
        if (user is Map<String, dynamic>) {
          await LocalStorageService.saveUser(UserModel.fromMap(user));
          final farmId = user['farmId'] as String?;
          if (farmId != null) await LocalStorageService.saveFarmId(farmId);
        }
        await LocalStorageService.saveFarmType(farmType);
        await LocalStorageService.setOfflineAllowed(true);
        errorMessage = null;
        loading = false;
        notifyListeners();
        OfflineSyncService.instance.start();
        return true;
      }
      errorMessage = (res['error'] as String?) ?? 'Registration failed';
    } catch (e) {
      errorMessage = e.toString();
    }
    loading = false;
    notifyListeners();
    return false;
  }

  // ── Password helpers ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    loading = true;
    notifyListeners();
    try {
      final res = await _service.forgot(email);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    loading = true;
    notifyListeners();
    try {
      final res = await _service.reset(token, newPassword);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    loading = true;
    notifyListeners();
    try {
      final res = await _service.changePassword(
          LocalStorageService.token() ?? '', oldPassword, newPassword);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return {'error': e.toString()};
    }
  }

  // ── Session refresh ───────────────────────────────────────────────────────────
  //
  // Critical offline contract:
  //   • NetworkException  → do NOT clear session; return false so the caller
  //                         can decide to grant offline access.
  //   • Server returns no token (invalid/revoked refresh) → clear session.

  Future<bool> refreshSession() async {
    final rt = LocalStorageService.refreshToken();
    if (rt == null || rt.isEmpty) {
      debugPrint('[AUTH] refreshSession  no refresh token – skip');
      return false;
    }
    debugPrint('[AUTH] refreshSession  attempting…');
    try {
      final res = await _service.refresh(rt);
      final newToken = res['token'] as String?;
      if (newToken != null) {
        await LocalStorageService.saveToken(
            newToken, '${res['expiresAt'] ?? ''}');
        final newRt = res['refreshToken'] as String?;
        if (newRt != null) await LocalStorageService.saveRefreshToken(newRt);
        await LocalStorageService.setOfflineAllowed(true);
        debugPrint('[AUTH] refreshSession  ✓ OK – token updated');
        return true;
      }
      debugPrint('[AUTH] refreshSession  server returned no token'
          ' – clearing session');
      await LocalStorageService.clearAll();
      return false;
    } on NetworkException {
      debugPrint('[AUTH] refreshSession  ✗ NetworkException'
          ' – session preserved for offline access');
      return false;
    } catch (e) {
      debugPrint('[AUTH] refreshSession  ✗ unknown error: $e'
          ' – clearing session');
      await LocalStorageService.clearAll();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    OfflineSyncService.instance.stop();
    try {
      await _service.logout();
    } catch (_) {}
    // Wipe farm-scoped cache and the pending queue before clearing auth so
    // OfflineCacheService._fid() still returns the correct farmId.
    await OfflineCacheService.clearFarmCache();
    await LocalStorageService.clearAll();
    notifyListeners();
  }
}
