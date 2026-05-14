import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/discount_schemes_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sales_invoice_controller.dart';
import '../models/sales_invoice_model.dart';
import '../widgets/invoice_line_item_row.dart';
import '../widgets/invoice_totals_footer.dart';
import '../widgets/record_browser_dialog.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);

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

  void _loadFromModel(SalesInvoiceModel m) {
    setState(() {
      _currentId = m.id;
      _saleId = m.saleId;
      _customerId = m.customerId;
      _townId = m.townId;
      _sectorId = m.sectorId;
      _salesmanId = m.salesmanId;
    });
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
    final netValue = invoiceValue + salesTax + fTax + expense + totalSED - spcDisc;
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
      final payload = _buildPayload(status);
      final ctrl = context.read<SalesInvoiceController>();
      if (_currentId == null) {
        final record = await ctrl.add(payload);
        setState(() {
          _currentId = record.id;
          _saleId = record.saleId;
        });
      } else {
        await ctrl.updateItem(_currentId!, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                status == 'saved' ? 'Saved successfully' : 'Saved as pending')));
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
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await context.read<SalesInvoiceController>().deleteItem(_currentId!);
        _clearForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _openRecords({bool pendingOnly = false}) async {
    final ctrl = context.read<SalesInvoiceController>();
    if (ctrl.items.isEmpty) {
      await ctrl.fetchAll();
    }
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<SalesInvoiceModel>(
      context: context,
      records: pendingOnly ? ctrl.pendingItems : ctrl.items,
      title: 'Sales Invoices',
      getBusinessId: (m) => m.saleId,
      getTitle: (m) => '${m.saleId}  •  ${m.customerName}',
      getSubtitle: (m) => '${m.entryDate.substring(0, 10)}  |  ${m.status}  |  Rs ${m.totalPayable.toStringAsFixed(0)}',
      statusField: 'status',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products       = context.read<ProductsController>().typedItems;
    final customers      = context.read<CustomersController>().typedItems;
    final salesmen       = context.read<SalesmenController>().typedItems;
    final towns          = context.read<TownsController>().typedItems;
    final sectors        = context.read<SectorsController>().typedItems;
    final discSchemes    = context.read<DiscountSchemesController>().typedItems;

    return Column(
      children: [
        // Header
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Text('Sales Invoice',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 16),
                    if (_saleId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Header card
                Container(
                  decoration: AppTheme.cardDecor,
                  padding: AppTheme.cardPadding,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _entryDateCtrl,
                          decoration: _dec('Entry Date'),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(_entryDateCtrl.text) ??
                                  DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _entryDateCtrl.text =
                                    picked.toIso8601String().substring(0, 10);
                              });
                            }
                          },
                          readOnly: true,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _customerId.isEmpty ? null : _customerId,
                          decoration: _dec('Customer'),
                          isExpanded: true,
                          items: customers.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.text('name'),
                                  overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final c = customers.firstWhere((x) => x.id == val);
                            setState(() {
                              _customerId = val;
                              _townId     = c.townId;
                              _sectorId   = c.sectorId;
                              _salesmanId = c.salesmanId;
                            });
                            _customerNameCtrl.text = c.name;
                            // auto-fill salesman name
                            try {
                              final sm = salesmen.firstWhere((s) => s.id == c.salesmanId);
                              _salesmanNameCtrl.text = sm.name;
                            } catch (_) {}
                            // auto-apply customer discount scheme
                            if (c.discountSchemeId.isNotEmpty) {
                              try {
                                final ds = discSchemes.firstWhere((d) => d.id == c.discountSchemeId);
                                final today = DateTime.now();
                                final from = ds.validFrom.isNotEmpty ? DateTime.tryParse(ds.validFrom) : null;
                                final to   = ds.validTo.isNotEmpty   ? DateTime.tryParse(ds.validTo)   : null;
                                final active = (from == null || !today.isBefore(from)) &&
                                               (to   == null || !today.isAfter(to));
                                if (active) {
                                  if (ds.type == 'percentage') {
                                    _disc2PercentCtrl.text = ds.value.toStringAsFixed(2);
                                  } else if (ds.type == 'flat') {
                                    _spcDiscCtrl.text = ds.value.toStringAsFixed(2);
                                  }
                                }
                              } catch (_) {}
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _townId.isEmpty ? null : _townId,
                          decoration: _dec('Town'),
                          isExpanded: true,
                          items: towns.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.text('name'),
                                  overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) =>
                              setState(() => _townId = val ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _sectorId.isEmpty ? null : _sectorId,
                          decoration: _dec('Sector'),
                          isExpanded: true,
                          items: sectors.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.text('name'),
                                  overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) =>
                              setState(() => _sectorId = val ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _salesmanId.isEmpty ? null : _salesmanId,
                          decoration: _dec('Salesman'),
                          isExpanded: true,
                          items: salesmen.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.text('name'),
                                  overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _salesmanId = val);
                            try {
                              _salesmanNameCtrl.text =
                                  salesmen.firstWhere((s) => s.id == val).text('name');
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

                // Line item row
                InvoiceLineItemRow(
                  isPurchase: false,
                  products: products,
                  onAdd: (item) {
                    _itemsNotifier.value = [..._itemsNotifier.value, item];
                  },
                ),
                const SizedBox(height: 12),

                // Items table
                RepaintBoundary(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _itemsNotifier,
                    builder: (context, items, _) {
                      if (items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No items added yet.',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: AppTheme.cardDecor,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    AppTheme.clayBg),
                                dataRowMinHeight: 36,
                                dataRowMaxHeight: 44,
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Packing')),
                                  DataColumn(label: Text('Pack')),
                                  DataColumn(label: Text('Qty(P)')),
                                  DataColumn(label: Text('Qty(L)')),
                                  DataColumn(label: Text('Bonus')),
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
                                    color: WidgetStateProperty.resolveWith(
                                      (states) => idx.isOdd
                                          ? AppTheme.clayBg.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                    ),
                                    cells: [
                                      DataCell(Text('${idx + 1}')),
                                      DataCell(Text(it['productName'] ?? '')),
                                      DataCell(Text(it['packingName'] ?? '')),
                                      DataCell(Text('${it['pack'] ?? ''}')),
                                      DataCell(Text('${it['qtyPacks'] ?? ''}')),
                                      DataCell(Text('${it['qtyLoose'] ?? ''}')),
                                      DataCell(Text('${it['bonus'] ?? 0}')),
                                      DataCell(Text(
                                          (it['price'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text(
                                          (it['discPercent'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text(
                                          (it['salesTaxPercent'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text(
                                          (it['lineGross'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(Text(
                                          (it['lineValueIncST'] as num?)?.toStringAsFixed(2) ?? '0')),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: AppTheme.dangerText),
                                        onPressed: () {
                                          final updated = [...items];
                                          updated.removeAt(idx);
                                          _itemsNotifier.value = updated;
                                        },
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
                              'gross', 'discounts', 'invoiceValue', 'salesTax',
                              'fTax', 'expense', 'totalSED', 'spcDisc',
                              'netValue', 'totalPayable', 'paidAmount', 'remBalance'
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

        // Action bar
        Container(
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TextButton(
                  onPressed: _isSaving ? null : () => _save('pending'),
                  child: const Text('Pending')),
              TextButton(
                  onPressed: _clearForm, child: const Text('Clear')),
              TextButton(
                  onPressed: () => _openRecords(),
                  child: const Text('Records')),
              TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Print not yet implemented'))),
                  child: const Text('Print')),
              TextButton(
                  onPressed: _currentId != null ? _remove : null,
                  child: const Text('Remove')),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save('saved'),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: _clearForm, child: const Text('Close')),
            ],
          ),
        ),
      ],
    );
  }
}
