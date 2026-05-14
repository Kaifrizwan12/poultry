import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/purchase_order_controller.dart';
import '../models/purchase_order_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/record_browser_dialog.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);

  final _entryDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _vendorNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _fTaxPercentCtrl = TextEditingController(text: '0');

  String _vendorId = '';
  String _orderId = '';

  @override
  void dispose() {
    _entryDateCtrl.dispose();
    _vendorNameCtrl.dispose();
    _cityCtrl.dispose();
    _disc2PercentCtrl.dispose();
    _fTaxPercentCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _orderId = '';
      _vendorId = '';
    });
    _entryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _vendorNameCtrl.clear();
    _cityCtrl.clear();
    _disc2PercentCtrl.text = '0';
    _fTaxPercentCtrl.text = '0';
    _itemsNotifier.value = [];
  }

  void _loadFromModel(PurchaseOrderModel m) {
    setState(() {
      _currentId = m.id;
      _orderId = m.orderId;
      _vendorId = m.vendorId;
    });
    _entryDateCtrl.text = m.entryDate;
    _vendorNameCtrl.text = m.vendorName;
    _cityCtrl.text = m.city;
    _disc2PercentCtrl.text = m.disc2Percent.toStringAsFixed(2);
    _fTaxPercentCtrl.text = m.fTaxPercent.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0, salesTax = 0;
    for (final it in items) {
      gross += (it['lineGross'] as num?)?.toDouble() ?? 0;
      salesTax += (it['lineTax'] as num?)?.toDouble() ?? 0;
    }
    final disc2Percent = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final fTaxPercent = double.tryParse(_fTaxPercentCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(
        0, (s, it) => s + ((it['lineDisc'] as num?)?.toDouble() ?? 0));
    final discounts = gross * (disc2Percent / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final furtherTaxValue = invoiceValue * (fTaxPercent / 100);
    final netValue = invoiceValue + salesTax + furtherTaxValue;
    return {
      'gross': gross,
      'disc2Percent': disc2Percent,
      'discounts': discounts,
      'invoiceValue': invoiceValue,
      'salesTax': salesTax,
      'fTaxPercent': fTaxPercent,
      'furtherTaxValue': furtherTaxValue,
      'netValue': netValue,
    };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    final totals = _computeTotals(items);
    return {
      'entryDate': _entryDateCtrl.text,
      'vendorId': _vendorId,
      'vendorName': _vendorNameCtrl.text,
      'city': _cityCtrl.text,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'fTaxPercent': double.tryParse(_fTaxPercentCtrl.text) ?? 0,
      'items': items,
      'status': status,
      ...totals,
    };
  }

  Future<void> _save(String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final payload = _buildPayload(status);
      final ctrl = context.read<PurchaseOrderController>();
      if (_currentId == null) {
        final record = await ctrl.add(payload);
        setState(() {
          _currentId = record.id;
          _orderId = record.orderId;
        });
      } else {
        await ctrl.updateItem(_currentId!, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                status == 'saved' ? 'Saved successfully' : 'Saved as pending')));
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
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<PurchaseOrderController>().deleteItem(_currentId!);
      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order deleted')));
      }
    }
  }

  Future<void> _openRecords({bool pendingOnly = false}) async {
    final ctrl = context.read<PurchaseOrderController>();
    if (ctrl.items.isEmpty) {
      await ctrl.fetchAll();
    }
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<PurchaseOrderModel>(
      context: context,
      records: pendingOnly ? ctrl.pendingItems : ctrl.items,
      title: 'Purchase Orders',
      getBusinessId: (m) => m.orderId,
      getTitle: (m) => '${m.orderId}  •  ${m.vendorName}',
      getSubtitle: (m) => '${m.entryDate.substring(0, 10)}  |  ${m.status}',
      statusField: 'status',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductsController>().typedItems;
    final vendors = context.read<VendorsController>().typedItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Purchase Order', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 16),
                    if (_orderId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)),
                        child: Text('Order ID: $_orderId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.cardDecor,
                  padding: AppTheme.cardPadding,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _entryDateCtrl,
                          decoration: _dec('Entry Date'),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(_entryDateCtrl.text) ?? DateTime.now(),
                              firstDate: DateTime(2000), lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _entryDateCtrl.text = picked.toIso8601String().substring(0, 10));
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _vendorId.isEmpty ? null : _vendorId,
                          decoration: _dec('Vendor'),
                          isExpanded: true,
                          items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final v = vendors.firstWhere((x) => x.id == val);
                            setState(() => _vendorId = val);
                            _vendorNameCtrl.text = v.text('name');
                            _cityCtrl.text = v.text('city');
                          },
                        ),
                      ),
                      SizedBox(width: 160, child: TextFormField(controller: _cityCtrl, decoration: _dec('City'))),
                      SizedBox(width: 100, child: TextFormField(controller: _disc2PercentCtrl, decoration: _dec('Disc2 %'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                      SizedBox(width: 100, child: TextFormField(controller: _fTaxPercentCtrl, decoration: _dec('FTax %'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InvoiceLineItemRow(isPurchase: true, products: products, onAdd: (item) => _itemsNotifier.value = [..._itemsNotifier.value, item]),
                const SizedBox(height: 12),
                RepaintBoundary(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _itemsNotifier,
                    builder: (context, items, _) {
                      if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No items added yet.', style: TextStyle(color: AppTheme.textSecondary)));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: AppTheme.cardDecor,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                                dataRowMinHeight: 36, dataRowMaxHeight: 44,
                                columns: const [
                                  DataColumn(label: Text('#')), DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Packing')), DataColumn(label: Text('Pack')),
                                  DataColumn(label: Text('Qty(P)')), DataColumn(label: Text('Qty(L)')),
                                  DataColumn(label: Text('Price')), DataColumn(label: Text('Disc%')),
                                  DataColumn(label: Text('Tax%')), DataColumn(label: Text('Gross')),
                                  DataColumn(label: Text('Val incST')), DataColumn(label: Text('')),
                                ],
                                rows: items.asMap().entries.map((entry) {
                                  final idx = entry.key; final it = entry.value;
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                                    cells: [
                                      DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')),
                                      DataCell(Text(it['packingName'] ?? '')), DataCell(Text('${it['pack'] ?? ''}')),
                                      DataCell(Text('${it['qtyPacks'] ?? ''}')), DataCell(Text('${it['qtyLoose'] ?? ''}')),
                                      DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text((it['discPercent'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text((it['salesTaxPercent'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text((it['lineGross'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text((it['lineValueIncST'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _itemsNotifier.value = u; })),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InvoiceTotalsFooter(totals: _computeTotals(items), visibleKeys: const ['gross', 'discounts', 'invoiceValue', 'salesTax', 'fTaxPercent', 'furtherTaxValue', 'netValue']),
                        ],
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
              TextButton(onPressed: _isSaving ? null : () => _save('pending'), child: const Text('Pending')),
              TextButton(onPressed: _clearForm, child: const Text('Clear')),
              TextButton(onPressed: () => _openRecords(), child: const Text('Records')),
              TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not yet implemented'))), child: const Text('Print')),
              TextButton(onPressed: _currentId != null ? _remove : null, child: const Text('Remove')),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save('saved'),
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
