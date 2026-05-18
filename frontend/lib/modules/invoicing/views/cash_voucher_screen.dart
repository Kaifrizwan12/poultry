import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/line_item_card.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cash_voucher_controller.dart';
import '../models/cash_voucher_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import '../widgets/voucher_line_row.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class CashVoucherScreen extends StatefulWidget {
  const CashVoucherScreen({super.key, required this.voucherType});

  final String voucherType;

  @override
  State<CashVoucherScreen> createState() => _CashVoucherScreenState();
}

class _CashVoucherScreenState extends State<CashVoucherScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<CashVoucherController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.voucherType) {
      case 'credit':
        return 'Cash Receiving Vouchers';
      case 'debit':
        return 'Cash Payment Vouchers';
      default:
        return 'Journal Vouchers';
    }
  }

  String get _newLabel {
    switch (widget.voucherType) {
      case 'credit':
        return 'New Receipt Voucher';
      case 'debit':
        return 'New Payment Voucher';
      default:
        return 'New Journal Voucher';
    }
  }

  Future<void> _openForm({CashVoucherModel? initial}) async {
    final ctrl = context.read<CashVoucherController>();
    final accountsCtrl = context.read<AccountsController>();
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ctrl),
          ChangeNotifierProvider.value(value: accountsCtrl),
        ],
        child: _CashVoucherFormDialog(
          voucherType: widget.voucherType,
          initial: initial,
        ),
      ),
    );
  }

  List<CashVoucherModel> _visibleItems(CashVoucherController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return ctrl.items.where((item) {
      if (item.voucherType != widget.voucherType) return false;
      if (q.isEmpty) return true;
      final firstLine = item.lines.isNotEmpty ? item.lines.first : const {};
      final accountName = '${firstLine['accountName'] ?? ''}'.toLowerCase();
      return item.voucherNo.toLowerCase().contains(q) ||
          item.voucherDate.toLowerCase().contains(q) ||
          accountName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashVoucherController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: _newLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by voucher no, date or first line account',
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
              if (ctrl.isLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.terra400,
                ),
              if (ctrl.isLoading)
                const Expanded(child: SizedBox.shrink())
              else if (ctrl.items
                  .where((e) => e.voucherType == widget.voucherType)
                  .isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No vouchers yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(_newLabel),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!ctrl.isLoading && items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching vouchers found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (isMobile)
                Expanded(
                    child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return RecordCard(
                      id: item.voucherNo,
                      subtitle: (() {
                        switch (item.voucherType) {
                          case 'credit':
                            return 'Cash Receiving';
                          case 'debit':
                            return 'Cash Payment';
                          case 'journal':
                            return 'Journal';
                          default:
                            return item.voucherType;
                        }
                      })(),
                      meta: AppUtils.formatDate(item.voucherDate),
                      amount: AppUtils.fmtAmt(item.totalDebit > 0
                          ? item.totalDebit
                          : item.totalCredit),
                      onTap: () => _openForm(initial: item),
                    );
                  },
                ))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      decoration: AppTheme.cardDecor,
                      child: HorizontalScrollWheel(
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(AppTheme.clayBg),
                          columnSpacing: AppTheme.tableColSpacing,
                          horizontalMargin: AppTheme.tableHMargin,
                          dataRowMinHeight: AppTheme.tableRowMin,
                          dataRowMaxHeight: AppTheme.tableRowMax,
                          headingRowHeight: AppTheme.tableHeadingH,
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Voucher No')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Lines')),
                            DataColumn(label: Text('Confirmed')),
                            DataColumn(label: Text('Debit'), numeric: true),
                            DataColumn(label: Text('Credit'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return AppTheme.terra50;
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return AppTheme.terra50;
                                }
                                return idx.isOdd
                                    ? AppTheme.clayBg.withValues(alpha: 0.4)
                                    : Colors.transparent;
                              }),
                              onSelectChanged: (_) => _openForm(initial: item),
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text(item.voucherNo)),
                                DataCell(Text(
                                    AppUtils.formatDate(item.voucherDate))),
                                DataCell(Text('${item.lines.length}')),
                                DataCell(
                                  Text(
                                    item.isConfirmed
                                        ? 'Confirmed'
                                        : 'Unconfirmed',
                                    style: TextStyle(
                                      color: item.isConfirmed
                                          ? AppTheme.successText
                                          : AppTheme.warningText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                    Text(AppUtils.fmtAmt(item.totalDebit))),
                                DataCell(
                                    Text(AppUtils.fmtAmt(item.totalCredit))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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

class _CashVoucherFormDialog extends StatefulWidget {
  const _CashVoucherFormDialog({
    required this.voucherType,
    this.initial,
  });

  final String voucherType;
  final CashVoucherModel? initial;

  @override
  State<_CashVoucherFormDialog> createState() => _CashVoucherFormDialogState();
}

class _CashVoucherFormDialogState extends State<_CashVoucherFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _linesNotifier =
      ValueNotifier([]);
  final _voucherDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  String _voucherNo = '';
  Map<String, dynamic>? _editingLine;
  int _lineRowKey = 0;

  String get _title {
    switch (widget.voucherType) {
      case 'credit':
        return 'Cash Receiving Voucher';
      case 'debit':
        return 'Cash Payment Voucher';
      default:
        return 'Journal Voucher';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _initFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _voucherDateCtrl.dispose();
    _linesNotifier.dispose();
    super.dispose();
  }

  void _initFromModel(CashVoucherModel m) {
    _currentId = m.id;
    _voucherNo = m.voucherNo;
    _voucherDateCtrl.text = m.voucherDate;
    _linesNotifier.value = List<Map<String, dynamic>>.from(m.lines);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _voucherNo = '';
      _editingLine = null;
      _lineRowKey++;
    });
    _voucherDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _linesNotifier.value = [];
  }

  Map<String, dynamic> _buildPayload() {
    final lines = _linesNotifier.value;
    final debitSum = lines.fold<double>(
      0,
      (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0),
    );
    final creditSum = lines.fold<double>(
      0,
      (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0),
    );
    return {
      'voucherType': widget.voucherType,
      'voucherDate': _voucherDateCtrl.text,
      'lines': lines,
      'totals': {'debit': debitSum, 'credit': creditSum},
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    final lines = _linesNotifier.value;
    if (widget.voucherType == 'journal') {
      final debitSum = lines.fold<double>(
        0,
        (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0),
      );
      final creditSum = lines.fold<double>(
        0,
        (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0),
      );
      if ((debitSum - creditSum).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal voucher: Debit must equal Credit'),
          ),
        );
        return;
      }
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<CashVoucherController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _voucherNo = record.voucherNo;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
          .showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this voucher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerText,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<CashVoucherController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final showDebit = widget.voucherType != 'credit';
    final showCredit = widget.voucherType != 'debit';

    return InvoicingFormDialog(
      title: _title,
      badgeText: _voucherNo.isNotEmpty ? 'Voucher No: $_voucherNo' : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.cardDecor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _voucherDateCtrl,
                    decoration: _dec('Voucher Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_voucherDateCtrl.text) ??
                            DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _voucherDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          VoucherLineRow(
            key: ValueKey(_lineRowKey),
            voucherType: widget.voucherType,
            initialValues: _editingLine,
            onAdd: (line) {
              _linesNotifier.value = [..._linesNotifier.value, line];
              setState(() => _editingLine = null);
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _linesNotifier,
            builder: (context, lines, _) {
              if (lines.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No lines added.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              final debitSum = lines.fold<double>(
                0,
                (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0),
              );
              final creditSum = lines.fold<double>(
                0,
                (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile)
                    Column(
                      children: lines.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final line = entry.value;
                        final debit =
                            ((line['debit'] as num?)?.toDouble() ?? 0);
                        final credit =
                            ((line['credit'] as num?)?.toDouble() ?? 0);
                        final amount = debit > 0 ? debit : credit;
                        final amountLabel = debit > 0 ? 'Debit' : 'Credit';
                        final narration = '${line['narration'] ?? ''}';
                        final detailSegments = <String>[];
                        final accountCode = '${line['accountCode'] ?? ''}';
                        if (accountCode.isNotEmpty) {
                          detailSegments.add('A/C $accountCode');
                        }
                        if (showDebit && debit > 0) {
                          detailSegments.add(
                            'Debit ${AppUtils.fmtAmt2(debit)}',
                          );
                        }
                        if (showCredit && credit > 0) {
                          detailSegments.add(
                            'Credit ${AppUtils.fmtAmt2(credit)}',
                          );
                        }
                        if (narration.isNotEmpty) {
                          detailSegments.add(narration);
                        }
                        final detailLine = detailSegments.join('  ·  ');
                        final displayItem = {
                          'productName': line['accountName'] ?? '',
                          'packingName': '',
                          'qtyPacks': null,
                          'qtyLoose': null,
                          'price': amount,
                          'discPercent': 0,
                          'lineGross': amount,
                        };
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx == lines.length - 1 ? 0 : 8,
                          ),
                          child: LineItemCard(
                            index: idx,
                            item: displayItem,
                            detailLine: detailLine.isNotEmpty
                                ? detailLine
                                : amountLabel,
                            onEdit: () {
                              final updated = [...lines];
                              final selected = updated.removeAt(idx);
                              _linesNotifier.value = updated;
                              setState(() {
                                _editingLine = selected;
                                _lineRowKey++;
                              });
                            },
                            onDelete: () {
                              final updated = [...lines];
                              updated.removeAt(idx);
                              _linesNotifier.value = updated;
                            },
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      decoration: AppTheme.cardDecor,
                      child: HorizontalScrollWheel(
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(AppTheme.clayBg),
                          columnSpacing: AppTheme.tableColSpacing,
                          horizontalMargin: AppTheme.tableHMargin,
                          dataRowMinHeight: AppTheme.tableRowMin,
                          dataRowMaxHeight: AppTheme.tableRowMax,
                          headingRowHeight: AppTheme.tableHeadingH,
                          columns: [
                            const DataColumn(label: Text('#')),
                            const DataColumn(label: Text('Account No')),
                            const DataColumn(label: Text('Account Name')),
                            if (showDebit)
                              const DataColumn(label: Text('Debit')),
                            if (showCredit)
                              const DataColumn(label: Text('Credit')),
                            const DataColumn(label: Text('Narration')),
                            const DataColumn(label: Text('')),
                          ],
                          rows: lines.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final line = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return AppTheme.terra50;
                                }
                                return idx.isOdd
                                    ? AppTheme.clayBg.withValues(alpha: 0.5)
                                    : Colors.transparent;
                              }),
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text('${line['accountCode'] ?? ''}')),
                                DataCell(Text('${line['accountName'] ?? ''}')),
                                if (showDebit)
                                  DataCell(
                                    Text(
                                      ((line['debit'] as num?)?.toDouble() ?? 0)
                                          .toStringAsFixed(2),
                                    ),
                                  ),
                                if (showCredit)
                                  DataCell(
                                    Text(
                                      ((line['credit'] as num?)?.toDouble() ??
                                              0)
                                          .toStringAsFixed(2),
                                    ),
                                  ),
                                DataCell(Text('${line['narration'] ?? ''}')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: AppTheme.terra600,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit',
                                        onPressed: () {
                                          final updated = [...lines];
                                          final selected =
                                              updated.removeAt(idx);
                                          _linesNotifier.value = updated;
                                          setState(() {
                                            _editingLine = selected;
                                            _lineRowKey++;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: AppTheme.dangerText,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete',
                                        onPressed: () {
                                          final updated = [...lines];
                                          updated.removeAt(idx);
                                          _linesNotifier.value = updated;
                                        },
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
                        const Text(
                          'Totals: ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (showDebit) ...[
                          Text(
                            'Debit: ${debitSum.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                        if (showCredit)
                          Text(
                            'Credit: ${creditSum.toStringAsFixed(2)}',
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
              );
            },
          ),
        ],
      ),
      footer: InvoicingActionBar(
        onSave: _save,
        isSaving: _isSaving,
        onClear: _clearForm,
        onRemove: _remove,
        canRemove: _currentId != null,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
