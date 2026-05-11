import 'package:flutter/foundation.dart';
import '../models/vaccine_schedule_model.dart';
import '../services/vaccine_schedule_service.dart';

class VaccineScheduleController extends ChangeNotifier {
  VaccineScheduleController() : _service = VaccineScheduleService();

  final VaccineScheduleService _service;

  List<VaccineScheduleModel> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<VaccineScheduleModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<VaccineScheduleModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) =>
      i.name.toLowerCase().contains(q) ||
      i.vaccineType.toLowerCase().contains(q)
    ).toList();
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
}
