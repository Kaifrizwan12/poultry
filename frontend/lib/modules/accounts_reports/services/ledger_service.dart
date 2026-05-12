import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:flutter/foundation.dart';

import '../models/ledger_entry_model.dart';
import '../models/ledger_view_model.dart';

class LedgerService {
  LedgerService() : _api = ApiService();

  final ApiService _api;
  static const _base = '/accounts/ledger';

  static void _log(String method, String path,
      {String? detail, Object? error}) {
    if (!kDebugMode) return;
    final ts   = DateTime.now().toIso8601String();
    final full = '/api/v1$path';
    if (error  != null) debugPrint('[$ts] [ACCOUNTS] ERROR $method $full — $error');
    else if (detail != null) debugPrint('[$ts] [ACCOUNTS] $method $full — $detail');
    else debugPrint('[$ts] [ACCOUNTS] $method $full');
  }

  // ── FETCH ALL ────────────────────────────────────────────────────────────────

  Future<List<LedgerEntry>> fetchAll({Map<String, String>? filters}) async {
    final qs = filters != null && filters.isNotEmpty
        ? '?${filters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final path     = '$_base$qs';
    final cacheKey = OfflineCacheService.ledgerListKey();
    _log('GET', path);
    try {
      final res   = await _api.get(path, auth: true);
      final items = _unwrapList(res).map(LedgerEntry.fromJson).toList();
      await OfflineCacheService.saveList(
          cacheKey, items.map((e) => e.toFullJson()).toList());
      await OfflineCacheService.saveTimestamp(cacheKey);
      _log('GET', path, detail: '${items.length} records');
      return items;
    } on NetworkException {
      final cached = OfflineCacheService.readList(cacheKey);
      if (cached != null) {
        _log('GET', path, detail: 'cache hit (offline)');
        return cached.map(LedgerEntry.fromJson).toList();
      }
      throw AppException('No internet and no cached ledger data available.');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── FETCH BY ID ──────────────────────────────────────────────────────────────

  Future<LedgerEntry> fetchById(String id) async {
    final path     = '$_base/$id';
    final cacheKey = OfflineCacheService.ledgerItemKey(id);
    _log('GET', path);
    try {
      final res  = await _api.get(path, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      await OfflineCacheService.saveItem(cacheKey, item.toFullJson());
      _log('GET', path, detail: 'found');
      return item;
    } on NetworkException {
      final cached = OfflineCacheService.readItem(cacheKey);
      if (cached != null) return LedgerEntry.fromJson(cached);
      throw AppException('No internet and ledger entry not cached: $id');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────

  Future<LedgerEntry> create(Map<String, dynamic> body) async {
    final cacheKey = OfflineCacheService.ledgerListKey();
    _log('POST', _base);
    try {
      final res  = await _api.post(_base, body, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      list.insert(0, item.toFullJson());
      await OfflineCacheService.saveList(cacheKey, list);
      await OfflineCacheService.saveItem(
          OfflineCacheService.ledgerItemKey(item.id), item.toFullJson());
      _log('POST', _base, detail: 'created ${item.id}');
      return item;
    } on NetworkException {
      final tempId   = OfflineOperation.generateTempId();
      final entryNo  = body['entryNo'] as String?;
      final offlineNo = (entryNo == null || entryNo.isEmpty)
          ? OfflineCacheService.nextOfflineEntryNo()
          : entryNo;
      final now      = DateTime.now().toIso8601String();
      final fullMap  = {
        'id': tempId, 'uid': '', 'createdAt': now, 'updatedAt': now,
        ...body, 'entryNo': offlineNo,
      };
      final item     = LedgerEntry.fromJson(fullMap);
      final list     = OfflineCacheService.readList(cacheKey) ?? [];
      list.insert(0, item.toFullJson());
      await OfflineCacheService.saveList(cacheKey, list);
      await OfflineQueueService.enqueue(OfflineOperation(
        id: OfflineOperation.generateId(),
        module: 'accounts',
        entity: 'ledger',
        method: 'POST',
        path: _base,
        payload: {...body, 'entryNo': offlineNo},
        localTempId: tempId,
        createdAt: DateTime.now(),
      ));
      _log('POST', _base, detail: 'queued offline create $tempId');
      return item;
    } catch (e) {
      _log('POST', _base, error: e);
      rethrow;
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  Future<LedgerEntry> update(String id, Map<String, dynamic> body) async {
    final path     = '$_base/$id';
    final cacheKey = OfflineCacheService.ledgerListKey();
    _log('PUT', path);
    try {
      final res  = await _api.put(path, body, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
        cacheKey,
        list.map((m) => m['id'] == id ? item.toFullJson() : m).toList(),
      );
      await OfflineCacheService.saveItem(
          OfflineCacheService.ledgerItemKey(id), item.toFullJson());
      _log('PUT', path, detail: 'updated');
      return item;
    } on NetworkException {
      final now     = DateTime.now().toIso8601String();
      final fullMap = {'id': id, 'uid': '', 'createdAt': now, 'updatedAt': now, ...body};
      final item    = LedgerEntry.fromJson(fullMap);
      final list    = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
        cacheKey,
        list.map((m) => m['id'] == id ? fullMap : m).toList(),
      );
      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        pendingCreate.payload = {...pendingCreate.payload, ...body};
        await OfflineQueueService.update(pendingCreate);
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'accounts',
          entity: 'ledger',
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
    final path     = '$_base/$id';
    final cacheKey = OfflineCacheService.ledgerListKey();
    _log('DELETE', path);
    try {
      final res = await _api.delete(path, auth: true);
      if (res['success'] != true) {
        throw AppException(_mapError(res, 'Unable to delete record'));
      }
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());
      await OfflineCacheService.removeItem(OfflineCacheService.ledgerItemKey(id));
      _log('DELETE', path, detail: 'deleted');
    } on NetworkException {
      final list = OfflineCacheService.readList(cacheKey) ?? [];
      await OfflineCacheService.saveList(
          cacheKey, list.where((m) => m['id'] != id).toList());
      await OfflineCacheService.removeItem(OfflineCacheService.ledgerItemKey(id));
      final pendingCreate = OfflineQueueService.findPendingCreate(id);
      if (pendingCreate != null) {
        await OfflineQueueService.remove(pendingCreate.id);
      } else {
        await OfflineQueueService.enqueue(OfflineOperation(
          id: OfflineOperation.generateId(),
          module: 'accounts',
          entity: 'ledger',
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

  // ── By-account view ──────────────────────────────────────────────────────────

  Future<LedgerViewModel> fetchByAccount(
    String accountId, {
    String? startDate,
    String? endDate,
    String? entryType,
    bool? isReconciled,
  }) async {
    final params = <String, String>{};
    if (startDate    != null) params['startDate']    = startDate;
    if (endDate      != null) params['endDate']      = endDate;
    if (entryType    != null) params['entryType']    = entryType;
    if (isReconciled != null) params['isReconciled'] = isReconciled.toString();
    final qs   = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final path = '$_base/by-account/$accountId$qs';
    final hash = params.entries.map((e) => '${e.key}=${e.value}').join('&').hashCode.abs().toString();
    final cacheKey = OfflineCacheService.ledgerByAccountKey(accountId, hash);
    _log('GET', path);
    try {
      final res   = await _api.get(path, auth: true);
      final raw   = _unwrapItem(res);
      final model = LedgerViewModel.fromJson(raw);
      await OfflineCacheService.saveItem(cacheKey, raw);
      _log('GET', path,
          detail: '${model.entries.length} entries, closing=${model.closingBalance}');
      return model;
    } on NetworkException {
      final cached = OfflineCacheService.readItem(cacheKey);
      if (cached != null) {
        _log('GET', path, detail: 'cache hit (offline)');
        return LedgerViewModel.fromJson(cached);
      }
      throw AppException(
          'No internet and no cached ledger view for account $accountId.');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── Summary ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSummary() async {
    const path     = '$_base/summary';
    final cacheKey = OfflineCacheService.ledgerSummaryKey();
    _log('GET', path);
    try {
      final res = await _api.get(path, auth: true);
      final raw = _unwrapList(res);
      await OfflineCacheService.saveList(cacheKey, raw);
      _log('GET', path, detail: '${raw.length} accounts');
      return raw;
    } on NetworkException {
      final cached = OfflineCacheService.readList(cacheKey);
      if (cached != null) {
        _log('GET', path, detail: 'cache hit (offline)');
        return cached;
      }
      throw AppException('No internet and no cached ledger summary.');
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  // ── Next entry number ─────────────────────────────────────────────────────────

  Future<String> nextEntryNo() async {
    const path = '$_base/next-entry-no';
    _log('POST', path);
    try {
      final res  = await _api.post(path, {}, auth: true);
      final data = _unwrapItem(res);
      final no   = '${data['nextEntryNo'] ?? 'JV-0001'}';
      _log('POST', path, detail: no);
      return no;
    } on NetworkException {
      final no = OfflineCacheService.nextOfflineEntryNo();
      _log('POST', path, detail: 'offline entry no: $no');
      return no;
    } catch (e) {
      _log('POST', path, error: e);
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

