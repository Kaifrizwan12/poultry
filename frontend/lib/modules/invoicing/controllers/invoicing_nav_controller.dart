import 'package:flutter/foundation.dart';
import '../config/invoicing_definitions.dart';

class InvoicingNavController extends ChangeNotifier {
  InvoicingSection selectedSection = InvoicingSection.salesInvoice;

  void selectSection(InvoicingSection section) {
    selectedSection = section;
    notifyListeners();
  }
}
