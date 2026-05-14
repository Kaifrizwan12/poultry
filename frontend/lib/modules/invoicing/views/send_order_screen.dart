import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/purchase_order_controller.dart';
import '../controllers/send_order_controller.dart';
import '../models/send_order_model.dart';
import '../widgets/record_browser_dialog.dart';

class SendOrderScreen extends StatefulWidget {
  const SendOrderScreen({super.key});

  @override
  State<SendOrderScreen> createState() => _SendOrderScreenState();
}

class _SendOrderScreenState extends State<SendOrderScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);

  // _poDocId = Firestore doc ID of the linked PO (used as FK and as dropdown value)
  String _poDocId  = '';
  String _vendorId = '';
  final _vendorNameCtrl = TextEditingController();
  final _draftNoCtrl = TextEditingController();
  final _draftDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _draftAmountCtrl = TextEditingController(text: '0');
  String _bankAccountId = '';
  final _bankAcNoCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _includeAllProductsWhenPrinting = false;

  @override
  void dispose() {
    _vendorNameCtrl.dispose();
    _draftNoCtrl.dispose();
    _draftDateCtrl.dispose();
    _draftAmountCtrl.dispose();
    _bankAcNoCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _poDocId  = '';
      _vendorId = '';
      _bankAccountId = '';
      _includeAllProductsWhenPrinting = false;
    });
    _vendorNameCtrl.clear();
    _draftNoCtrl.clear();
    _draftDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _draftAmountCtrl.text = '0';
    _bankAcNoCtrl.clear();
    _bankAccountNameCtrl.clear();
    _descriptionCtrl.clear();
    _itemsNotifier.value = [];
  }

  void _loadFromModel(SendOrderModel m) {
    setState(() {
      _currentId = m.id;
      _poDocId  = m.orderId;   // m.orderId stores the Firestore doc ID of the linked PO
      _vendorId = m.vendorId;
      _bankAccountId = m.bankAccountId;
      _includeAllProductsWhenPrinting = m.includeAllProductsWhenPrinting;
    });
    _vendorNameCtrl.text = m.vendorName;
    _draftNoCtrl.text = m.draftNo;
    _draftDateCtrl.text = m.draftDate;
    _draftAmountCtrl.text = m.draftAmount.toStringAsFixed(2);
    _bankAcNoCtrl.text = m.bankAcNo;
    _bankAccountNameCtrl.text = m.bankAccountName;
    _descriptionCtrl.text = m.description;
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'orderId': _poDocId,   // always the Firestore doc ID — what the backend FK check expects
      'vendorId': _vendorId,
      'vendorName': _vendorNameCtrl.text,
      'draftNo': _draftNoCtrl.text,
      'draftDate': _draftDateCtrl.text,
      'draftAmount': double.tryParse(_draftAmountCtrl.text) ?? 0,
      'bankAccountId': _bankAccountId,
      'bankAcNo': _bankAcNoCtrl.text,
      'bankAccountName': _bankAccountNameCtrl.text,
      'description': _descriptionCtrl.text,
      'includeAllProductsWhenPrinting': _includeAllProductsWhenPrinting,
      'items': _itemsNotifier.value,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final payload = _buildPayload();
      final ctrl = context.read<SendOrderController>();
      if (_currentId == null) {
        final record = await ctrl.add(payload);
        setState(() => _currentId = record.id);
      } else {
        await ctrl.updateItem(_currentId!, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this send order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<SendOrderController>().deleteItem(_currentId!);
      _clearForm();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<SendOrderController>();
    if (ctrl.items.isEmpty) {
      await ctrl.fetchAll();
    }
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<SendOrderModel>(
      context: context,
      records: ctrl.items,
      title: 'Send Orders',
      getBusinessId: (m) => m.sendOrderId,
      getTitle: (m) => '${m.sendOrderId}  •  ${m.vendorName}',
      getSubtitle: (m) => '${m.draftDate.isNotEmpty ? m.draftDate.substring(0, 10) : "—"}  |  Rs ${m.totalOrderValue.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final poCtrl = context.read<PurchaseOrderController>();
    final accountsCtrl = context.read<AccountsController>();
    final orders = poCtrl.items;
    final accounts = accountsCtrl.typedItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send Purchase Order', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.cardDecor,
                  padding: AppTheme.cardPadding,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          // value = Firestore doc ID — always unique, never crashes
                          value: _poDocId.isEmpty ? null : _poDocId,
                          decoration: _dec('Purchase Order'),
                          isExpanded: true,
                          items: orders.map((o) => DropdownMenuItem<String>(
                            value: o.id,  // Firestore doc ID — guaranteed unique
                            child: Text(
                              o.orderId.isNotEmpty
                                ? '${o.orderId}  •  ${o.vendorName}'
                                : o.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (docId) {
                            if (docId == null) return;
                            final po = orders.firstWhere((o) => o.id == docId);
                            setState(() {
                              _poDocId  = docId;
                              _vendorId = po.vendorId;
                            });
                            _vendorNameCtrl.text = po.vendorName;
                            _itemsNotifier.value = List<Map<String, dynamic>>.from(po.items);
                          },
                        ),
                      ),
                      SizedBox(width: 200, child: AbsorbPointer(child: TextFormField(controller: _vendorNameCtrl, decoration: _dec('Vendor Name'), style: const TextStyle(color: AppTheme.textSecondary)))),
                      SizedBox(width: 160, child: TextFormField(controller: _draftNoCtrl, decoration: _dec('Draft No'))),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _draftDateCtrl,
                          decoration: _dec('Draft Date'),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(_draftDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (picked != null) setState(() => _draftDateCtrl.text = picked.toIso8601String().substring(0, 10));
                          },
                        ),
                      ),
                      SizedBox(width: 140, child: TextFormField(controller: _draftAmountCtrl, decoration: _dec('Draft Amount'), keyboardType: TextInputType.number)),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _bankAccountId.isEmpty ? null : _bankAccountId,
                          decoration: _dec('Bank Account'),
                          isExpanded: true,
                          items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final a = accounts.firstWhere((x) => x.id == val);
                            setState(() => _bankAccountId = val);
                            _bankAcNoCtrl.text = a.text('accountCode');
                            _bankAccountNameCtrl.text = a.text('accountName');
                          },
                        ),
                      ),
                      SizedBox(width: 300, child: TextFormField(controller: _descriptionCtrl, decoration: _dec('Description'))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(value: _includeAllProductsWhenPrinting, onChanged: (v) => setState(() => _includeAllProductsWhenPrinting = v), activeColor: AppTheme.terra400),
                          const SizedBox(width: 8),
                          const Text('Include All Products When Printing', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _itemsNotifier,
                    builder: (context, items, _) {
                      if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No items. Select a purchase order to populate.', style: TextStyle(color: AppTheme.textSecondary)));
                      return Container(
                        decoration: AppTheme.cardDecor,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                            dataRowMinHeight: 36, dataRowMaxHeight: 44,
                            columns: const [
                              DataColumn(label: Text('#')), DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Packing')), DataColumn(label: Text('Qty(P)')),
                              DataColumn(label: Text('Qty(L)')), DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Gross')),
                            ],
                            rows: items.asMap().entries.map((entry) {
                              final idx = entry.key; final it = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                                cells: [
                                  DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')),
                                  DataCell(Text(it['packingName'] ?? '')), DataCell(Text('${it['qtyPacks'] ?? ''}')),
                                  DataCell(Text('${it['qtyLoose'] ?? ''}')), DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')),
                                  DataCell(Text((it['lineGross'] as num?)?.toStringAsFixed(2) ?? '0')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TextButton(onPressed: _clearForm, child: const Text('Clear')),
              TextButton(onPressed: () => _openRecords(), child: const Text('Records')),
              TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not yet implemented'))), child: const Text('Print')),
              TextButton(onPressed: _currentId != null ? _remove : null, child: const Text('Remove')),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _clearForm, child: const Text('Close')),
            ],
          ),
        ),
      ],
    );
  }
}
