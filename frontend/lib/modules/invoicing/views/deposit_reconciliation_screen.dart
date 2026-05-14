import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';

class DepositReconciliationScreen extends StatefulWidget {
  const DepositReconciliationScreen({super.key});

  @override
  State<DepositReconciliationScreen> createState() => _DepositReconciliationScreenState();
}

class _DepositReconciliationScreenState extends State<DepositReconciliationScreen> {
  String _filterBankAccountId = '';
  final _yearMonthCtrl = TextEditingController();
  List<BankDepositModel> _loaded = [];
  final Map<String, TextEditingController> _stmtRefControllers = {};

  @override
  void dispose() {
    _yearMonthCtrl.dispose();
    for (final c in _stmtRefControllers.values) { c.dispose(); }
    super.dispose();
  }

  void _load() {
    final ctrl = context.read<BankDepositController>();
    var filtered = ctrl.items.toList();
    if (_filterBankAccountId.isNotEmpty) filtered = filtered.where((d) => d.bankAccountId == _filterBankAccountId).toList();
    if (_yearMonthCtrl.text.isNotEmpty) filtered = filtered.where((d) => d.depositDate.startsWith(_yearMonthCtrl.text)).toList();
    for (final d in filtered) {
      _stmtRefControllers.putIfAbsent(d.id, () => TextEditingController(text: d.bankStatementRef));
    }
    setState(() => _loaded = filtered);
  }

  Future<void> _reconcile(String id) async {
    final ref = _stmtRefControllers[id]?.text ?? '';
    try {
      await context.read<BankDepositController>().reconcile(id, bankStatementRef: ref);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reconciled')));
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
              Text('Deposit Reconciliation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _filterBankAccountId.isEmpty ? null : _filterBankAccountId, decoration: _dec('Bank Account'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('All')), ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis)))], onChanged: (val) => setState(() => _filterBankAccountId = val ?? ''))),
                SizedBox(width: 160, child: TextFormField(controller: _yearMonthCtrl, decoration: _dec('Year-Month (YYYY-MM)'))),
                ElevatedButton(onPressed: _load, child: const Text('Load')),
              ])),
              const SizedBox(height: 16),
              if (_loaded.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Apply filters and click Load.', style: TextStyle(color: AppTheme.textSecondary)))
              else Builder(
                builder: (context) {
                  final total = _loaded.fold<double>(0, (s, d) => s + d.amount);
                  final reconciled = _loaded.where((d) => d.isReconciled).fold<double>(0, (s, d) => s + d.amount);
                  final difference = total - reconciled;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    RepaintBoundary(
                      child: Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 44, dataRowMaxHeight: 60,
                        columns: const [DataColumn(label: Text('ID')), DataColumn(label: Text('Date')), DataColumn(label: Text('Type')), DataColumn(label: Text('Amount')), DataColumn(label: Text('Confirmed')), DataColumn(label: Text('Reconciled')), DataColumn(label: Text('Stmt Ref')), DataColumn(label: Text('Action'))],
                        rows: _loaded.asMap().entries.map((en) { final idx = en.key; final d = en.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [
                            DataCell(Text(d.depositId.isNotEmpty ? d.depositId : d.id)),
                            DataCell(Text(d.depositDate)), DataCell(Text(d.depositType)),
                            DataCell(Text(d.amount.toStringAsFixed(2))),
                            DataCell(Icon(d.isConfirmed ? Icons.check_circle : Icons.circle_outlined, color: d.isConfirmed ? AppTheme.successText : AppTheme.textSecondary, size: 18)),
                            DataCell(Icon(d.isReconciled ? Icons.check_circle : Icons.circle_outlined, color: d.isReconciled ? AppTheme.successText : AppTheme.textSecondary, size: 18)),
                            DataCell(SizedBox(width: 140, child: TextFormField(controller: _stmtRefControllers[d.id], decoration: _dec('')))),
                            DataCell(d.isReconciled ? const Text('Reconciled', style: TextStyle(color: AppTheme.successText, fontSize: 12)) : ElevatedButton(onPressed: () => _reconcile(d.id), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), backgroundColor: AppTheme.terra400), child: const Text('Reconcile', style: TextStyle(fontSize: 12)))),
                          ],
                        ); }).toList(),
                      ))),
                    ),
                    const SizedBox(height: 8),
                    Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                      Text('Total: ${total.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 24),
                      Text('Reconciled: ${reconciled.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 24),
                      Text('Difference: ${difference.toStringAsFixed(2)}', style: TextStyle(color: difference.abs() > 0.01 ? AppTheme.dangerText : AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
                    ])),
                  ]);
                },
              ),
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
