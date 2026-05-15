import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sales_invoice_controller.dart';
import '../controllers/sales_return_controller.dart';
import '../models/sales_return_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key, required this.returnType});

  final String returnType;

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<SalesReturnController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({SalesReturnModel? initial}) async {
    final returnCtrl = context.read<SalesReturnController>();
    final invoiceCtrl = context.read<SalesInvoiceController>();
    if (invoiceCtrl.items.isEmpty) {
      await invoiceCtrl.fetchAll();
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: returnCtrl),
          ChangeNotifierProvider.value(value: invoiceCtrl),
          ChangeNotifierProvider.value(
            value: context.read<CustomersController>(),
          ),
          ChangeNotifierProvider.value(value: context.read<SalesmenController>()),
          ChangeNotifierProvider.value(value: context.read<ProductsController>()),
          ChangeNotifierProvider.value(value: context.read<PackingsController>()),
          ChangeNotifierProvider.value(value: context.read<UnitsController>()),
        ],
        child: _SalesReturnFormDialog(
          returnType: widget.returnType,
          initial: initial,
        ),
      ),
    );
  }

  List<SalesReturnModel> _visibleItems(SalesReturnController ctrl) {
    List<SalesReturnModel> items = ctrl.items
        .where((item) => item.returnType == widget.returnType)
        .toList();
    switch (_filter) {
      case 'pending':
        items = items.where((item) => item.text('status') == 'pending').toList();
        break;
      case 'saved':
        items = items.where((item) => item.text('status') == 'saved').toList();
        break;
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.returnId.toLowerCase().contains(q) ||
          item.customerName.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.saleId.toLowerCase().contains(q) ||
          item.returnDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.returnType == 'with_invoice'
        ? 'Sales Returns With Invoice'
        : 'Sales Returns Without Invoice';
    return Consumer<SalesReturnController>(
      builder: (context, ctrl, _) {
        final scopedItems = ctrl.items
            .where((item) => item.returnType == widget.returnType)
            .toList();
        final items = _visibleItems(ctrl);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Sales Return'),
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
                            'Search by return ID, customer, salesman, sale or date',
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
              if (scopedItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_return_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No sales returns yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Sales Return'),
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
                            DataColumn(label: Text('Return ID')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(label: Text('Sale Ref')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Net'), numeric: true),
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
                                DataCell(Text(item.returnId)),
                                DataCell(Text(item.customerName)),
                                DataCell(Text(item.salesmanName)),
                                DataCell(
                                  Text(
                                    item.saleId.isEmpty
                                        ? 'Without Invoice'
                                        : item.saleId,
                                  ),
                                ),
                                DataCell(Text(item.returnDate)),
                                DataCell(
                                  _StatusBadge(status: item.text('status')),
                                ),
                                DataCell(Text(item.netValue.toStringAsFixed(0))),
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

class _SalesReturnFormDialog extends StatefulWidget {
  const _SalesReturnFormDialog({
    required this.returnType,
    this.initial,
  });

  final String returnType;
  final SalesReturnModel? initial;

  @override
  State<_SalesReturnFormDialog> createState() => _SalesReturnFormDialogState();
}

class _SalesReturnFormDialogState extends State<_SalesReturnFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingItem;
  int _entryRowKey = 0;

  final _returnDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _customerNameCtrl = TextEditingController();
  final _salesmanNameCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _sedCtrl = TextEditingController(text: '0');
  final _specialDiscountCtrl = TextEditingController(text: '0');
  final _prevCreditCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController(text: '0');

  String _customerId = '';
  String _salesmanId = '';
  String _saleId = '';
  String _returnId = '';
  bool _toMainStore = true;
  bool _isFullReturn = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    for (final controller in [
      _returnDateCtrl,
      _customerNameCtrl,
      _salesmanNameCtrl,
      _disc2PercentCtrl,
      _sedCtrl,
      _specialDiscountCtrl,
      _prevCreditCtrl,
      _paidAmountCtrl,
    ]) {
      controller.dispose();
    }
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _loadFromModel(SalesReturnModel model) {
    _currentId = model.id;
    _customerId = model.customerId;
    _salesmanId = model.salesmanId;
    _saleId = model.saleId;
    _returnId = model.returnId;
    _toMainStore = model.toMainStore;
    _returnDateCtrl.text = model.returnDate;
    _customerNameCtrl.text = model.customerName;
    _salesmanNameCtrl.text = model.salesmanName;
    _disc2PercentCtrl.text = model.disc2Percent.toStringAsFixed(2);
    _sedCtrl.text = model.sed.toStringAsFixed(2);
    _specialDiscountCtrl.text = model.specialDiscount.toStringAsFixed(2);
    _prevCreditCtrl.text = model.prevCredit.toStringAsFixed(2);
    _paidAmountCtrl.text = model.paidAmount.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(model.items);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _customerId = '';
      _salesmanId = '';
      _saleId = '';
      _returnId = '';
      _toMainStore = true;
      _isFullReturn = false;
      _editingItem = null;
      _entryRowKey++;
    });
    _returnDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _customerNameCtrl.clear();
    _salesmanNameCtrl.clear();
    for (final controller in [
      _disc2PercentCtrl,
      _sedCtrl,
      _specialDiscountCtrl,
      _prevCreditCtrl,
      _paidAmountCtrl,
    ]) {
      controller.text = '0';
    }
    _itemsNotifier.value = [];
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0;
    double salesTax = 0;
    for (final item in items) {
      gross += (item['lineGross'] as num?)?.toDouble() ?? 0;
      salesTax += (item['lineTax'] as num?)?.toDouble() ?? 0;
    }
    final disc2Percent = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final sed = double.tryParse(_sedCtrl.text) ?? 0;
    final specialDiscount = double.tryParse(_specialDiscountCtrl.text) ?? 0;
    final prevCredit = double.tryParse(_prevCreditCtrl.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(
      0,
      (sum, item) => sum + ((item['lineDisc'] as num?)?.toDouble() ?? 0),
    );
    final discounts = gross * (disc2Percent / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final netValue = invoiceValue + salesTax + sed - specialDiscount;
    final totalPayable = netValue + prevCredit;
    final remBalance = totalPayable - paidAmount;
    return {
      'gross': gross,
      'disc2Percent': disc2Percent,
      'discounts': discounts,
      'invoiceValue': invoiceValue,
      'salesTax': salesTax,
      'totalSED': sed,
      'spcDisc': specialDiscount,
      'netValue': netValue,
      'totalPayable': totalPayable,
      'paidAmount': paidAmount,
      'remBalance': remBalance,
    };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    return {
      'returnType': widget.returnType,
      'returnDate': _returnDateCtrl.text,
      'customerId': _customerId,
      'customerName': _customerNameCtrl.text,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'saleId': _saleId,
      'toMainStore': _toMainStore,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'sed': double.tryParse(_sedCtrl.text) ?? 0,
      'specialDiscount': double.tryParse(_specialDiscountCtrl.text) ?? 0,
      'prevCredit': double.tryParse(_prevCreditCtrl.text) ?? 0,
      'paidAmount': double.tryParse(_paidAmountCtrl.text) ?? 0,
      'items': items,
      'status': status,
      ..._computeTotals(items),
    };
  }

  Future<void> _save(String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<SalesReturnController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload(status));
        setState(() {
          _currentId = record.id;
          _returnId = record.returnId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload(status));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'saved' ? 'Saved successfully' : 'Saved as pending',
            ),
          ),
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
        content: const Text('Delete this sales return?'),
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
      await context.read<SalesReturnController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  void _startEditingItem(int index, Map<String, dynamic> item) {
    final updatedItems = [..._itemsNotifier.value];
    updatedItems.removeAt(index);
    setState(() {
      _editingItem = Map<String, dynamic>.from(item);
      _entryRowKey++;
    });
    _itemsNotifier.value = updatedItems;
  }

  void _addItem(Map<String, dynamic> item) {
    setState(() {
      _editingItem = null;
      _entryRowKey++;
    });
    _itemsNotifier.value = [..._itemsNotifier.value, item];
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsController>().typedItems;
    final customers = context.watch<CustomersController>().typedItems;
    final salesmen = context.watch<SalesmenController>().typedItems;
    final salesInvoices = context.watch<SalesInvoiceController>().items;
    final isWithInvoice = widget.returnType == 'with_invoice';
    final title = isWithInvoice
        ? 'Sales Return (With Invoice)'
        : 'Sales Return (Without Invoice)';

    return InvoicingFormDialog(
      title: title,
      badgeText: _returnId.isNotEmpty ? 'Return ID: $_returnId' : null,
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
                    controller: _returnDateCtrl,
                    decoration: _dec('Return Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_returnDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _returnDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                if (isWithInvoice) ...[
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: _saleId.isEmpty ? null : _saleId,
                      decoration: _dec('Sales Invoice'),
                      isExpanded: true,
                      items: salesInvoices
                          .map(
                            (invoice) => DropdownMenuItem<String>(
                              value: invoice.id,
                              child: Text(
                                invoice.saleId.isNotEmpty
                                    ? invoice.saleId
                                    : invoice.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final invoice =
                            salesInvoices.firstWhere((i) => i.id == value);
                        setState(() {
                          _saleId = value;
                          _customerId = invoice.customerId;
                          _salesmanId = invoice.salesmanId;
                          _editingItem = null;
                          _entryRowKey++;
                        });
                        _customerNameCtrl.text = invoice.customerName;
                        _salesmanNameCtrl.text = invoice.salesmanName;
                        _itemsNotifier.value =
                            List<Map<String, dynamic>>.from(invoice.items);
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _isFullReturn = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFullReturn
                          ? AppTheme.terra400
                          : AppTheme.softBorder,
                    ),
                    child: const Text('Full Return'),
                  ),
                ],
                if (!isWithInvoice) ...[
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
                        final customer =
                            customers.firstWhere((c) => c.id == value);
                        setState(() => _customerId = value);
                        _customerNameCtrl.text = customer.text('name');
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
                            salesmen.firstWhere((s) => s.id == value);
                        setState(() => _salesmanId = value);
                        _salesmanNameCtrl.text = salesman.text('name');
                      },
                    ),
                  ),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _toMainStore,
                      onChanged: (value) =>
                          setState(() => _toMainStore = value),
                      activeColor: AppTheme.terra400,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'To Main Store',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _disc2PercentCtrl,
                    decoration: _dec('Disc2 %'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _sedCtrl,
                    decoration: _dec('SED'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _specialDiscountCtrl,
                    decoration: _dec('Spc Disc'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _prevCreditCtrl,
                    decoration: _dec('Prev Credit'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _paidAmountCtrl,
                    decoration: _dec('Paid Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InvoiceLineItemRow(
            key: ValueKey(_entryRowKey),
            isPurchase: false,
            products: products,
            initialValues: _editingItem,
            onAdd: _addItem,
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _itemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No items added yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
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
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Packing')),
                          DataColumn(label: Text('Qty(P)')),
                          DataColumn(label: Text('Qty(L)')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Disc%')),
                          DataColumn(label: Text('Gross')),
                          DataColumn(label: Text('')),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith(
                              (_) => idx.isOdd
                                  ? AppTheme.clayBg.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(Text(item['productName'] ?? '')),
                              DataCell(Text(item['packingName'] ?? '')),
                              DataCell(Text('${item['qtyPacks'] ?? ''}')),
                              DataCell(Text('${item['qtyLoose'] ?? ''}')),
                              DataCell(
                                Text(
                                  (item['price'] as num?)?.toStringAsFixed(2) ??
                                      '0',
                                ),
                              ),
                              DataCell(
                                Text(
                                  (item['discPercent'] as num?)
                                          ?.toStringAsFixed(2) ??
                                      '0',
                                ),
                              ),
                              DataCell(
                                Text(
                                  (item['lineGross'] as num?)
                                          ?.toStringAsFixed(2) ??
                                      '0',
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
                                        color: AppTheme.textSecondary,
                                      ),
                                      onPressed: () =>
                                          _startEditingItem(idx, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppTheme.dangerText,
                                      ),
                                      onPressed: () {
                                        final updatedItems = [...items];
                                        updatedItems.removeAt(idx);
                                        _itemsNotifier.value = updatedItems;
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
                  InvoiceTotalsFooter(
                    totals: _computeTotals(items),
                    visibleKeys: const [
                      'gross',
                      'discounts',
                      'invoiceValue',
                      'salesTax',
                      'totalSED',
                      'spcDisc',
                      'netValue',
                      'totalPayable',
                      'paidAmount',
                      'remBalance',
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      footer: InvoicingActionBar(
        onSave: () => _save('saved'),
        isSaving: _isSaving,
        onPending: _isSaving ? null : () => _save('pending'),
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
