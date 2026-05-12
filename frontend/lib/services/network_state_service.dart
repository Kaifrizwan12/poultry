import 'dart:async';
import 'dart:io';
import 'package:farm_mgt_auth/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lightweight connectivity probe.
class NetworkStateService {
  static bool _lastKnown = true;
  static DateTime? _lastCheck;
  static const _ttl = Duration(seconds: 10);

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[NET] $msg');
  }

  static Future<bool> isProbablyOnline() async {
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < _ttl) {
      _log('probe  → ${_lastKnown ? 'ONLINE' : 'OFFLINE'}  (cached)');
      return _lastKnown;
    }
    _lastCheck = now;

    try {
      final base = Uri.parse(ApiConfig.baseUrl);
      final probe = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.port,
        path: '/',
      );
      _log('probing  ${probe.toString()}…');
      final res = await http.head(probe).timeout(const Duration(seconds: 5));
      _lastKnown = res.statusCode < 500;
      _log('probe  → ${_lastKnown ? 'ONLINE' : 'SERVER_ERROR'}  '
          '(HTTP ${res.statusCode})');
    } on SocketException catch (e) {
      _lastKnown = false;
      _log('probe  → OFFLINE  (SocketException: ${e.message})');
    } on TimeoutException {
      _lastKnown = false;
      _log('probe  → OFFLINE  (timeout 5 s)');
    } on http.ClientException catch (e) {
      // On Flutter Web this is "XMLHttpRequest error."; on native it may say
      // "Connection refused". Treat all ClientExceptions as offline.
      _lastKnown = false;
      _log('probe  → OFFLINE  (ClientException: ${e.message})');
    } catch (e) {
      _lastKnown = true;
      _log('probe  → ONLINE (assumed)  unknown error: $e');
    }
    return _lastKnown;
  }

  static void markOnline() {
    _lastKnown = true;
    _lastCheck = DateTime.now();
    _log('markOnline  (forced)');
  }

  static void markOffline() {
    _lastKnown = false;
    _lastCheck = DateTime.now();
    _log('markOffline  (forced)');
  }

  static void invalidate() {
    _lastCheck = null;
    _log('invalidated  (next probe will be fresh)');
  }
}
