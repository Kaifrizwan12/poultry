import 'package:farm_mgt_auth/services/local_storage_service.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();
  bool loading = false;
  String? errorMessage;

  bool _validEmail(String e) {
    final re = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return re.hasMatch(e);
  }

  bool _validPassword(String p) {
    if (p.length < 8) return false;
    final up = RegExp(r'[A-Z]');
    final num = RegExp(r'\d');
    return up.hasMatch(p) && num.hasMatch(p);
  }

  bool _validName(String n) => n.trim().length >= 2;

  String? validateEmail(String e) {
    if (e.isEmpty) return 'Enter your email';
    return _validEmail(e) ? null : 'Enter a valid email';
  }

  String? validateLoginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  String? validatePassword(String p) {
    if (p.isEmpty) return 'Enter a password';
    if (p.length < 8) return 'Minimum 8 characters';
    final up = RegExp(r'[A-Z]');
    final num = RegExp(r'\d');
    if (!up.hasMatch(p)) return 'Include an uppercase letter';
    if (!num.hasMatch(p)) return 'Include a number';
    return null;
  }

  String? validateName(String n) {
    if (n.trim().isEmpty) return 'Enter your name';
    return _validName(n) ? null : 'Name must be at least 2 characters';
  }

  Future<bool> login(String email, String password,
      {bool remember = false}) async {
    if (!_validEmail(email) || password.isEmpty) return false;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final Map<String, dynamic> res = await _service.login(email, password);
      final String? token = res['token'] as String?;
      final String? expiresAt = res['expiresAt'] as String?;
      final String? refreshToken = res['refreshToken'] as String?;
      final dynamic user = res['user'];
      if (token != null) {
        await LocalStorageService.saveToken(token, expiresAt ?? '');
        if (refreshToken != null) {
          await LocalStorageService.saveRefreshToken(refreshToken);
        }
        if (user != null) {
          await LocalStorageService.saveUser(UserModel.fromMap(user));
          final String? farmId =
              user is Map<String, dynamic> ? user['farmId'] as String? : null;
          if (farmId != null) {
            await LocalStorageService.saveFarmId(farmId);
          }
        }
        await LocalStorageService.setRememberMe(remember);
        errorMessage = null;
        loading = false;
        notifyListeners();
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
    final String name = payload['name'] as String? ?? '';
    final String email = payload['email'] as String? ?? '';
    final String password = payload['password'] as String? ?? '';
    final String? farmType = payload['farmType'] as String?;
    if (!_validName(name) ||
        !_validEmail(email) ||
        !_validPassword(password) ||
        farmType == null) {
      return false;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final Map<String, dynamic> res = await _service.register(payload);
      final String? token = res['token'] as String?;
      final String? expiresAt = res['expiresAt'] as String?;
      final String? refreshToken = res['refreshToken'] as String?;
      final dynamic user = res['user'];
      if (token != null) {
        await LocalStorageService.saveToken(token, expiresAt ?? '');
        if (refreshToken != null) {
          await LocalStorageService.saveRefreshToken(refreshToken);
        }
        if (user != null) {
          await LocalStorageService.saveUser(UserModel.fromMap(user));
          final String? farmId =
              user is Map<String, dynamic> ? user['farmId'] as String? : null;
          if (farmId != null) {
            await LocalStorageService.saveFarmId(farmId);
          }
        }
        await LocalStorageService.saveFarmType(farmType);
        errorMessage = null;
        loading = false;
        notifyListeners();
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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    loading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> res = await _service.forgot(email);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return <String, dynamic>{'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    loading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> res = await _service.reset(token, newPassword);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return <String, dynamic>{'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    loading = true;
    notifyListeners();
    try {
      final String token = LocalStorageService.token() ?? '';
      final Map<String, dynamic> res =
          await _service.changePassword(token, oldPassword, newPassword);
      loading = false;
      notifyListeners();
      return res;
    } catch (e) {
      loading = false;
      notifyListeners();
      return <String, dynamic>{'error': e.toString()};
    }
  }

  Future<bool> refreshSession() async {
    final refreshToken = LocalStorageService.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> res = await _service.refresh(refreshToken);
      final String? token = res['token'] as String?;
      final String? expiresAt = res['expiresAt'] as String?;
      final String? newRefreshToken = res['refreshToken'] as String?;
      if (token != null) {
        await LocalStorageService.saveToken(token, expiresAt ?? '');
        if (newRefreshToken != null) {
          await LocalStorageService.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
    } catch (_) {}

    await LocalStorageService.clearAll();
    return false;
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } catch (_) {}
    await LocalStorageService.clearAll();
    notifyListeners();
  }
}
