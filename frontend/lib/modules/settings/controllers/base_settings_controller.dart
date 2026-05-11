import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/modules/settings/services/settings_service_base.dart';
import 'package:flutter/foundation.dart';

abstract class SettingsCrudController extends ChangeNotifier {
  List<BaseSettingsModel> get items;
  List<BaseSettingsModel> get filteredItems;
  bool get isLoading;
  String? get error;
  String get searchQuery;
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
        _searchableFields = searchableFields;

  final SettingsServiceBase<T> _service;
  final List<String> _searchableFields;

  List<T> _typedItems = <T>[];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

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
  List<BaseSettingsModel> get filteredItems {
    if (_searchQuery.trim().isEmpty) {
      return items;
    }
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      return _searchableFields.any((field) {
        return item.text(field).toLowerCase().contains(query);
      });
    }).toList();
  }

  @override
  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _typedItems = await _service.fetchAll();
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
  }

  @override
  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _typedItems = _typedItems.map((item) {
      return item.id == id ? record : item;
    }).toList();
    notifyListeners();
  }

  @override
  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _typedItems = _typedItems.where((item) => item.id != id).toList();
    notifyListeners();
  }

  @override
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  List<T> whereFieldEquals(String field, String? value) {
    if (value == null || value.isEmpty) {
      return _typedItems;
    }
    return _typedItems.where((item) => item.text(field) == value).toList();
  }
}
