import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

/// Namespaced JSON cache on top of SharedPreferences.
/// All keys are scoped to the current farmId so multi-farm or multi-user
/// devices never bleed data across accounts.
class OfflineCacheService {
  static late SharedPreferences _prefs;

  static void init(SharedPreferences prefs) => _prefs = prefs;

  static String _fid() => LocalStorageService.farmId() ?? 'default';

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[CACHE] $msg');
  }

  // ── Key builders ────────────────────────────────────────────────────────────

  static String settingsListKey(String entity) =>
      'cache:${_fid()}:settings:$entity:list';

  static String settingsTsKey(String entity) =>
      'cache:${_fid()}:settings:$entity:ts';

  static String poultryListKey(String entity, {String? queryString}) {
    final suffix = (queryString != null && queryString.isNotEmpty)
        ? ':${queryString.hashCode.abs()}'
        : '';
    return 'cache:${_fid()}:poultry:$entity:list$suffix';
  }

  static String poultryItemKey(String entity, String id) =>
      'cache:${_fid()}:poultry:$entity:item:$id';

  static String poultryTsKey(String entity) =>
      'cache:${_fid()}:poultry:$entity:ts';

  static String poultryReportKey(String reportName, String paramHash) =>
      'cache:${_fid()}:poultry:report:$reportName:$paramHash';

  static String invoicingListKey(String entity, {String? queryString}) {
    final suffix = (queryString != null && queryString.isNotEmpty)
        ? ':${queryString.hashCode.abs()}'
        : '';
    return 'cache:${_fid()}:invoicing:$entity:list$suffix';
  }

  static String invoicingItemKey(String entity, String id) =>
      'cache:${_fid()}:invoicing:$entity:item:$id';

  static String invoicingTsKey(String entity) =>
      'cache:${_fid()}:invoicing:$entity:ts';

  static String ledgerListKey() => 'cache:${_fid()}:accounts:ledger:list';

  static String ledgerItemKey(String id) =>
      'cache:${_fid()}:accounts:ledger:item:$id';

  static String ledgerByAccountKey(String accountId, String hash) =>
      'cache:${_fid()}:accounts:ledger:by_account:$accountId:$hash';

  static String ledgerSummaryKey() =>
      'cache:${_fid()}:accounts:ledger:summary';

  static String ledgerTsKey() => 'cache:${_fid()}:accounts:ledger:ts';

  // ── List helpers ─────────────────────────────────────────────────────────────

  static Future<void> saveList(
      String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
    _log('WRITE  $key  (${items.length} items)');
  }

  static List<Map<String, dynamic>>? readList(String key) {
    final s = _prefs.getString(key);
    if (s == null) {
      _log('MISS   $key');
      return null;
    }
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) {
        _log('CORRUPT $key – not a list');
        return null;
      }
      final result = decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      _log('HIT    $key  (${result.length} items)');
      return result;
    } catch (e) {
      _log('CORRUPT $key – parse error: $e');
      return null;
    }
  }

  // ── Item helpers ─────────────────────────────────────────────────────────────

  static Future<void> saveItem(
      String key, Map<String, dynamic> item) async {
    await _prefs.setString(key, jsonEncode(item));
    _log('WRITE  $key  (item)');
  }

  static Map<String, dynamic>? readItem(String key) {
    final s = _prefs.getString(key);
    if (s == null) {
      _log('MISS   $key');
      return null;
    }
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) {
        _log('CORRUPT $key – not a map');
        return null;
      }
      _log('HIT    $key');
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      _log('CORRUPT $key – parse error: $e');
      return null;
    }
  }

  static Future<void> removeItem(String key) async {
    await _prefs.remove(key);
    _log('DELETE $key');
  }

  // ── Timestamp helpers ────────────────────────────────────────────────────────

  static Future<void> saveTimestamp(String key) async {
    final ts = DateTime.now().toIso8601String();
    await _prefs.setString('${key}_ts', ts);
    _log('TS     $key  = $ts');
  }

  static DateTime? readTimestamp(String key) {
    final s = _prefs.getString('${key}_ts');
    return s != null ? DateTime.tryParse(s) : null;
  }

  // ── Farm-scoped cache wipe (call on logout) ──────────────────────────────────

  static Future<void> clearFarmCache() async {
    final fid = _fid();
    final keys = _prefs
        .getKeys()
        .where((k) =>
            k.startsWith('cache:$fid:') || k.startsWith('outbox:$fid:'))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
    _log('CLEARED farm cache for farmId=$fid  (${keys.length} keys removed)');
  }

  // ── Offline entry-number counter ─────────────────────────────────────────────

  static String nextOfflineEntryNo() {
    final counterKey = 'cache:${_fid()}:accounts:offline_entry_counter';
    final count = (_prefs.getInt(counterKey) ?? 0) + 1;
    _prefs.setInt(counterKey, count);
    final no = 'OFF-JV-${count.toString().padLeft(4, '0')}';
    _log('OFFLINE_ENTRY_NO generated: $no');
    return no;
  }
}
