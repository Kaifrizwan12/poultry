import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/responsive_search_filter_bar.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/purchase_invoice_controller.dart';
import '../controllers/purchase_return_controller.dart';
import '../models/purchase_return_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';
import 'package:farm_mgt_auth/core/line_item_card.dart';


class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key, required this.returnType});

  final String returnType;

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<PurchaseReturnController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({PurchaseReturnModel? initial}) async {
    final returnCtrl = context.read<PurchaseReturnController>();
    final invoiceCtrl = context.read<PurchaseInvoiceController>();
    if (invoiceCtrl.items.isEmpty) {
      await invoiceCtrl.fetchAll();
    }
    if (!mounted) return;

    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: returnCtrl),
          ChangeNotifierProvider.value(value: invoiceCtrl),
          ChangeNotifierProvider.value(value: context.read<ProductsController>()),
          ChangeNotifierProvider.value(value: context.read<PackingsController>()),
          ChangeNotifierProvider.value(value: context.read<UnitsController>()),
          ChangeNotifierProvider.value(value: context.read<VendorsController>()),
        ],
        child: _PurchaseReturnFormDialog(
          returnType: widget.returnType,
          initial: initial,
        ),
      ),
    );
  }

  List<PurchaseReturnModel> _visibleItems(PurchaseReturnController ctrl) {
    List<PurchaseReturnModel> items = ctrl.items
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
          item.vendorName.toLowerCase().contains(q) ||
          item.purchaseInvoiceId.toLowerCase().contains(q) ||
          item.returnDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.returnType == 'with_invoice'
        ? 'Purchase Returns With Invoice'
        : 'Purchase Returns Without Invoice';
    return Consumer<PurchaseReturnController>(
      builder: (context, ctrl, _) {
        final scopedItems = ctrl.items
            .where((item) => item.returnType == widget.returnType)
            .toList();
        final items = _visibleItems(ctrl);
        final isMobile = MediaQuery.of(context).size.width < 600;
        final piLookup = {
          for (final i in context.read<PurchaseInvoiceController>().items)
            i.id: i.purchaseId
        };
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Purchase Return',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveSearchFilterBar(
                search: TextFormField(
                  controller: _searchCtrl,
                  decoration: AppTheme.inputDecoration(
                    null,
                    hintText: 'Search by return ID, vendor, invoice ID or date',
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
              else if (scopedItems.isEmpty)
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
                          'No purchase returns yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Purchase Return'),
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
              else if (isMobile)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return RecordCard(
                        id: item.returnId,
                        subtitle: item.vendorName,
                        meta: AppUtils.formatDate(item.returnDate),
                        amount: AppUtils.fmtAmt(item.netValue),
                        badge: _StatusBadge(status: item.text('status')),
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
                            DataColumn(label: Text('Return ID')),
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Invoice Ref')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Items'), numeric: true),
                            DataColumn(label: Text('Net'), numeric: true),
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
                                DataCell(Text(item.returnId)),
                                DataCell(Text(item.vendorName)),
                                DataCell(
                                  Text(
                                    item.purchaseInvoiceRef.isNotEmpty
                                        ? item.purchaseInvoiceRef
                                        : item.purchaseInvoiceId.isEmpty
                                            ? 'Without Invoice'
                                            : piLookup[item.purchaseInvoiceId] ?? '—',
                                  ),
                                ),
                                DataCell(Text(AppUtils.formatDate(item.returnDate))),
                                DataCell(
                                  _StatusBadge(status: item.text('status')),
                                ),
                                DataCell(Text('${item.items.length}')),
                                DataCell(Text(AppUtils.fmtAmt(item.netValue))),
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

class _PurchaseReturnFormDialog extends StatefulWidget {
  const _PurchaseReturnFormDialog({
    required this.returnType,
    this.initial,
  });

  final String returnType;
  final PurchaseReturnModel? initial;

  @override
  State<_PurchaseReturnFormDialog> createState() =>
      _PurchaseReturnFormDialogState();
}

class _PurchaseReturnFormDialogState extends State<_PurchaseReturnFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingItem;
  int? _editingItemOriginalIndex;
  int _entryRowKey = 0;

  final _returnDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _vendorNameCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _fTaxPercentCtrl = TextEditingController(text: '0');

  String _vendorId = '';
  String _purchaseInvoiceId = '';
  String _purchaseInvoiceRef = '';
  String _returnId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _returnDateCtrl.dispose();
    _vendorNameCtrl.dispose();
    _disc2PercentCtrl.dispose();
    _fTaxPercentCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _loadFromModel(PurchaseReturnModel model) {
    _currentId = model.id;
    _vendorId = model.vendorId;
    _purchaseInvoiceId = model.purchaseInvoiceId;
    _purchaseInvoiceRef = model.purchaseInvoiceRef;
    _returnId = model.returnId;
    _returnDateCtrl.text = model.returnDate;
    _vendorNameCtrl.text = model.vendorName;
    _disc2PercentCtrl.text = model.disc2Percent.toStringAsFixed(2);
    _fTaxPercentCtrl.text = model.fTaxPercent.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(model.items);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _vendorId = '';
      _purchaseInvoiceId = '';
      _purchaseInvoiceRef = '';
      _returnId = '';
      _editingItem = null;
      _entryRowKey++;
      _editingItemOriginalIndex = null;
    });
    _returnDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _vendorNameCtrl.clear();
    _disc2PercentCtrl.text = '0';
    _fTaxPercentCtrl.text = '0';
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
    final fTaxPercent = double.tryParse(_fTaxPercentCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(
      0,
      (sum, item) => sum + ((item['lineDisc'] as num?)?.toDouble() ?? 0),
    );
    final discounts = gross * (disc2Percent / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final furtherTaxValue = invoiceValue * (fTaxPercent / 100);
    final netValue = invoiceValue + salesTax + furtherTaxValue;
    return {
      'gross': gross,
      'disc2Percent': disc2Percent,
      'discounts': discounts,
      'invoiceValue': invoiceValue,
      'salesTax': salesTax,
      'fTaxPercent': fTaxPercent,
      'furtherTaxValue': furtherTaxValue,
      'netValue': netValue,
    };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    return {
      'returnType': widget.returnType,
      'returnDate': _returnDateCtrl.text,
      'vendorId': _vendorId,
      'vendorName': _vendorNameCtrl.text,
      'purchaseInvoiceId': _purchaseInvoiceId,
      'purchaseInvoiceRef': _purchaseInvoiceRef,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'fTaxPercent': double.tryParse(_fTaxPercentCtrl.text) ?? 0,
      'items': items,
      'status': status,
      ..._computeTotals(items),
    };
  }

  Future<void> _save(String status) async {
    if (widget.returnType == 'with_invoice' && _purchaseInvoiceId.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purchase invoice')));
    }
    return;
    }
    if (widget.returnType != 'with_invoice' && _vendorId.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')));
    }
    return;
    }
    if (_itemsNotifier.value.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')));
    }
    return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<PurchaseReturnController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload(status));
        setState(() {
          _currentId = record.id;
          _returnId = record.returnId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload(status));
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(status == 'saved' ? 'Saved successfully' : 'Saved as pending'),
      ));
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
        content: const Text('Delete this purchase return?'),
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
      await context.read<PurchaseReturnController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  void _startEditingItem(int index, Map<String, dynamic> item) {
    final updatedItems = [..._itemsNotifier.value];
    updatedItems.removeAt(index);
    setState(() {
      _editingItem = Map<String, dynamic>.from(item);
      _editingItemOriginalIndex = index;
      _entryRowKey++;
    });
    _itemsNotifier.value = updatedItems;
  }

  void _cancelEditingItem() {
    final item = _editingItem;
    final idx = _editingItemOriginalIndex;
    setState(() {
      _editingItem = null;
      _editingItemOriginalIndex = null;
      _entryRowKey++;
    });
    if (item == null) return;
    final items = [..._itemsNotifier.value];
    items.insert((idx ?? items.length).clamp(0, items.length), item);
    _itemsNotifier.value = items;
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
    final vendors = context.watch<VendorsController>().typedItems;
    final purchaseInvoices = context.watch<PurchaseInvoiceController>().items;
    final isWithInvoice = widget.returnType == 'with_invoice';
    final title = isWithInvoice
        ? 'Purchase Return (With Invoice)'
        : 'Purchase Return (Without Invoice)';

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
                if (isWithInvoice)
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value:
                          _purchaseInvoiceId.isEmpty ? null : _purchaseInvoiceId,
                      decoration: _dec('Purchase Invoice'),
                      isExpanded: true,
                      items: purchaseInvoices
                          .map(
                            (invoice) => DropdownMenuItem<String>(
                              value: invoice.id,
                              child: Text(
                                invoice.purchaseId.isNotEmpty
                                    ? invoice.purchaseId
                                    : invoice.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final invoice =
                            purchaseInvoices.firstWhere((i) => i.id == value);
                        setState(() {
                          _purchaseInvoiceId = value;
                          _purchaseInvoiceRef = invoice.purchaseId;
                          _vendorId = invoice.vendorId;
                          _editingItem = null;
                          _entryRowKey++;
                        });
                        _vendorNameCtrl.text = invoice.vendorName;
                        _itemsNotifier.value =
                            List<Map<String, dynamic>>.from(invoice.items);
                      },
                    ),
                  ),
                if (!isWithInvoice)
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
                        setState(() => _vendorId = value);
                        _vendorNameCtrl.text = vendor.text('name');
                      },
                    ),
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
                    controller: _fTaxPercentCtrl,
                    decoration: _dec('FTax %'),
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
            isPurchase: true,
            products: products,
            initialValues: _editingItem,
            onCancel: _editingItem != null ? _cancelEditingItem : null,
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
              if (MediaQuery.of(context).size.width < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: AppTheme.cardDecor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items.asMap().entries.map((entry) {
                          return LineItemCard(
                            index: entry.key,
                            item: entry.value,
                            onEdit: () => _startEditingItem(entry.key, entry.value),
                            onDelete: () {
                              final u = [..._itemsNotifier.value];
                              u.removeAt(entry.key);
                              _itemsNotifier.value = u;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
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
                          DataColumn(label: Text('Gross')),
                          DataColumn(label: Text('')),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
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
                      'furtherTaxValue',
                      'netValue',
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
