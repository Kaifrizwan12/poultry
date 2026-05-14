import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_invoice_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/recovery_invoice_model.dart';

class RecoveryInvoiceScreen extends StatefulWidget {
  const RecoveryInvoiceScreen({super.key});

  @override
  State<RecoveryInvoiceScreen> createState() => _RecoveryInvoiceScreenState();
}

class _RecoveryInvoiceScreenState extends State<RecoveryInvoiceScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _entriesNotifier = ValueNotifier([]);

  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  String _recoveryId = '';

  // Entry row state
  String? _entryCustomerId;
  final _entryCustomerNameCtrl = TextEditingController();
  String? _entrySaleId;
  double _entrySaleValue = 0;
  final _entryAdjustedCtrl = TextEditingController(text: '0');
  final _entryReceivedCtrl = TextEditingController(text: '0');
  final _entryDiscountCtrl = TextEditingController(text: '0');
  final _entryNarrationCtrl = TextEditingController();

  @override
  void dispose() {
    _dateCtrl.dispose(); _salesmanNameCtrl.dispose();
    _entryCustomerNameCtrl.dispose(); _entryAdjustedCtrl.dispose();
    _entryReceivedCtrl.dispose(); _entryDiscountCtrl.dispose(); _entryNarrationCtrl.dispose();
    _entriesNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _recoveryId = ''; _salesmanId = ''; _entryCustomerId = null; _entrySaleId = null; _entrySaleValue = 0; });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear(); _entryCustomerNameCtrl.clear();
    for (final c in [_entryAdjustedCtrl, _entryReceivedCtrl, _entryDiscountCtrl]) { c.text = '0'; }
    _entryNarrationCtrl.clear();
    _entriesNotifier.value = [];
  }

  void _loadFromModel(RecoveryInvoiceModel m) {
    setState(() { _currentId = m.id; _recoveryId = m.recoveryId; _salesmanId = m.salesmanId; });
    _dateCtrl.text = m.date; _salesmanNameCtrl.text = m.salesmanName;
    _entriesNotifier.value = List<Map<String, dynamic>>.from(m.customerRecoveries);
  }

  void _addEntry() {
    if (_entryCustomerId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a customer'))); return; }
    if (_entrySaleId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a sale invoice'))); return; }
    final received = double.tryParse(_entryReceivedCtrl.text) ?? 0;
    final discount = double.tryParse(_entryDiscountCtrl.text) ?? 0;
    if (received + discount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Received or Discount must be > 0'))); return; }
    final adjusted = double.tryParse(_entryAdjustedCtrl.text) ?? 0;
    final receivable = _entrySaleValue - adjusted;
    final finalCredit = received + discount;
    _entriesNotifier.value = [..._entriesNotifier.value, {
      'customerId': _entryCustomerId, 'customerName': _entryCustomerNameCtrl.text,
      'saleId': _entrySaleId, 'saleValue': _entrySaleValue,
      'adjusted': adjusted, 'receivable': receivable,
      'received': received, 'discount': discount, 'finalCredit': finalCredit,
      'narration': _entryNarrationCtrl.text,
    }];
    setState(() { _entryCustomerId = null; _entrySaleId = null; _entrySaleValue = 0; });
    _entryCustomerNameCtrl.clear();
    for (final c in [_entryAdjustedCtrl, _entryReceivedCtrl, _entryDiscountCtrl]) { c.text = '0'; }
    _entryNarrationCtrl.clear();
  }

  Map<String, dynamic> _buildPayload() {
    final entries = _entriesNotifier.value;
    final totalNoInvoices = entries.length;
    final amount = entries.fold<double>(0, (s, e) => s + ((e['received'] as num?)?.toDouble() ?? 0));
    final discount = entries.fold<double>(0, (s, e) => s + ((e['discount'] as num?)?.toDouble() ?? 0));
    return { 'date': _dateCtrl.text, 'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text, 'totalNoInvoices': totalNoInvoices, 'amount': amount, 'discount': discount, 'customerRecoveries': entries, 'status': 'saved' };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<RecoveryInvoiceController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _recoveryId = r.recoveryId; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this recovery?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<RecoveryInvoiceController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<RecoveryInvoiceController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<RecoveryInvoiceModel>(
      context: context,
      records: ctrl.items,
      title: 'Recovery Invoices',
      getBusinessId: (m) => m.recoveryId,
      getTitle: (m) => '${m.recoveryId}  -  ${m.salesmanName}',
      getSubtitle: (m) => '${m.date.isNotEmpty ? m.date.substring(0,10) : "?"}  |  Rs ${m.amount.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.read<SalesmenController>().typedItems;
    final customers = context.read<CustomersController>().typedItems;
    final salesInvoices = context.read<SalesInvoiceController>().items;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Recovery Invoice', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_recoveryId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Recovery ID: $_recoveryId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _dateCtrl, decoration: _dec('Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman'), isExpanded: true, items: salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _salesmanId = val); _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); })),
              ])),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)),
                child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _entryCustomerId, decoration: _dec('Customer'), isExpanded: true, items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() { _entryCustomerId = val; _entrySaleId = null; _entrySaleValue = 0; }); _entryCustomerNameCtrl.text = customers.firstWhere((c) => c.id == val).text('name'); })),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _entrySaleId,
                      decoration: _dec('Sale Invoice'),
                      isExpanded: true,
                      items: salesInvoices.where((si) => _entryCustomerId == null || si.customerId == _entryCustomerId).map((si) => DropdownMenuItem(value: si.id, child: Text(si.saleId.isNotEmpty ? 'SI: ${si.saleId}' : si.id, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final si = salesInvoices.firstWhere((x) => x.id == val);
                        setState(() { _entrySaleId = val; _entrySaleValue = si.totalPayable; });
                      },
                    ),
                  ),
                  SizedBox(width: 100, child: AbsorbPointer(child: TextFormField(decoration: _dec('Sale Value'), controller: TextEditingController(text: _entrySaleValue.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  SizedBox(width: 100, child: TextFormField(controller: _entryAdjustedCtrl, decoration: _dec('Adjusted'), keyboardType: TextInputType.number)),
                  SizedBox(width: 110, child: TextFormField(controller: _entryReceivedCtrl, decoration: _dec('Received'), keyboardType: TextInputType.number)),
                  SizedBox(width: 100, child: TextFormField(controller: _entryDiscountCtrl, decoration: _dec('Discount'), keyboardType: TextInputType.number)),
                  SizedBox(width: 220, child: TextFormField(controller: _entryNarrationCtrl, decoration: _dec('Narration'))),
                  ElevatedButton.icon(onPressed: _addEntry, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                ]),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _entriesNotifier,
                  builder: (context, entries, _) {
                    if (entries.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No entries added.', style: TextStyle(color: AppTheme.textSecondary)));
                    final totalInvoices = entries.length;
                    final totalAmount = entries.fold<double>(0, (s, e) => s + ((e['received'] as num?)?.toDouble() ?? 0));
                    final totalDiscount = entries.fold<double>(0, (s, e) => s + ((e['discount'] as num?)?.toDouble() ?? 0));
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                        columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Customer')), DataColumn(label: Text('Sale ID')), DataColumn(label: Text('Sale Value')), DataColumn(label: Text('Adjusted')), DataColumn(label: Text('Receivable')), DataColumn(label: Text('Received')), DataColumn(label: Text('Discount')), DataColumn(label: Text('Final Credit')), DataColumn(label: Text('Narration')), DataColumn(label: Text(''))],
                        rows: entries.asMap().entries.map((en) { final idx = en.key; final e = en.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [DataCell(Text('${idx + 1}')), DataCell(Text(e['customerName'] ?? '')), DataCell(Text(e['saleId'] ?? '')), DataCell(Text((e['saleValue'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['adjusted'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['receivable'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['received'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['discount'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['finalCredit'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text(e['narration'] ?? '')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...entries]; u.removeAt(idx); _entriesNotifier.value = u; }))],
                        ); }).toList(),
                      ))),
                      const SizedBox(height: 8),
                      Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                        Text('Invoices: $totalInvoices', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 20),
                        Text('Amount: ${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 20),
                        Text('Discount: ${totalDiscount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ])),
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
            TextButton(onPressed: _clearForm, child: const Text('Clear')),
            TextButton(onPressed: _openRecords, child: const Text('Records')),
            TextButton(onPressed: _currentId != null ? _remove : null, child: const Text('Remove')),
            const Spacer(),
            ElevatedButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _clearForm, child: const Text('Close')),
          ]),
        ),
      ],
    );
  }
}
