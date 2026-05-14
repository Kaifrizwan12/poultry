import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/purchase_return_controller.dart';
import '../controllers/purchase_invoice_controller.dart';
import '../models/purchase_return_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/record_browser_dialog.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key, required this.returnType});
  final String returnType;

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier = ValueNotifier([]);

  final _returnDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _vendorNameCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _fTaxPercentCtrl = TextEditingController(text: '0');

  String _vendorId = '';
  String _purchaseInvoiceId = '';

  @override
  void dispose() {
    _returnDateCtrl.dispose(); _vendorNameCtrl.dispose();
    _disc2PercentCtrl.dispose(); _fTaxPercentCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _vendorId = ''; _purchaseInvoiceId = ''; });
    _returnDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _vendorNameCtrl.clear(); _disc2PercentCtrl.text = '0'; _fTaxPercentCtrl.text = '0';
    _itemsNotifier.value = [];
  }

  void _loadFromModel(PurchaseReturnModel m) {
    setState(() { _currentId = m.id; _vendorId = m.vendorId; _purchaseInvoiceId = m.purchaseInvoiceId; });
    _returnDateCtrl.text = m.returnDate; _vendorNameCtrl.text = m.vendorName;
    _disc2PercentCtrl.text = m.disc2Percent.toStringAsFixed(2);
    _fTaxPercentCtrl.text = m.fTaxPercent.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0, salesTax = 0;
    for (final it in items) { gross += (it['lineGross'] as num?)?.toDouble() ?? 0; salesTax += (it['lineTax'] as num?)?.toDouble() ?? 0; }
    final disc2 = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final fTaxPct = double.tryParse(_fTaxPercentCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(0, (s, it) => s + ((it['lineDisc'] as num?)?.toDouble() ?? 0));
    final discounts = gross * (disc2 / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final furtherTaxValue = invoiceValue * (fTaxPct / 100);
    final netValue = invoiceValue + salesTax + furtherTaxValue;
    return { 'gross': gross, 'disc2Percent': disc2, 'discounts': discounts, 'invoiceValue': invoiceValue, 'salesTax': salesTax, 'fTaxPercent': fTaxPct, 'furtherTaxValue': furtherTaxValue, 'netValue': netValue };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    final totals = _computeTotals(items);
    return {
      'returnType': widget.returnType, 'returnDate': _returnDateCtrl.text,
      'vendorId': _vendorId, 'vendorName': _vendorNameCtrl.text,
      'purchaseInvoiceId': _purchaseInvoiceId,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'fTaxPercent': double.tryParse(_fTaxPercentCtrl.text) ?? 0,
      'items': items, 'status': status, ...totals,
    };
  }

  Future<void> _save(String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<PurchaseReturnController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload(status)); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload(status)); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'saved' ? 'Saved successfully' : 'Saved as pending')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this return?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<PurchaseReturnController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<PurchaseReturnController>();
    if (ctrl.items.isEmpty) {
      await ctrl.fetchAll();
    }
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<PurchaseReturnModel>(
      context: context,
      records: ctrl.items,
      title: 'Purchase Returns',
      getBusinessId: (m) => m.returnId,
      getTitle: (m) => '${m.returnId}  •  ${m.vendorName}',
      getSubtitle: (m) => '${m.returnDate.substring(0, 10)}  |  ${m.returnType}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductsController>().typedItems;
    final vendors = context.read<VendorsController>().typedItems;
    final purchaseInvoices = context.read<PurchaseInvoiceController>().items;
    final isWithInvoice = widget.returnType == 'with_invoice';
    final title = isWithInvoice ? 'Purchase Return (With Invoice)' : 'Purchase Return (Without Invoice)';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _returnDateCtrl, decoration: _dec('Return Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_returnDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _returnDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                if (isWithInvoice)
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      value: _purchaseInvoiceId.isEmpty ? null : _purchaseInvoiceId,
                      decoration: _dec('Purchase Invoice'), isExpanded: true,
                      items: purchaseInvoices.map((pi) => DropdownMenuItem(value: pi.id, child: Text(pi.purchaseId.isNotEmpty ? 'PI: ${pi.purchaseId}' : pi.id, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final pi = purchaseInvoices.firstWhere((x) => x.id == val);
                        setState(() { _purchaseInvoiceId = val; _vendorId = pi.vendorId; });
                        _vendorNameCtrl.text = pi.vendorName;
                        _itemsNotifier.value = List<Map<String, dynamic>>.from(pi.items);
                      },
                    ),
                  ),
                if (!isWithInvoice)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _vendorId.isEmpty ? null : _vendorId, decoration: _dec('Vendor'), isExpanded: true,
                      items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) { if (val == null) return; setState(() => _vendorId = val); _vendorNameCtrl.text = vendors.firstWhere((v) => v.id == val).text('name'); },
                    ),
                  ),
                SizedBox(width: 100, child: TextFormField(controller: _disc2PercentCtrl, decoration: _dec('Disc2 %'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 100, child: TextFormField(controller: _fTaxPercentCtrl, decoration: _dec('FTax %'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              ])),
              const SizedBox(height: 16),
              InvoiceLineItemRow(isPurchase: true, products: products, onAdd: (item) => _itemsNotifier.value = [..._itemsNotifier.value, item]),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _itemsNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No items added yet.', style: TextStyle(color: AppTheme.textSecondary)));
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                        columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Packing')), DataColumn(label: Text('Qty(P)')), DataColumn(label: Text('Qty(L)')), DataColumn(label: Text('Price')), DataColumn(label: Text('Gross')), DataColumn(label: Text(''))],
                        rows: items.asMap().entries.map((e) { final idx = e.key; final it = e.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')), DataCell(Text(it['packingName'] ?? '')), DataCell(Text('${it['qtyPacks'] ?? ''}')), DataCell(Text('${it['qtyLoose'] ?? ''}')), DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['lineGross'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _itemsNotifier.value = u; }))],
                        ); }).toList(),
                      ))),
                      const SizedBox(height: 8),
                      InvoiceTotalsFooter(totals: _computeTotals(items), visibleKeys: const ['gross', 'discounts', 'invoiceValue', 'salesTax', 'furtherTaxValue', 'netValue']),
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite, padding: const EdgeInsets.all(12),
          child: Row(children: [
            TextButton(onPressed: _isSaving ? null : () => _save('pending'), child: const Text('Pending')),
            TextButton(onPressed: _clearForm, child: const Text('Clear')),
            TextButton(onPressed: () => _openRecords(), child: const Text('Records')),
            TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not yet implemented'))), child: const Text('Print')),
            TextButton(onPressed: _currentId != null ? _remove : null, child: const Text('Remove')),
            const Spacer(),
            ElevatedButton(onPressed: _isSaving ? null : () => _save('saved'), child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _clearForm, child: const Text('Close')),
          ]),
        ),
      ],
    );
  }
}
