import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/feed_schedule_model.dart';
import '../services/feed_schedule_service.dart';

class FeedScheduleController extends ChangeNotifier {
  FeedScheduleController() : _service = FeedScheduleService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .addTempIdListener('feed-schedules', _onTempIdReplaced);
  }

  final FeedScheduleService _service;

  List<FeedScheduleModel> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<FeedScheduleModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error  => _error;
  String get searchQuery => _searchQuery;
  bool get hasPendingSync => _items.any((i) => OfflineOperation.isTemp(i.id));

  List<FeedScheduleModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) =>
        i.name.toLowerCase().contains(q) ||
        i.feedType.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .removeTempIdListener('feed-schedules', _onTempIdReplaced);
    super.dispose();
  }

  Future<void> fetchAll() async {
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

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(
        OfflineCacheService.poultryListKey('feed-schedules'));
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
