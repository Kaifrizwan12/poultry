import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:farm_mgt_auth/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:farm_mgt_auth/services/local_storage_service.dart';
import 'network_state_service.dart';

typedef SessionRefreshHandler = Future<bool> Function();

SessionRefreshHandler? _sessionRefreshHandler;

void registerSessionRefreshHandler(SessionRefreshHandler handler) {
  _sessionRefreshHandler = handler;
}

/// Thrown when the device cannot reach the backend (SocketException, timeout,
/// connection refused, etc.). Callers must catch this separately from
/// [AppException] to trigger offline fallback paths.
class NetworkException implements Exception {
  const NetworkException([this.message]);
  final String? message;
  @override
  String toString() => message ?? 'Network unavailable';
}

class ApiService {
  static const base = ApiConfig.baseUrl;
  static const bool _enableVerboseLogs = false;

  static void _log(String level, String message, {dynamic data}) {
    if (!_enableVerboseLogs || !kDebugMode) return;
    final ts = DateTime.now().toIso8601String();
    final logMsg = '[$ts] [$level] $message';
    final sanitized = _sanitizeData(data);
    if (data != null) {
      developer.log(logMsg, name: 'ApiService', error: sanitized);
    } else {
      developer.log(logMsg, name: 'ApiService');
    }
  }

  static dynamic _sanitizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return {
        for (final e in data.entries)
          e.key: e.key.toLowerCase() == 'authorization'
              ? 'Bearer [REDACTED]'
              : (e.value is Map<String, dynamic>
                  ? _sanitizeData(e.value)
                  : e.value)
      };
    }
    return data;
  }

  Map<String, String> _headers({
    Map<String, String>? headers,
    bool auth = false,
  }) {
    final h = <String, String>{'Content-Type': 'application/json', ...?headers};
    if (auth) {
      final token = LocalStorageService.token();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
  }

  /// Wraps any exception that indicates the network is unreachable.
  /// Auth errors (401) and server errors (5xx) are NOT network failures.
  Never _rethrowAsNetwork(Object e) {
    // SocketException  → native mobile/desktop no-network
    // TimeoutException → request timed out
    // ClientException  → covers Flutter Web's "XMLHttpRequest error." and any
    //                    other transport-level failure (connection refused, etc.)
    //                    Note: HTTP 4xx/5xx responses are NOT ClientExceptions;
    //                    they come back as Response objects, so this is safe.
    if (e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException) {
      NetworkStateService.markOffline();
      if (kDebugMode) debugPrint('[API] NetworkException: $e');
      throw const NetworkException();
    }
    if (kDebugMode) debugPrint('[API] unexpected error: $e');
    throw e;
  }

  // ── POST ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'POST $url');
    try {
      final res = await http
          .post(Uri.parse(url),
              body: jsonEncode(body), headers: _headers(auth: auth))
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http
              .post(Uri.parse(url),
                  body: jsonEncode(body), headers: _headers(auth: true))
              .timeout(const Duration(seconds: 30));
          return _decode(retry);
        }
      }
      NetworkStateService.markOnline();
      return _decode(res);
    } catch (e) {
      _rethrowAsNetwork(e);
    }
  }

  // ── GET ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'GET $url');
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers(headers: headers, auth: auth))
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http
              .get(Uri.parse(url), headers: _headers(auth: true))
              .timeout(const Duration(seconds: 30));
          return _decode(retry);
        }
      }
      NetworkStateService.markOnline();
      return _decode(res);
    } catch (e) {
      _rethrowAsNetwork(e);
    }
  }

  // ── PUT ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'PUT $url');
    try {
      final res = await http
          .put(Uri.parse(url),
              body: jsonEncode(body), headers: _headers(auth: auth))
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http
              .put(Uri.parse(url),
                  body: jsonEncode(body), headers: _headers(auth: true))
              .timeout(const Duration(seconds: 30));
          return _decode(retry);
        }
      }
      NetworkStateService.markOnline();
      return _decode(res);
    } catch (e) {
      _rethrowAsNetwork(e);
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'DELETE $url');
    try {
      final res = await http
          .delete(Uri.parse(url), headers: _headers(auth: auth))
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http
              .delete(Uri.parse(url), headers: _headers(auth: true))
              .timeout(const Duration(seconds: 30));
          return _decode(retry);
        }
      }
      NetworkStateService.markOnline();
      return _decode(res);
    } catch (e) {
      _rethrowAsNetwork(e);
    }
  }
}
