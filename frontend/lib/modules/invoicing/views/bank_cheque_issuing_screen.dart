import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_cheque_controller.dart';
import '../models/bank_cheque_model.dart';

class BankChequeIssuingScreen extends StatefulWidget {
  const BankChequeIssuingScreen({super.key});

  @override
  State<BankChequeIssuingScreen> createState() => _BankChequeIssuingScreenState();
}

class _BankChequeIssuingScreenState extends State<BankChequeIssuingScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _chequeNoCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _bankAccountId = '';
  final _bankAcNoCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  String _payeeType = 'vendor';
  String _vendorId = '';
  String _payeeAccountId = '';
  final _payeeNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  bool _isPostDated = false;
  String _chequeId = '';

  @override
  void dispose() {
    for (final c in [_chequeNoCtrl, _chequeDateCtrl, _bankAcNoCtrl, _bankAccountNameCtrl, _payeeNameCtrl, _amountCtrl, _narrationCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _chequeId = ''; _bankAccountId = ''; _payeeType = 'vendor'; _vendorId = ''; _payeeAccountId = ''; _isPostDated = false; });
    _chequeNoCtrl.clear(); _chequeDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _bankAcNoCtrl.clear(); _bankAccountNameCtrl.clear(); _payeeNameCtrl.clear(); _amountCtrl.text = '0'; _narrationCtrl.clear();
  }

  void _loadFromModel(BankChequeModel m) {
    setState(() { _currentId = m.id; _chequeId = m.chequeId; _bankAccountId = m.bankAccountId; _payeeType = m.payeeType.isNotEmpty ? m.payeeType : 'vendor'; _vendorId = m.vendorId; _payeeAccountId = m.payeeAccountId; _isPostDated = m.isPostDated; });
    _chequeNoCtrl.text = m.chequeNo; _chequeDateCtrl.text = m.chequeDate; _bankAcNoCtrl.text = m.bankAcNo; _bankAccountNameCtrl.text = m.bankAccountName; _payeeNameCtrl.text = m.payeeName; _amountCtrl.text = m.amount.toStringAsFixed(2); _narrationCtrl.text = m.narration;
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'chequeNo': _chequeNoCtrl.text, 'chequeDate': _chequeDateCtrl.text,
      'bankAccountId': _bankAccountId, 'bankAcNo': _bankAcNoCtrl.text, 'bankAccountName': _bankAccountNameCtrl.text,
      'payeeType': _payeeType, 'vendorId': _vendorId, 'payeeAccountId': _payeeAccountId, 'payeeName': _payeeNameCtrl.text,
      'amount': double.tryParse(_amountCtrl.text) ?? 0, 'narration': _narrationCtrl.text, 'isPostDated': _isPostDated, 'status': 'issued',
    };
  }

  Future<void> _save() async {
    if (_chequeNoCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cheque No is required'))); return; }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<BankChequeController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _chequeId = r.chequeId; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this cheque?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<BankChequeController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<BankChequeController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<BankChequeModel>(
      context: context,
      records: ctrl.items,
      title: 'Bank Cheques',
      getBusinessId: (m) => m.chequeId,
      getTitle: (m) => '${m.chequeId}  -  ${m.vendorName.isNotEmpty ? m.vendorName : m.payeeName}',
      getSubtitle: (m) => '${m.chequeDate.isNotEmpty ? m.chequeDate.substring(0,10) : "?"}  |  ${m.status}  |  Rs ${m.amount.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AccountsController>().typedItems;
    final vendors = context.read<VendorsController>().typedItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Bank Cheque Issuing', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_chequeId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Cheque ID: $_chequeId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _chequeNoCtrl, decoration: _dec('Cheque No *'))),
                SizedBox(width: 160, child: TextFormField(controller: _chequeDateCtrl, decoration: _dec('Cheque Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_chequeDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _chequeDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value: _bankAccountId.isEmpty ? null : _bankAccountId, decoration: _dec('Bank Account'), isExpanded: true,
                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) { if (val == null) return; final a = accounts.firstWhere((x) => x.id == val); setState(() => _bankAccountId = val); _bankAcNoCtrl.text = a.text('accountCode'); _bankAccountNameCtrl.text = a.text('accountName'); },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _payeeType, decoration: _dec('Payee Type'), isExpanded: true,
                    items: const [DropdownMenuItem(value: 'vendor', child: Text('Vendor')), DropdownMenuItem(value: 'account', child: Text('Account')), DropdownMenuItem(value: 'other', child: Text('Other'))],
                    onChanged: (val) => setState(() { _payeeType = val ?? 'vendor'; _vendorId = ''; _payeeAccountId = ''; }),
                  ),
                ),
                if (_payeeType == 'vendor')
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _vendorId.isEmpty ? null : _vendorId, decoration: _dec('Vendor'), isExpanded: true, items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _vendorId = val ?? '')))
                else if (_payeeType == 'account')
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _payeeAccountId.isEmpty ? null : _payeeAccountId, decoration: _dec('Payee Account'), isExpanded: true, items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _payeeAccountId = val ?? '')))
                else
                  SizedBox(width: 200, child: TextFormField(controller: _payeeNameCtrl, decoration: _dec('Payee Name'))),
                SizedBox(width: 140, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number)),
                SizedBox(width: 280, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
                Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: _isPostDated, onChanged: (v) => setState(() => _isPostDated = v), activeColor: AppTheme.terra400), const SizedBox(width: 8), const Text('Post Dated', style: TextStyle(fontSize: 13))]),
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
