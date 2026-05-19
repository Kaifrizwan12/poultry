import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/chicken_invoice_model.dart';
import '../services/chicken_invoice_service.dart';

class ChickenInvoiceController extends ChangeNotifier {
  ChickenInvoiceController() : _service = ChickenInvoiceService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .addTempIdListener('chicken-invoices', _onTempIdReplaced);
  }

  final ChickenInvoiceService _service;

  List<ChickenInvoiceModel> _items = [];
  String? _currentFlockId;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ChickenInvoiceModel> get items => _items;
  bool get isLoading                   => _isLoading;
  String? get error                    => _error;
  bool get hasPendingSync              =>
      _items.any((i) => OfflineOperation.isTemp(i.id));

  List<ChickenInvoiceModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items
        .where((i) => i.invoiceNo.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .removeTempIdListener('chicken-invoices', _onTempIdReplaced);
    super.dispose();
  }

  Future<void> fetchAll() async {
    _currentFlockId = null;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchAll();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchByFlock(String flockId) async {
    if (_currentFlockId == flockId && _items.isNotEmpty) return;
    _currentFlockId = flockId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchByFlock(flockId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _items = [record, ..._items];

    // When created offline, also update the flock's cached bird count so
    // the flock list screen stays coherent without a server round-trip.
    if (OfflineOperation.isTemp(record.id)) {
      _patchFlockBirdCount(payload);
    }

    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _items = _items.map((i) => i.id == id ? record : i).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> deleteItem(String id, {String flockId = '', int birdsCount = 0}) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    if (flockId.isNotEmpty && birdsCount > 0) _unpatchFlockBirdCount(flockId, birdsCount);
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clear() {
    _items = [];
    _currentFlockId = null;
    notifyListeners();
  }

  // ── Offline flock-count patch ──────────────────────────────────────────────

  void _patchFlockBirdCount(Map<String, dynamic> payload) {
    final flockId   = payload['flockId'] as String? ?? '';
    final soldBirds = (payload['birdsCount'] as num?)?.toInt() ?? 0;
    if (flockId.isEmpty || soldBirds == 0) return;

    final cacheKey = OfflineCacheService.poultryListKey('flocks');
    final list     = OfflineCacheService.readList(cacheKey);
    if (list == null) return;

    final patched = list.map((f) {
      if (f['id'] != flockId) return f;
      final current =
          (f['currentBirdsCount'] as num?)?.toInt() ?? 0;
      return <String, dynamic>{
        ...f,
        'currentBirdsCount': (current - soldBirds).clamp(0, current),
      };
    }).toList();

    OfflineCacheService.saveList(cacheKey, patched);
  }

  void _unpatchFlockBirdCount(String flockId, int birdsCount) {
    final cacheKey = OfflineCacheService.poultryListKey('flocks');
    final list     = OfflineCacheService.readList(cacheKey);
    if (list == null) return;
    final patched = list.map((f) {
      if (f['id'] != flockId) return f;
      final current = (f['currentBirdsCount'] as num?)?.toInt() ?? 0;
      return <String, dynamic>{...f, 'currentBirdsCount': current + birdsCount};
    }).toList();
    OfflineCacheService.saveList(cacheKey, patched);
  }

  // ── Sync callbacks ───────────────────────────────────────────────────────────

  void _onSyncComplete() {
    if (_currentFlockId == null) return;
    final qs       = 'flockId=$_currentFlockId';
    final cacheKey = OfflineCacheService.poultryListKey('chicken-invoices',
        queryString: qs);
    final cached   = OfflineCacheService.readList(cacheKey);
    if (cached == null) return;
    _items = _service.parseAll(cached);
    notifyListeners();
  }

  void _onTempIdReplaced(String tempId, String realId) {
    bool changed = false;
    _items = _items.map((i) {
      if (i.id != tempId) return i;
      changed = true;
      return _service.parseItem({'id': realId, ...i.toJson()});
    }).toList();
    if (changed) notifyListeners();
  }
}
