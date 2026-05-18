import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/bank_deposit_model.dart';
import '../services/bank_deposit_service.dart';

class BankDepositController extends ChangeNotifier {
  BankDepositController() : _service = BankDepositService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener('bank-deposits', _onTempIdReplaced);
  }

  final BankDepositService _service;
  List<BankDepositModel> _items = [];
  bool _isLoading = true;
  String? _error;
  bool _isOfflineData = false;

  List<BankDepositModel> get items  => _items;
  bool get isLoading                => _isLoading;
  String? get error                 => _error;
  bool get isOfflineData            => _isOfflineData;
  bool get hasPendingSync           => _items.any((i) => OfflineOperation.isTemp(i.id));

  List<BankDepositModel> get unconfirmedDeposits =>
      _items.where((i) => !i.isConfirmed).toList();

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance.removeTempIdListener('bank-deposits', _onTempIdReplaced);
    super.dispose();
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchAll();
      _isOfflineData = false;
    } on Exception catch (e) {
      _error = e.toString();
      _isOfflineData = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<BankDepositModel> add(Map<String, dynamic> payload) async {
    final record = await _service.create(payload);
    _items = [record, ..._items];
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
    return record;
  }

  Future<void> updateItem(String id, Map<String, dynamic> payload) async {
    final record = await _service.update(id, payload);
    _items = _items.map((i) => i.id == id ? record : i).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
    OfflineSyncService.instance.triggerSync();
  }

  Future<void> confirm(String id) async {
    await _service.confirm(id);
    await fetchAll();
  }

  Future<void> reconcile(String id, {String? bankStatementRef}) async {
    await _service.reconcile(id, bankStatementRef: bankStatementRef);
    await fetchAll();
  }

  BankDepositModel? findById(String id) {
    try { return _items.firstWhere((i) => i.id == id || i.text('depositId') == id); } catch (_) { return null; }
  }

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(
        OfflineCacheService.invoicingListKey('bank-deposits'));
    if (cached == null) return;
    _items = _service.parseAll(cached);
    _isOfflineData = false;
    notifyListeners();
  }

  void _onTempIdReplaced(String tempId, String realId) {
    bool changed = false;
    _items = _items.map((i) {
      if (i.id != tempId) return i;
      changed = true;
      return _service.parseItem({'id': realId, ...i.toJson()});
    }).toList();
    if (changed) notifyListeners();
  }
}
