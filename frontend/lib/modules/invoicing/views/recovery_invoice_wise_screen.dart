import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_invoice_wise_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/recovery_invoice_wise_model.dart';

class RecoveryInvoiceWiseScreen extends StatefulWidget {
  const RecoveryInvoiceWiseScreen({super.key});

  @override
  State<RecoveryInvoiceWiseScreen> createState() => _RecoveryInvoiceWiseScreenState();
}

class _RecoveryInvoiceWiseScreenState extends State<RecoveryInvoiceWiseScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _recoveryDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  String _townId = '';
  String _sectorId = '';
  bool _showSalesmanInNarration = false;

  // Customer rows: Map<customerId, List<invoiceEntry>>
  final Map<String, List<Map<String, dynamic>>> _customerInvoices = {};
  final Map<String, TextEditingController> _narrationControllers = {};

  @override
  void dispose() {
    _recoveryDateCtrl.dispose(); _salesmanNameCtrl.dispose();
    for (final c in _narrationControllers.values) { c.dispose(); }
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _salesmanId = ''; _townId = ''; _sectorId = ''; _showSalesmanInNarration = false; _customerInvoices.clear(); });
    _recoveryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10); _salesmanNameCtrl.clear();
    for (final c in _narrationControllers.values) { c.dispose(); }
    _narrationControllers.clear();
  }

  void _loadFromModel(RecoveryInvoiceWiseModel m) {
    setState(() { _currentId = m.id; _salesmanId = m.salesmanId; });
    _recoveryDateCtrl.text = m.recoveryDate; _salesmanNameCtrl.text = m.salesmanName;
  }

  void _populate() {
    final salesInvoices = context.read<SalesInvoiceController>().items;
    final filtered = _salesmanId.isEmpty ? salesInvoices : salesInvoices.where((si) => si.salesmanId == _salesmanId).toList();
    setState(() {
      _customerInvoices.clear();
      for (final si in filtered) {
        _customerInvoices.putIfAbsent(si.customerId, () => []).add({
          'saleId': si.id, 'saleDisplayId': si.saleId, 'date': si.entryDate,
          'invoiceValue': si.totalPayable, 'adjusted': 0.0, 'receivable': si.totalPayable,
          'received': 0.0, 'discount': 0.0, 'balance': si.totalPayable, 'narration': '',
          'receivedCtrl': TextEditingController(text: '0'),
          'discountCtrl': TextEditingController(text: '0'),
          'narrationCtrl': TextEditingController(),
        });
      }
    });
  }

  Map<String, dynamic> _buildPayload() {
    final customerData = <Map<String, dynamic>>[];
    for (final entry in _customerInvoices.entries) {
      customerData.add({ 'customerId': entry.key, 'invoices': entry.value.map((inv) => { 'saleId': inv['saleId'], 'date': inv['date'], 'invoiceValue': inv['invoiceValue'], 'received': double.tryParse((inv['receivedCtrl'] as TextEditingController).text) ?? 0, 'discount': double.tryParse((inv['discountCtrl'] as TextEditingController).text) ?? 0, 'narration': (inv['narrationCtrl'] as TextEditingController).text }).toList() });
    }
    final netReceived = customerData.fold<double>(0, (s, c) => s + (c['invoices'] as List).fold<double>(0, (ss, i) => ss + ((i['received'] as num?)?.toDouble() ?? 0)));
    final discount = customerData.fold<double>(0, (s, c) => s + (c['invoices'] as List).fold<double>(0, (ss, i) => ss + ((i['discount'] as num?)?.toDouble() ?? 0)));
    return { 'recoveryDate': _recoveryDateCtrl.text, 'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text, 'townId': _townId, 'sectorId': _sectorId, 'showSalesmanInNarration': _showSalesmanInNarration, 'customerData': customerData, 'netReceived': netReceived, 'discount': discount, 'grossRecoveries': netReceived + discount, 'status': 'saved' };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<RecoveryInvoiceWiseController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this recovery?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<RecoveryInvoiceWiseController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<RecoveryInvoiceWiseController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<RecoveryInvoiceWiseModel>(
      context: context,
      records: ctrl.items,
      title: 'Recovery (Invoice Wise)',
      getBusinessId: (m) => m.recoveryId,
      getTitle: (m) => '${m.recoveryId}  -  ${m.salesmanName}',
      getSubtitle: (m) => m.recoveryDate.isNotEmpty ? m.recoveryDate.substring(0,10) : '?',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.read<SalesmenController>().typedItems;
    final towns = context.read<TownsController>().typedItems;
    final sectors = context.read<SectorsController>().typedItems;
    final customers = context.read<CustomersController>().typedItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recovery (Invoice Wise)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _recoveryDateCtrl, decoration: _dec('Recovery Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_recoveryDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _recoveryDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman'), isExpanded: true, items: salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _salesmanId = val); _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); })),
                SizedBox(width: 160, child: DropdownButtonFormField<String>(value: _townId.isEmpty ? null : _townId, decoration: _dec('Town'), isExpanded: true, items: towns.map((t) => DropdownMenuItem(value: t.id, child: Text(t.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _townId = val ?? ''))),
                SizedBox(width: 160, child: DropdownButtonFormField<String>(value: _sectorId.isEmpty ? null : _sectorId, decoration: _dec('Sector'), isExpanded: true, items: sectors.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _sectorId = val ?? ''))),
                Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: _showSalesmanInNarration, onChanged: (v) => setState(() => _showSalesmanInNarration = v ?? false)), const Text('Show Salesman in Narration', style: TextStyle(fontSize: 13))]),
                ElevatedButton(onPressed: _populate, child: const Text('Populate')),
              ])),
              const SizedBox(height: 16),
              if (_customerInvoices.isNotEmpty) ...[
                for (final entry in _customerInvoices.entries) ...[
                  Builder(builder: (ctx) {
                    String custName = entry.key;
                    try { custName = customers.firstWhere((c) => c.id == entry.key).text('name'); } catch (_) {}
                    return ExpansionTile(
                      title: Text(custName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      initiallyExpanded: true,
                      children: [
                        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 40, dataRowMaxHeight: 56,
                          columns: const [DataColumn(label: Text('Sale ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Inv Value')), DataColumn(label: Text('Receivable')), DataColumn(label: Text('Received')), DataColumn(label: Text('Discount')), DataColumn(label: Text('Balance')), DataColumn(label: Text('Narration'))],
                          rows: entry.value.asMap().entries.map((en) { final idx = en.key; final inv = en.value; final received = double.tryParse((inv['receivedCtrl'] as TextEditingController).text) ?? 0; final discount = double.tryParse((inv['discountCtrl'] as TextEditingController).text) ?? 0; final balance = ((inv['invoiceValue'] as num?)?.toDouble() ?? 0) - received - discount; return DataRow(
                            color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                            cells: [
                              DataCell(Text(inv['saleDisplayId'] ?? inv['saleId'] ?? '')),
                              DataCell(Text(inv['date'] ?? '')),
                              DataCell(Text((inv['invoiceValue'] as num?)?.toStringAsFixed(2) ?? '0')),
                              DataCell(Text((inv['receivable'] as num?)?.toStringAsFixed(2) ?? '0')),
                              DataCell(SizedBox(width: 100, child: TextFormField(controller: inv['receivedCtrl'] as TextEditingController, decoration: _dec(''), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})))),
                              DataCell(SizedBox(width: 100, child: TextFormField(controller: inv['discountCtrl'] as TextEditingController, decoration: _dec(''), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})))),
                              DataCell(Text(balance.toStringAsFixed(2))),
                              DataCell(SizedBox(width: 160, child: TextFormField(controller: inv['narrationCtrl'] as TextEditingController, decoration: _dec('')))),
                            ],
                          ); }).toList(),
                        )),
                      ],
                    );
                  }),
                ],
              ] else
                const Padding(padding: EdgeInsets.all(16), child: Text('Click Populate to load invoices.', style: TextStyle(color: AppTheme.textSecondary))),
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
