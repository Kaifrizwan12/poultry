import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';

class DepositReconciliationScreen extends StatefulWidget {
  const DepositReconciliationScreen({super.key});

  @override
  State<DepositReconciliationScreen> createState() =>
      _DepositReconciliationScreenState();
}

class _DepositReconciliationScreenState
    extends State<DepositReconciliationScreen> {
  String _filterBankAccountId = '';
  final _yearMonthCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Map<String, TextEditingController> _stmtRefControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = context.read<BankDepositController>();
      if (ctrl.items.isEmpty) {
        await ctrl.fetchAll();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _yearMonthCtrl.dispose();
    _searchCtrl.dispose();
    for (final controller in _stmtRefControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<BankDepositModel> _visibleItems(BankDepositController ctrl) {
    var items = ctrl.items.toList();
    if (_filterBankAccountId.isNotEmpty) {
      items = items
          .where((item) => item.bankAccountId == _filterBankAccountId)
          .toList();
    }
    if (_yearMonthCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.depositDate.startsWith(_yearMonthCtrl.text))
          .toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((item) {
        return item.depositId.toLowerCase().contains(q) ||
            item.depositSlipNo.toLowerCase().contains(q) ||
            item.depositType.toLowerCase().contains(q) ||
            item.depositDate.toLowerCase().contains(q) ||
            item.bankStatementRef.toLowerCase().contains(q);
      }).toList();
    }
    for (final item in items) {
      _stmtRefControllers.putIfAbsent(
        item.id,
        () => TextEditingController(text: item.bankStatementRef),
      );
    }
    return items;
  }

  Future<void> _reconcile(String id) async {
    final ref = _stmtRefControllers[id]?.text ?? '';
    try {
      await context.read<BankDepositController>().reconcile(
            id,
            bankStatementRef: ref,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconciled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>().typedItems;
    return Consumer<BankDepositController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        final total = items.fold<double>(0, (sum, item) => sum + item.amount);
        final reconciled = items
            .where((item) => item.isReconciled)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final difference = total - reconciled;
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposit Reconciliation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by deposit ID, slip no, type, date or statement ref',
                  prefixIcon: const Icon(Icons.search_outlined, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: AppTheme.cardDecor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _filterBankAccountId.isEmpty
                            ? null
                            : _filterBankAccountId,
                        decoration: _dec('Bank Account'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('All'),
                          ),
                          ...accounts.map(
                            (account) => DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(
                                account.text('accountName'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterBankAccountId = value ?? ''),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: TextFormField(
                        controller: _yearMonthCtrl,
                        decoration: _dec('Year-Month (YYYY-MM)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _filterBankAccountId = '';
                        _yearMonthCtrl.clear();
                        _searchCtrl.clear();
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (ctrl.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No deposits found yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching deposits.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: AppTheme.cardDecor,
                          child: HorizontalScrollWheel(
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AppTheme.clayBg),
                              columnSpacing: 16,
                              horizontalMargin: 12,
                              dataRowMinHeight: 44,
                              dataRowMaxHeight: 52,
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Confirmed')),
                                DataColumn(label: Text('Reconciled')),
                                DataColumn(label: Text('Stmt Ref')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith(
                                    (states) => idx.isOdd
                                        ? AppTheme.clayBg.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        item.depositId.isNotEmpty
                                            ? item.depositId
                                            : '—',
                                      ),
                                    ),
                                    DataCell(Text(item.depositDate)),
                                    DataCell(Text(item.depositType)),
                                    DataCell(
                                      Text(item.amount.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Icon(
                                        item.isConfirmed
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: item.isConfirmed
                                            ? AppTheme.successText
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        item.isReconciled
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: item.isReconciled
                                            ? AppTheme.successText
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: TextFormField(
                                          controller:
                                              _stmtRefControllers[item.id],
                                          decoration: _dec(''),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      item.isReconciled
                                          ? const Text(
                                              'Reconciled',
                                              style: TextStyle(
                                                color: AppTheme.successText,
                                                fontSize: 12,
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: () =>
                                                  _reconcile(item.id),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                backgroundColor:
                                                    AppTheme.terra400,
                                              ),
                                              child: const Text(
                                                'Reconcile',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          color: AppTheme.clayBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Total: ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Reconciled: ${reconciled.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.successText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Difference: ${difference.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: difference.abs() > 0.01
                                      ? AppTheme.dangerText
                                      : AppTheme.successText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
