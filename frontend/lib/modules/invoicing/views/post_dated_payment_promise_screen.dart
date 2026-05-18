import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/responsive_search_filter_bar.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../controllers/purchase_invoice_controller.dart';
import '../models/payment_promise_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class PostDatedPaymentPromiseScreen extends StatefulWidget {
  const PostDatedPaymentPromiseScreen({super.key});

  @override
  State<PostDatedPaymentPromiseScreen> createState() =>
      _PostDatedPaymentPromiseScreenState();
}

class _PostDatedPaymentPromiseScreenState
    extends State<PostDatedPaymentPromiseScreen> {
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
    final invoiceCtrl = context.read<PurchaseInvoiceController>();
    if (invoiceCtrl.items.isEmpty) {
      await invoiceCtrl.fetchAll();
    }

    if (!mounted) return;

    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: promiseCtrl),
          ChangeNotifierProvider.value(value: invoiceCtrl),
          ChangeNotifierProvider.value(value: context.read<VendorsController>()),
        ],
        child: _PaymentPromiseFormDialog(initial: initial),
      ),
    );
  }

  List<PaymentPromiseModel> _visibleItems(PaymentPromiseController ctrl) {
    List<PaymentPromiseModel> items = ctrl.items
        .where((item) => item.promiseType == 'payment')
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
          item.vendorName.toLowerCase().contains(q) ||
          item.chequeNo.toLowerCase().contains(q) ||
          item.bankName.toLowerCase().contains(q) ||
          item.promiseDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentPromiseController>(
      builder: (context, ctrl, _) {
        final paymentItems = ctrl.items
            .where((item) => item.promiseType == 'payment')
            .toList();
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
                      'Post Dated Payment Promises',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Payment Promise',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveSearchFilterBar(
                search: TextFormField(
                  controller: _searchCtrl,
                  decoration: AppTheme.inputDecoration(
                    null,
                    hintText:
                        'Search by promise ID, vendor, cheque, bank or date',
                    prefixIcon: const Icon(Icons.search_outlined, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            padding: EdgeInsets.zero,
                            tooltip: 'Clear search',
                            onPressed: () =>
                                setState(() => _searchCtrl.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                filters: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _FilterChip(
                    label: 'Saved',
                    selected: _filter == 'saved',
                    onTap: () => setState(() => _filter = 'saved'),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    selected: _filter == 'pending',
                    onTap: () => setState(() => _filter = 'pending'),
                  ),
                ],
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
              else if (paymentItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payment promises yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Payment Promise'),
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
                        id: item.promiseId,
                        subtitle: item.vendorName,
                        meta: AppUtils.formatDate(item.promiseDate),
                        amount: AppUtils.fmtAmt(item.amount),
                        badge: _StatusBadge(status: item.status),
                        onTap: () => _openForm(initial: item),
                      );
                    },
                  )
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
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Linked')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Amount'), numeric: true),
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
                                DataCell(Text(item.promiseId)),
                                DataCell(Text(AppUtils.formatDate(item.promiseDate))),
                                DataCell(Text(item.vendorName)),
                                DataCell(
                                  Text('${item.linkedPurchaseIds.length}'),
                                ),
                                DataCell(_StatusBadge(status: item.status)),
                                DataCell(Text(AppUtils.fmtAmt(item.amount))),
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

class _PaymentPromiseFormDialog extends StatefulWidget {
  const _PaymentPromiseFormDialog({this.initial});

  final PaymentPromiseModel? initial;

  @override
  State<_PaymentPromiseFormDialog> createState() =>
      _PaymentPromiseFormDialogState();
}

class _PaymentPromiseFormDialogState extends State<_PaymentPromiseFormDialog> {
  String? _currentId;
  bool _isSaving = false;

  final _entryDate = DateTime.now().toIso8601String().substring(0, 10);
  final _promiseDateCtrl = TextEditingController();
  String _vendorId = '';
  final _vendorNameCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  List<String> _linkedPurchaseIds = [];
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
      _vendorNameCtrl,
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
      _vendorId = '';
      _linkedPurchaseIds = [];
    });
    _promiseDateCtrl.clear();
    _vendorNameCtrl.clear();
    _chequeNoCtrl.clear();
    _bankNameCtrl.clear();
    _amountCtrl.text = '0';
    _narrationCtrl.clear();
  }

  void _loadFromModel(PaymentPromiseModel model) {
    setState(() {
      _currentId = model.id;
      _promiseId = model.promiseId;
      _vendorId = model.vendorId;
      _linkedPurchaseIds = List<String>.from(model.linkedPurchaseIds);
    });
    _promiseDateCtrl.text = model.promiseDate;
    _vendorNameCtrl.text = model.vendorName;
    _chequeNoCtrl.text = model.chequeNo;
    _bankNameCtrl.text = model.bankName;
    _amountCtrl.text = model.amount.toStringAsFixed(2);
    _narrationCtrl.text = model.narration;
  }

  Map<String, dynamic> _buildPayload() => {
        'promiseType': 'payment',
        'entryDate': _entryDate,
        'promiseDate': _promiseDateCtrl.text,
        'vendorId': _vendorId,
        'vendorName': _vendorNameCtrl.text,
        'chequeNo': _chequeNoCtrl.text,
        'bankName': _bankNameCtrl.text,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'narration': _narrationCtrl.text,
        'linkedPurchaseIds': _linkedPurchaseIds,
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
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Saved successfully')));
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
        content: const Text('Delete this payment promise?'),
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
    final vendors = context.watch<VendorsController>().typedItems;
    final purchaseInvoices = context
        .watch<PurchaseInvoiceController>()
        .items
        .where((item) => _vendorId.isEmpty || item.vendorId == _vendorId)
        .toList();
    final totalLinked = purchaseInvoices
        .where((item) => _linkedPurchaseIds.contains(item.id))
        .fold<double>(0, (sum, item) => sum + item.totalPayable);
    final promiseAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final difference = totalLinked - promiseAmount;

    return InvoicingFormDialog(
      title: 'Post Dated Payment Promise',
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
                    value: _vendorId.isEmpty ? null : _vendorId,
                    decoration: _dec('Vendor'),
                    isExpanded: true,
                    items: vendors
                        .map(
                          (vendor) => DropdownMenuItem<String>(
                            value: vendor.id,
                            child: Text(
                              vendor.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final vendor = vendors.firstWhere((v) => v.id == value);
                      setState(() {
                        _vendorId = value;
                        _linkedPurchaseIds = [];
                      });
                      _vendorNameCtrl.text = vendor.text('name');
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
            'Linked Purchase Invoices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_vendorId.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Select a vendor to see invoices.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else if (purchaseInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No purchase invoices found for this vendor.',
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
                    DataColumn(label: Text('Purchase ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Total Payable'), numeric: true),
                  ],
                  rows: purchaseInvoices.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final purchase = entry.value;
                    final linked = _linkedPurchaseIds.contains(purchase.id);
                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return AppTheme.terra50;
                        }
                        return idx.isOdd
                            ? AppTheme.clayBg.withValues(alpha: 0.4)
                            : Colors.transparent;
                      }),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: linked,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _linkedPurchaseIds = [
                                    ..._linkedPurchaseIds,
                                    purchase.id,
                                  ];
                                } else {
                                  _linkedPurchaseIds = _linkedPurchaseIds
                                      .where((id) => id != purchase.id)
                                      .toList();
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(
                          Text(
                            purchase.purchaseId.isNotEmpty
                                ? purchase.purchaseId
                                : '—',
                          ),
                        ),
                        DataCell(
                          Text(
                            purchase.entryDate.length >= 10
                                ? purchase.entryDate.substring(0, 10)
                                : purchase.entryDate,
                          ),
                        ),
                        DataCell(
                          Text(AppUtils.fmtAmt(purchase.totalPayable)),
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
