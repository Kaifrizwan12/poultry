import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:flutter/foundation.dart';

/// Base service for all poultry CRUD entities. Handles both online and offline
/// paths transparently. All poultry models extend [BaseSettingsModel].
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

  T parseItem(Map<String, dynamic> map) => _parser(map);
  List<T> parseAll(List<Map<String, dynamic>> data) => data.map(_parser).toList();

  Map<String, dynamic> _toMap(T item) {
    if (item is BaseSettingsModel) {
      return {'id': item.id, ...item.toJson()};
    }
    return {};
  }

  // ── Logging (unchanged) ──────────────────────────────────────────────────────

  static void _log(String method, String path,
      {String? detail, Object? error}) {
    if (!kDebugMode) return;
    final ts   = DateTime.now().toIso8601String();
    final full = '/api/v1$path';
    if (error != null) {
      debugPrint('[$ts] [POULTRY] ERROR $method $full — $error');
    } else if (detail != null) {
      debugPrint('[$ts] [POULTRY] $method $full — $detail');
    } else {
      debugPrint('[$ts] [POULTRY] $method $full');
    }
  }

  // ── FETCH ALL ────────────────────────────────────────────────────────────────

  Future<List<T>> fetchAll({String? queryString}) async {
    final path     = queryString != null ? '$_basePath?$queryString' : _basePath;
    final cacheKey = OfflineCacheService.poultryListKey(entityPath,
        queryString: queryString);
    _log('GET', path);
    try {
      final response = await _api.get(path, auth: true);
      final items    = _unwrapList(response).map(_parser).toList();
      await OfflineCacheService.saveList(
          cacheKey, items.map(_toMap).toList());
      await OfflineCacheService.saveTimestamp(cacheKey);
      _log('GET', path, detail: '${items.length} records');
      return items;
    } on NetworkException {
      final cached = OfflineCacheService.readList(cacheKey);
      if (cached != null) {
        _log('GET', path, detail: 'cache hit (offline)');
        return cached.map(_parser).toList();
      }
      throw AppException(
          'No internet and no cached data available for $entityPath.');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── FETCH BY ID ──────────────────────────────────────────────────────────────

  Future<T> fetchById(String id) async {
    final path     = '$_basePath/$id';
    final cacheKey = OfflineCacheService.poultryItemKey(entityPath, id);
    _log('GET', path);
    try {
      final response = await _api.get(path, auth: true);
      final item     = _parser(_unwrapItem(response));
      await OfflineCacheService.saveItem(cacheKey, _toMap(item));
      _log('GET', path, detail: 'found');
      return item;
    } on NetworkException {
      final cached = OfflineCacheService.readItem(cacheKey);
      if (cached != null) {
        _log('GET', path, detail: 'cache hit (offline)');
        return _parser(cached);
      }
      throw AppException('No internet and item not cached: $entityPath/$id');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────

  Future<T> create(Map<String, dynamic> body) async {
    final cacheKey = OfflineCacheService.poultryListKey(entityPath);
    _log('POST', _basePath);
    try {
      final response = await _api.post(_basePath, body, auth: true);
      final item     = _parser(_unwrapItem(response));
      final list     = OfflineCacheService.readList(cacheKey) ?? [];
      list.insert(0, _toMap(item));
      await OfflineCacheService.saveList(cacheKey, list);
      if (item is BaseSettingsModel) {
        await OfflineCacheService.saveItem(
            OfflineCacheService.poultryItemKey(entityPath, item.id),
            _toMap(item));
      }
      _log('POST', _basePath, detail: 'created');
      return item;
    } on NetworkException {
      final tempId  = OfflineOperation.generateTempId();
      final fullMap = {'id': tempId, ...body};
      final item    = _parser(fullMap);
      final list    = OfflineCacheService.readList(cacheKey) ?? [];
      list.insert(0, fullMap);
      await OfflineCacheService.saveList(cacheKey, list);
      await OfflineQueueService.enqueue(OfflineOperation(
        id: OfflineOperation.generateId(),
        module: 'poultry',
        entity: entityPath,
        method: 'POST',
        path: _basePath,
        payload: body,
        localTempId: tempId,
        createdAt: DateTime.now(),
      ));
      _log('POST', _basePath, detail: 'queued offline create $tempId');
      return item;
    } catch (e) {
      _log('POST', _basePath, error: e);
      rethrow;
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  Future<T> update(String id, Map<String, dynamic> body) async {
    final path     = '$_basePath/$id';
    final cacheKey = OfflineCacheService.poultryListKey(entityPath);
    _log('PUT', path);
    try {
      final response = await _api.put(path, body, auth: true);
      final item     = _parser(_unwrapItem(response));
      final updated  = _toMap(item);
      final list     = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.map((m) => m['id'] == id ? updated : m).toList());
      await OfflineCacheService.saveItem(
          OfflineCacheService.poultryItemKey(entityPath, id), updated);
      _log('PUT', path, detail: 'updated');
      return item;
    } on NetworkException {
      final fullMap = {'id': id, ...body};
      final item    = _parser(fullMap);
      final list    = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.map((m) => m['id'] == id ? fullMap : m).toList());
      await OfflineCacheService.saveItem(
          OfflineCacheService.poultryItemKey(entityPath, id), fullMap);
      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        pendingCreate.payload = {...pendingCreate.payload, ...body};
        await OfflineQueueService.update(pendingCreate);
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'poultry',
          entity: entityPath,
          method: 'PUT',
          path: path,
          payload: body,
          recordId: id,
          createdAt: DateTime.now(),
        ));
      }
      _log('PUT', path, detail: 'queued offline update');
      return item;
    } catch (e) {
      _log('PUT', path, error: e);
      rethrow;
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    final path     = '$_basePath/$id';
    final cacheKey = OfflineCacheService.poultryListKey(entityPath);
    _log('DELETE', path);
    try {
      final response = await _api.delete(path, auth: true);
      if (response['success'] != true) {
        throw AppException(_mapError(response, 'Unable to delete record'));
      }
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());
      await OfflineCacheService.removeItem(
          OfflineCacheService.poultryItemKey(entityPath, id));
      _log('DELETE', path, detail: 'deleted');
    } on NetworkException {
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());
      await OfflineCacheService.removeItem(
          OfflineCacheService.poultryItemKey(entityPath, id));
      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        await OfflineQueueService.remove(pendingCreate.id);
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'poultry',
          entity: entityPath,
          method: 'DELETE',
          path: path,
          payload: {},
          recordId: id,
          createdAt: DateTime.now(),
        ));
      }
      _log('DELETE', path, detail: 'queued offline delete');
    } catch (e) {
      _log('DELETE', path, error: e);
      rethrow;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

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

  String _mapError(Map<String, dynamic> response, String fallback) =>
      '${response['error'] ?? fallback}'.trim();
}
