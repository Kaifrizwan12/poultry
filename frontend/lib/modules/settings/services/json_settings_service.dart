import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/modules/settings/services/settings_service_base.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:flutter/foundation.dart';

class JsonSettingsService<T> extends SettingsServiceBase<T> {
  JsonSettingsService({
    required String entity,
    required T Function(Map<String, dynamic>) parser,
  })  : _parser = parser,
        _apiService = ApiService(),
        super(entity);

  final ApiService _apiService;
  final T Function(Map<String, dynamic>) _parser;

  String get _path => '/settings/$entity';

  /// Whether the last [fetchAll] returned cached data (true) or live API data (false).
  bool wasLastFetchOffline = false;

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[SETTINGS] $msg');
  }

  // ── Public parse helper (used by controller's sync listener) ────────────────

  T parseItem(Map<String, dynamic> map) => _parser(map);
  List<T> parseAll(List<Map<String, dynamic>> data) => data.map(_parser).toList();

  // ── Serialise a model instance for local cache storage ──────────────────────

  Map<String, dynamic> _toMap(T item) {
    if (item is BaseSettingsModel) {
      return {'id': item.id, ...item.toJson()};
    }
    return {};
  }

  // ── FETCH ────────────────────────────────────────────────────────────────────

  @override
  Future<List<T>> fetchAll() async {
    final cacheKey = OfflineCacheService.settingsListKey(entity);
    _log('fetchAll  entity=$entity');
    try {
      final response = await _apiService.get(_path, auth: true);
      final data  = _unwrapList(response);
      final items = data.map(_parser).toList();
      await OfflineCacheService.saveList(cacheKey, items.map(_toMap).toList());
      await OfflineCacheService.saveTimestamp(cacheKey);
      wasLastFetchOffline = false;
      _log('fetchAll  entity=$entity  ✓ ${items.length} items from API');
      return items;
    } on NetworkException {
      final cached = OfflineCacheService.readList(cacheKey);
      if (cached != null) {
        wasLastFetchOffline = true;
        _log('fetchAll  entity=$entity  → cache hit (${cached.length} items, OFFLINE)');
        return cached.map(_parser).toList();
      }
      wasLastFetchOffline = true;
      _log('fetchAll  entity=$entity  ✗ OFFLINE + no cache');
      throw AppException(
          'No internet connection and no saved data available for $entity.');
    }
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────

  @override
  Future<T> create(Map<String, dynamic> body) async {
    final cacheKey = OfflineCacheService.settingsListKey(entity);
    _log('create  entity=$entity');
    try {
      final response = await _apiService.post(_path, body, auth: true);
      final item = _parser(_unwrapItem(response));
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      list.insert(0, _toMap(item));
      await OfflineCacheService.saveList(cacheKey, list);
      _log('create  entity=$entity  ✓ online');
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
        module: 'settings',
        entity: entity,
        method: 'POST',
        path: _path,
        payload: body,
        localTempId: tempId,
        createdAt: DateTime.now(),
      ));
      _log('create  entity=$entity  → queued offline  tempId=$tempId');
      return item;
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  @override
  Future<T> update(String id, Map<String, dynamic> body) async {
    final cacheKey = OfflineCacheService.settingsListKey(entity);
    _log('update  entity=$entity  id=$id');
    try {
      final response = await _apiService.put('$_path/$id', body, auth: true);
      final item    = _parser(_unwrapItem(response));
      final list    = OfflineCacheService.readList(cacheKey) ?? [];
      final updated = list.map((m) => m['id'] == id ? _toMap(item) : m).toList();
      await OfflineCacheService.saveList(cacheKey, updated);
      _log('update  entity=$entity  id=$id  ✓ online');
      return item;
    } on NetworkException {
      final fullMap = {'id': id, ...body};
      final item = _parser(fullMap);
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
        cacheKey,
        list.map((m) => m['id'] == id ? fullMap : m).toList(),
      );
      // If there's already a pending CREATE for this temp record, merge into it
      // instead of queuing a separate PUT.
      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        pendingCreate.payload = {...pendingCreate.payload, ...body};
        await OfflineQueueService.update(pendingCreate);
        _log('update  entity=$entity  id=$id  → merged into pending CREATE (offline)');
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'settings',
          entity: entity,
          method: 'PUT',
          path: '$_path/$id',
          payload: body,
          recordId: id,
          createdAt: DateTime.now(),
        ));
        _log('update  entity=$entity  id=$id  → queued PUT (offline)');
      }
      return item;
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(String id) async {
    final cacheKey = OfflineCacheService.settingsListKey(entity);
    _log('delete  entity=$entity  id=$id');
    try {
      final response = await _apiService.delete('$_path/$id', auth: true);
      if (response['success'] != true) {
        throw AppException(_mapError(response, 'Unable to delete record'));
      }
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());
      _log('delete  entity=$entity  id=$id  ✓ online');
    } on NetworkException {
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());

      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        await OfflineQueueService.remove(pendingCreate.id);
        _log('delete  entity=$entity  id=$id  → dropped pending CREATE (never synced)');
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'settings',
          entity: entity,
          method: 'DELETE',
          path: '$_path/$id',
          payload: {},
          recordId: id,
          createdAt: DateTime.now(),
        ));
        _log('delete  entity=$entity  id=$id  → queued DELETE (offline)');
      }
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Unable to fetch records'));
    }
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
    final raw = '${response['error'] ?? fallback}'.trim();
    if (raw == 'not found') {
      return 'Settings API route was not found. Restart the backend server and try again.';
    }
    return raw;
  }
}
