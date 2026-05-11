import 'dart:convert';
import 'dart:developer' as developer;
import 'package:farm_mgt_auth/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:farm_mgt_auth/services/local_storage_service.dart';

typedef SessionRefreshHandler = Future<bool> Function();

SessionRefreshHandler? _sessionRefreshHandler;

void registerSessionRefreshHandler(SessionRefreshHandler handler) {
  _sessionRefreshHandler = handler;
}

class ApiService {
  static const base = ApiConfig.baseUrl;
  static const bool _enableVerboseLogs = false;

  /// Detailed request/response logging for debugging API integration
  static void _log(String level, String message, {dynamic data}) {
    if (!_enableVerboseLogs && !kDebugMode) {
      return;
    }
    if (!_enableVerboseLogs) {
      return;
    }
    final timestamp = DateTime.now().toIso8601String();
    final logMsg = '[$timestamp] [$level] $message';
    final sanitized = _sanitizeData(data);
    if (data != null) {
      developer.log(logMsg, name: 'ApiService', error: sanitized);
      print('$logMsg\n${jsonEncode(sanitized)}');
    } else {
      developer.log(logMsg, name: 'ApiService');
      print(logMsg);
    }
  }

  static dynamic _sanitizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final next = <String, dynamic>{};
      for (final entry in data.entries) {
        if (entry.key.toLowerCase() == 'authorization') {
          next[entry.key] = 'Bearer [REDACTED]';
        } else if (entry.value is Map<String, dynamic>) {
          next[entry.key] = _sanitizeData(entry.value);
        } else {
          next[entry.key] = entry.value;
        }
      }
      return next;
    }
    return data;
  }

  Map<String, String> _headers({
    Map<String, String>? headers,
    bool auth = false,
  }) {
    final finalHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (auth) {
      final token = LocalStorageService.token();
      if (token != null && token.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
      }
    }

    return finalHeaders;
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    if (res.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'POST request', data: {'url': url, 'body': body});

    try {
      final res = await http.post(Uri.parse(url),
          body: jsonEncode(body), headers: _headers(auth: auth));

      _log('INFO', 'Response received',
          data: {'statusCode': res.statusCode, 'url': url});

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http.post(
            Uri.parse(url),
            body: jsonEncode(body),
            headers: _headers(auth: true),
          );
          _log('INFO', 'Retry response received',
              data: {'statusCode': retry.statusCode, 'url': url});
          return _decode(retry);
        }
      }

      if (res.statusCode != 200) {
        _log('WARN', 'Non-200 response', data: {'statusCode': res.statusCode});
      }

      final decoded = await _decode(res);
      _log('INFO', 'Response body decoded', data: decoded);
      return decoded;
    } catch (e, stackTrace) {
      _log('ERROR', 'API request failed', data: {
        'url': url,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final url = '$base$path';
    final finalHeaders = _headers(headers: headers, auth: auth);
    _log('INFO', 'GET request', data: {'url': url, 'headers': finalHeaders});

    try {
      final res = await http.get(Uri.parse(url), headers: finalHeaders);

      _log('INFO', 'Response received',
          data: {'statusCode': res.statusCode, 'url': url});

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry =
              await http.get(Uri.parse(url), headers: _headers(auth: true));
          _log('INFO', 'Retry response received',
              data: {'statusCode': retry.statusCode, 'url': url});
          return _decode(retry);
        }
      }

      final decoded = await _decode(res);
      _log('INFO', 'Response body decoded', data: decoded);
      return decoded;
    } catch (e, stackTrace) {
      _log('ERROR', 'GET request failed', data: {
        'url': url,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'PUT request', data: {'url': url, 'body': body});

    try {
      final res = await http.put(Uri.parse(url),
          body: jsonEncode(body), headers: _headers(auth: auth));

      _log('INFO', 'Response received',
          data: {'statusCode': res.statusCode, 'url': url});

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry = await http.put(
            Uri.parse(url),
            body: jsonEncode(body),
            headers: _headers(auth: true),
          );
          _log('INFO', 'Retry response received',
              data: {'statusCode': retry.statusCode, 'url': url});
          return _decode(retry);
        }
      }

      final decoded = await _decode(res);
      _log('INFO', 'Response body decoded', data: decoded);
      return decoded;
    } catch (e, stackTrace) {
      _log('ERROR', 'PUT request failed', data: {
        'url': url,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final url = '$base$path';
    _log('INFO', 'DELETE request', data: {'url': url});

    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: _headers(auth: auth),
      );

      _log('INFO', 'Response received',
          data: {'statusCode': res.statusCode, 'url': url});

      if (res.statusCode == 401 && auth && _sessionRefreshHandler != null) {
        final renewed = await _sessionRefreshHandler!();
        if (renewed) {
          final retry =
              await http.delete(Uri.parse(url), headers: _headers(auth: true));
          _log('INFO', 'Retry response received',
              data: {'statusCode': retry.statusCode, 'url': url});
          return _decode(retry);
        }
      }

      final decoded = await _decode(res);
      _log('INFO', 'Response body decoded', data: decoded);
      return decoded;
    } catch (e, stackTrace) {
      _log('ERROR', 'DELETE request failed', data: {
        'url': url,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }
}
