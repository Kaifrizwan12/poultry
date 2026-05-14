import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../controllers/purchase_invoice_controller.dart';
import '../models/payment_promise_model.dart';

class PostDatedPaymentPromiseScreen extends StatefulWidget {
  const PostDatedPaymentPromiseScreen({super.key});

  @override
  State<PostDatedPaymentPromiseScreen> createState() => _PostDatedPaymentPromiseScreenState();
}

class _PostDatedPaymentPromiseScreenState extends State<PostDatedPaymentPromiseScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _entryDate = DateTime.now().toIso8601String().substring(0, 10);
  final _promiseDateCtrl = TextEditingController();
  String _vendorId = '';
  final _vendorNameCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  List<String> _linkedPurchaseIds = [];
  String _promiseId = '';

  @override
  void dispose() {
    for (final c in [_promiseDateCtrl, _vendorNameCtrl, _chequeNoCtrl, _bankNameCtrl, _amountCtrl, _narrationCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _promiseId = ''; _vendorId = ''; _linkedPurchaseIds = []; });
    _promiseDateCtrl.clear(); _vendorNameCtrl.clear(); _chequeNoCtrl.clear(); _bankNameCtrl.clear(); _amountCtrl.text = '0'; _narrationCtrl.clear();
  }

  void _loadFromModel(PaymentPromiseModel m) {
    setState(() { _currentId = m.id; _promiseId = m.promiseId; _vendorId = m.vendorId; _linkedPurchaseIds = List<String>.from(m.linkedPurchaseIds); });
    _promiseDateCtrl.text = m.promiseDate; _vendorNameCtrl.text = m.vendorName;
    _chequeNoCtrl.text = m.chequeNo; _bankNameCtrl.text = m.bankName; _amountCtrl.text = m.amount.toStringAsFixed(2); _narrationCtrl.text = m.narration;
  }

  Map<String, dynamic> _buildPayload() => {
    'promiseType': 'payment', 'entryDate': _entryDate, 'promiseDate': _promiseDateCtrl.text,
    'vendorId': _vendorId, 'vendorName': _vendorNameCtrl.text,
    'chequeNo': _chequeNoCtrl.text, 'bankName': _bankNameCtrl.text,
    'amount': double.tryParse(_amountCtrl.text) ?? 0, 'narration': _narrationCtrl.text,
    'linkedPurchaseIds': _linkedPurchaseIds, 'status': 'pending',
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
      title: 'Payment Promises',
      getBusinessId: (m) => m.promiseId,
      getTitle: (m) => '${m.promiseId}  -  ${m.vendorName}',
      getSubtitle: (m) => '${m.promiseDate.isNotEmpty ? m.promiseDate.substring(0,10) : "?"}  |  ${m.status}  |  Rs ${m.amount.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorsController>().typedItems;
    final purchaseInvoices = context.read<PurchaseInvoiceController>().items;
    final filteredInvoices = _vendorId.isEmpty ? purchaseInvoices : purchaseInvoices.where((pi) => pi.vendorId == _vendorId).toList();
    final totalLinked = filteredInvoices.where((pi) => _linkedPurchaseIds.contains(pi.id)).fold<double>(0, (s, pi) => s + pi.totalPayable);
    final promiseAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final difference = totalLinked - promiseAmount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Post Dated Payment Promise', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_promiseId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Promise ID: $_promiseId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(6)), child: Text('Entry Date: $_entryDate', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                SizedBox(width: 160, child: TextFormField(controller: _promiseDateCtrl, decoration: _dec('Promise Date *'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _promiseDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _vendorId.isEmpty ? null : _vendorId, decoration: _dec('Vendor'), isExpanded: true, items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() { _vendorId = val; _linkedPurchaseIds = []; }); _vendorNameCtrl.text = vendors.firstWhere((v) => v.id == val).text('name'); })),
                SizedBox(width: 160, child: TextFormField(controller: _chequeNoCtrl, decoration: _dec('Cheque No'))),
                SizedBox(width: 180, child: TextFormField(controller: _bankNameCtrl, decoration: _dec('Bank Name'))),
                SizedBox(width: 140, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                SizedBox(width: 280, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
              ])),
              const SizedBox(height: 16),
              Text('Linked Purchase Invoices', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (filteredInvoices.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('Select a vendor to see invoices.', style: TextStyle(color: AppTheme.textSecondary)))
              else Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                columns: const [DataColumn(label: Text('Link')), DataColumn(label: Text('Purchase ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Total Payable'))],
                rows: filteredInvoices.asMap().entries.map((en) { final idx = en.key; final pi = en.value; final isLinked = _linkedPurchaseIds.contains(pi.id); return DataRow(
                  color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                  cells: [
                    DataCell(Checkbox(value: isLinked, onChanged: (v) { setState(() { if (v == true) { _linkedPurchaseIds = [..._linkedPurchaseIds, pi.id]; } else { _linkedPurchaseIds = _linkedPurchaseIds.where((id) => id != pi.id).toList(); } }); })),
                    DataCell(Text(pi.purchaseId.isNotEmpty ? pi.purchaseId : pi.id)), DataCell(Text(pi.entryDate)), DataCell(Text(pi.totalPayable.toStringAsFixed(2))),
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
