import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/flock_feed_model.dart';
import '../services/flock_feed_service.dart';

class FlockFeedController extends ChangeNotifier {
  FlockFeedController() : _service = FlockFeedService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .addTempIdListener('flock-feeds', _onTempIdReplaced);
  }

  final FlockFeedService _service;

  List<FlockFeedModel> _items = [];
  String? _currentFlockId;
  bool _isLoading = false;
  String? _error;

  List<FlockFeedModel> get items  => _items;
  bool get isLoading               => _isLoading;
  String? get error                => _error;
  bool get hasPendingSync          =>
      _items.any((i) => OfflineOperation.isTemp(i.id));

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .removeTempIdListener('flock-feeds', _onTempIdReplaced);
    super.dispose();
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

  Future<void> fetchAll() async { /* no-op: fetch lazily by flock */ }

  Future<void> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _items = [record, ..._items];
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
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

  void clear() {
    _items = [];
    _currentFlockId = null;
    notifyListeners();
  }

  void _onSyncComplete() {
    if (_currentFlockId == null) return;
    final qs       = 'flockId=$_currentFlockId';
    final cacheKey = OfflineCacheService.poultryListKey('flock-feeds',
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
