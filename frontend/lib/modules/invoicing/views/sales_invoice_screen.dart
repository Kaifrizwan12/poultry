import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/discount_schemes_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';

import '../controllers/sales_invoice_controller.dart';
import '../models/sales_invoice_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/invoicing_action_bar.dart';

// ─── List Page ────────────────────────────────────────────────────────────────

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<SalesInvoiceController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({SalesInvoiceModel? initial}) async {
    final siCtrl = context.read<SalesInvoiceController>();
    final prodCtrl = context.read<ProductsController>();
    final custCtrl = context.read<CustomersController>();
    final smCtrl = context.read<SalesmenController>();
    final townCtrl = context.read<TownsController>();
    final secCtrl = context.read<SectorsController>();
    final discCtrl = context.read<DiscountSchemesController>();
    final packCtrl = context.read<PackingsController>();
    final unitsCtrl = context.read<UnitsController>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: siCtrl),
          ChangeNotifierProvider.value(value: prodCtrl),
          ChangeNotifierProvider.value(value: custCtrl),
          ChangeNotifierProvider.value(value: smCtrl),
          ChangeNotifierProvider.value(value: townCtrl),
          ChangeNotifierProvider.value(value: secCtrl),
          ChangeNotifierProvider.value(value: discCtrl),
          ChangeNotifierProvider.value(value: packCtrl),
          ChangeNotifierProvider.value(value: unitsCtrl),
        ],
        child: _SalesInvoiceFormDialog(initial: initial),
      ),
    );
  }

  List<SalesInvoiceModel> _applyFilters(SalesInvoiceController ctrl) {
    List<SalesInvoiceModel> items;
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
    if (q.isNotEmpty) {
      items = items
          .where((i) =>
              i.customerName.toLowerCase().contains(q) ||
              i.saleId.toLowerCase().contains(q) ||
              i.salesmanName.toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesInvoiceController>(
      builder: (context, ctrl, _) {
        final items = _applyFilters(ctrl);

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Text('Sales Invoices',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Invoice'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Search + filter chips ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchCtrl,
                      decoration: AppTheme.inputDecoration(
                        null,
                        hintText: 'Search by customer, salesman or sale ID',
                        prefixIcon: const Icon(Icons.search_outlined, size: 18),
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
                      onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Saved',
                      selected: _filter == 'saved',
                      onTap: () => setState(() => _filter = 'saved')),
                  const SizedBox(width: 6),
                  _FilterChip(
                      label: 'Pending',
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending')),
                ],
              ),
              const SizedBox(height: 12),

              // ── List ─────────────────────────────────────────────────────
              if (ctrl.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 52, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text('No invoices yet.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Invoice'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No matches for "${_searchCtrl.text}".',
                        style: const TextStyle(color: AppTheme.textSecondary)),
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
                            DataColumn(label: Text('Sale ID')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Total'), numeric: true),
                            DataColumn(label: Text('Balance'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final inv = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
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
                                DataCell(Text(inv.saleId)),
                                DataCell(Text(inv.customerName,
                                    overflow: TextOverflow.ellipsis)),
                                DataCell(Text(inv.salesmanName,
                                    overflow: TextOverflow.ellipsis)),
                                DataCell(Text(inv.entryDate.length >= 10
                                    ? inv.entryDate.substring(0, 10)
                                    : inv.entryDate)),
                                DataCell(_StatusBadge(status: inv.status)),
                                DataCell(
                                    Text(inv.totalPayable.toStringAsFixed(0))),
                                DataCell(Text(
                                  inv.remBalance.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: inv.remBalance > 0
                                        ? AppTheme.dangerText
                                        : AppTheme.successText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
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

// ─── Small helpers ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.terra100 : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.terra400 : AppTheme.softBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.terra800 : AppTheme.textSecondary,
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

// ─── Form Dialog ──────────────────────────────────────────────────────────────

class _SalesInvoiceFormDialog extends StatefulWidget {
  const _SalesInvoiceFormDialog({this.initial});
  final SalesInvoiceModel? initial;

  @override
  State<_SalesInvoiceFormDialog> createState() =>
      _SalesInvoiceFormDialogState();
}

class _SalesInvoiceFormDialogState extends State<_SalesInvoiceFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final _itemsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  // When non-null an existing row is being edited; the entry row is pre-filled.
  Map<String, dynamic>? _editingItem;
  int _entryRowKey = 0; // incremented to force InvoiceLineItemRow rebuild

  final _entryDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _customerNameCtrl = TextEditingController();
  final _salesmanNameCtrl = TextEditingController();
  final _prevDebitCtrl = TextEditingController(text: '0');
  final _disc2PercentCtrl = TextEditingController(text: '0');
  final _fTaxCtrl = TextEditingController(text: '0');
  final _expenseCtrl = TextEditingController(text: '0');
  final _totalSEDCtrl = TextEditingController(text: '0');
  final _spcDiscCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController(text: '0');

  String _customerId = '';
  String _townId = '';
  String _sectorId = '';
  String _salesmanId = '';
  String _saleId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _initFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _entryDateCtrl.dispose();
    _customerNameCtrl.dispose();
    _salesmanNameCtrl.dispose();
    _prevDebitCtrl.dispose();
    _disc2PercentCtrl.dispose();
    _fTaxCtrl.dispose();
    _expenseCtrl.dispose();
    _totalSEDCtrl.dispose();
    _spcDiscCtrl.dispose();
    _paidAmountCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _initFromModel(SalesInvoiceModel m) {
    _currentId = m.id;
    _saleId = m.saleId;
    _customerId = m.customerId;
    _townId = m.townId;
    _sectorId = m.sectorId;
    _salesmanId = m.salesmanId;
    _entryDateCtrl.text = m.entryDate;
    _customerNameCtrl.text = m.customerName;
    _salesmanNameCtrl.text = m.salesmanName;
    _prevDebitCtrl.text = m.prevDebit.toStringAsFixed(2);
    _disc2PercentCtrl.text = m.disc2Percent.toStringAsFixed(2);
    _fTaxCtrl.text = m.fTax.toStringAsFixed(2);
    _expenseCtrl.text = m.expense.toStringAsFixed(2);
    _totalSEDCtrl.text = m.totalSED.toStringAsFixed(2);
    _spcDiscCtrl.text = m.spcDisc.toStringAsFixed(2);
    _paidAmountCtrl.text = m.paidAmount.toStringAsFixed(2);
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _saleId = '';
      _customerId = '';
      _townId = '';
      _sectorId = '';
      _salesmanId = '';
    });
    _entryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _customerNameCtrl.clear();
    _salesmanNameCtrl.clear();
    _prevDebitCtrl.text = '0';
    _disc2PercentCtrl.text = '0';
    _fTaxCtrl.text = '0';
    _expenseCtrl.text = '0';
    _totalSEDCtrl.text = '0';
    _spcDiscCtrl.text = '0';
    _paidAmountCtrl.text = '0';
    _itemsNotifier.value = [];
  }

  Map<String, double> _computeTotals(List<Map<String, dynamic>> items) {
    double gross = 0, salesTax = 0;
    for (final it in items) {
      gross += (it['lineGross'] as num?)?.toDouble() ?? 0;
      salesTax += (it['lineTax'] as num?)?.toDouble() ?? 0;
    }
    final disc2Percent = double.tryParse(_disc2PercentCtrl.text) ?? 0;
    final fTax = double.tryParse(_fTaxCtrl.text) ?? 0;
    final expense = double.tryParse(_expenseCtrl.text) ?? 0;
    final totalSED = double.tryParse(_totalSEDCtrl.text) ?? 0;
    final spcDisc = double.tryParse(_spcDiscCtrl.text) ?? 0;
    final prevDebit = double.tryParse(_prevDebitCtrl.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;

    final lineDiscounts = items.fold<double>(
        0, (s, it) => s + ((it['lineDisc'] as num?)?.toDouble() ?? 0));
    final discounts = gross * (disc2Percent / 100) + lineDiscounts;
    final invoiceValue = gross - discounts;
    final netValue =
        invoiceValue + salesTax + fTax + expense + totalSED - spcDisc;
    final totalPayable = netValue + prevDebit;
    final remBalance = totalPayable - paidAmount;

    return {
      'gross': gross,
      'disc2Percent': disc2Percent,
      'discounts': discounts,
      'invoiceValue': invoiceValue,
      'salesTax': salesTax,
      'fTax': fTax,
      'expense': expense,
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
      'customerId': _customerId,
      'customerName': _customerNameCtrl.text,
      'townId': _townId,
      'sectorId': _sectorId,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'prevDebit': double.tryParse(_prevDebitCtrl.text) ?? 0,
      'disc2Percent': double.tryParse(_disc2PercentCtrl.text) ?? 0,
      'fTax': double.tryParse(_fTaxCtrl.text) ?? 0,
      'expense': double.tryParse(_expenseCtrl.text) ?? 0,
      'totalSED': double.tryParse(_totalSEDCtrl.text) ?? 0,
      'spcDisc': double.tryParse(_spcDiscCtrl.text) ?? 0,
      'paidAmount': double.tryParse(_paidAmountCtrl.text) ?? 0,
      'items': items,
      'status': status,
      ...totals,
    };
  }

  Future<void> _save(String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<SalesInvoiceController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload(status));
        setState(() {
          _currentId = record.id;
          _saleId = record.saleId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload(status));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(status == 'saved'
                ? 'Invoice saved successfully'
                : 'Saved as pending')));
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
        content: const Text('Delete this invoice?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<SalesInvoiceController>().deleteItem(_currentId!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsController>().typedItems;
    final customers = context.watch<CustomersController>().typedItems;
    final salesmen = context.watch<SalesmenController>().typedItems;
    final towns = context.watch<TownsController>().typedItems;
    final sectors = context.watch<SectorsController>().typedItems;
    final discSchemes = context.watch<DiscountSchemesController>().typedItems;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final dialogWidth = isMobile
        ? size.width
        : size.width < AppTheme.dialogDesktopWidth + 80
            ? size.width - 40
            : AppTheme.dialogDesktopWidth;
    final dialogHeight = isMobile
        ? size.height
        : size.height < AppTheme.dialogDesktopHeight + 64
            ? size.height - 32
            : AppTheme.dialogDesktopHeight;

    return Dialog(
        insetPadding: isMobile
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: AppTheme.dialogRadius),
        child: ClipRRect(
          borderRadius: AppTheme.dialogRadius,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                // ── Title bar ──────────────────────────────────────────────
                Container(
                  color: AppTheme.surfaceWhite,
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Sales Invoice',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 12),
                      if (_saleId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.terra50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.terra200),
                          ),
                          child: Text('Sale ID: $_saleId',
                              style: const TextStyle(
                                  color: AppTheme.terra800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppTheme.textSecondary,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // ── Scrollable form body ────────────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header fields
                            Container(
                              decoration: AppTheme.cardDecor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                                          initialDate: DateTime.tryParse(
                                                  _entryDateCtrl.text) ??
                                              DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null && mounted) {
                                          setState(() {
                                            _entryDateCtrl.text = picked
                                                .toIso8601String()
                                                .substring(0, 10);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String>(
                                      value: _customerId.isEmpty
                                          ? null
                                          : _customerId,
                                      decoration: _dec('Customer'),
                                      isExpanded: true,
                                      items: customers
                                          .map((c) => DropdownMenuItem(
                                              value: c.id,
                                              child: Text(c.text('name'),
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val == null) return;
                                        final c = customers
                                            .firstWhere((x) => x.id == val);
                                        setState(() {
                                          _customerId = val;
                                          _townId = c.townId;
                                          _sectorId = c.sectorId;
                                          _salesmanId = c.salesmanId;
                                        });
                                        _customerNameCtrl.text = c.name;
                                        try {
                                          final sm = salesmen.firstWhere(
                                              (s) => s.id == c.salesmanId);
                                          _salesmanNameCtrl.text = sm.name;
                                        } catch (_) {}
                                        if (c.discountSchemeId.isNotEmpty) {
                                          try {
                                            final ds = discSchemes.firstWhere(
                                                (d) =>
                                                    d.id == c.discountSchemeId);
                                            final today = DateTime.now();
                                            final from = ds.validFrom.isNotEmpty
                                                ? DateTime.tryParse(
                                                    ds.validFrom)
                                                : null;
                                            final to = ds.validTo.isNotEmpty
                                                ? DateTime.tryParse(ds.validTo)
                                                : null;
                                            final active = (from == null ||
                                                    !today.isBefore(from)) &&
                                                (to == null ||
                                                    !today.isAfter(to));
                                            if (active) {
                                              if (ds.type == 'percentage') {
                                                _disc2PercentCtrl.text =
                                                    ds.value.toStringAsFixed(2);
                                              } else if (ds.type == 'flat') {
                                                _spcDiscCtrl.text =
                                                    ds.value.toStringAsFixed(2);
                                              }
                                            }
                                          } catch (_) {}
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String>(
                                      value: _townId.isEmpty ? null : _townId,
                                      decoration: _dec('Town'),
                                      isExpanded: true,
                                      items: towns
                                          .map((t) => DropdownMenuItem(
                                              value: t.id,
                                              child: Text(t.text('name'),
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _townId = val ?? ''),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _sectorId.isEmpty ? null : _sectorId,
                                      decoration: _dec('Sector'),
                                      isExpanded: true,
                                      items: sectors
                                          .map((s) => DropdownMenuItem(
                                              value: s.id,
                                              child: Text(s.text('name'),
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _sectorId = val ?? ''),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String>(
                                      value: _salesmanId.isEmpty
                                          ? null
                                          : _salesmanId,
                                      decoration: _dec('Salesman'),
                                      isExpanded: true,
                                      items: salesmen
                                          .map((s) => DropdownMenuItem(
                                              value: s.id,
                                              child: Text(s.text('name'),
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val == null) return;
                                        setState(() => _salesmanId = val);
                                        try {
                                          _salesmanNameCtrl.text = salesmen
                                              .firstWhere((s) => s.id == val)
                                              .text('name');
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: TextFormField(
                                      controller: _prevDebitCtrl,
                                      decoration: _dec('Prev Debit'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
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
                                      controller: _expenseCtrl,
                                      decoration: _dec('Expense'),
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

                            // Line item entry row — key forces rebuild when editing
                            InvoiceLineItemRow(
                              key: ValueKey(_entryRowKey),
                              isPurchase: false,
                              products: products,
                              initialValues: _editingItem,
                              onAdd: (item) {
                                _itemsNotifier.value = [
                                  ..._itemsNotifier.value,
                                  item,
                                ];
                                setState(() => _editingItem = null);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Items table
                            RepaintBoundary(
                              child: ValueListenableBuilder<
                                  List<Map<String, dynamic>>>(
                                valueListenable: _itemsNotifier,
                                builder: (context, items, _) {
                                  if (items.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No items added yet.',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary)),
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: AppTheme.cardDecor,
                                        child: HorizontalScrollWheel(
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    AppTheme.clayBg),
                                            columnSpacing:
                                                AppTheme.tableColSpacing,
                                            horizontalMargin:
                                                AppTheme.tableHMargin,
                                            dataRowMinHeight:
                                                AppTheme.tableRowMin,
                                            dataRowMaxHeight:
                                                AppTheme.tableRowMax,
                                            headingRowHeight:
                                                AppTheme.tableHeadingH,
                                            columns: const [
                                              DataColumn(label: Text('#')),
                                              DataColumn(
                                                  label: Text('Product')),
                                              DataColumn(
                                                  label: Text('Packing')),
                                              DataColumn(label: Text('Pack')),
                                              DataColumn(label: Text('Qty(P)')),
                                              DataColumn(label: Text('Qty(L)')),
                                              DataColumn(label: Text('Bonus')),
                                              DataColumn(label: Text('Price')),
                                              DataColumn(label: Text('Disc%')),
                                              DataColumn(label: Text('Tax%')),
                                              DataColumn(label: Text('Gross')),
                                              DataColumn(
                                                  label: Text('Val incST')),
                                              DataColumn(label: Text('')),
                                            ],
                                            rows: items
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final idx = entry.key;
                                              final it = entry.value;
                                              return DataRow(
                                                color: WidgetStateProperty
                                                    .resolveWith((states) => idx
                                                            .isOdd
                                                        ? AppTheme.clayBg
                                                            .withValues(
                                                                alpha: 0.5)
                                                        : Colors.transparent),
                                                cells: [
                                                  DataCell(Text('${idx + 1}')),
                                                  DataCell(Text(
                                                      it['productName'] ?? '')),
                                                  DataCell(Text(
                                                      it['packingName'] ?? '')),
                                                  DataCell(Text(
                                                      '${it['pack'] ?? ''}')),
                                                  DataCell(Text(
                                                      '${it['qtyPacks'] ?? ''}')),
                                                  DataCell(Text(
                                                      '${it['qtyLoose'] ?? ''}')),
                                                  DataCell(Text(
                                                      '${it['bonus'] ?? 0}')),
                                                  DataCell(Text(
                                                      (it['price'] as num?)
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0')),
                                                  DataCell(Text(
                                                      (it['discPercent']
                                                                  as num?)
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0')),
                                                  DataCell(Text(
                                                      (it['salesTaxPercent']
                                                                  as num?)
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0')),
                                                  DataCell(Text(
                                                      (it['lineGross'] as num?)
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0')),
                                                  DataCell(Text(
                                                      (it['lineValueIncST']
                                                                  as num?)
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0')),
                                                  DataCell(Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit_outlined,
                                                            size: 16,
                                                            color: AppTheme
                                                                .terra600),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        tooltip: 'Edit',
                                                        onPressed: () {
                                                          final updated = [
                                                            ...items
                                                          ];
                                                          final item = updated
                                                              .removeAt(idx);
                                                          _itemsNotifier.value =
                                                              updated;
                                                          setState(() {
                                                            _editingItem = item;
                                                            _entryRowKey++;
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(width: 6),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            size: 16,
                                                            color: AppTheme
                                                                .dangerText),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        tooltip: 'Delete',
                                                        onPressed: () {
                                                          final updated = [
                                                            ...items
                                                          ];
                                                          updated.removeAt(idx);
                                                          _itemsNotifier.value =
                                                              updated;
                                                        },
                                                      ),
                                                    ],
                                                  )),
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
                                          'expense',
                                          'totalSED',
                                          'spcDisc',
                                          'netValue',
                                          'totalPayable',
                                          'paidAmount',
                                          'remBalance'
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Action bar ─────────────────────────────────────────────
                const Divider(height: 1, thickness: 1),
                InvoicingActionBar(
                  onSave: () => _save('saved'),
                  isSaving: _isSaving,
                  onPending: _isSaving ? null : () => _save('pending'),
                  onClear: _clearForm,
                  onRemove: _remove,
                  canRemove: _currentId != null,
                ),
              ],
            ),
          ),
        ));
  }
}
