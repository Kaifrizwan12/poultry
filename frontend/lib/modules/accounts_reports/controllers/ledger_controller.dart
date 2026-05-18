import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';

import '../models/ledger_entry_model.dart';
import '../models/ledger_view_model.dart';
import '../services/ledger_service.dart';

class LedgerController extends ChangeNotifier {
  LedgerController() : _service = LedgerService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .addTempIdListener('ledger', _onTempIdReplaced);
  }

  final LedgerService _service;

  List<LedgerEntry> _items  = [];
  LedgerViewModel? _accountView;
  bool _isLoading            = true;
  String? _error;
  bool _isOfflineData        = false;

  // Filter state
  String? _filterAccountId;
  String? _filterEntryType;
  String  _searchQuery = '';

  List<LedgerEntry>  get items        => _items;
  LedgerViewModel?   get accountView  => _accountView;
  bool               get isLoading    => _isLoading;
  String?            get error        => _error;
  String             get searchQuery  => _searchQuery;
  String?            get filterEntryType => _filterEntryType;
  bool               get isOfflineData   => _isOfflineData;
  bool               get hasPendingSync  =>
      _items.any((e) => OfflineOperation.isTemp(e.id));

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
      list = list.where((e) =>
          e.entryNo.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          (e.referenceNo?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance
        .removeTempIdListener('ledger', _onTempIdReplaced);
    super.dispose();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items         = await _service.fetchAll();
      _isOfflineData = false;
    } catch (e) {
      _error         = e.toString();
      _isOfflineData = true;
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
    _isLoading   = true;
    _error       = null;
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
      _isOfflineData = false;
    } catch (e) {
      _error         = e.toString();
      _isOfflineData = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<LedgerEntry> createEntry(Map<String, dynamic> body) async {
    final record = await _service.create(body);
    _items = [record, ..._items];
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
    return record;
  }

  Future<void> updateEntry(String id, Map<String, dynamic> body) async {
    final record = await _service.update(id, body);
    _items = _items.map((e) => e.id == id ? record : e).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> toggleReconciled(LedgerEntry entry) async {
    final payload  = entry.toJson()..['isReconciled'] = !entry.isReconciled;
    final updated  = await _service.update(entry.id, payload);
    _items = _items.map((e) => e.id == entry.id ? updated : e).toList();
    // Also patch the by-account view in-memory.
    if (_accountView != null) {
      final patched = _accountView!.entries.map((e) => e.id == entry.id
          ? updated.copyWith(runningBalance: e.runningBalance)
          : e).toList();
      _accountView = LedgerViewModel(
        account:        _accountView!.account,
        entries:        patched,
        openingBalance: _accountView!.openingBalance,
        totalDebits:    _accountView!.totalDebits,
        totalCredits:   _accountView!.totalCredits,
        closingBalance: _accountView!.closingBalance,
      );
    }
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> deleteEntry(String id) async {
    await _service.delete(id);
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<String> nextEntryNo() => _service.nextEntryNo();

  // ── Filter / search ──────────────────────────────────────────────────────────

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
    _searchQuery     = '';
    notifyListeners();
  }

  void clearAccountView() {
    _accountView = null;
    notifyListeners();
  }

  // ── Sync callbacks ────────────────────────────────────────────────────────────

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(OfflineCacheService.ledgerListKey());
    if (cached == null) return;
    _items         = cached.map(LedgerEntry.fromJson).toList();
    _isOfflineData = false;
    notifyListeners();
  }

  void _onTempIdReplaced(String tempId, String realId) {
    bool changed = false;
    _items = _items.map((e) {
      if (e.id != tempId) return e;
      changed = true;
      return LedgerEntry.fromJson({...e.toFullJson(), 'id': realId});
    }).toList();
    if (_accountView != null) {
      final patched = _accountView!.entries.map((e) {
        if (e.id != tempId) return e;
        changed = true;
        return LedgerEntry.fromJson({...e.toFullJson(), 'id': realId});
      }).toList();
      _accountView = LedgerViewModel(
        account:        _accountView!.account,
        entries:        patched,
        openingBalance: _accountView!.openingBalance,
        totalDebits:    _accountView!.totalDebits,
        totalCredits:   _accountView!.totalCredits,
        closingBalance: _accountView!.closingBalance,
      );
    }
    if (changed) notifyListeners();
  }
}
