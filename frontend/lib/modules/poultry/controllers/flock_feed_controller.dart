import 'package:flutter/foundation.dart';
import '../models/flock_feed_model.dart';
import '../services/flock_feed_service.dart';

class FlockFeedController extends ChangeNotifier {
  FlockFeedController() : _service = FlockFeedService();

  final FlockFeedService _service;

  List<FlockFeedModel> _items = [];
  String? _currentFlockId;
  bool _isLoading = false;
  String? _error;

  List<FlockFeedModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  void clear() {
    _items = [];
    _currentFlockId = null;
    notifyListeners();
  }
}
