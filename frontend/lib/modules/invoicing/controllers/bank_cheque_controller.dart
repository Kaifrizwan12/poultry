import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/bank_cheque_model.dart';
import '../services/bank_cheque_service.dart';

class BankChequeController extends ChangeNotifier {
  BankChequeController() : _service = BankChequeService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener('bank-cheques', _onTempIdReplaced);
  }

  final BankChequeService _service;
  List<BankChequeModel> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _isOfflineData = false;

  List<BankChequeModel> get items  => _items;
  bool get isLoading               => _isLoading;
  String? get error                => _error;
  bool get isOfflineData           => _isOfflineData;
  bool get hasPendingSync          => _items.any((i) => OfflineOperation.isTemp(i.id));

  List<BankChequeModel> get issuedCheques =>
      _items.where((i) => i.status == 'issued').toList();

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance.removeTempIdListener('bank-cheques', _onTempIdReplaced);
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

  Future<BankChequeModel> add(Map<String, dynamic> payload) async {
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

  Future<void> updateStatus(String id, String status, {String? clearedDate}) async {
    await _service.updateStatus(id, status, clearedDate: clearedDate);
    await fetchAll();
  }

  BankChequeModel? findById(String id) {
    try { return _items.firstWhere((i) => i.id == id || i.text('chequeId') == id); } catch (_) { return null; }
  }

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(
        OfflineCacheService.invoicingListKey('bank-cheques'));
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
