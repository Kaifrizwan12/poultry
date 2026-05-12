import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

enum SyncStatus { pending, syncing, failed }

/// A single mutation that must be replayed against the backend.
class OfflineOperation {
  OfflineOperation({
    required this.id,
    required this.module,
    required this.entity,
    required this.method,
    required this.path,
    required this.payload,
    required this.createdAt,
    this.recordId,
    this.localTempId,
    this.retryCount = 0,
    this.lastError,
    this.syncStatus = SyncStatus.pending,
  });

  final String id;
  final String module;
  final String entity;
  final String method;
  String path;
  Map<String, dynamic> payload;
  String? recordId;
  final String? localTempId;
  final DateTime createdAt;
  int retryCount;
  String? lastError;
  SyncStatus syncStatus;

  bool get isLocalRecord =>
      localTempId != null || (recordId?.startsWith('local_') ?? false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'entity': entity,
        'method': method,
        'path': path,
        'payload': payload,
        'recordId': recordId,
        'localTempId': localTempId,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
        'syncStatus': syncStatus.name,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) =>
      OfflineOperation(
        id: '${json['id'] ?? ''}',
        module: '${json['module'] ?? ''}',
        entity: '${json['entity'] ?? ''}',
        method: '${json['method'] ?? 'POST'}',
        path: '${json['path'] ?? ''}',
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : <String, dynamic>{},
        recordId: json['recordId'] as String?,
        localTempId: json['localTempId'] as String?,
        createdAt:
            DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastError: json['lastError'] as String?,
        syncStatus: SyncStatus.values.firstWhere(
          (s) => s.name == json['syncStatus'],
          orElse: () => SyncStatus.pending,
        ),
      );

  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'op_${ts}_$rand';
  }

  static String generateTempId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'local_${ts}_$rand';
  }

  static bool isTemp(String id) => id.startsWith('local_');
}

/// Durable outbox queue backed by SharedPreferences.
class OfflineQueueService {
  static late SharedPreferences _prefs;

  static void init(SharedPreferences prefs) => _prefs = prefs;

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[QUEUE] $msg');
  }

  static String _key() =>
      'outbox:${LocalStorageService.farmId() ?? 'default'}:operations';

  // ── Read ────────────────────────────────────────────────────────────────────

  static List<OfflineOperation> getAll() {
    final s = _prefs.getString(_key());
    if (s == null) return [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => OfflineOperation.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static int get pendingCount =>
      getAll().where((op) => op.syncStatus == SyncStatus.pending).length;

  static OfflineOperation? findPendingCreate(String tempId) {
    for (final op in getAll()) {
      if (op.localTempId == tempId && op.method == 'POST') return op;
    }
    return null;
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  static Future<void> enqueue(OfflineOperation op) async {
    final all = getAll()..add(op);
    await _persist(all);
    _log('ENQUEUE  ${op.method} ${op.path}  id=${op.id}'
        '${op.localTempId != null ? '  tempId=${op.localTempId}' : ''}');
    _log('QUEUE_SIZE  total=${all.length}  pending=$pendingCount');
  }

  static Future<void> update(OfflineOperation op) async {
    final all = getAll();
    final idx = all.indexWhere((o) => o.id == op.id);
    if (idx >= 0) {
      all[idx] = op;
      await _persist(all);
      _log('UPDATE  ${op.id}  status=${op.syncStatus.name}'
          '  retries=${op.retryCount}');
    }
  }

  static Future<void> remove(String opId) async {
    final before = getAll();
    final all = before..removeWhere((o) => o.id == opId);
    await _persist(all);
    _log('REMOVE  $opId  remaining=${all.length}');
  }

  static Future<void> removeAll() async {
    await _prefs.remove(_key());
    _log('CLEAR  all operations removed');
  }

  // ── Temp-ID propagation ──────────────────────────────────────────────────────

  static Future<void> replaceTempId(String tempId, String realId) async {
    final all = getAll();
    bool changed = false;
    int patchCount = 0;

    for (final op in all) {
      if (op.localTempId == tempId) continue;

      if (op.path.contains(tempId)) {
        op.path = op.path.replaceAll(tempId, realId);
        changed = true;
        patchCount++;
      }
      if (op.recordId == tempId) {
        op.recordId = realId;
        changed = true;
        patchCount++;
      }
      final updated = _replaceInMap(op.payload, tempId, realId);
      if (updated != null) {
        op.payload = updated;
        changed = true;
        patchCount++;
      }
    }

    if (changed) {
      await _persist(all);
      _log('REPLACE_ID  $tempId → $realId  ($patchCount fields patched)');
    } else {
      _log('REPLACE_ID  $tempId → $realId  (no downstream ops to patch)');
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  static Future<void> _persist(List<OfflineOperation> ops) async {
    await _prefs.setString(
        _key(), jsonEncode(ops.map((o) => o.toJson()).toList()));
  }

  static Map<String, dynamic>? _replaceInMap(
      Map<String, dynamic> map, String from, String to) {
    bool changed = false;
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final v = entry.value;
      if (v is String && v == from) {
        result[entry.key] = to;
        changed = true;
      } else if (v is Map<String, dynamic>) {
        final inner = _replaceInMap(v, from, to);
        result[entry.key] = inner ?? v;
        if (inner != null) changed = true;
      } else {
        result[entry.key] = v;
      }
    }
    return changed ? result : null;
  }
}
