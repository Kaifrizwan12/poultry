import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_cheque_controller.dart';
import '../models/bank_cheque_model.dart';

class BankChequesReconciliationScreen extends StatefulWidget {
  const BankChequesReconciliationScreen({super.key});

  @override
  State<BankChequesReconciliationScreen> createState() =>
      _BankChequesReconciliationScreenState();
}

class _BankChequesReconciliationScreenState
    extends State<BankChequesReconciliationScreen> {
  String _filterBankAccountId = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  double _clearedThisSession = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = context.read<BankChequeController>();
      if (ctrl.items.isEmpty) {
        await ctrl.fetchAll();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BankChequeModel> _visibleItems(BankChequeController ctrl) {
    var items = ctrl.items.where((item) => item.status == 'issued').toList();
    if (_filterBankAccountId.isNotEmpty) {
      items = items
          .where((item) => item.bankAccountId == _filterBankAccountId)
          .toList();
    }
    if (_dateFromCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.chequeDate.compareTo(_dateFromCtrl.text) >= 0)
          .toList();
    }
    if (_dateToCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.chequeDate.compareTo(_dateToCtrl.text) <= 0)
          .toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final payee = item.payeeType == 'vendor'
          ? item.vendorName
          : item.payeeType == 'account'
              ? item.payeeAccountName
              : item.payeeName;
      return item.chequeId.toLowerCase().contains(q) ||
          item.chequeNo.toLowerCase().contains(q) ||
          payee.toLowerCase().contains(q) ||
          item.bankAccountName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _updateStatus(String id, String status) async {
    String? clearedDate;
    if (status == 'cleared') {
      clearedDate = DateTime.now().toIso8601String().substring(0, 10);
      final ctrl = context.read<BankChequeController>();
      try {
        final cheque = ctrl.items.firstWhere((item) => item.id == id);
        setState(() => _clearedThisSession += cheque.amount);
      } catch (_) {}
    }
    try {
      await context.read<BankChequeController>().updateStatus(
            id,
            status,
            clearedDate: clearedDate,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
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
    return Consumer<BankChequeController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        final totalOutstanding = items.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Cheques Reconciliation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by cheque ID, cheque no, payee or bank',
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
                      width: 150,
                      child: TextFormField(
                        controller: _dateFromCtrl,
                        decoration: _dec('Date From'),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _dateFromCtrl.text =
                                  picked.toIso8601String().substring(0, 10);
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _dateToCtrl,
                        decoration: _dec('Date To'),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _dateToCtrl.text =
                                  picked.toIso8601String().substring(0, 10);
                            });
                          }
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _filterBankAccountId = '';
                        _dateFromCtrl.clear();
                        _dateToCtrl.clear();
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
                      'No issued cheques found yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No matching issued cheques.',
                      style: const TextStyle(color: AppTheme.textSecondary),
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
                              dataRowMinHeight: 30,
                              dataRowMaxHeight: 36,
                              columns: const [
                                DataColumn(label: Text('Cheque No')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Payee')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final payee = item.payeeType == 'vendor'
                                    ? item.vendorName
                                    : item.payeeType == 'account'
                                        ? item.payeeAccountName
                                        : item.payeeName;
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith(
                                    (states) => idx.isOdd
                                        ? AppTheme.clayBg.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                  ),
                                  cells: [
                                    DataCell(Text(item.chequeNo)),
                                    DataCell(Text(item.chequeDate)),
                                    DataCell(Text(payee)),
                                    DataCell(
                                      Text(item.amount.toStringAsFixed(2)),
                                    ),
                                    DataCell(Text(item.status)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () => _updateStatus(
                                              item.id,
                                              'cleared',
                                            ),
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(
                                                color: AppTheme.successText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _updateStatus(
                                              item.id,
                                              'bounced',
                                            ),
                                            child: const Text(
                                              'Bounce',
                                              style: TextStyle(
                                                color: AppTheme.dangerText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _updateStatus(
                                              item.id,
                                              'cancelled',
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                'Outstanding: ${totalOutstanding.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Cleared This Session: ${_clearedThisSession.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.successText,
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
