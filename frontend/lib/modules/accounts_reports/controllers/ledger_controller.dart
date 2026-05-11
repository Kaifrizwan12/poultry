import 'package:flutter/foundation.dart';

import '../models/ledger_entry_model.dart';
import '../models/ledger_view_model.dart';
import '../services/ledger_service.dart';

class LedgerController extends ChangeNotifier {
  LedgerController() : _service = LedgerService();

  final LedgerService _service;

  List<LedgerEntry> _items = [];
  LedgerViewModel? _accountView;
  bool _isLoading = false;
  String? _error;

  // Filter state for list view
  String? _filterAccountId;
  String? _filterEntryType; // null | 'debit' | 'credit'
  String _searchQuery = '';

  List<LedgerEntry> get items => _items;
  LedgerViewModel? get accountView => _accountView;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get filterEntryType => _filterEntryType;

  List<LedgerEntry> get filteredItems {
    var list = _items;
    if (_filterAccountId != null && _filterAccountId!.isNotEmpty) {
      list = list.where((e) => e.accountId == _filterAccountId).toList();
    }
    if (_filterEntryType != null) {
      list = list.where((e) => e.entryType == _filterEntryType).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.entryNo.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              (e.referenceNo?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  Future<void> loadAll() async {
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

  Future<void> loadByAccount(
    String accountId, {
    String? startDate,
    String? endDate,
    String? entryType,
    bool? isReconciled,
  }) async {
    _isLoading = true;
    _error = null;
    _accountView = null;
    notifyListeners();
    try {
      _accountView = await _service.fetchByAccount(
        accountId,
        startDate: startDate,
        endDate: endDate,
        entryType: entryType,
        isReconciled: isReconciled,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<LedgerEntry> createEntry(Map<String, dynamic> body) async {
    final record = await _service.create(body);
    _items = [record, ..._items];
    notifyListeners();
    return record;
  }

  Future<void> updateEntry(String id, Map<String, dynamic> body) async {
    final record = await _service.update(id, body);
    _items = _items.map((e) => e.id == id ? record : e).toList();
    notifyListeners();
  }

  // Flip isReconciled without opening the full edit dialog.
  // Sends all existing fields unchanged except isReconciled.
  Future<void> toggleReconciled(LedgerEntry entry) async {
    final payload = entry.toJson()..['isReconciled'] = !entry.isReconciled;
    final updated = await _service.update(entry.id, payload);
    _items = _items.map((e) => e.id == entry.id ? updated : e).toList();
    // Also patch accountView entries in-memory so the by-account screen reflects immediately
    if (_accountView != null) {
      final patched = _accountView!.entries
          .map((e) => e.id == entry.id
              // Preserve runningBalance computed by the by-account endpoint.
              // The generic CRUD update endpoint doesn't return runningBalance,
              // so replacing the row would make UI fall back to 0.
              ? updated.copyWith(runningBalance: e.runningBalance)
              : e)
          .toList();
      _accountView = LedgerViewModel(
        account: _accountView!.account,
        entries: patched,
        openingBalance: _accountView!.openingBalance,
        totalDebits: _accountView!.totalDebits,
        totalCredits: _accountView!.totalCredits,
        closingBalance: _accountView!.closingBalance,
      );
    }
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _service.delete(id);
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<String> nextEntryNo() => _service.nextEntryNo();

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilterAccountId(String? value) {
    _filterAccountId = value;
    notifyListeners();
  }

  void setFilterEntryType(String? value) {
    _filterEntryType = value;
    notifyListeners();
  }

  void clearFilters() {
    _filterAccountId = null;
    _filterEntryType = null;
    _searchQuery = '';
    notifyListeners();
  }

  void clearAccountView() {
    _accountView = null;
    notifyListeners();
  }
}
