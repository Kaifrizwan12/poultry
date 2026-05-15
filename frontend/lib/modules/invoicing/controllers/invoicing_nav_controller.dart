import 'package:flutter/foundation.dart';
import '../config/invoicing_definitions.dart';

class InvoicingNavController extends ChangeNotifier {
  InvoicingSection selectedSection = InvoicingSection.salesInvoice;
  bool showMobileMenu = true;

  void selectSection(InvoicingSection section) {
    selectedSection = section;
    showMobileMenu = false;
    notifyListeners();
  }

  void goBackToMenu() {
    showMobileMenu = true;
    notifyListeners();
  }
}
