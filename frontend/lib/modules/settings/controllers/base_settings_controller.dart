import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/modules/settings/services/json_settings_service.dart';
import 'package:farm_mgt_auth/modules/settings/services/settings_service_base.dart';
import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';

abstract class SettingsCrudController extends ChangeNotifier {
  List<BaseSettingsModel> get items;
  List<BaseSettingsModel> get filteredItems;
  bool get isLoading;
  String? get error;
  String get searchQuery;
  bool get isOfflineData;
  bool get hasPendingSync;
  Future<void> fetchAll();
  Future<void> add(Map<String, dynamic> payload);
  Future<void> updateItem(String id, Map<String, dynamic> payload);
  Future<void> deleteItem(String id);
  void setSearchQuery(String value);
}

class SettingsEntityController<T extends BaseSettingsModel>
    extends ChangeNotifier implements SettingsCrudController {
  SettingsEntityController({
    required SettingsServiceBase<T> service,
    required List<String> searchableFields,
  })  : _service = service,
        _searchableFields = searchableFields {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener(
        (service as JsonSettingsService<T>).entity, _onTempIdReplaced);
  }

  final SettingsServiceBase<T> _service;
  final List<String> _searchableFields;

  List<T> _typedItems = <T>[];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _isOfflineData = false;

  @override
  void dispose() {
    final svc = _service;
    if (svc is JsonSettingsService<T>) {
      OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
      OfflineSyncService.instance
          .removeTempIdListener(svc.entity, _onTempIdReplaced);
    }
    super.dispose();
  }

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<T> get typedItems => _typedItems;

  @override
  List<BaseSettingsModel> get items => List<BaseSettingsModel>.from(_typedItems);

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  String get searchQuery => _searchQuery;

  @override
  bool get isOfflineData => _isOfflineData;

  @override
  bool get hasPendingSync =>
      _typedItems.any((item) => OfflineOperation.isTemp(item.id));

  DateTime? get lastSyncedAt {
    final svc = _service;
    if (svc is JsonSettingsService<T>) {
      return OfflineCacheService.readTimestamp(
          OfflineCacheService.settingsListKey(svc.entity));
    }
    return null;
  }

  @override
  List<BaseSettingsModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      return _searchableFields.any(
          (field) => item.text(field).toLowerCase().contains(query));
    }).toList();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  @override
  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _typedItems = await _service.fetchAll();
      final svc = _service;
      if (svc is JsonSettingsService<T>) {
        _isOfflineData = svc.wasLastFetchOffline;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _typedItems = <T>[record, ..._typedItems];
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  @override
  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _typedItems = _typedItems.map((item) => item.id == id ? record : item).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  @override
  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _typedItems = _typedItems.where((item) => item.id != id).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  @override
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  List<T> whereFieldEquals(String field, String? value) {
    if (value == null || value.isEmpty) return _typedItems;
    return _typedItems.where((item) => item.text(field) == value).toList();
  }

  // ── Sync callbacks ────────────────────────────────────────────────────────────

  // After any sync cycle completes, silently refresh from the updated cache.
  void _onSyncComplete() {
    final svc = _service;
    if (svc is! JsonSettingsService<T>) return;
    final cached =
        OfflineCacheService.readList(OfflineCacheService.settingsListKey(svc.entity));
    if (cached == null) return;
    _typedItems = svc.parseAll(cached);
    _isOfflineData = false;
    notifyListeners();
  }

  // Replace a temp record in-memory once the server returns the real ID.
  void _onTempIdReplaced(String tempId, String realId) {
    final svc = _service;
    if (svc is! JsonSettingsService<T>) return;
    bool changed = false;
    _typedItems = _typedItems.map((item) {
      if (item.id != tempId) return item;
      changed = true;
      return svc.parseItem({'id': realId, ...item.toJson()});
    }).toList();
    if (changed) notifyListeners();
  }
}
