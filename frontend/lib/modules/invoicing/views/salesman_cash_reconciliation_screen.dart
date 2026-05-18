import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/detail_line_card.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_invoice_controller.dart';
import '../controllers/salesman_cash_reconciliation_controller.dart';
import '../models/salesman_cash_reconciliation_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class SalesmanCashReconciliationScreen extends StatefulWidget {
  const SalesmanCashReconciliationScreen({super.key});

  @override
  State<SalesmanCashReconciliationScreen> createState() =>
      _SalesmanCashReconciliationScreenState();
}

class _SalesmanCashReconciliationScreenState
    extends State<SalesmanCashReconciliationScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<SalesmanCashReconciliationController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({SalesmanCashReconciliationModel? initial}) async {
    final recoveryCtrl = context.read<RecoveryInvoiceController>();
    if (recoveryCtrl.items.isEmpty) {
      await recoveryCtrl.fetchAll();
    }
    if (!mounted) return;
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<SalesmanCashReconciliationController>(),
          ),
          ChangeNotifierProvider.value(value: recoveryCtrl),
          ChangeNotifierProvider.value(
            value: context.read<SalesmenController>(),
          ),
        ],
        child: _SalesmanCashReconciliationFormDialog(initial: initial),
      ),
    );
  }

  List<SalesmanCashReconciliationModel> _visibleItems(
    SalesmanCashReconciliationController ctrl,
  ) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      return item.reconciliationId.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesmanCashReconciliationController>(
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
                      'Salesman Cash Reconciliation',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Reconciliation',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText:
                      'Search by reconciliation ID, salesman, date or status',
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
              if (ctrl.isOfflineData) const OfflineBanner(),
              if (!ctrl.isLoading && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${items.length} record${items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              if (ctrl.isLoading)
                const Expanded(child: SizedBox.shrink())
              else if (ctrl.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.point_of_sale_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cash reconciliations yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Reconciliation'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!ctrl.isLoading && items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No matches for "${_searchCtrl.text}".',
                      style: const TextStyle(color: AppTheme.textSecondary),
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
                      id: item.reconciliationId,
                      subtitle: item.salesmanName,
                      meta: AppUtils.formatDate(item.date),
                      amount: AppUtils.fmtAmt(item.totalCashReceived),
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
                            DataColumn(label: Text('Rec. ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(
                                label: Text('Recoveries'), numeric: true),
                            DataColumn(label: Text('Expenses'), numeric: true),
                            DataColumn(
                              label: Text('Closing Balance'),
                              numeric: true,
                            ),
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
                                DataCell(Text(item.reconciliationId)),
                                DataCell(Text(AppUtils.formatDate(item.date))),
                                DataCell(Text(item.salesmanName)),
                                DataCell(
                                    Text('${item.recoveryEntries.length}')),
                                DataCell(Text('${item.expenseEntries.length}')),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.closingBalance)),
                                ),
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

class _SalesmanCashReconciliationFormDialog extends StatefulWidget {
  const _SalesmanCashReconciliationFormDialog({this.initial});

  final SalesmanCashReconciliationModel? initial;

  @override
  State<_SalesmanCashReconciliationFormDialog> createState() =>
      _SalesmanCashReconciliationFormDialogState();
}

class _SalesmanCashReconciliationFormDialogState
    extends State<_SalesmanCashReconciliationFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _recoveryEntriesNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _expenseEntriesNotifier =
      ValueNotifier([]);

  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  String _salesmanId = '';
  String _reconciliationId = '';
  final _salesmanNameCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController(text: '0');
  final _cashDepositedCtrl = TextEditingController(text: '0');

  String? _recEntryRecoveryId;
  String _recEntryRecoveryDisplayId = '';
  final _recEntryRecoveryDateCtrl = TextEditingController();
  final _recEntryCashReceivedCtrl = TextEditingController(text: '0');
  final _recEntryDiscountCtrl = TextEditingController(text: '0');
  final _recEntryNarrationCtrl = TextEditingController();
  Map<String, dynamic>? _editingRecoveryEntry;

  final _expDescCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController(text: '0');
  Map<String, dynamic>? _editingExpenseEntry;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _salesmanNameCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _cashDepositedCtrl.dispose();
    _recEntryRecoveryDateCtrl.dispose();
    _recEntryCashReceivedCtrl.dispose();
    _recEntryDiscountCtrl.dispose();
    _recEntryNarrationCtrl.dispose();
    _expDescCtrl.dispose();
    _expAmountCtrl.dispose();
    _recoveryEntriesNotifier.dispose();
    _expenseEntriesNotifier.dispose();
    super.dispose();
  }

  void _clearRecoveryEntry() {
    setState(() {
      _recEntryRecoveryId = null;
      _recEntryRecoveryDisplayId = '';
      _editingRecoveryEntry = null;
    });
    _recEntryRecoveryDateCtrl.clear();
    _recEntryCashReceivedCtrl.text = '0';
    _recEntryDiscountCtrl.text = '0';
    _recEntryNarrationCtrl.clear();
  }

  void _clearExpenseEntry() {
    setState(() => _editingExpenseEntry = null);
    _expDescCtrl.clear();
    _expAmountCtrl.text = '0';
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _salesmanId = '';
      _reconciliationId = '';
    });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear();
    _openingBalanceCtrl.text = '0';
    _cashDepositedCtrl.text = '0';
    _recoveryEntriesNotifier.value = [];
    _expenseEntriesNotifier.value = [];
    _clearRecoveryEntry();
    _clearExpenseEntry();
  }

  void _loadFromModel(SalesmanCashReconciliationModel model) {
    _currentId = model.id;
    _salesmanId = model.salesmanId;
    _reconciliationId = model.reconciliationId;
    _dateCtrl.text = model.date;
    _salesmanNameCtrl.text = model.salesmanName;
    _openingBalanceCtrl.text = model.openingBalance.toStringAsFixed(2);
    _cashDepositedCtrl.text = model.cashDeposited.toStringAsFixed(2);
    _recoveryEntriesNotifier.value = model.recoveryEntries
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    _expenseEntriesNotifier.value = model.expenseEntries
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  void _startEditingRecoveryEntry(int index, Map<String, dynamic> entry) {
    final updatedEntries = [..._recoveryEntriesNotifier.value];
    updatedEntries.removeAt(index);
    _recoveryEntriesNotifier.value = updatedEntries;
    setState(() {
      _editingRecoveryEntry = Map<String, dynamic>.from(entry);
      _recEntryRecoveryId = entry['recoveryId'] as String?;
      _recEntryRecoveryDisplayId =
          '${entry['recoveryDisplayId'] ?? entry['recoveryId'] ?? ''}';
    });
    _recEntryRecoveryDateCtrl.text = '${entry['recoveryDate'] ?? ''}';
    _recEntryCashReceivedCtrl.text =
        ((entry['cashReceived'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _recEntryDiscountCtrl.text =
        ((entry['discountGiven'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _recEntryNarrationCtrl.text = '${entry['narration'] ?? ''}';
  }

  void _startEditingExpenseEntry(int index, Map<String, dynamic> entry) {
    final updatedEntries = [..._expenseEntriesNotifier.value];
    updatedEntries.removeAt(index);
    _expenseEntriesNotifier.value = updatedEntries;
    setState(() => _editingExpenseEntry = Map<String, dynamic>.from(entry));
    _expDescCtrl.text = '${entry['description'] ?? ''}';
    _expAmountCtrl.text =
        ((entry['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
  }

  void _addRecoveryEntry() {
    if (_recEntryRecoveryId == null || _recEntryRecoveryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a recovery')),
      );
      return;
    }
    final cashReceived = double.tryParse(_recEntryCashReceivedCtrl.text) ?? 0;
    final entry = {
      'recoveryId': _recEntryRecoveryId,
      'recoveryDisplayId': _recEntryRecoveryDisplayId,
      'recoveryDate': _recEntryRecoveryDateCtrl.text,
      'cashReceived': cashReceived,
      'discountGiven': double.tryParse(_recEntryDiscountCtrl.text) ?? 0,
      'narration': _recEntryNarrationCtrl.text,
    };
    _recoveryEntriesNotifier.value = [..._recoveryEntriesNotifier.value, entry];
    _clearRecoveryEntry();
  }

  void _addExpenseEntry() {
    final amount = double.tryParse(_expAmountCtrl.text) ?? 0;
    if (_expDescCtrl.text.trim().isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter description and amount')),
      );
      return;
    }
    final entry = {
      'description': _expDescCtrl.text.trim(),
      'amount': amount,
    };
    _expenseEntriesNotifier.value = [..._expenseEntriesNotifier.value, entry];
    _clearExpenseEntry();
  }

  Map<String, dynamic> _buildPayload() {
    final recoveryEntries = _recoveryEntriesNotifier.value;
    final expenseEntries = _expenseEntriesNotifier.value;
    final openingBalance = double.tryParse(_openingBalanceCtrl.text) ?? 0;
    final totalCashReceived = recoveryEntries.fold<double>(
      0,
      (sum, entry) => sum + ((entry['cashReceived'] as num?)?.toDouble() ?? 0),
    );
    final totalDiscount = recoveryEntries.fold<double>(
      0,
      (sum, entry) => sum + ((entry['discountGiven'] as num?)?.toDouble() ?? 0),
    );
    final totalExpenses = expenseEntries.fold<double>(
      0,
      (sum, entry) => sum + ((entry['amount'] as num?)?.toDouble() ?? 0),
    );
    final cashDeposited = double.tryParse(_cashDepositedCtrl.text) ?? 0;
    final closingBalance =
        openingBalance + totalCashReceived - totalExpenses - cashDeposited;
    return {
      'date': _dateCtrl.text,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'openingBalance': openingBalance,
      'recoveryEntries': recoveryEntries,
      'expenseEntries': expenseEntries,
      'totalCashReceived': totalCashReceived,
      'totalDiscount': totalDiscount,
      'totalExpenses': totalExpenses,
      'cashDeposited': cashDeposited,
      'closingBalance': closingBalance,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<SalesmanCashReconciliationController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _reconciliationId = record.reconciliationId;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this reconciliation?'),
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
    if (confirmed == true && mounted) {
      await context.read<SalesmanCashReconciliationController>().deleteItem(
            _currentId!,
          );
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.watch<SalesmenController>().typedItems;
    final recoveries = context.watch<RecoveryInvoiceController>().items;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InvoicingFormDialog(
      title: 'Salesman Cash Reconciliation',
      badgeText:
          _reconciliationId.isNotEmpty ? 'Rec. ID: $_reconciliationId' : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.cardDecor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _dateCtrl,
                    decoration: _dec('Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _salesmanId.isEmpty ? null : _salesmanId,
                    decoration: _dec('Salesman'),
                    isExpanded: true,
                    items: salesmen
                        .map(
                          (salesman) => DropdownMenuItem<String>(
                            value: salesman.id,
                            child: Text(
                              salesman.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final salesman =
                          salesmen.firstWhere((item) => item.id == value);
                      setState(() => _salesmanId = value);
                      _salesmanNameCtrl.text = salesman.text('name');
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _openingBalanceCtrl,
                    decoration: _dec('Opening Bal'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recovery Entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.clayBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.softBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _recEntryRecoveryId,
                    decoration: _dec('Recovery'),
                    isExpanded: true,
                    items: recoveries
                        .where(
                          (recovery) =>
                              _salesmanId.isEmpty ||
                              recovery.salesmanId == _salesmanId,
                        )
                        .map(
                          (recovery) => DropdownMenuItem<String>(
                            value: recovery.id,
                            child: Text(
                              recovery.recoveryId.isNotEmpty
                                  ? recovery.recoveryId
                                  : recovery.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final recovery =
                          recoveries.firstWhere((item) => item.id == value);
                      setState(() {
                        _recEntryRecoveryId = value;
                        _recEntryRecoveryDisplayId = recovery.recoveryId;
                        _recEntryRecoveryDateCtrl.text = recovery.date;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _recEntryRecoveryDateCtrl,
                      decoration: _dec('Recovery Date'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    controller: _recEntryCashReceivedCtrl,
                    decoration: _dec('Cash Received'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _recEntryDiscountCtrl,
                    decoration: _dec('Discount'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _recEntryNarrationCtrl,
                    decoration: _dec('Narration'),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addRecoveryEntry,
                  icon: Icon(
                    _editingRecoveryEntry == null ? Icons.add : Icons.check,
                    size: 16,
                  ),
                  label: Text(
                    _editingRecoveryEntry == null ? 'Add' : 'Update',
                  ),
                ),
                if (_editingRecoveryEntry != null)
                  OutlinedButton(
                    onPressed: _clearRecoveryEntry,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _recoveryEntriesNotifier,
            builder: (context, entries, _) {
              if (entries.isEmpty) return const SizedBox.shrink();
              if (isMobile) {
                return Column(
                  children: entries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    final recoveryId =
                        '${row['recoveryDisplayId'] ?? row['recoveryId'] ?? ''}';
                    final date = '${row['recoveryDate'] ?? ''}';
                    final narration = '${row['narration'] ?? ''}';
                    final cashReceived =
                        (row['cashReceived'] as num?)?.toDouble() ?? 0;
                    final discount =
                        (row['discountGiven'] as num?)?.toDouble() ?? 0;
                    final subtitleParts = <String>[];
                    if (date.isNotEmpty) subtitleParts.add(date);
                    if (narration.isNotEmpty) subtitleParts.add(narration);
                    final chips = <String>[];
                    if (discount > 0) {
                      chips.add('Disc ${AppUtils.fmtAmt2(discount)}');
                    }
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx == entries.length - 1 ? 0 : 8,
                      ),
                      child: DetailLineCard(
                        index: idx,
                        title: recoveryId.isNotEmpty
                            ? recoveryId
                            : 'Recovery ${idx + 1}',
                        subtitle: subtitleParts.isNotEmpty
                            ? subtitleParts.join('  ·  ')
                            : null,
                        amount: AppUtils.fmtAmt2(cashReceived),
                        amountLabel: 'Cash',
                        chips: chips,
                        onEdit: () => _startEditingRecoveryEntry(idx, row),
                        onDelete: () {
                          final updatedEntries = [...entries];
                          updatedEntries.removeAt(idx);
                          _recoveryEntriesNotifier.value = updatedEntries;
                        },
                      ),
                    );
                  }).toList(),
                );
              }
              return Container(
                width: double.infinity,
                decoration: AppTheme.cardDecor,
                child: HorizontalScrollWheel(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Recovery ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Cash Received')),
                      DataColumn(label: Text('Discount')),
                      DataColumn(label: Text('Narration')),
                      DataColumn(label: Text('')),
                    ],
                    rows: entries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
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
                          DataCell(
                            Text(
                              '${row['recoveryDisplayId'] ?? row['recoveryId'] ?? ''}',
                            ),
                          ),
                          DataCell(Text('${row['recoveryDate'] ?? ''}')),
                          DataCell(
                            Text(
                              ((row['cashReceived'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          DataCell(
                            Text(
                              ((row['discountGiven'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          DataCell(Text('${row['narration'] ?? ''}')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppTheme.terra600,
                                  ),
                                  onPressed: () =>
                                      _startEditingRecoveryEntry(idx, row),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppTheme.dangerText,
                                  ),
                                  onPressed: () {
                                    final updatedEntries = [...entries];
                                    updatedEntries.removeAt(idx);
                                    _recoveryEntriesNotifier.value =
                                        updatedEntries;
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
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Expense Entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.clayBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.softBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _expDescCtrl,
                    decoration: _dec('Description'),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _expAmountCtrl,
                    decoration: _dec('Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addExpenseEntry,
                  icon: Icon(
                    _editingExpenseEntry == null ? Icons.add : Icons.check,
                    size: 16,
                  ),
                  label: Text(_editingExpenseEntry == null ? 'Add' : 'Update'),
                ),
                if (_editingExpenseEntry != null)
                  OutlinedButton(
                    onPressed: _clearExpenseEntry,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _expenseEntriesNotifier,
            builder: (context, entries, _) {
              if (entries.isEmpty) return const SizedBox.shrink();
              if (isMobile) {
                return Column(
                  children: entries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx == entries.length - 1 ? 0 : 8,
                      ),
                      child: DetailLineCard(
                        index: idx,
                        title: '${row['description'] ?? ''}',
                        amount: AppUtils.fmtAmt2(amount),
                        amountLabel: 'Expense',
                        onEdit: () => _startEditingExpenseEntry(idx, row),
                        onDelete: () {
                          final updatedEntries = [...entries];
                          updatedEntries.removeAt(idx);
                          _expenseEntriesNotifier.value = updatedEntries;
                        },
                      ),
                    );
                  }).toList(),
                );
              }
              return Container(
                width: double.infinity,
                decoration: AppTheme.cardDecor,
                child: HorizontalScrollWheel(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('')),
                    ],
                    rows: entries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
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
                          DataCell(Text('${row['description'] ?? ''}')),
                          DataCell(
                            Text(
                              ((row['amount'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppTheme.terra600,
                                  ),
                                  onPressed: () =>
                                      _startEditingExpenseEntry(idx, row),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppTheme.dangerText,
                                  ),
                                  onPressed: () {
                                    final updatedEntries = [...entries];
                                    updatedEntries.removeAt(idx);
                                    _expenseEntriesNotifier.value =
                                        updatedEntries;
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
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _recoveryEntriesNotifier,
            builder: (context, recoveryEntries, _) =>
                ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _expenseEntriesNotifier,
              builder: (context, expenseEntries, _) {
                final openingBalance =
                    double.tryParse(_openingBalanceCtrl.text) ?? 0;
                final totalCashReceived = recoveryEntries.fold<double>(
                  0,
                  (sum, entry) =>
                      sum + ((entry['cashReceived'] as num?)?.toDouble() ?? 0),
                );
                final discount = recoveryEntries.fold<double>(
                  0,
                  (sum, entry) =>
                      sum + ((entry['discountGiven'] as num?)?.toDouble() ?? 0),
                );
                final totalExpenses = expenseEntries.fold<double>(
                  0,
                  (sum, entry) =>
                      sum + ((entry['amount'] as num?)?.toDouble() ?? 0),
                );
                final cashDeposited =
                    double.tryParse(_cashDepositedCtrl.text) ?? 0;
                final closingBalance = openingBalance +
                    totalCashReceived -
                    totalExpenses -
                    cashDeposited;
                return Container(
                  decoration: AppTheme.cardDecor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _TotalItem(
                        'Opening Bal',
                        openingBalance.toStringAsFixed(2),
                      ),
                      _TotalItem(
                        'Cash Received',
                        totalCashReceived.toStringAsFixed(2),
                      ),
                      _TotalItem('Discount', discount.toStringAsFixed(2)),
                      _TotalItem('Expenses', totalExpenses.toStringAsFixed(2)),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _cashDepositedCtrl,
                          decoration: _dec('Cash Deposited'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      _TotalItem(
                        'Closing Balance',
                        closingBalance.toStringAsFixed(2),
                        bold: true,
                      ),
                    ],
                  ),
                );
              },
            ),
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

class _TotalItem extends StatelessWidget {
  const _TotalItem(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
