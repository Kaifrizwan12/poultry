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
import '../controllers/purchase_order_controller.dart';
import '../models/purchase_invoice_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';
import 'package:farm_mgt_auth/core/line_item_card.dart';


class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<PurchaseInvoiceController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({PurchaseInvoiceModel? initial}) async {
    final piCtrl = context.read<PurchaseInvoiceController>();
    final packCtrl = context.read<PackingsController>();
    final prodCtrl = context.read<ProductsController>();
    final unitCtrl = context.read<UnitsController>();
    final vendorCtrl = context.read<VendorsController>();
    final poCtrl = context.read<PurchaseOrderController>();

    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: piCtrl),
          ChangeNotifierProvider.value(value: packCtrl),
          ChangeNotifierProvider.value(value: prodCtrl),
          ChangeNotifierProvider.value(value: unitCtrl),
          ChangeNotifierProvider.value(value: vendorCtrl),
          ChangeNotifierProvider.value(value: poCtrl),
        ],
        child: _PurchaseInvoiceFormDialog(initial: initial),
      ),
    );
  }

  List<PurchaseInvoiceModel> _applyFilters(PurchaseInvoiceController ctrl) {
    List<PurchaseInvoiceModel> items;
    switch (_filter) {
      case 'pending':
        items = ctrl.pendingItems;
        break;
      case 'saved':
        items = ctrl.items.where((i) => i.status == 'saved').toList();
        break;
      default:
        items = ctrl.items;
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) {
      return i.purchaseId.toLowerCase().contains(q) ||
          i.vendorName.toLowerCase().contains(q) ||
          i.vendorBillNo.toLowerCase().contains(q) ||
          i.entryDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseInvoiceController>(
      builder: (context, ctrl, _) {
        final items = _applyFilters(ctrl);
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
                      'Purchase Invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Purchase Invoice',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveSearchFilterBar(
                search: TextFormField(
                  controller: _searchCtrl,
                  decoration: AppTheme.inputDecoration(
                    null,
                    hintText: 'Search by purchase ID, vendor, bill no or date',
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
              else if (ctrl.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No purchase invoices yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Purchase Invoice'),
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
                      final inv = items[i];
                      return RecordCard(
                        id: inv.purchaseId,
                        subtitle: inv.vendorName,
                        meta: AppUtils.formatDate(inv.entryDate),
                        amount: AppUtils.fmtAmt(inv.netValue),
                        badge: _StatusBadge(status: inv.status),
                        onTap: () => _openForm(initial: inv),
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
                            DataColumn(label: Text('Purchase ID')),
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Bill No')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Net'), numeric: true),
                            DataColumn(label: Text('Balance'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final inv = entry.value;
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
                              onSelectChanged: (_) => _openForm(initial: inv),
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text(inv.purchaseId)),
                                DataCell(
                                  Text(
                                    inv.vendorName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(inv.vendorBillNo)),
                                DataCell(
                                  Text(
                                    inv.entryDate.length >= 10
                                        ? inv.entryDate.substring(0, 10)
                                        : inv.entryDate,
                                  ),
                                ),
                                DataCell(_StatusBadge(status: inv.status)),
                                DataCell(
                                  Text(AppUtils.fmtAmt(inv.netValue)),
                                ),
                                DataCell(
                                  Text(
                                    AppUtils.fmtAmt(inv.remBalance),
                                    style: TextStyle(
                                      color: inv.remBalance > 0
                                          ? AppTheme.dangerText
                                          : AppTheme.successText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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

class _PurchaseInvoiceFormDialog extends StatefulWidget {
  const _PurchaseInvoiceFormDialog({this.initial});

  final PurchaseInvoiceModel? initial;

  @override
  State<_PurchaseInvoiceFormDialog> createState() =>
      _PurchaseInvoiceFormDialogState();
}

class _PurchaseInvoiceFormDialogState extends State<_PurchaseInvoiceFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingItem;
  int? _editingItemOriginalIndex;
  int _entryRowKey = 0;

  final _entryDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _vendorBillNoCtrl = TextEditingController();
  final _billDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _vendorNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _fTaxCtrl = TextEditingController(text: '0');
  final _totalSEDCtrl = TextEditingController(text: '0');
  final _spcDiscCtrl = TextEditingController(text: '0');
  final _prevCreditCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController(text: '0');

  String _vendorId = '';
  String _linkedOrderId = '';
  String _purchaseId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _initFromModel(widget.initial!);
  }

  @override
  void dispose() {
    for (final c in [
      _entryDateCtrl,
      _vendorBillNoCtrl,
      _billDateCtrl,
      _vendorNameCtrl,
      _cityCtrl,
      _disc2PercentCtrl,
      _fTaxCtrl,
      _totalSEDCtrl,
      _spcDiscCtrl,
      _prevCreditCtrl,
      _paidAmountCtrl,
    ]) {
      c.dispose();
    }
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _initFromModel(PurchaseInvoiceModel m) {
    _currentId = m.id;
    _purchaseId = m.purchaseId;
    _vendorId = m.vendorId;
    _linkedOrderId = m.orderId;
    _entryDateCtrl.text = m.entryDate;
    _vendorBillNoCtrl.text = m.vendorBillNo;
    _billDateCtrl.text = m.billDate;
    _vendorNameCtrl.text = m.vendorName;
    _cityCtrl.text = m.city;
    _disc2PercentCtrl.text = m.disc2Percent.toStringAsFixed(2);
    _fTaxCtrl.text = m.fTax.toStringAsFixed(2);
    _totalSEDCtrl.text = m.totalSED.toStringAsFixed(2);
    _spcDiscCtrl.text = m.spcDisc.toStringAsFixed(2);
    _prevCreditCtrl.text = m.prevCredit.toStringAsFixed(2);
    _paidAmountCtrl.text = m.paidAmount.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _purchaseId = '';
      _vendorId = '';
      _linkedOrderId = '';
      _editingItem = null;
      _entryRowKey++;
    });
    _entryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _vendorBillNoCtrl.clear();
    _billDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _vendorNameCtrl.clear();
    _cityCtrl.clear();
    for (final c in [
      _disc2PercentCtrl,
      _fTaxCtrl,
      _totalSEDCtrl,
      _spcDiscCtrl,
      _prevCreditCtrl,
      _paidAmountCtrl,
    ]) {
      c.text = '0';
    }
    _itemsNotifier.value = [];
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0;
    double salesTax = 0;
    for (final it in items) {
      gross += (it['lineGross'] as num?)?.toDouble() ?? 0;
      salesTax += (it['lineTax'] as num?)?.toDouble() ?? 0;
    }
    final disc2 = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final fTax = double.tryParse(_fTaxCtrl.text) ?? 0;
    final totalSED = double.tryParse(_totalSEDCtrl.text) ?? 0;
    final spcDisc = double.tryParse(_spcDiscCtrl.text) ?? 0;
    final prevCredit = double.tryParse(_prevCreditCtrl.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;
    final lineDiscounts = items.fold<double>(
      0,
      (s, it) => s + ((it['lineDisc'] as num?)?.toDouble() ?? 0),
    );
    final discounts = gross * (disc2 / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final netValue = invoiceValue + salesTax + fTax + totalSED - spcDisc;
    final totalPayable = netValue + prevCredit;
    final remBalance = totalPayable - paidAmount;
    return {
      'gross': gross,
      'disc2Percent': disc2,
      'discounts': discounts,
      'invoiceValue': invoiceValue,
      'salesTax': salesTax,
      'fTax': fTax,
      'totalSED': totalSED,
      'spcDisc': spcDisc,
      'netValue': netValue,
      'totalPayable': totalPayable,
      'paidAmount': paidAmount,
      'remBalance': remBalance,
    };
  }

  Map<String, dynamic> _buildPayload(String status) {
    final items = _itemsNotifier.value;
    final totals = _computeTotals(items);
    return {
      'entryDate': _entryDateCtrl.text,
      'vendorBillNo': _vendorBillNoCtrl.text,
      'billDate': _billDateCtrl.text,
      'orderId': _linkedOrderId,
      'vendorId': _vendorId,
      'vendorName': _vendorNameCtrl.text,
      'city': _cityCtrl.text,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'fTax': double.tryParse(_fTaxCtrl.text) ?? 0,
      'totalSED': double.tryParse(_totalSEDCtrl.text) ?? 0,
      'spcDisc': double.tryParse(_spcDiscCtrl.text) ?? 0,
      'prevCredit': double.tryParse(_prevCreditCtrl.text) ?? 0,
      'paidAmount': double.tryParse(_paidAmountCtrl.text) ?? 0,
      'items': items,
      'status': status,
      ...totals,
    };
  }

  Future<void> _save(String status) async {
    if (_vendorId.isEmpty) {
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
      final ctrl = context.read<PurchaseInvoiceController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload(status));
        setState(() {
          _currentId = record.id;
          _purchaseId = record.purchaseId;
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
        content: const Text('Delete this purchase invoice?'),
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
      await context.read<PurchaseInvoiceController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
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

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsController>().typedItems;
    final vendors = context.watch<VendorsController>().typedItems;
    final orders = context.watch<PurchaseOrderController>().items;

    return InvoicingFormDialog(
      title: 'Purchase Invoice',
      badgeText: _purchaseId.isNotEmpty ? 'PI: $_purchaseId' : null,
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
                    controller: _entryDateCtrl,
                    decoration: _dec('Entry Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_entryDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _entryDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _vendorBillNoCtrl,
                    decoration: _dec('Vendor Bill No'),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _billDateCtrl,
                    decoration: _dec('Bill Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_billDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _billDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _linkedOrderId.isEmpty ? null : _linkedOrderId,
                    decoration: _dec('Link to PO (optional)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      ...orders.map(
                        (o) => DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(
                            o.orderId.isNotEmpty
                                ? '${o.orderId}  •  ${o.vendorName}'
                                : o.vendorName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (docId) {
                      setState(() => _linkedOrderId = docId ?? '');
                      if (docId != null && docId.isNotEmpty) {
                        final po = orders.firstWhere((o) => o.id == docId);
                        setState(() => _vendorId = po.vendorId);
                        _vendorNameCtrl.text = po.vendorName;
                        _cityCtrl.text = po.city;
                        _itemsNotifier.value =
                            List<Map<String, dynamic>>.from(po.items);
                        setState(() {
                          _editingItem = null;
                          _entryRowKey++;
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
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              v.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final vendor = vendors.firstWhere((x) => x.id == val);
                      setState(() => _vendorId = val);
                      _vendorNameCtrl.text = vendor.text('name');
                      _cityCtrl.text = vendor.text('city');
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: _dec('City'),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _disc2PercentCtrl,
                    decoration: _dec('Disc2 %'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _fTaxCtrl,
                    decoration: _dec('F.Tax'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _totalSEDCtrl,
                    decoration: _dec('Total SED'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _spcDiscCtrl,
                    decoration: _dec('Spc Disc'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _prevCreditCtrl,
                    decoration: _dec('Prev Credit'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 120,
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
            isPurchase: true,
            products: products,
            initialValues: _editingItem,
            onAdd: (item) {
              _itemsNotifier.value = [..._itemsNotifier.value, item];
              setState(() {
                _editingItem = null;
                _editingItemOriginalIndex = null;
              });
            },
            onCancel: _editingItem != null ? _cancelEditingItem : null,
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
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
                              onEdit: () {
                                final u = [..._itemsNotifier.value];
                                final it = u.removeAt(entry.key);
                                _itemsNotifier.value = u;
                                setState(() {
                                  _editingItem = it;
                                  _editingItemOriginalIndex = entry.key;
                                  _entryRowKey++;
                                });
                              },
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
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Packing')),
                            DataColumn(label: Text('Qty(P)')),
                            DataColumn(label: Text('Qty(L)')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Disc%')),
                            DataColumn(label: Text('Tax%')),
                            DataColumn(label: Text('Gross')),
                            DataColumn(label: Text('Val incST')),
                            DataColumn(label: Text('')),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final it = entry.value;
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
                                DataCell(Text(it['productName'] ?? '')),
                                DataCell(Text(it['packingName'] ?? '')),
                                DataCell(Text('${it['qtyPacks'] ?? ''}')),
                                DataCell(Text('${it['qtyLoose'] ?? ''}')),
                                DataCell(
                                  Text(
                                    (it['price'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (it['discPercent'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (it['salesTaxPercent'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (it['lineGross'] as num?)
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (it['lineValueIncST'] as num?)
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
                                          size: 16,
                                          color: AppTheme.terra600,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit',
                                        onPressed: () {
                                          final updated = [...items];
                                          final item = updated.removeAt(idx);
                                          _itemsNotifier.value = updated;
                                          setState(() {
                                            _editingItem = item;
                                            _editingItemOriginalIndex = idx;
                                            _entryRowKey++;
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
                                          final updated = [...items];
                                          updated.removeAt(idx);
                                          _itemsNotifier.value = updated;
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
                        'fTax',
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPending ? AppTheme.warningBg : AppTheme.successBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPending ? 'Pending' : 'Saved',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPending ? AppTheme.warningText : AppTheme.successText,
        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.terra50 : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.terra400 : AppTheme.softBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.terra800 : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
