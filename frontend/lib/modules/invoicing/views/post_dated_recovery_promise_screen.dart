import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/payment_promise_model.dart';

class PostDatedRecoveryPromiseScreen extends StatefulWidget {
  const PostDatedRecoveryPromiseScreen({super.key});

  @override
  State<PostDatedRecoveryPromiseScreen> createState() => _PostDatedRecoveryPromiseScreenState();
}

class _PostDatedRecoveryPromiseScreenState extends State<PostDatedRecoveryPromiseScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _entryDate = DateTime.now().toIso8601String().substring(0, 10);
  final _promiseDateCtrl = TextEditingController();
  String _customerId = '';
  final _customerNameCtrl = TextEditingController();
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  List<String> _linkedSaleIds = [];
  String _promiseId = '';

  @override
  void dispose() {
    for (final c in [_promiseDateCtrl, _customerNameCtrl, _salesmanNameCtrl, _chequeNoCtrl, _bankNameCtrl, _amountCtrl, _narrationCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _promiseId = ''; _customerId = ''; _salesmanId = ''; _linkedSaleIds = []; });
    _promiseDateCtrl.clear(); _customerNameCtrl.clear(); _salesmanNameCtrl.clear();
    _chequeNoCtrl.clear(); _bankNameCtrl.clear(); _amountCtrl.text = '0'; _narrationCtrl.clear();
  }

  void _loadFromModel(PaymentPromiseModel m) {
    setState(() { _currentId = m.id; _promiseId = m.promiseId; _customerId = m.customerId; _salesmanId = m.salesmanId; _linkedSaleIds = List<String>.from(m.linkedSaleIds); });
    _promiseDateCtrl.text = m.promiseDate; _customerNameCtrl.text = m.customerName; _salesmanNameCtrl.text = m.salesmanName;
    _chequeNoCtrl.text = m.chequeNo; _bankNameCtrl.text = m.bankName; _amountCtrl.text = m.amount.toStringAsFixed(2); _narrationCtrl.text = m.narration;
  }

  Map<String, dynamic> _buildPayload() => {
    'promiseType': 'recovery', 'entryDate': _entryDate, 'promiseDate': _promiseDateCtrl.text,
    'customerId': _customerId, 'customerName': _customerNameCtrl.text,
    'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text,
    'chequeNo': _chequeNoCtrl.text, 'bankName': _bankNameCtrl.text,
    'amount': double.tryParse(_amountCtrl.text) ?? 0, 'narration': _narrationCtrl.text,
    'linkedSaleIds': _linkedSaleIds, 'status': 'pending',
  };

  Future<void> _save() async {
    if (_promiseDateCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promise Date is required'))); return; }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<PaymentPromiseController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _promiseId = r.promiseId; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this promise?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<PaymentPromiseController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<PaymentPromiseController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<PaymentPromiseModel>(
      context: context,
      records: ctrl.items,
      title: 'Recovery Promises',
      getBusinessId: (m) => m.promiseId,
      getTitle: (m) => '${m.promiseId}  -  ${m.customerName}',
      getSubtitle: (m) => '${m.promiseDate.isNotEmpty ? m.promiseDate.substring(0,10) : "?"}  |  ${m.status}  |  Rs ${m.amount.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final customers = context.read<CustomersController>().typedItems;
    final salesmen = context.read<SalesmenController>().typedItems;
    final salesInvoices = context.read<SalesInvoiceController>().items;
    final filteredInvoices = _customerId.isEmpty ? salesInvoices : salesInvoices.where((si) => si.customerId == _customerId).toList();
    final totalLinked = filteredInvoices.where((si) => _linkedSaleIds.contains(si.id)).fold<double>(0, (s, si) => s + si.totalPayable);
    final promiseAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final difference = totalLinked - promiseAmount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Post Dated Recovery Promise', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_promiseId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Promise ID: $_promiseId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(6)), child: Text('Entry Date: $_entryDate', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                SizedBox(width: 160, child: TextFormField(controller: _promiseDateCtrl, decoration: _dec('Promise Date *'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _promiseDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _customerId.isEmpty ? null : _customerId, decoration: _dec('Customer'), isExpanded: true, items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() { _customerId = val; _linkedSaleIds = []; }); _customerNameCtrl.text = customers.firstWhere((c) => c.id == val).text('name'); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman (optional)'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('None')), ...salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis)))], onChanged: (val) { setState(() => _salesmanId = val ?? ''); if (val != null && val.isNotEmpty) { _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); } else { _salesmanNameCtrl.clear(); } })),
                SizedBox(width: 160, child: TextFormField(controller: _chequeNoCtrl, decoration: _dec('Cheque No'))),
                SizedBox(width: 180, child: TextFormField(controller: _bankNameCtrl, decoration: _dec('Bank Name'))),
                SizedBox(width: 140, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 280, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
              ])),
              const SizedBox(height: 16),
              Text('Linked Invoices', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (filteredInvoices.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('Select a customer to see invoices.', style: TextStyle(color: AppTheme.textSecondary)))
              else Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                columns: const [DataColumn(label: Text('Link')), DataColumn(label: Text('Sale ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Total Payable'))],
                rows: filteredInvoices.asMap().entries.map((en) { final idx = en.key; final si = en.value; final isLinked = _linkedSaleIds.contains(si.id); return DataRow(
                  color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                  cells: [
                    DataCell(Checkbox(value: isLinked, onChanged: (v) { setState(() { if (v == true) { _linkedSaleIds = [..._linkedSaleIds, si.id]; } else { _linkedSaleIds = _linkedSaleIds.where((id) => id != si.id).toList(); } }); })),
                    DataCell(Text(si.saleId.isNotEmpty ? si.saleId : si.id)), DataCell(Text(si.entryDate)), DataCell(Text(si.totalPayable.toStringAsFixed(2))),
                  ],
                ); }).toList(),
              ))),
              const SizedBox(height: 8),
              Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                Text('Total Linked: ${totalLinked.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 24),
                Text('Promise Amount: ${promiseAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 24),
                Text('Difference: ${difference.toStringAsFixed(2)}', style: TextStyle(color: difference.abs() > 0.01 ? AppTheme.warningText : AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
              ])),
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
