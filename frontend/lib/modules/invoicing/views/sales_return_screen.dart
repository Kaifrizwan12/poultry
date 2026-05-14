import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/sales_return_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/sales_return_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key, required this.returnType});
  final String returnType;

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier = ValueNotifier([]);

  final _returnDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _customerNameCtrl = TextEditingController();
  final _salesmanNameCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _sedCtrl = TextEditingController(text: '0');
  final _specialDiscountCtrl = TextEditingController(text: '0');
  final _prevCreditCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController(text: '0');

  String _customerId = '';
  String _salesmanId = '';
  String _saleId = '';
  bool _toMainStore = true;
  bool _isFullReturn = false;

  @override
  void dispose() {
    for (final c in [_returnDateCtrl, _customerNameCtrl, _salesmanNameCtrl, _disc2PercentCtrl, _sedCtrl, _specialDiscountCtrl, _prevCreditCtrl, _paidAmountCtrl]) {
      c.dispose();
    }
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _customerId = ''; _salesmanId = ''; _saleId = ''; _toMainStore = true; _isFullReturn = false; });
    _returnDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _customerNameCtrl.clear(); _salesmanNameCtrl.clear();
    for (final c in [_disc2PercentCtrl, _sedCtrl, _specialDiscountCtrl, _prevCreditCtrl, _paidAmountCtrl]) { c.text = '0'; }
    _itemsNotifier.value = [];
  }

  void _loadFromModel(SalesReturnModel m) {
    setState(() { _currentId = m.id; _customerId = m.customerId; _salesmanId = m.salesmanId; _saleId = m.saleId; _toMainStore = m.toMainStore; });
    _returnDateCtrl.text = m.returnDate; _customerNameCtrl.text = m.customerName; _salesmanNameCtrl.text = m.salesmanName;
    _disc2PercentCtrl.text = m.disc2Percent.toStringAsFixed(2);
    _sedCtrl.text = m.sed.toStringAsFixed(2);
    _specialDiscountCtrl.text = m.specialDiscount.toStringAsFixed(2);
    _prevCreditCtrl.text = m.prevCredit.toStringAsFixed(2);
    _paidAmountCtrl.text = m.paidAmount.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0, salesTax = 0;
    for (final it in items) { gross += (it['lineGross'] as num?)?.toDouble() ?? 0; salesTax += (it['lineTax'] as num?)?.toDouble() ?? 0; }
    final disc2 = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final sed = double.tryParse(_sedCtrl.text) ?? 0;
    final spcDisc = double.tryParse(_specialDiscountCtrl.text) ?? 0;
    final prevCredit = double.tryParse(_prevCreditCtrl.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(0, (s, it) => s + ((it['lineDisc'] as num?)?.toDouble() ?? 0));
    final discounts = gross * (disc2 / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final netValue = invoiceValue + salesTax + sed - spcDisc;
    final totalPayable = netValue + prevCredit;
    final remBalance = totalPayable - paidAmount;
    return { 'gross': gross, 'disc2Percent': disc2, 'discounts': discounts, 'invoiceValue': invoiceValue, 'salesTax': salesTax, 'totalSED': sed, 'spcDisc': spcDisc, 'netValue': netValue, 'totalPayable': totalPayable, 'paidAmount': paidAmount, 'remBalance': remBalance };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    return {
      'returnType': widget.returnType, 'returnDate': _returnDateCtrl.text,
      'customerId': _customerId, 'customerName': _customerNameCtrl.text,
      'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text,
      'saleId': _saleId, 'toMainStore': _toMainStore,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'sed': double.tryParse(_sedCtrl.text) ?? 0,
      'specialDiscount': double.tryParse(_specialDiscountCtrl.text) ?? 0,
      'prevCredit': double.tryParse(_prevCreditCtrl.text) ?? 0,
      'paidAmount': double.tryParse(_paidAmountCtrl.text) ?? 0,
      'items': items, 'status': status, ..._computeTotals(items),
    };
  }

  Future<void> _save(String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<SalesReturnController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload(status)); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload(status)); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'saved' ? 'Saved successfully' : 'Saved as pending')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this return?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<SalesReturnController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<SalesReturnController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<SalesReturnModel>(
      context: context,
      records: ctrl.items,
      title: 'Sales Returns',
      getBusinessId: (m) => m.returnId,
      getTitle: (m) => '${m.returnId}  -  ${m.customerName}',
      getSubtitle: (m) => '${m.returnDate.isNotEmpty ? m.returnDate.substring(0,10) : "?"}  |  ${m.returnType}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductsController>().typedItems;
    final customers = context.read<CustomersController>().typedItems;
    final salesmen = context.read<SalesmenController>().typedItems;
    final salesInvoices = context.read<SalesInvoiceController>().items;
    final isWithInvoice = widget.returnType == 'with_invoice';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isWithInvoice ? 'Sales Return (With Invoice)' : 'Sales Return (Without Invoice)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _returnDateCtrl, decoration: _dec('Return Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_returnDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _returnDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                if (isWithInvoice) ...[
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      value: _saleId.isEmpty ? null : _saleId, decoration: _dec('Sales Invoice'), isExpanded: true,
                      items: salesInvoices.map((si) => DropdownMenuItem(value: si.id, child: Text(si.saleId.isNotEmpty ? 'SI: ${si.saleId}' : si.id, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final si = salesInvoices.firstWhere((x) => x.id == val);
                        setState(() { _saleId = val; _customerId = si.customerId; _salesmanId = si.salesmanId; });
                        _customerNameCtrl.text = si.customerName; _salesmanNameCtrl.text = si.salesmanName;
                        _itemsNotifier.value = List<Map<String, dynamic>>.from(si.items);
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _isFullReturn = true),
                    style: ElevatedButton.styleFrom(backgroundColor: _isFullReturn ? AppTheme.terra400 : AppTheme.softBorder),
                    child: const Text('Full Return'),
                  ),
                ],
                if (!isWithInvoice) ...[
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _customerId.isEmpty ? null : _customerId, decoration: _dec('Customer'), isExpanded: true, items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _customerId = val); _customerNameCtrl.text = customers.firstWhere((c) => c.id == val).text('name'); })),
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman'), isExpanded: true, items: salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _salesmanId = val); _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); })),
                ],
                Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: _toMainStore, onChanged: (v) => setState(() => _toMainStore = v), activeColor: AppTheme.terra400), const SizedBox(width: 8), const Text('To Main Store', style: TextStyle(fontSize: 13))]),
                SizedBox(width: 100, child: TextFormField(controller: _disc2PercentCtrl, decoration: _dec('Disc2 %'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 100, child: TextFormField(controller: _sedCtrl, decoration: _dec('SED'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 120, child: TextFormField(controller: _specialDiscountCtrl, decoration: _dec('Spc Disc'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 120, child: TextFormField(controller: _prevCreditCtrl, decoration: _dec('Prev Credit'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 120, child: TextFormField(controller: _paidAmountCtrl, decoration: _dec('Paid Amount'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              ])),
              const SizedBox(height: 16),
              InvoiceLineItemRow(isPurchase: false, products: products, onAdd: (item) => _itemsNotifier.value = [..._itemsNotifier.value, item]),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _itemsNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No items added yet.', style: TextStyle(color: AppTheme.textSecondary)));
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                        columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Packing')), DataColumn(label: Text('Qty(P)')), DataColumn(label: Text('Qty(L)')), DataColumn(label: Text('Price')), DataColumn(label: Text('Disc%')), DataColumn(label: Text('Gross')), DataColumn(label: Text(''))],
                        rows: items.asMap().entries.map((e) { final idx = e.key; final it = e.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')), DataCell(Text(it['packingName'] ?? '')), DataCell(Text('${it['qtyPacks'] ?? ''}')), DataCell(Text('${it['qtyLoose'] ?? ''}')), DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['discPercent'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['lineGross'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _itemsNotifier.value = u; }))],
                        ); }).toList(),
                      ))),
                      const SizedBox(height: 8),
                      InvoiceTotalsFooter(totals: _computeTotals(items), visibleKeys: const ['gross', 'discounts', 'invoiceValue', 'salesTax', 'totalSED', 'spcDisc', 'netValue', 'totalPayable', 'paidAmount', 'remBalance']),
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
            TextButton(onPressed: _openRecords, child: const Text('Records')),
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
