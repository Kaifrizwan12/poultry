import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/salesman_cash_reconciliation_controller.dart';
import '../controllers/recovery_invoice_controller.dart';
import '../models/salesman_cash_reconciliation_model.dart';

class SalesmanCashReconciliationScreen extends StatefulWidget {
  const SalesmanCashReconciliationScreen({super.key});

  @override
  State<SalesmanCashReconciliationScreen> createState() => _SalesmanCashReconciliationScreenState();
}

class _SalesmanCashReconciliationScreenState extends State<SalesmanCashReconciliationScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _recoveryEntriesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _expenseEntriesNotifier = ValueNotifier([]);

  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController(text: '0');
  final _cashDepositedCtrl = TextEditingController(text: '0');

  // Recovery entry row
  String? _recEntryRecoveryId;
  final _recEntryRecoveryDateCtrl = TextEditingController();
  final _recEntryCashReceivedCtrl = TextEditingController(text: '0');
  final _recEntryDiscountCtrl = TextEditingController(text: '0');
  final _recEntryNarrationCtrl = TextEditingController();

  // Expense entry row
  final _expDescCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _dateCtrl.dispose(); _salesmanNameCtrl.dispose(); _openingBalanceCtrl.dispose(); _cashDepositedCtrl.dispose();
    _recEntryRecoveryDateCtrl.dispose(); _recEntryCashReceivedCtrl.dispose(); _recEntryDiscountCtrl.dispose(); _recEntryNarrationCtrl.dispose();
    _expDescCtrl.dispose(); _expAmountCtrl.dispose();
    _recoveryEntriesNotifier.dispose(); _expenseEntriesNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _salesmanId = ''; _recEntryRecoveryId = null; });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear(); _openingBalanceCtrl.text = '0'; _cashDepositedCtrl.text = '0';
    _recEntryRecoveryDateCtrl.clear(); _recEntryCashReceivedCtrl.text = '0'; _recEntryDiscountCtrl.text = '0'; _recEntryNarrationCtrl.clear();
    _expDescCtrl.clear(); _expAmountCtrl.text = '0';
    _recoveryEntriesNotifier.value = []; _expenseEntriesNotifier.value = [];
  }

  void _loadFromModel(SalesmanCashReconciliationModel m) {
    setState(() { _currentId = m.id; _salesmanId = m.salesmanId; });
    _dateCtrl.text = m.date; _salesmanNameCtrl.text = m.salesmanName;
    _openingBalanceCtrl.text = m.openingBalance.toStringAsFixed(2);
    _cashDepositedCtrl.text = m.cashDeposited.toStringAsFixed(2);
    _recoveryEntriesNotifier.value = List<Map<String, dynamic>>.from(m.recoveryEntries);
    _expenseEntriesNotifier.value = List<Map<String, dynamic>>.from(m.expenseEntries);
  }

  void _addRecoveryEntry() {
    if (_recEntryRecoveryId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a recovery'))); return; }
    final cashReceived = double.tryParse(_recEntryCashReceivedCtrl.text) ?? 0;
    _recoveryEntriesNotifier.value = [..._recoveryEntriesNotifier.value, { 'recoveryId': _recEntryRecoveryId, 'recoveryDate': _recEntryRecoveryDateCtrl.text, 'cashReceived': cashReceived, 'discountGiven': double.tryParse(_recEntryDiscountCtrl.text) ?? 0, 'narration': _recEntryNarrationCtrl.text }];
    setState(() => _recEntryRecoveryId = null);
    _recEntryRecoveryDateCtrl.clear(); _recEntryCashReceivedCtrl.text = '0'; _recEntryDiscountCtrl.text = '0'; _recEntryNarrationCtrl.clear();
  }

  void _addExpenseEntry() {
    final amount = double.tryParse(_expAmountCtrl.text) ?? 0;
    if (_expDescCtrl.text.trim().isEmpty || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter description and amount'))); return; }
    _expenseEntriesNotifier.value = [..._expenseEntriesNotifier.value, { 'description': _expDescCtrl.text.trim(), 'amount': amount }];
    _expDescCtrl.clear(); _expAmountCtrl.text = '0';
  }

  Map<String, dynamic> _buildPayload() {
    final recoveryEntries = _recoveryEntriesNotifier.value;
    final expenseEntries = _expenseEntriesNotifier.value;
    final openingBalance = double.tryParse(_openingBalanceCtrl.text) ?? 0;
    final totalCashReceived = recoveryEntries.fold<double>(0, (s, e) => s + ((e['cashReceived'] as num?)?.toDouble() ?? 0));
    final totalExpenses = expenseEntries.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    final cashDeposited = double.tryParse(_cashDepositedCtrl.text) ?? 0;
    final closingBalance = openingBalance + totalCashReceived - totalExpenses - cashDeposited;
    return { 'date': _dateCtrl.text, 'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text, 'openingBalance': openingBalance, 'recoveryEntries': recoveryEntries, 'expenseEntries': expenseEntries, 'totalCashReceived': totalCashReceived, 'totalExpenses': totalExpenses, 'cashDeposited': cashDeposited, 'closingBalance': closingBalance, 'status': 'saved' };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<SalesmanCashReconciliationController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<SalesmanCashReconciliationController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<SalesmanCashReconciliationController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<SalesmanCashReconciliationModel>(
      context: context,
      records: ctrl.items,
      title: 'Cash Reconciliations',
      getBusinessId: (m) => m.reconciliationId,
      getTitle: (m) => '${m.reconciliationId}  -  ${m.salesmanName}',
      getSubtitle: (m) => '${m.date.isNotEmpty ? m.date.substring(0,10) : "?"}  |  ${m.status}',
      statusField: 'status',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.read<SalesmenController>().typedItems;
    final recoveries = context.read<RecoveryInvoiceController>().items;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Salesman Cash Reconciliation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _dateCtrl, decoration: _dec('Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman'), isExpanded: true, items: salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _salesmanId = val); _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); })),
                SizedBox(width: 130, child: TextFormField(controller: _openingBalanceCtrl, decoration: _dec('Opening Bal'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              ])),
              const SizedBox(height: 16),
              Text('Recovery Entries', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)), child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _recEntryRecoveryId, decoration: _dec('Recovery'), isExpanded: true, items: recoveries.where((r) => r.salesmanId == _salesmanId || _salesmanId.isEmpty).map((r) => DropdownMenuItem(value: r.id, child: Text(r.recoveryId.isNotEmpty ? 'REC: ${r.recoveryId}' : r.id, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; final r = recoveries.firstWhere((x) => x.id == val); setState(() { _recEntryRecoveryId = val; _recEntryRecoveryDateCtrl.text = r.date; }); })),
                SizedBox(width: 120, child: AbsorbPointer(child: TextFormField(controller: _recEntryRecoveryDateCtrl, decoration: _dec('Recovery Date'), style: const TextStyle(color: AppTheme.textSecondary)))),
                SizedBox(width: 120, child: TextFormField(controller: _recEntryCashReceivedCtrl, decoration: _dec('Cash Received'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 110, child: TextFormField(controller: _recEntryDiscountCtrl, decoration: _dec('Discount'), keyboardType: TextInputType.number)),
                SizedBox(width: 200, child: TextFormField(controller: _recEntryNarrationCtrl, decoration: _dec('Narration'))),
                ElevatedButton.icon(onPressed: _addRecoveryEntry, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              ])),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _recoveryEntriesNotifier,
                  builder: (context, entries, _) {
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                      columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Recovery ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Cash Received')), DataColumn(label: Text('Discount')), DataColumn(label: Text('Narration')), DataColumn(label: Text(''))],
                      rows: entries.asMap().entries.map((en) { final idx = en.key; final e = en.value; return DataRow(
                        color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                        cells: [DataCell(Text('${idx + 1}')), DataCell(Text(e['recoveryId'] ?? '')), DataCell(Text(e['recoveryDate'] ?? '')), DataCell(Text((e['cashReceived'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((e['discountGiven'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text(e['narration'] ?? '')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...entries]; u.removeAt(idx); _recoveryEntriesNotifier.value = u; }))],
                      ); }).toList(),
                    )));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Expense Entries', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)), child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                SizedBox(width: 280, child: TextFormField(controller: _expDescCtrl, decoration: _dec('Description'))),
                SizedBox(width: 120, child: TextFormField(controller: _expAmountCtrl, decoration: _dec('Amount'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                ElevatedButton.icon(onPressed: _addExpenseEntry, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              ])),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _expenseEntriesNotifier,
                  builder: (context, entries, _) {
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                      columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Description')), DataColumn(label: Text('Amount')), DataColumn(label: Text(''))],
                      rows: entries.asMap().entries.map((en) { final idx = en.key; final e = en.value; return DataRow(
                        color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                        cells: [DataCell(Text('${idx + 1}')), DataCell(Text(e['description'] ?? '')), DataCell(Text((e['amount'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...entries]; u.removeAt(idx); _expenseEntriesNotifier.value = u; }))],
                      ); }).toList(),
                    )));
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Footer totals
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _recoveryEntriesNotifier,
                builder: (context, recEntries, _) => ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _expenseEntriesNotifier,
                  builder: (context, expEntries, _) {
                    final openingBalance = double.tryParse(_openingBalanceCtrl.text) ?? 0;
                    final totalCashReceived = recEntries.fold<double>(0, (s, e) => s + ((e['cashReceived'] as num?)?.toDouble() ?? 0));
                    final discount = recEntries.fold<double>(0, (s, e) => s + ((e['discountGiven'] as num?)?.toDouble() ?? 0));
                    final totalExpenses = expEntries.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
                    final cashDeposited = double.tryParse(_cashDepositedCtrl.text) ?? 0;
                    final closingBalance = openingBalance + totalCashReceived - totalExpenses - cashDeposited;
                    return Container(
                      decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding,
                      child: Wrap(spacing: 20, runSpacing: 12, children: [
                        _TotalItem('Opening Bal', openingBalance.toStringAsFixed(2)),
                        _TotalItem('Cash Received', totalCashReceived.toStringAsFixed(2)),
                        _TotalItem('Discount', discount.toStringAsFixed(2)),
                        _TotalItem('Expenses', totalExpenses.toStringAsFixed(2)),
                        SizedBox(width: 140, child: TextFormField(controller: _cashDepositedCtrl, decoration: _dec('Cash Deposited'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                        _TotalItem('Closing Balance', closingBalance.toStringAsFixed(2), bold: true),
                      ]),
                    );
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

class _TotalItem extends StatelessWidget {
  const _TotalItem(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: AppTheme.textPrimary, fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
    ]);
  }
}
