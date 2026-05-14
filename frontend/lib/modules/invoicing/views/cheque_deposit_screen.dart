import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';

class ChequeDepositScreen extends StatefulWidget {
  const ChequeDepositScreen({super.key});

  @override
  State<ChequeDepositScreen> createState() => _ChequeDepositScreenState();
}

class _ChequeDepositScreenState extends State<ChequeDepositScreen> {
  String? _currentId;
  bool _isSaving = false;

  final _depositDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _bankAccountId = '';
  final _bankAccountNameCtrl = TextEditingController();
  final _depositSlipNoCtrl = TextEditingController();
  String _fromAccountId = '';
  final _fromAccountNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController();
  final _drawerNameCtrl = TextEditingController();
  final _drawerBankNameCtrl = TextEditingController();
  String _depositId = '';

  @override
  void dispose() {
    for (final c in [_depositDateCtrl, _bankAccountNameCtrl, _depositSlipNoCtrl, _fromAccountNameCtrl, _amountCtrl, _narrationCtrl, _chequeNoCtrl, _chequeDateCtrl, _drawerNameCtrl, _drawerBankNameCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _depositId = ''; _bankAccountId = ''; _fromAccountId = ''; });
    _depositDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    for (final c in [_bankAccountNameCtrl, _depositSlipNoCtrl, _fromAccountNameCtrl, _narrationCtrl, _chequeNoCtrl, _chequeDateCtrl, _drawerNameCtrl, _drawerBankNameCtrl]) { c.clear(); }
    _amountCtrl.text = '0';
  }

  void _loadFromModel(BankDepositModel m) {
    setState(() { _currentId = m.id; _depositId = m.depositId; _bankAccountId = m.bankAccountId; _fromAccountId = m.fromAccountId; });
    _depositDateCtrl.text = m.depositDate; _bankAccountNameCtrl.text = m.bankAccountName; _depositSlipNoCtrl.text = m.depositSlipNo; _fromAccountNameCtrl.text = m.fromAccountName; _amountCtrl.text = m.amount.toStringAsFixed(2); _narrationCtrl.text = m.narration; _chequeNoCtrl.text = m.chequeNo; _chequeDateCtrl.text = m.chequeDate; _drawerNameCtrl.text = m.drawerName; _drawerBankNameCtrl.text = m.drawerBankName;
  }

  Map<String, dynamic> _buildPayload() => {
    'depositType': 'cheque', 'depositDate': _depositDateCtrl.text, 'bankAccountId': _bankAccountId, 'bankAccountName': _bankAccountNameCtrl.text, 'depositSlipNo': _depositSlipNoCtrl.text, 'fromAccountId': _fromAccountId, 'fromAccountName': _fromAccountNameCtrl.text, 'amount': double.tryParse(_amountCtrl.text) ?? 0, 'narration': _narrationCtrl.text, 'chequeNo': _chequeNoCtrl.text, 'chequeDate': _chequeDateCtrl.text, 'drawerName': _drawerNameCtrl.text, 'drawerBankName': _drawerBankNameCtrl.text, 'status': 'saved',
  };

  Future<void> _save() async {
    if (_chequeNoCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cheque No is required'))); return; }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<BankDepositController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _depositId = r.depositId; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this deposit?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<BankDepositController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<BankDepositController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<BankDepositModel>(
      context: context,
      records: ctrl.items,
      title: 'Cheque Deposits',
      getBusinessId: (m) => m.depositId,
      getTitle: (m) => '${m.depositId}  -  ${m.bankAccountName}',
      getSubtitle: (m) => '${m.depositDate.isNotEmpty ? m.depositDate.substring(0,10) : "?"}  |  ${m.chequeNo}  |  Rs ${m.amount.toStringAsFixed(0)}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AccountsController>().typedItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Cheque Deposit in Bank', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_depositId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Deposit ID: $_depositId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _depositDateCtrl, decoration: _dec('Deposit Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_depositDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _depositDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 240, child: DropdownButtonFormField<String>(value: _bankAccountId.isEmpty ? null : _bankAccountId, decoration: _dec('Bank Account'), isExpanded: true, items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; final a = accounts.firstWhere((x) => x.id == val); setState(() => _bankAccountId = val); _bankAccountNameCtrl.text = a.text('accountName'); })),
                SizedBox(width: 160, child: TextFormField(controller: _depositSlipNoCtrl, decoration: _dec('Deposit Slip No'))),
                SizedBox(width: 160, child: TextFormField(controller: _chequeNoCtrl, decoration: _dec('Cheque No *'))),
                SizedBox(width: 160, child: TextFormField(controller: _chequeDateCtrl, decoration: _dec('Cheque Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _chequeDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 200, child: TextFormField(controller: _drawerNameCtrl, decoration: _dec('Drawer Name'))),
                SizedBox(width: 200, child: TextFormField(controller: _drawerBankNameCtrl, decoration: _dec('Drawer Bank Name'))),
                SizedBox(width: 240, child: DropdownButtonFormField<String>(value: _fromAccountId.isEmpty ? null : _fromAccountId, decoration: _dec('From Account (optional)'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('None')), ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis)))], onChanged: (val) { setState(() => _fromAccountId = val ?? ''); if (val != null && val.isNotEmpty) { _fromAccountNameCtrl.text = accounts.firstWhere((a) => a.id == val).text('accountName'); } else { _fromAccountNameCtrl.clear(); } })),
                SizedBox(width: 140, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number)),
                SizedBox(width: 280, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
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
