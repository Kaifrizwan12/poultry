import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';

class DepositConfirmationScreen extends StatefulWidget {
  const DepositConfirmationScreen({super.key});

  @override
  State<DepositConfirmationScreen> createState() => _DepositConfirmationScreenState();
}

class _DepositConfirmationScreenState extends State<DepositConfirmationScreen> {
  String _filterBankAccountId = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  String _depositTypeFilter = '';
  List<BankDepositModel> _loaded = [];
  int _pendingCount = 0;
  int _confirmedCount = 0;

  @override
  void dispose() {
    _dateFromCtrl.dispose(); _dateToCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final ctrl = context.read<BankDepositController>();
    var filtered = ctrl.items.where((d) => !d.isConfirmed).toList();
    if (_filterBankAccountId.isNotEmpty) filtered = filtered.where((d) => d.bankAccountId == _filterBankAccountId).toList();
    if (_dateFromCtrl.text.isNotEmpty) filtered = filtered.where((d) => d.depositDate.compareTo(_dateFromCtrl.text) >= 0).toList();
    if (_dateToCtrl.text.isNotEmpty) filtered = filtered.where((d) => d.depositDate.compareTo(_dateToCtrl.text) <= 0).toList();
    if (_depositTypeFilter.isNotEmpty) filtered = filtered.where((d) => d.depositType == _depositTypeFilter).toList();
    setState(() { _loaded = filtered; _pendingCount = filtered.where((d) => !d.isConfirmed).length; _confirmedCount = filtered.where((d) => d.isConfirmed).length; });
  }

  Future<void> _confirm(String id) async {
    try {
      await context.read<BankDepositController>().confirm(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deposit confirmed')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
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
              Text('Deposit Confirmation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _filterBankAccountId.isEmpty ? null : _filterBankAccountId, decoration: _dec('Bank Account'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('All')), ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis)))], onChanged: (val) => setState(() => _filterBankAccountId = val ?? ''))),
                SizedBox(width: 160, child: TextFormField(controller: _dateFromCtrl, decoration: _dec('Date From'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateFromCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 160, child: TextFormField(controller: _dateToCtrl, decoration: _dec('Date To'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateToCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 160, child: DropdownButtonFormField<String>(value: _depositTypeFilter.isEmpty ? null : _depositTypeFilter, decoration: _dec('Type'), isExpanded: true, items: const [DropdownMenuItem(value: '', child: Text('All')), DropdownMenuItem(value: 'cash', child: Text('Cash')), DropdownMenuItem(value: 'cheque', child: Text('Cheque'))], onChanged: (val) => setState(() => _depositTypeFilter = val ?? ''))),
                ElevatedButton(onPressed: _load, child: const Text('Load')),
              ])),
              const SizedBox(height: 16),
              if (_loaded.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No unconfirmed deposits. Apply filters and click Load.', style: TextStyle(color: AppTheme.textSecondary)))
              else Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RepaintBoundary(
                  child: Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 44, dataRowMaxHeight: 56,
                    columns: const [DataColumn(label: Text('ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Type')), DataColumn(label: Text('Slip No')), DataColumn(label: Text('Amount')), DataColumn(label: Text('Confirmed')), DataColumn(label: Text('Action'))],
                    rows: _loaded.asMap().entries.map((en) { final idx = en.key; final d = en.value; return DataRow(
                      color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                      cells: [
                        DataCell(Text(d.depositId.isNotEmpty ? d.depositId : d.id)),
                        DataCell(Text(d.depositDate)), DataCell(Text(d.depositType)),
                        DataCell(Text(d.depositSlipNo)), DataCell(Text(d.amount.toStringAsFixed(2))),
                        DataCell(Icon(d.isConfirmed ? Icons.check_circle : Icons.pending, color: d.isConfirmed ? AppTheme.successText : AppTheme.textSecondary, size: 18)),
                        DataCell(d.isConfirmed ? const Text('Confirmed', style: TextStyle(color: AppTheme.successText, fontSize: 12)) : ElevatedButton(onPressed: () => _confirm(d.id), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), backgroundColor: AppTheme.terra400), child: const Text('Confirm', style: TextStyle(fontSize: 12)))),
                      ],
                    ); }).toList(),
                  ))),
                ),
                const SizedBox(height: 8),
                Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                  Text('Pending: $_pendingCount', style: const TextStyle(color: AppTheme.warningText, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 24),
                  Text('Confirmed: $_confirmedCount', style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
              ]),
            ]),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite, padding: const EdgeInsets.all(12),
          child: Row(children: [const Spacer(), OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Close'))]),
        ),
      ],
    );
  }
}
