import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  String? _selectedCategoryId;
  String _selectedOpeningChildId = 'opening_stock';

  // True while SettingsScope.bootstrap() is running.
  // Form buttons should be disabled (or show a snackbar) while this is true.
  bool isBootstrapping = true;

  void markBootstrapComplete() {
    isBootstrapping = false;
    notifyListeners();
  }

  String? get selectedCategoryId => _selectedCategoryId;
  String get selectedOpeningChildId => _selectedOpeningChildId;

  void selectCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void ensureSelectedCategory(String id) {
    if (_selectedCategoryId == null) {
      _selectedCategoryId = id;
      notifyListeners();
    }
  }

  void selectOpeningChild(String id) {
    _selectedOpeningChildId = id;
    notifyListeners();
  }
}
