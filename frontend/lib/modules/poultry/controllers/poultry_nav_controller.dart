import 'package:flutter/foundation.dart';

class PoultryNavController extends ChangeNotifier {
  String selectedSection = 'flocks';
  String? selectedFlockId;
  int flockDetailTabIndex = 0;

  void selectSection(String section) {
    selectedSection = section;
    selectedFlockId = null;
    flockDetailTabIndex = 0;
    notifyListeners();
  }

  void openFlock(String flockId) {
    selectedFlockId = flockId;
    flockDetailTabIndex = 0;
    notifyListeners();
  }

  void closeFlock() {
    selectedFlockId = null;
    notifyListeners();
  }

  void selectFlockTab(int index) {
    flockDetailTabIndex = index;
    notifyListeners();
  }
}
