import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_receivable_wise_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/recovery_receivable_wise_model.dart';

class RecoveryReceivableWiseScreen extends StatefulWidget {
  const RecoveryReceivableWiseScreen({super.key});

  @override
  State<RecoveryReceivableWiseScreen> createState() => _RecoveryReceivableWiseScreenState();
}

class _RecoveryReceivableWiseScreenState extends State<RecoveryReceivableWiseScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _recoveryDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  String _townId = '';
  String _sectorId = '';
  bool _showSalesmanInNarration = false;

  // Rows: one per customer
  final List<Map<String, dynamic>> _rows = [];

  @override
  void dispose() {
    _recoveryDateCtrl.dispose(); _salesmanNameCtrl.dispose();
    for (final row in _rows) {
      (row['receivedCtrl'] as TextEditingController).dispose();
      (row['discountCtrl'] as TextEditingController).dispose();
      (row['narrationCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    for (final row in _rows) {
      (row['receivedCtrl'] as TextEditingController).dispose();
      (row['discountCtrl'] as TextEditingController).dispose();
      (row['narrationCtrl'] as TextEditingController).dispose();
    }
    setState(() { _currentId = null; _salesmanId = ''; _townId = ''; _sectorId = ''; _showSalesmanInNarration = false; _rows.clear(); });
    _recoveryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10); _salesmanNameCtrl.clear();
  }

  void _loadFromModel(RecoveryReceivableWiseModel m) {
    setState(() { _currentId = m.id; _salesmanId = m.salesmanId; });
    _recoveryDateCtrl.text = m.recoveryDate; _salesmanNameCtrl.text = m.salesmanName;
  }

  void _populate() {
    final salesInvoices = context.read<SalesInvoiceController>().items;
    final customers = context.read<CustomersController>().typedItems;
    final filtered = _salesmanId.isEmpty ? salesInvoices : salesInvoices.where((si) => si.salesmanId == _salesmanId).toList();

    // Group receivable by customer
    final Map<String, double> receivableMap = {};
    for (final si in filtered) {
      receivableMap[si.customerId] = (receivableMap[si.customerId] ?? 0) + si.remBalance;
    }

    for (final row in _rows) {
      (row['receivedCtrl'] as TextEditingController).dispose();
      (row['discountCtrl'] as TextEditingController).dispose();
      (row['narrationCtrl'] as TextEditingController).dispose();
    }

    setState(() {
      _rows.clear();
      for (final entry in receivableMap.entries) {
        if (entry.value <= 0) continue;
        String custName = entry.key;
        String sectorId = '';
        try { final c = customers.firstWhere((x) => x.id == entry.key); custName = c.text('name'); sectorId = c.text('sectorId'); } catch (_) {}
        _rows.add({ 'customerId': entry.key, 'customerName': custName, 'sectorId': sectorId, 'receivable': entry.value, 'receivedCtrl': TextEditingController(text: '0'), 'discountCtrl': TextEditingController(text: '0'), 'narrationCtrl': TextEditingController() });
      }
    });
  }

  Map<String, dynamic> _buildPayload() {
    final rowData = _rows.map((row) => { 'customerId': row['customerId'], 'customerName': row['customerName'], 'sectorId': row['sectorId'], 'receivable': row['receivable'], 'received': double.tryParse((row['receivedCtrl'] as TextEditingController).text) ?? 0, 'discount': double.tryParse((row['discountCtrl'] as TextEditingController).text) ?? 0, 'narration': (row['narrationCtrl'] as TextEditingController).text }).toList();
    final netReceived = rowData.fold<double>(0, (s, r) => s + ((r['received'] as num?)?.toDouble() ?? 0));
    final discount = rowData.fold<double>(0, (s, r) => s + ((r['discount'] as num?)?.toDouble() ?? 0));
    return { 'recoveryDate': _recoveryDateCtrl.text, 'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text, 'townId': _townId, 'sectorId': _sectorId, 'showSalesmanInNarration': _showSalesmanInNarration, 'rows': rowData, 'netReceived': netReceived, 'discount': discount, 'grossRecoveries': netReceived + discount, 'status': 'saved' };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<RecoveryReceivableWiseController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<RecoveryReceivableWiseController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<RecoveryReceivableWiseController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<RecoveryReceivableWiseModel>(
      context: context,
      records: ctrl.items,
      title: 'Recovery (Receivable Wise)',
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recovery (Receivable Wise)', style: Theme.of(context).textTheme.titleLarge),
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
              RepaintBoundary(
                child: _rows.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Click Populate to load customers.', style: TextStyle(color: AppTheme.textSecondary)))
                    : Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 40, dataRowMaxHeight: 56,
                        columns: const [DataColumn(label: Text('ID')), DataColumn(label: Text('Customer Name')), DataColumn(label: Text('Sector')), DataColumn(label: Text('Receivable')), DataColumn(label: Text('Received')), DataColumn(label: Text('Discount')), DataColumn(label: Text('Balance')), DataColumn(label: Text('Narration'))],
                        rows: _rows.asMap().entries.map((en) { final idx = en.key; final row = en.value; final received = double.tryParse((row['receivedCtrl'] as TextEditingController).text) ?? 0; final discount = double.tryParse((row['discountCtrl'] as TextEditingController).text) ?? 0; final balance = ((row['receivable'] as num?)?.toDouble() ?? 0) - received - discount; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [
                            DataCell(Text(row['customerId'] ?? '')),
                            DataCell(Text(row['customerName'] ?? '')),
                            DataCell(Text(row['sectorId'] ?? '')),
                            DataCell(Text((row['receivable'] as num?)?.toStringAsFixed(2) ?? '0')),
                            DataCell(SizedBox(width: 100, child: TextFormField(controller: row['receivedCtrl'] as TextEditingController, decoration: _dec(''), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})))),
                            DataCell(SizedBox(width: 100, child: TextFormField(controller: row['discountCtrl'] as TextEditingController, decoration: _dec(''), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})))),
                            DataCell(Text(balance.toStringAsFixed(2))),
                            DataCell(SizedBox(width: 160, child: TextFormField(controller: row['narrationCtrl'] as TextEditingController, decoration: _dec('')))),
                          ],
                        ); }).toList(),
                      ))),
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
