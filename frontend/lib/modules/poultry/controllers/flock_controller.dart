import 'package:flutter/foundation.dart';
import '../models/flock_model.dart';
import '../services/flock_service.dart';

class FlockController extends ChangeNotifier {
  FlockController() : _service = FlockService();

  final FlockService _service;

  List<FlockModel> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';

  List<FlockModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

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
        f.shedNo.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  List<FlockModel> get activeFlocks =>
      _items.where((f) => f.isActive).toList();

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

  Future<FlockModel> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _items = [record, ..._items];
    notifyListeners();
    return record;
  }

  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _items = _items.map((i) => i.id == id ? record : i).toList();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
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

  // Refresh a single flock after invoice creation (bird count may have changed)
  Future<void> refreshFlock(String flockId) async {
    try {
      final updated = await _service.fetchById(flockId);
      _items = _items.map((f) => f.id == flockId ? updated : f).toList();
      notifyListeners();
    } catch (_) {}
  }
}
