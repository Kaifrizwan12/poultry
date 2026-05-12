import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'network_state_service.dart';
import 'offline_cache_service.dart';
import 'offline_queue_service.dart';
import '../core/app_exception.dart';

/// Singleton that periodically drains the offline outbox queue.
class OfflineSyncService {
  OfflineSyncService._();
  static final instance = OfflineSyncService._();

  static const _interval  = Duration(seconds: 25);
  static const _maxRetries = 3;

  Timer? _timer;
  bool   _isSyncing = false;
  final  _api = ApiService();

  final List<VoidCallback> _syncListeners = [];
  final Map<String, List<void Function(String, String)>> _tempIdListeners = {};

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[SYNC] $msg');
  }

  // ── Subscription API ─────────────────────────────────────────────────────────

  void addSyncListener(VoidCallback cb) => _syncListeners.add(cb);
  void removeSyncListener(VoidCallback cb) => _syncListeners.remove(cb);

  void addTempIdListener(String entity, void Function(String, String) cb) {
    _tempIdListeners[entity] ??= [];
    _tempIdListeners[entity]!.add(cb);
  }

  void removeTempIdListener(String entity, void Function(String, String) cb) {
    _tempIdListeners[entity]?.remove(cb);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _trySyncOnce());
    _log('started  (interval=${_interval.inSeconds}s)');
    Future.microtask(_trySyncOnce);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _log('stopped');
  }

  void triggerSync() {
    _log('triggerSync  (immediate)');
    Future.microtask(_trySyncOnce);
  }

  // ── Sync loop ────────────────────────────────────────────────────────────────

  Future<void> _trySyncOnce() async {
    final pending = OfflineQueueService.pendingCount;
    if (pending == 0) {
      _log('tick  queue empty – skip');
      return;
    }
    if (_isSyncing) {
      _log('tick  already syncing – skip');
      return;
    }
    _log('tick  pending=$pending – starting cycle');
    _isSyncing = true;
    try {
      await _syncCycle();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCycle() async {
    // 1. Network check
    final online = await NetworkStateService.isProbablyOnline();
    if (!online) {
      _log('cycle  OFFLINE – aborting');
      return;
    }
    _log('cycle  ONLINE – proceeding');

    // 2. Session check
    if (LocalStorageService.token() == null ||
        LocalStorageService.isTokenExpired()) {
      _log('cycle  token missing/expired – attempting refresh');
      final rt = LocalStorageService.refreshToken();
      if (rt == null) {
        _log('cycle  no refresh token – aborting');
        return;
      }
      try {
        final res = await _api.post('/auth/refresh', {'refreshToken': rt});
        final newToken = res['token'] as String?;
        if (newToken == null) {
          _log('cycle  refresh failed (no token in response) – aborting');
          return;
        }
        await LocalStorageService.saveToken(
            newToken, '${res['expiresAt'] ?? ''}');
        final newRt = res['refreshToken'] as String?;
        if (newRt != null) await LocalStorageService.saveRefreshToken(newRt);
        _log('cycle  token refreshed successfully');
      } catch (e) {
        _log('cycle  refresh error: $e – aborting');
        return;
      }
    }

    // 3. Process queue
    final ops = OfflineQueueService.getAll()
        .where((op) =>
            op.syncStatus == SyncStatus.pending ||
            op.syncStatus == SyncStatus.failed)
        .toList();

    _log('cycle  processing ${ops.length} op(s)');
    bool anySynced = false;

    for (final op in ops) {
      _log('op  [${op.id}]  ${op.method} ${op.path}'
          '${op.localTempId != null ? '  tempId=${op.localTempId}' : ''}');
      try {
        await _processOp(op);
        await OfflineQueueService.remove(op.id);
        _log('op  [${op.id}]  ✓ SUCCESS');
        anySynced = true;
      } on NetworkException {
        _log('op  [${op.id}]  ✗ NetworkException – stopping cycle');
        break;
      } on AppException catch (e) {
        op.retryCount++;
        op.lastError = e.message;
        op.syncStatus = op.retryCount >= _maxRetries
            ? SyncStatus.failed
            : SyncStatus.pending;
        _log('op  [${op.id}]  ✗ AppException  retries=${op.retryCount}'
            '  msg=${e.message}');
        if (op.retryCount >= _maxRetries) {
          _log('op  [${op.id}]  ABANDONED after $_maxRetries retries');
          await OfflineQueueService.remove(op.id);
        } else {
          await OfflineQueueService.update(op);
        }
      } catch (e) {
        op.retryCount++;
        op.lastError = e.toString();
        op.syncStatus = SyncStatus.pending;
        _log('op  [${op.id}]  ✗ error  retries=${op.retryCount}  $e');
        await OfflineQueueService.update(op);
      }
    }

    if (anySynced) {
      _log('cycle  complete  notifying ${_syncListeners.length} listener(s)');
      _notifySyncComplete();
    } else {
      _log('cycle  complete  nothing synced');
    }
  }

  // ── Per-operation dispatch ────────────────────────────────────────────────────

  Future<void> _processOp(OfflineOperation op) async {
    switch (op.method) {
      case 'POST':
        final res = await _api.post(op.path, op.payload, auth: true);
        await _handleCreate(op, res);
        break;
      case 'PUT':
        final res = await _api.put(op.path, op.payload, auth: true);
        await _handleUpdate(op, res);
        break;
      case 'DELETE':
        await _api.delete(op.path, auth: true);
        break;
      default:
        _log('op  [${op.id}]  unknown method ${op.method} – skipping');
    }
  }

  Future<void> _handleCreate(
      OfflineOperation op, Map<String, dynamic> res) async {
    if (res['success'] != true) {
      throw AppException('${res['error'] ?? 'Create failed'}');
    }
    final raw = res['data'];
    if (raw is! Map) return;
    final realItem = Map<String, dynamic>.from(raw);
    final realId   = '${realItem['id'] ?? ''}';
    if (realId.isEmpty || op.localTempId == null) return;

    _log('create  tempId=${op.localTempId}  →  realId=$realId');

    final listKey = _listCacheKey(op);
    if (listKey.isNotEmpty) {
      final list = OfflineCacheService.readList(listKey) ?? [];
      await OfflineCacheService.saveList(
        listKey,
        list.map((m) => m['id'] == op.localTempId ? realItem : m).toList(),
      );
    }

    if (op.module == 'poultry') {
      await OfflineCacheService.saveItem(
          OfflineCacheService.poultryItemKey(op.entity, realId), realItem);
      await OfflineCacheService.removeItem(
          OfflineCacheService.poultryItemKey(op.entity, op.localTempId!));
    } else if (op.module == 'accounts') {
      await OfflineCacheService.saveItem(
          OfflineCacheService.ledgerItemKey(realId), realItem);
      await OfflineCacheService.removeItem(
          OfflineCacheService.ledgerItemKey(op.localTempId!));
    }

    await OfflineQueueService.replaceTempId(op.localTempId!, realId);

    final listeners = _tempIdListeners[op.entity]?.length ?? 0;
    _log('create  notifying $listeners controller listener(s) for entity=${op.entity}');
    _tempIdListeners[op.entity]?.forEach((cb) => cb(op.localTempId!, realId));
  }

  Future<void> _handleUpdate(
      OfflineOperation op, Map<String, dynamic> res) async {
    if (res['success'] != true) return;
    final raw = res['data'];
    if (raw is! Map) return;
    final realItem = Map<String, dynamic>.from(raw);
    final realId   = '${realItem['id'] ?? op.recordId ?? ''}';

    final listKey = _listCacheKey(op);
    if (listKey.isNotEmpty) {
      final list = OfflineCacheService.readList(listKey) ?? [];
      await OfflineCacheService.saveList(
        listKey,
        list.map((m) => m['id'] == realId ? realItem : m).toList(),
      );
      _log('update  patched $realId in $listKey');
    }
  }

  String _listCacheKey(OfflineOperation op) {
    switch (op.module) {
      case 'settings': return OfflineCacheService.settingsListKey(op.entity);
      case 'poultry':  return OfflineCacheService.poultryListKey(op.entity);
      case 'accounts': return OfflineCacheService.ledgerListKey();
      default:         return '';
    }
  }

  void _notifySyncComplete() {
    for (final cb in _syncListeners) {
      try { cb(); } catch (_) {}
    }
  }
}
