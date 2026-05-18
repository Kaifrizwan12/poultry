import 'package:farm_mgt_auth/services/offline_cache_service.dart';
import 'package:farm_mgt_auth/services/offline_queue_service.dart';
import 'package:farm_mgt_auth/services/offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../models/sales_invoice_model.dart';
import '../services/sales_invoice_service.dart';

class SalesInvoiceController extends ChangeNotifier {
  SalesInvoiceController() : _service = SalesInvoiceService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener('sales-invoices', _onTempIdReplaced);
  }

  final SalesInvoiceService _service;
  List<SalesInvoiceModel> _items = [];
  bool _isLoading = true;
  String? _error;
  bool _isOfflineData = false;

  List<SalesInvoiceModel> get items       => _items;
  bool get isLoading                      => _isLoading;
  String? get error                       => _error;
  bool get isOfflineData                  => _isOfflineData;
  bool get hasPendingSync                 => _items.any((i) => OfflineOperation.isTemp(i.id));

  List<SalesInvoiceModel> get pendingItems =>
      _items.where((i) => i.status == 'pending').toList();

  @override
  void dispose() {
    OfflineSyncService.instance.removeSyncListener(_onSyncComplete);
    OfflineSyncService.instance.removeTempIdListener('sales-invoices', _onTempIdReplaced);
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

  Future<SalesInvoiceModel> add(Map<String, dynamic> payload) async {
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

  SalesInvoiceModel? findById(String id) {
    try { return _items.firstWhere((i) => i.id == id || i.text('saleId') == id); } catch (_) { return null; }
  }

  void _onSyncComplete() {
    final cached = OfflineCacheService.readList(
        OfflineCacheService.invoicingListKey('sales-invoices'));
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
