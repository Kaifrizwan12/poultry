import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_cheque_controller.dart';
import '../models/bank_cheque_model.dart';

class BankChequesReconciliationScreen extends StatefulWidget {
  const BankChequesReconciliationScreen({super.key});

  @override
  State<BankChequesReconciliationScreen> createState() => _BankChequesReconciliationScreenState();
}

class _BankChequesReconciliationScreenState extends State<BankChequesReconciliationScreen> {
  String _filterBankAccountId = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  List<BankChequeModel> _loaded = [];
  bool _isLoading = false;
  double _clearedThisSession = 0;

  @override
  void dispose() {
    _dateFromCtrl.dispose(); _dateToCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final ctrl = context.read<BankChequeController>();
    var filtered = ctrl.items.where((c) => c.status == 'issued').toList();
    if (_filterBankAccountId.isNotEmpty) filtered = filtered.where((c) => c.bankAccountId == _filterBankAccountId).toList();
    if (_dateFromCtrl.text.isNotEmpty) filtered = filtered.where((c) => c.chequeDate.compareTo(_dateFromCtrl.text) >= 0).toList();
    if (_dateToCtrl.text.isNotEmpty) filtered = filtered.where((c) => c.chequeDate.compareTo(_dateToCtrl.text) <= 0).toList();
    setState(() { _loaded = filtered; });
  }

  Future<void> _updateStatus(String id, String status) async {
    String? clearedDate;
    if (status == 'cleared') {
      clearedDate = DateTime.now().toIso8601String().substring(0, 10);
      setState(() => _clearedThisSession += _loaded.firstWhere((c) => c.id == id, orElse: () => _loaded.first).amount);
    }
    try {
      await context.read<BankChequeController>().updateStatus(id, status, clearedDate: clearedDate);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
              Text('Bank Cheques Reconciliation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _filterBankAccountId.isEmpty ? null : _filterBankAccountId, decoration: _dec('Bank Account (Filter)'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('All')), ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis)))], onChanged: (val) => setState(() => _filterBankAccountId = val ?? ''))),
                SizedBox(width: 160, child: TextFormField(controller: _dateFromCtrl, decoration: _dec('Date From'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateFromCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 160, child: TextFormField(controller: _dateToCtrl, decoration: _dec('Date To'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateToCtrl.text = p.toIso8601String().substring(0, 10)); })),
                ElevatedButton(onPressed: _load, child: const Text('Load')),
              ])),
              const SizedBox(height: 16),
              if (_isLoading) const Center(child: CircularProgressIndicator())
              else if (_loaded.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No issued cheques found. Apply filters and click Load.', style: TextStyle(color: AppTheme.textSecondary)))
              else Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RepaintBoundary(
                  child: Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 44, dataRowMaxHeight: 56,
                    columns: const [DataColumn(label: Text('Cheque No')), DataColumn(label: Text('Date')), DataColumn(label: Text('Payee')), DataColumn(label: Text('Amount')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
                    rows: _loaded.asMap().entries.map((en) { final idx = en.key; final c = en.value; final payee = c.payeeType == 'vendor' ? c.vendorName : c.payeeType == 'account' ? c.payeeAccountName : c.payeeName; return DataRow(
                      color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                      cells: [
                        DataCell(Text(c.chequeNo)), DataCell(Text(c.chequeDate)), DataCell(Text(payee)),
                        DataCell(Text(c.amount.toStringAsFixed(2))), DataCell(Text(c.status)),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          TextButton(onPressed: () => _updateStatus(c.id, 'cleared'), child: const Text('Clear', style: TextStyle(color: AppTheme.successText, fontSize: 12))),
                          TextButton(onPressed: () => _updateStatus(c.id, 'bounced'), child: const Text('Bounce', style: TextStyle(color: AppTheme.dangerText, fontSize: 12))),
                          TextButton(onPressed: () => _updateStatus(c.id, 'cancelled'), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                        ])),
                      ],
                    ); }).toList(),
                  ))),
                ),
                const SizedBox(height: 8),
                Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                  Text('Outstanding: ${_loaded.fold<double>(0, (s, c) => s + c.amount).toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 24),
                  Text('Cleared This Session: ${_clearedThisSession.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
              ]),
            ]),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite, padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Spacer(),
            OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Close')),
          ]),
        ),
      ],
    );
  }
}
