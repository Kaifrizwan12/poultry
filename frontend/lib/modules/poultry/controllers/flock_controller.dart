import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/flock_model.dart';
import '../services/flock_service.dart';

class FlockController extends ChangeNotifier {
  FlockController() : _service = FlockService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener('flocks', _onTempIdReplaced);
  }

  final FlockService _service;

  List<FlockModel> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _isOfflineData = false;

  List<FlockModel> get items        => _items;
  bool get isLoading                => _isLoading;
  String? get error                 => _error;
  String get searchQuery            => _searchQuery;
  String get statusFilter           => _statusFilter;
  bool get isOfflineData            => _isOfflineData;
  bool get hasPendingSync           =>
      _items.any((f) => OfflineOperation.isTemp(f.id));

  List<FlockModel> get filteredItems {
    var list = _items;
    if (_statusFilter != 'all') {
      list = list.where((f) => f.status == _statusFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) =>
          f.flockName.toLowerCase().contains(q) ||
          f.flockNo.toLowerCase().contains(q) ||
          f.shedNo.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<FlockModel> get activeFlocks =>
      _items.where((f) => f.isActive).toList();

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance.removeTempIdListener('flocks', _onTempIdReplaced);
    super.dispose();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchAll();
      _isOfflineData = false;
    } on Exception catch (e) {
      _error = e.toString();
      _isOfflineData = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<FlockModel> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _items = [record, ..._items];
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
    return record;
  }

  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _items = _items.map((i) => i.id == id ? record : i).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  FlockModel? findById(String id) {
    try {
      return _items.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Refresh a single flock after an invoice affects bird count.
  /// Falls back to cached list silently when offline.
  Future<void> refreshFlock(String flockId) async {
    try {
      final updated = await _service.fetchById(flockId);
      _items = _items.map((f) => f.id == flockId ? updated : f).toList();
      notifyListeners();
    } catch (_) {
      // If offline the cache was already patched by ChickenInvoiceController.
    }
  }

  // ── Sync callbacks ────────────────────────────────────────────────────────────

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(
        OfflineCacheService.poultryListKey('flocks'));
    if (cached == null) return;
    _items        = _service.parseAll(cached);
    _isOfflineData = false;
    notifyListeners();
  }

  void _onTempIdReplaced(String tempId, String realId) {
    bool changed = false;
    _items = _items.map((f) {
      if (f.id != tempId) return f;
      changed = true;
      return _service.parseItem({'id': realId, ...f.toJson()});
    }).toList();
    if (changed) notifyListeners();
  }
}
