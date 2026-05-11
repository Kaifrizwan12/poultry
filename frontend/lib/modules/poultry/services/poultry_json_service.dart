import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:flutter/foundation.dart';

// Base service for all poultry CRUD entities. Uses /api/v1/poultry/ path prefix.
class PoultryJsonService<T> {
  PoultryJsonService({
    required this.entityPath,
    required T Function(Map<String, dynamic>) parser,
  })  : _parser = parser,
        _api = ApiService();

  final String entityPath; // e.g. 'feed-schedules'
  final T Function(Map<String, dynamic>) _parser;
  final ApiService _api;

  String get _basePath => '/poultry/$entityPath';

  static void _log(String method, String path, {String? detail, Object? error}) {
    if (!kDebugMode) return;
    final ts = DateTime.now().toIso8601String();
    final full = '/api/v1$path';
    if (error != null) {
      debugPrint('[$ts] [POULTRY] ERROR $method $full — $error');
    } else if (detail != null) {
      debugPrint('[$ts] [POULTRY] $method $full — $detail');
    } else {
      debugPrint('[$ts] [POULTRY] $method $full');
    }
  }

  Future<List<T>> fetchAll({String? queryString}) async {
    final path = queryString != null ? '$_basePath?$queryString' : _basePath;
    _log('GET', path);
    try {
      final response = await _api.get(path, auth: true);
      final items = _unwrapList(response).map(_parser).toList();
      _log('GET', path, detail: '${items.length} records');
      return items;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<T> fetchById(String id) async {
    final path = '$_basePath/$id';
    _log('GET', path);
    try {
      final response = await _api.get(path, auth: true);
      final item = _parser(_unwrapItem(response));
      _log('GET', path, detail: 'found');
      return item;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<T> create(Map<String, dynamic> body) async {
    _log('POST', _basePath);
    try {
      final response = await _api.post(_basePath, body, auth: true);
      final item = _parser(_unwrapItem(response));
      _log('POST', _basePath, detail: 'created');
      return item;
    } catch (e) {
      _log('POST', _basePath, error: e);
      rethrow;
    }
  }

  Future<T> update(String id, Map<String, dynamic> body) async {
    final path = '$_basePath/$id';
    _log('PUT', path);
    try {
      final response = await _api.put(path, body, auth: true);
      final item = _parser(_unwrapItem(response));
      _log('PUT', path, detail: 'updated');
      return item;
    } catch (e) {
      _log('PUT', path, error: e);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final path = '$_basePath/$id';
    _log('DELETE', path);
    try {
      final response = await _api.delete(path, auth: true);
      if (response['success'] != true) {
        throw AppException(_mapError(response, 'Unable to delete record'));
      }
      _log('DELETE', path, detail: 'deleted');
    } catch (e) {
      _log('DELETE', path, error: e);
      rethrow;
    }
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Unable to fetch records'));
    }
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Map<String, dynamic> _unwrapItem(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Request failed'));
    }
    final raw = response['data'];
    if (raw is! Map) throw AppException('Malformed response');
    return Map<String, dynamic>.from(raw);
  }

  String _mapError(Map<String, dynamic> response, String fallback) {
    return '${response['error'] ?? fallback}'.trim();
  }
}
