import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';

class DepositConfirmationScreen extends StatefulWidget {
  const DepositConfirmationScreen({super.key});

  @override
  State<DepositConfirmationScreen> createState() =>
      _DepositConfirmationScreenState();
}

class _DepositConfirmationScreenState extends State<DepositConfirmationScreen> {
  String _filterBankAccountId = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _depositTypeFilter = '';

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
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BankDepositModel> _visibleItems(BankDepositController ctrl) {
    var items = ctrl.items.where((item) => !item.isConfirmed).toList();
    if (_filterBankAccountId.isNotEmpty) {
      items = items
          .where((item) => item.bankAccountId == _filterBankAccountId)
          .toList();
    }
    if (_dateFromCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.depositDate.compareTo(_dateFromCtrl.text) >= 0)
          .toList();
    }
    if (_dateToCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.depositDate.compareTo(_dateToCtrl.text) <= 0)
          .toList();
    }
    if (_depositTypeFilter.isNotEmpty) {
      items = items
          .where((item) => item.depositType == _depositTypeFilter)
          .toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.depositId.toLowerCase().contains(q) ||
          item.depositSlipNo.toLowerCase().contains(q) ||
          item.depositType.toLowerCase().contains(q) ||
          item.depositDate.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirm(String id) async {
    try {
      await context.read<BankDepositController>().confirm(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit confirmed')),
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
        final pendingCount = items.where((item) => !item.isConfirmed).length;
        final confirmedCount = items.where((item) => item.isConfirmed).length;
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposit Confirmation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by deposit ID, slip no, type or date',
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
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _depositTypeFilter.isEmpty
                            ? null
                            : _depositTypeFilter,
                        decoration: _dec('Type'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text('All'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'cash',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'cheque',
                            child: Text('Cheque'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _depositTypeFilter = value ?? ''),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _filterBankAccountId = '';
                        _depositTypeFilter = '';
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
                      'No deposits found yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching unconfirmed deposits.',
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
                              dataRowMinHeight: 30,
                              dataRowMaxHeight: 36,
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Slip No')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Confirmed')),
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
                                    DataCell(Text(item.depositSlipNo)),
                                    DataCell(
                                      Text(item.amount.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Icon(
                                        item.isConfirmed
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        color: item.isConfirmed
                                            ? AppTheme.successText
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                    DataCell(
                                      item.isConfirmed
                                          ? const Text(
                                              'Confirmed',
                                              style: TextStyle(
                                                color: AppTheme.successText,
                                                fontSize: 12,
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: () => _confirm(item.id),
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
                                                'Confirm',
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
                                'Pending: $pendingCount',
                                style: const TextStyle(
                                  color: AppTheme.warningText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Confirmed: $confirmedCount',
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
