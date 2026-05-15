import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/payment_promise_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';

class PostDatedRecoveryPromiseScreen extends StatefulWidget {
  const PostDatedRecoveryPromiseScreen({super.key});

  @override
  State<PostDatedRecoveryPromiseScreen> createState() =>
      _PostDatedRecoveryPromiseScreenState();
}

class _PostDatedRecoveryPromiseScreenState
    extends State<PostDatedRecoveryPromiseScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<PaymentPromiseController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({PaymentPromiseModel? initial}) async {
    final promiseCtrl = context.read<PaymentPromiseController>();
    final salesCtrl = context.read<SalesInvoiceController>();
    if (salesCtrl.items.isEmpty) {
      await salesCtrl.fetchAll();
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: promiseCtrl),
          ChangeNotifierProvider.value(value: salesCtrl),
          ChangeNotifierProvider.value(value: context.read<CustomersController>()),
          ChangeNotifierProvider.value(value: context.read<SalesmenController>()),
        ],
        child: _RecoveryPromiseFormDialog(initial: initial),
      ),
    );
  }

  List<PaymentPromiseModel> _visibleItems(PaymentPromiseController ctrl) {
    List<PaymentPromiseModel> items = ctrl.items
        .where((item) => item.promiseType == 'recovery')
        .toList();
    switch (_filter) {
      case 'pending':
        items = items.where((item) => item.status == 'pending').toList();
        break;
      case 'saved':
        items = items.where((item) => item.status == 'saved').toList();
        break;
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.promiseId.toLowerCase().contains(q) ||
          item.customerName.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.chequeNo.toLowerCase().contains(q) ||
          item.bankName.toLowerCase().contains(q) ||
          item.promiseDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentPromiseController>(
      builder: (context, ctrl, _) {
        final recoveryItems = ctrl.items
            .where((item) => item.promiseType == 'recovery')
            .toList();
        final items = _visibleItems(ctrl);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Post Dated Recovery Promises',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Recovery Promise'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchCtrl,
                      decoration: AppTheme.inputDecoration(
                        null,
                        hintText:
                            'Search by promise ID, customer, salesman, cheque or bank',
                        prefixIcon:
                            const Icon(Icons.search_outlined, size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    setState(() => _searchCtrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Saved',
                    selected: _filter == 'saved',
                    onTap: () => setState(() => _filter = 'saved'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Pending',
                    selected: _filter == 'pending',
                    onTap: () => setState(() => _filter = 'pending'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recoveryItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_send_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recovery promises yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Recovery Promise'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No matches for "${_searchCtrl.text}".',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
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
                            DataColumn(label: Text('Promise ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(label: Text('Linked')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Amount'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
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
                                DataCell(Text(item.promiseId)),
                                DataCell(Text(item.promiseDate)),
                                DataCell(Text(item.customerName)),
                                DataCell(Text(item.salesmanName)),
                                DataCell(Text('${item.linkedSaleIds.length}')),
                                DataCell(_StatusBadge(status: item.status)),
                                DataCell(Text(item.amount.toStringAsFixed(0))),
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

class _RecoveryPromiseFormDialog extends StatefulWidget {
  const _RecoveryPromiseFormDialog({this.initial});

  final PaymentPromiseModel? initial;

  @override
  State<_RecoveryPromiseFormDialog> createState() =>
      _RecoveryPromiseFormDialogState();
}

class _RecoveryPromiseFormDialogState extends State<_RecoveryPromiseFormDialog> {
  String? _currentId;
  bool _isSaving = false;

  final _entryDate =
      DateTime.now().toIso8601String().substring(0, 10);
  final _promiseDateCtrl = TextEditingController();
  String _customerId = '';
  final _customerNameCtrl = TextEditingController();
  String _salesmanId = '';
  final _salesmanNameCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  List<String> _linkedSaleIds = [];
  String _promiseId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    for (final controller in [
      _promiseDateCtrl,
      _customerNameCtrl,
      _salesmanNameCtrl,
      _chequeNoCtrl,
      _bankNameCtrl,
      _amountCtrl,
      _narrationCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _promiseId = '';
      _customerId = '';
      _salesmanId = '';
      _linkedSaleIds = [];
    });
    _promiseDateCtrl.clear();
    _customerNameCtrl.clear();
    _salesmanNameCtrl.clear();
    _chequeNoCtrl.clear();
    _bankNameCtrl.clear();
    _amountCtrl.text = '0';
    _narrationCtrl.clear();
  }

  void _loadFromModel(PaymentPromiseModel model) {
    setState(() {
      _currentId = model.id;
      _promiseId = model.promiseId;
      _customerId = model.customerId;
      _salesmanId = model.salesmanId;
      _linkedSaleIds = List<String>.from(model.linkedSaleIds);
    });
    _promiseDateCtrl.text = model.promiseDate;
    _customerNameCtrl.text = model.customerName;
    _salesmanNameCtrl.text = model.salesmanName;
    _chequeNoCtrl.text = model.chequeNo;
    _bankNameCtrl.text = model.bankName;
    _amountCtrl.text = model.amount.toStringAsFixed(2);
    _narrationCtrl.text = model.narration;
  }

  Map<String, dynamic> _buildPayload() => {
        'promiseType': 'recovery',
        'entryDate': _entryDate,
        'promiseDate': _promiseDateCtrl.text,
        'customerId': _customerId,
        'customerName': _customerNameCtrl.text,
        'salesmanId': _salesmanId,
        'salesmanName': _salesmanNameCtrl.text,
        'chequeNo': _chequeNoCtrl.text,
        'bankName': _bankNameCtrl.text,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'narration': _narrationCtrl.text,
        'linkedSaleIds': _linkedSaleIds,
        'status': 'pending',
      };

  Future<void> _save() async {
    if (_promiseDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promise Date is required')),
      );
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<PaymentPromiseController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _promiseId = record.promiseId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this recovery promise?'),
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
      await context.read<PaymentPromiseController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomersController>().typedItems;
    final salesmen = context.watch<SalesmenController>().typedItems;
    final salesInvoices = context
        .watch<SalesInvoiceController>()
        .items
        .where((item) => _customerId.isEmpty || item.customerId == _customerId)
        .toList();
    final totalLinked = salesInvoices
        .where((item) => _linkedSaleIds.contains(item.id))
        .fold<double>(0, (sum, item) => sum + item.totalPayable);
    final promiseAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final difference = totalLinked - promiseAmount;

    return InvoicingFormDialog(
      title: 'Post Dated Recovery Promise',
      badgeText: _promiseId.isNotEmpty ? 'Promise ID: $_promiseId' : null,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.clayBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Entry Date: $_entryDate',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _promiseDateCtrl,
                    decoration: _dec('Promise Date *'),
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
                          _promiseDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _customerId.isEmpty ? null : _customerId,
                    decoration: _dec('Customer'),
                    isExpanded: true,
                    items: customers
                        .map(
                          (customer) => DropdownMenuItem<String>(
                            value: customer.id,
                            child: Text(
                              customer.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final customer = customers.firstWhere((c) => c.id == value);
                      setState(() {
                        _customerId = value;
                        _linkedSaleIds = [];
                      });
                      _customerNameCtrl.text = customer.text('name');
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _salesmanId.isEmpty ? null : _salesmanId,
                    decoration: _dec('Salesman (optional)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      ...salesmen.map(
                        (salesman) => DropdownMenuItem<String>(
                          value: salesman.id,
                          child: Text(
                            salesman.text('name'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _salesmanId = value ?? '');
                      if (value != null && value.isNotEmpty) {
                        final salesman =
                            salesmen.firstWhere((item) => item.id == value);
                        _salesmanNameCtrl.text = salesman.text('name');
                      } else {
                        _salesmanNameCtrl.clear();
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _chequeNoCtrl,
                    decoration: _dec('Cheque No'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _bankNameCtrl,
                    decoration: _dec('Bank Name'),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: _dec('Amount *'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: _narrationCtrl,
                    decoration: _dec('Narration'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Linked Invoices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_customerId.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Select a customer to see invoices.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else if (salesInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No invoices found for this customer.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: AppTheme.cardDecor,
              child: HorizontalScrollWheel(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                  columnSpacing: AppTheme.tableColSpacing,
                  horizontalMargin: AppTheme.tableHMargin,
                  dataRowMinHeight: AppTheme.tableRowMin,
                  dataRowMaxHeight: AppTheme.tableRowMax,
                  headingRowHeight: AppTheme.tableHeadingH,
                  columns: const [
                    DataColumn(label: Text('Link')),
                    DataColumn(label: Text('Sale ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Total Payable'), numeric: true),
                  ],
                  rows: salesInvoices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sale = entry.value;
                    final linked = _linkedSaleIds.contains(sale.id);
                    return DataRow(
                      color: WidgetStateProperty.resolveWith(
                        (_) => idx.isOdd
                            ? AppTheme.clayBg.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: linked,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _linkedSaleIds = [..._linkedSaleIds, sale.id];
                                } else {
                                  _linkedSaleIds = _linkedSaleIds
                                      .where((id) => id != sale.id)
                                      .toList();
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(sale.saleId.isNotEmpty ? sale.saleId : '—')),
                        DataCell(
                          Text(
                            sale.entryDate.length >= 10
                                ? sale.entryDate.substring(0, 10)
                                : sale.entryDate,
                          ),
                        ),
                        DataCell(Text(sale.totalPayable.toStringAsFixed(0))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            color: AppTheme.clayBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                Text(
                  'Total Linked: ${totalLinked.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Promise Amount: ${promiseAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Difference: ${difference.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: difference.abs() > 0.01
                        ? AppTheme.warningText
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.terra600 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.terra600 : AppTheme.softBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isPending = normalized == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending ? AppTheme.warningBg : AppTheme.successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'saved' : status,
        style: TextStyle(
          color: isPending ? AppTheme.warningText : AppTheme.successText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
