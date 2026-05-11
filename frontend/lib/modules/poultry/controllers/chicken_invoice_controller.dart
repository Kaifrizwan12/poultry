import 'package:flutter/foundation.dart';
import '../models/chicken_invoice_model.dart';
import '../services/chicken_invoice_service.dart';

class ChickenInvoiceController extends ChangeNotifier {
  ChickenInvoiceController() : _service = ChickenInvoiceService();

  final ChickenInvoiceService _service;

  List<ChickenInvoiceModel> _items = [];
  String? _currentFlockId;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ChickenInvoiceModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ChickenInvoiceModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) =>
      i.invoiceNo.toLowerCase().contains(q)
    ).toList();
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

  void clear() {
    _items = [];
    _currentFlockId = null;
    notifyListeners();
  }
}
