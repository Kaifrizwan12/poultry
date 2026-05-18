import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/detail_line_card.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_invoice_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/recovery_invoice_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class RecoveryInvoiceScreen extends StatefulWidget {
  const RecoveryInvoiceScreen({super.key});

  @override
  State<RecoveryInvoiceScreen> createState() => _RecoveryInvoiceScreenState();
}

class _RecoveryInvoiceScreenState extends State<RecoveryInvoiceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<RecoveryInvoiceController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({RecoveryInvoiceModel? initial}) async {
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<RecoveryInvoiceController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<SalesInvoiceController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<CustomersController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<SalesmenController>(),
          ),
        ],
        child: _RecoveryInvoiceFormDialog(initial: initial),
      ),
    );
  }

  List<RecoveryInvoiceModel> _visibleItems(RecoveryInvoiceController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      return item.recoveryId.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecoveryInvoiceController>(
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
                      'Recovery Invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Recovery',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by recovery ID, salesman or date',
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
                          Icons.account_balance_wallet_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recovery invoices yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Recovery'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!ctrl.isLoading && items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching recoveries found.',
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
                      id: item.recoveryId,
                      subtitle: item.salesmanName,
                      meta: AppUtils.formatDate(item.date),
                      amount: AppUtils.fmtAmt(item.amount),
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
                            DataColumn(label: Text('Recovery ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(label: Text('Invoices')),
                            DataColumn(label: Text('Amount'), numeric: true),
                            DataColumn(label: Text('Discount'), numeric: true),
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
                                DataCell(Text(item.recoveryId)),
                                DataCell(Text(AppUtils.formatDate(item.date))),
                                DataCell(Text(item.salesmanName)),
                                DataCell(
                                  Text('${item.customerRecoveries.length}'),
                                ),
                                DataCell(Text(AppUtils.fmtAmt(item.amount))),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.discount)),
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

class _RecoveryInvoiceFormDialog extends StatefulWidget {
  const _RecoveryInvoiceFormDialog({this.initial});

  final RecoveryInvoiceModel? initial;

  @override
  State<_RecoveryInvoiceFormDialog> createState() =>
      _RecoveryInvoiceFormDialogState();
}

class _RecoveryInvoiceFormDialogState
    extends State<_RecoveryInvoiceFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _entriesNotifier =
      ValueNotifier([]);

  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  String _recoveryId = '';

  String? _entryCustomerId;
  final _entryCustomerNameCtrl = TextEditingController();
  String? _entrySaleId;
  String _entrySaleDisplayId = '';
  double _entrySaleValue = 0;
  final _entrySaleValueCtrl = TextEditingController(text: '0.00');
  final _entryAdjustedCtrl = TextEditingController(text: '0');
  final _entryReceivedCtrl = TextEditingController(text: '0');
  final _entryDiscountCtrl = TextEditingController(text: '0');
  final _entryNarrationCtrl = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _initFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _salesmanNameCtrl.dispose();
    _entryCustomerNameCtrl.dispose();
    _entrySaleValueCtrl.dispose();
    _entryAdjustedCtrl.dispose();
    _entryReceivedCtrl.dispose();
    _entryDiscountCtrl.dispose();
    _entryNarrationCtrl.dispose();
    _entriesNotifier.dispose();
    super.dispose();
  }

  void _initFromModel(RecoveryInvoiceModel m) {
    _currentId = m.id;
    _recoveryId = m.recoveryId;
    _salesmanId = m.salesmanId;
    _dateCtrl.text = m.date;
    _salesmanNameCtrl.text = m.salesmanName;
    _entriesNotifier.value =
        List<Map<String, dynamic>>.from(m.customerRecoveries);
  }

  void _resetEntryRow() {
    setState(() {
      _entryCustomerId = null;
      _entrySaleId = null;
      _entrySaleDisplayId = '';
      _entrySaleValue = 0;
      _editingIndex = null;
    });
    _entryCustomerNameCtrl.clear();
    _entrySaleValueCtrl.text = '0.00';
    _entryAdjustedCtrl.text = '0';
    _entryReceivedCtrl.text = '0';
    _entryDiscountCtrl.text = '0';
    _entryNarrationCtrl.clear();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _recoveryId = '';
      _salesmanId = '';
    });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear();
    _entriesNotifier.value = [];
    _resetEntryRow();
  }

  void _addEntry() {
    if (_entryCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer')),
      );
      return;
    }
    if (_entrySaleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a sale invoice')),
      );
      return;
    }
    final received = double.tryParse(_entryReceivedCtrl.text) ?? 0;
    final discount = double.tryParse(_entryDiscountCtrl.text) ?? 0;
    if (received + discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Received or Discount must be > 0')),
      );
      return;
    }

    final adjusted = double.tryParse(_entryAdjustedCtrl.text) ?? 0;
    final receivable = _entrySaleValue - adjusted;
    final finalCredit = received + discount;
    final entry = {
      'customerId': _entryCustomerId,
      'customerName': _entryCustomerNameCtrl.text,
      'saleId': _entrySaleId,
      'saleDisplayId': _entrySaleDisplayId,
      'saleValue': _entrySaleValue,
      'adjusted': adjusted,
      'receivable': receivable,
      'received': received,
      'discount': discount,
      'finalCredit': finalCredit,
      'narration': _entryNarrationCtrl.text,
    };

    final updated = [..._entriesNotifier.value];
    if (_editingIndex != null) {
      updated.insert(_editingIndex!, entry);
    } else {
      updated.add(entry);
    }
    _entriesNotifier.value = updated;
    _resetEntryRow();
  }

  Map<String, dynamic> _buildPayload() {
    final entries = _entriesNotifier.value
        .map(
          (e) => {
            'customerId': e['customerId'],
            'customerName': e['customerName'],
            'saleId': e['saleId'],
            'saleValue': e['saleValue'],
            'adjusted': e['adjusted'],
            'receivable': e['receivable'],
            'received': e['received'],
            'discount': e['discount'],
            'finalCredit': e['finalCredit'],
            'narration': e['narration'],
          },
        )
        .toList();
    final totalNoInvoices = entries.length;
    final amount = entries.fold<double>(
      0,
      (s, e) => s + ((e['received'] as num?)?.toDouble() ?? 0),
    );
    final discount = entries.fold<double>(
      0,
      (s, e) => s + ((e['discount'] as num?)?.toDouble() ?? 0),
    );
    return {
      'date': _dateCtrl.text,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'totalNoInvoices': totalNoInvoices,
      'amount': amount,
      'discount': discount,
      'customerRecoveries': entries,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_salesmanId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a salesman')));
      }
      return;
    }
    if (_entriesNotifier.value.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one item')));
      }
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<RecoveryInvoiceController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _recoveryId = record.recoveryId;
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
        content: const Text('Delete this recovery?'),
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
      await context.read<RecoveryInvoiceController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.watch<SalesmenController>().typedItems;
    final customers = context.watch<CustomersController>().typedItems;
    final salesInvoices = context.watch<SalesInvoiceController>().items;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InvoicingFormDialog(
      title: 'Recovery Invoice',
      badgeText: _recoveryId.isNotEmpty ? 'Recovery ID: $_recoveryId' : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.cardDecor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
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
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _salesmanId.isEmpty ? null : _salesmanId,
                    decoration: _dec('Salesman'),
                    isExpanded: true,
                    items: salesmen
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _salesmanId = val);
                      _salesmanNameCtrl.text =
                          salesmen.firstWhere((s) => s.id == val).text('name');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _entryCustomerId,
                    decoration: _dec('Customer'),
                    isExpanded: true,
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _entryCustomerId = val;
                        _entrySaleId = null;
                        _entrySaleDisplayId = '';
                        _entrySaleValue = 0;
                      });
                      _entryCustomerNameCtrl.text =
                          customers.firstWhere((c) => c.id == val).text('name');
                      _entrySaleValueCtrl.text = '0.00';
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _entrySaleId,
                    decoration: _dec('Sale Invoice'),
                    isExpanded: true,
                    items: salesInvoices
                        .where(
                          (si) =>
                              _entryCustomerId == null ||
                              si.customerId == _entryCustomerId,
                        )
                        .map(
                          (si) => DropdownMenuItem(
                            value: si.id,
                            child: Text(
                              si.saleId,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final sale = salesInvoices.firstWhere((x) => x.id == val);
                      setState(() {
                        _entrySaleId = val;
                        _entrySaleDisplayId = sale.saleId;
                        _entrySaleValue = sale.totalPayable;
                      });
                      _entrySaleValueCtrl.text =
                          _entrySaleValue.toStringAsFixed(2);
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _entrySaleValueCtrl,
                      decoration: _dec('Sale Value'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _entryAdjustedCtrl,
                    decoration: _dec('Adjusted'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _entryReceivedCtrl,
                    decoration: _dec('Received'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _entryDiscountCtrl,
                    decoration: _dec('Discount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _entryNarrationCtrl,
                    decoration: _dec('Narration'),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addEntry,
                  icon: Icon(
                    _editingIndex != null ? Icons.check : Icons.add,
                    size: 16,
                  ),
                  label: Text(_editingIndex != null ? 'Update' : 'Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _entriesNotifier,
            builder: (context, entries, _) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No entries added.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              final totalInvoices = entries.length;
              final totalAmount = entries.fold<double>(
                0,
                (s, e) => s + ((e['received'] as num?)?.toDouble() ?? 0),
              );
              final totalDiscount = entries.fold<double>(
                0,
                (s, e) => s + ((e['discount'] as num?)?.toDouble() ?? 0),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile)
                    Column(
                      children: entries.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        final saleId =
                            '${e['saleDisplayId'] ?? e['saleId'] ?? ''}';
                        final saleValue =
                            (e['saleValue'] as num?)?.toDouble() ?? 0;
                        final adjusted =
                            (e['adjusted'] as num?)?.toDouble() ?? 0;
                        final receivable =
                            (e['receivable'] as num?)?.toDouble() ?? 0;
                        final received =
                            (e['received'] as num?)?.toDouble() ?? 0;
                        final discount =
                            (e['discount'] as num?)?.toDouble() ?? 0;
                        final finalCredit =
                            (e['finalCredit'] as num?)?.toDouble() ??
                                (received + discount);
                        final narration = '${e['narration'] ?? ''}';
                        final subtitleParts = <String>[];
                        if (saleId.isNotEmpty)
                          subtitleParts.add('Sale $saleId');
                        subtitleParts.add(
                          'Value ${AppUtils.fmtAmt2(saleValue)}',
                        );
                        if (narration.isNotEmpty) subtitleParts.add(narration);
                        final chips = <String>[
                          'Recvbl ${AppUtils.fmtAmt2(receivable)}',
                          'Recv ${AppUtils.fmtAmt2(received)}',
                        ];
                        if (adjusted > 0) {
                          chips.add('Adj ${AppUtils.fmtAmt2(adjusted)}');
                        }
                        if (discount > 0) {
                          chips.add('Disc ${AppUtils.fmtAmt2(discount)}');
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx == entries.length - 1 ? 0 : 8,
                          ),
                          child: DetailLineCard(
                            index: idx,
                            title: '${e['customerName'] ?? ''}',
                            subtitle: subtitleParts.isNotEmpty
                                ? subtitleParts.join('  ·  ')
                                : null,
                            amount: AppUtils.fmtAmt2(finalCredit),
                            amountLabel: 'Final Credit',
                            chips: chips,
                            onEdit: () {
                              final updated = [...entries];
                              final selected = updated.removeAt(idx);
                              _entriesNotifier.value = updated;
                              setState(() {
                                _editingIndex = idx;
                                _entryCustomerId =
                                    '${selected['customerId'] ?? ''}';
                                _entrySaleId = '${selected['saleId'] ?? ''}';
                                _entrySaleDisplayId =
                                    '${selected['saleDisplayId'] ?? selected['saleId'] ?? ''}';
                                _entrySaleValue =
                                    ((selected['saleValue'] as num?)
                                            ?.toDouble() ??
                                        0);
                              });
                              _entryCustomerNameCtrl.text =
                                  '${selected['customerName'] ?? ''}';
                              _entrySaleValueCtrl.text =
                                  _entrySaleValue.toStringAsFixed(2);
                              _entryAdjustedCtrl.text =
                                  ((selected['adjusted'] as num?)?.toDouble() ??
                                          0)
                                      .toStringAsFixed(2);
                              _entryReceivedCtrl.text =
                                  ((selected['received'] as num?)?.toDouble() ??
                                          0)
                                      .toStringAsFixed(2);
                              _entryDiscountCtrl.text =
                                  ((selected['discount'] as num?)?.toDouble() ??
                                          0)
                                      .toStringAsFixed(2);
                              _entryNarrationCtrl.text =
                                  '${selected['narration'] ?? ''}';
                            },
                            onDelete: () {
                              final updated = [...entries];
                              updated.removeAt(idx);
                              _entriesNotifier.value = updated;
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
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Sale ID')),
                            DataColumn(label: Text('Sale Value')),
                            DataColumn(label: Text('Adjusted')),
                            DataColumn(label: Text('Receivable')),
                            DataColumn(label: Text('Received')),
                            DataColumn(label: Text('Discount')),
                            DataColumn(label: Text('Final Credit')),
                            DataColumn(label: Text('Narration')),
                            DataColumn(label: Text('')),
                          ],
                          rows: entries.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final e = entry.value;
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
                                DataCell(Text('${e['customerName'] ?? ''}')),
                                DataCell(
                                  Text(
                                    '${e['saleDisplayId'] ?? e['saleId'] ?? ''}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['saleValue'] as num?)?.toDouble() ?? 0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['adjusted'] as num?)?.toDouble() ?? 0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['receivable'] as num?)?.toDouble() ?? 0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['received'] as num?)?.toDouble() ?? 0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['discount'] as num?)?.toDouble() ?? 0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    ((e['finalCredit'] as num?)?.toDouble() ??
                                            0)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(Text('${e['narration'] ?? ''}')),
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
                                          final updated = [...entries];
                                          final selected =
                                              updated.removeAt(idx);
                                          _entriesNotifier.value = updated;
                                          setState(() {
                                            _editingIndex = idx;
                                            _entryCustomerId =
                                                '${selected['customerId'] ?? ''}';
                                            _entrySaleId =
                                                '${selected['saleId'] ?? ''}';
                                            _entrySaleDisplayId =
                                                '${selected['saleDisplayId'] ?? selected['saleId'] ?? ''}';
                                            _entrySaleValue =
                                                ((selected['saleValue'] as num?)
                                                        ?.toDouble() ??
                                                    0);
                                          });
                                          _entryCustomerNameCtrl.text =
                                              '${selected['customerName'] ?? ''}';
                                          _entrySaleValueCtrl.text =
                                              _entrySaleValue
                                                  .toStringAsFixed(2);
                                          _entryAdjustedCtrl.text =
                                              ((selected['adjusted'] as num?)
                                                          ?.toDouble() ??
                                                      0)
                                                  .toStringAsFixed(2);
                                          _entryReceivedCtrl.text =
                                              ((selected['received'] as num?)
                                                          ?.toDouble() ??
                                                      0)
                                                  .toStringAsFixed(2);
                                          _entryDiscountCtrl.text =
                                              ((selected['discount'] as num?)
                                                          ?.toDouble() ??
                                                      0)
                                                  .toStringAsFixed(2);
                                          _entryNarrationCtrl.text =
                                              '${selected['narration'] ?? ''}';
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
                                          final updated = [...entries];
                                          updated.removeAt(idx);
                                          _entriesNotifier.value = updated;
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
                        Text(
                          'Invoices: $totalInvoices',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Amount: ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Discount: ${totalDiscount.toStringAsFixed(2)}',
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
