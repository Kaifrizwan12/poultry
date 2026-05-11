import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:flutter/foundation.dart';

import '../models/ledger_entry_model.dart';
import '../models/ledger_view_model.dart';

class LedgerService {
  LedgerService() : _api = ApiService();

  final ApiService _api;
  static const _base = '/accounts/ledger';

  static void _log(String method, String path, {String? detail, Object? error}) {
    if (!kDebugMode) return;
    final ts   = DateTime.now().toIso8601String();
    final full = '/api/v1$path';
    if (error != null) {
      debugPrint('[$ts] [ACCOUNTS] ERROR $method $full — $error');
    } else if (detail != null) {
      debugPrint('[$ts] [ACCOUNTS] $method $full — $detail');
    } else {
      debugPrint('[$ts] [ACCOUNTS] $method $full');
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<List<LedgerEntry>> fetchAll({Map<String, String>? filters}) async {
    final qs = filters != null && filters.isNotEmpty
        ? '?${filters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final path = '$_base$qs';
    _log('GET', path);
    try {
      final res   = await _api.get(path, auth: true);
      final items = _unwrapList(res).map(LedgerEntry.fromJson).toList();
      _log('GET', path, detail: '${items.length} records');
      return items;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<LedgerEntry> fetchById(String id) async {
    final path = '$_base/$id';
    _log('GET', path);
    try {
      final res  = await _api.get(path, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      _log('GET', path, detail: 'found');
      return item;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<LedgerEntry> create(Map<String, dynamic> body) async {
    _log('POST', _base);
    try {
      final res  = await _api.post(_base, body, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      _log('POST', _base, detail: 'created ${item.id}');
      return item;
    } catch (e) {
      _log('POST', _base, error: e);
      rethrow;
    }
  }

  Future<LedgerEntry> update(String id, Map<String, dynamic> body) async {
    final path = '$_base/$id';
    _log('PUT', path);
    try {
      final res  = await _api.put(path, body, auth: true);
      final item = LedgerEntry.fromJson(_unwrapItem(res));
      _log('PUT', path, detail: 'updated');
      return item;
    } catch (e) {
      _log('PUT', path, error: e);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final path = '$_base/$id';
    _log('DELETE', path);
    try {
      final res = await _api.delete(path, auth: true);
      if (res['success'] != true) throw AppException(_mapError(res, 'Unable to delete record'));
      _log('DELETE', path, detail: 'deleted');
    } catch (e) {
      _log('DELETE', path, error: e);
      rethrow;
    }
  }

  // ── Special endpoints ────────────────────────────────────────────────────────

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

    final qs   = params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}' : '';
    final path = '$_base/by-account/$accountId$qs';
    _log('GET', path);
    try {
      final res   = await _api.get(path, auth: true);
      final model = LedgerViewModel.fromJson(_unwrapItem(res));
      _log('GET', path, detail: '${model.entries.length} entries, closing=${model.closingBalance}');
      return model;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSummary() async {
    const path = '$_base/summary';
    _log('GET', path);
    try {
      final res = await _api.get(path, auth: true);
      final raw = _unwrapList(res);
      _log('GET', path, detail: '${raw.length} accounts in summary');
      return raw;
    } catch (e) {
      _log('GET', path, error: e);
      rethrow;
    }
  }

  Future<String> nextEntryNo() async {
    const path = '$_base/next-entry-no';
    _log('POST', path);
    try {
      final res  = await _api.post(path, {}, auth: true);
      final data = _unwrapItem(res);
      final no   = '${data['nextEntryNo'] ?? 'JV-0001'}';
      _log('POST', path, detail: no);
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

  String _mapError(Map<String, dynamic> response, String fallback) {
    return '${response['error'] ?? fallback}'.trim();
  }
}
