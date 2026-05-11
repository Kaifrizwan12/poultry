import 'package:flutter/foundation.dart';

class AccountsReportsNavController extends ChangeNotifier {
  String _selectedSection = 'ledger_entries';
  String? _selectedAccountId;

  String get selectedSection => _selectedSection;
  String? get selectedAccountId => _selectedAccountId;

  void selectSection(String section) {
    _selectedSection = section;
    // Keep selected account when user explicitly navigates to the by-account view,
    // so the chip/tab works and can retain the last selection.
    if (section != 'account_ledger_view') {
      _selectedAccountId = null;
    }
    notifyListeners();
  }

  void viewAccountLedger(String accountId) {
    _selectedAccountId = accountId;
    _selectedSection = 'account_ledger_view';
    notifyListeners();
  }

  void backToList() {
    _selectedAccountId = null;
    _selectedSection = 'ledger_entries';
    notifyListeners();
  }
}
