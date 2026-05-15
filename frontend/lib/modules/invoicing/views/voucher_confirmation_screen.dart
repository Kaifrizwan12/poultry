import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cash_voucher_controller.dart';
import '../models/cash_voucher_model.dart';

class VoucherConfirmationScreen extends StatefulWidget {
  const VoucherConfirmationScreen({super.key});

  @override
  State<VoucherConfirmationScreen> createState() =>
      _VoucherConfirmationScreenState();
}

class _VoucherConfirmationScreenState extends State<VoucherConfirmationScreen> {
  String _typeFilter = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = context.read<CashVoucherController>();
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

  String _typeLabel(String type) {
    switch (type) {
      case 'credit':
        return 'Cash Receiving';
      case 'debit':
        return 'Cash Payment';
      case 'journal':
        return 'Journal';
      default:
        return type;
    }
  }

  List<CashVoucherModel> _visibleItems(CashVoucherController ctrl) {
    var items = ctrl.items.where((item) => !item.isConfirmed).toList();
    if (_typeFilter.isNotEmpty) {
      items = items.where((item) => item.voucherType == _typeFilter).toList();
    }
    if (_dateFromCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.voucherDate.compareTo(_dateFromCtrl.text) >= 0)
          .toList();
    }
    if (_dateToCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.voucherDate.compareTo(_dateToCtrl.text) <= 0)
          .toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.voucherNo.toLowerCase().contains(q) ||
          item.voucherDate.toLowerCase().contains(q) ||
          _typeLabel(item.voucherType).toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirm(String id) async {
    try {
      await context.read<CashVoucherController>().confirmVoucher(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher confirmed')),
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
    return Consumer<CashVoucherController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        final pendingTotal = items
            .where((item) => !item.isConfirmed)
            .fold<double>(0, (sum, item) => sum + item.totalDebit);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voucher Confirmation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by voucher no, type or date',
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
                        value: _typeFilter.isEmpty ? null : _typeFilter,
                        decoration: _dec('Voucher Type'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text('All'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'credit',
                            child: Text('Cash Receiving'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'debit',
                            child: Text('Cash Payment'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'journal',
                            child: Text('Journal'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value ?? ''),
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
                        _typeFilter = '';
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
                      'No vouchers found yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching unconfirmed vouchers.',
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
                                DataColumn(label: Text('Voucher No')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Debit')),
                                DataColumn(label: Text('Credit')),
                                DataColumn(label: Text('Lines')),
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
                                        item.voucherNo.isNotEmpty
                                            ? item.voucherNo
                                            : '—',
                                      ),
                                    ),
                                    DataCell(Text(item.voucherDate)),
                                    DataCell(Text(_typeLabel(item.voucherType))),
                                    DataCell(
                                      Text(item.totalDebit.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Text(item.totalCredit.toStringAsFixed(2)),
                                    ),
                                    DataCell(Text('${item.lines.length}')),
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
                                              onPressed: () =>
                                                  _confirm(item.id),
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
                                'Pending Total (Debit): ${pendingTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
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
