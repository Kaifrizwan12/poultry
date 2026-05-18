import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/detail_line_card.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/purchase_order_controller.dart';
import '../controllers/send_order_controller.dart';
import '../models/send_order_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class SendOrderScreen extends StatefulWidget {
  const SendOrderScreen({super.key});

  @override
  State<SendOrderScreen> createState() => _SendOrderScreenState();
}

class _SendOrderScreenState extends State<SendOrderScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<SendOrderController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({SendOrderModel? initial}) async {
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<SendOrderController>()),
          ChangeNotifierProvider.value(
            value: context.read<PurchaseOrderController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<AccountsController>(),
          ),
        ],
        child: _SendOrderFormDialog(initial: initial),
      ),
    );
  }

  List<SendOrderModel> _visibleItems(SendOrderController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      return item.sendOrderId.toLowerCase().contains(q) ||
          item.vendorName.toLowerCase().contains(q) ||
          item.draftNo.toLowerCase().contains(q) ||
          item.draftDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SendOrderController>(
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
                      'Send Purchase Orders',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Send Order',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by order ID, vendor, draft no or date',
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
                          Icons.send_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No send orders yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Send Order'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!ctrl.isLoading && items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching send orders found.',
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
                        id: item.sendOrderId,
                        subtitle: item.vendorName,
                        meta: AppUtils.formatDate(item.draftDate),
                        amount: AppUtils.fmtAmt(item.totalOrderValue),
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
                            DataColumn(label: Text('Order ID')),
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Draft No')),
                            DataColumn(label: Text('Draft Date')),
                            DataColumn(label: Text('Draft Amt'), numeric: true),
                            DataColumn(label: Text('Order Value'), numeric: true),
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
                                DataCell(Text(item.sendOrderId)),
                                DataCell(Text(item.vendorName)),
                                DataCell(Text(item.draftNo)),
                                DataCell(Text(AppUtils.formatDate(item.draftDate))),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.draftAmount)),
                                ),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.totalOrderValue)),
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

class _SendOrderFormDialog extends StatefulWidget {
  const _SendOrderFormDialog({this.initial});

  final SendOrderModel? initial;

  @override
  State<_SendOrderFormDialog> createState() => _SendOrderFormDialogState();
}

class _SendOrderFormDialogState extends State<_SendOrderFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);

  String _poDocId = '';
  String _sendOrderId = '';
  String _vendorId = '';
  final _vendorNameCtrl = TextEditingController();
  final _draftNoCtrl = TextEditingController();
  final _draftDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _draftAmountCtrl = TextEditingController(text: '0');
  String _bankAccountId = '';
  final _bankAcNoCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _includeAllProductsWhenPrinting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _initFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _vendorNameCtrl.dispose();
    _draftNoCtrl.dispose();
    _draftDateCtrl.dispose();
    _draftAmountCtrl.dispose();
    _bankAcNoCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _initFromModel(SendOrderModel m) {
    _currentId = m.id;
    _poDocId = m.orderId;
    _vendorId = m.vendorId;
    _bankAccountId = m.bankAccountId;
    _includeAllProductsWhenPrinting = m.includeAllProductsWhenPrinting;
    _sendOrderId = m.sendOrderId;
    _vendorNameCtrl.text = m.vendorName;
    _draftNoCtrl.text = m.draftNo;
    _draftDateCtrl.text = m.draftDate;
    _draftAmountCtrl.text = m.draftAmount.toStringAsFixed(2);
    _bankAcNoCtrl.text = m.bankAcNo;
    _bankAccountNameCtrl.text = m.bankAccountName;
    _descriptionCtrl.text = m.description;
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _poDocId = '';
      _vendorId = '';
      _bankAccountId = '';
      _includeAllProductsWhenPrinting = false;
      _sendOrderId = '';
    });
    _vendorNameCtrl.clear();
    _draftNoCtrl.clear();
    _draftDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _draftAmountCtrl.text = '0';
    _bankAcNoCtrl.clear();
    _bankAccountNameCtrl.clear();
    _descriptionCtrl.clear();
    _itemsNotifier.value = [];
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'orderId': _poDocId,
      'vendorId': _vendorId,
      'vendorName': _vendorNameCtrl.text,
      'draftNo': _draftNoCtrl.text,
      'draftDate': _draftDateCtrl.text,
      'draftAmount': double.tryParse(_draftAmountCtrl.text) ?? 0,
      'bankAccountId': _bankAccountId,
      'bankAcNo': _bankAcNoCtrl.text,
      'bankAccountName': _bankAccountNameCtrl.text,
      'description': _descriptionCtrl.text,
      'includeAllProductsWhenPrinting': _includeAllProductsWhenPrinting,
      'items': _itemsNotifier.value,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final payload = _buildPayload();
      final ctrl = context.read<SendOrderController>();
      if (_currentId == null) {
        final record = await ctrl.add(payload);
        setState(() {
          _currentId = record.id;
          _sendOrderId = record.sendOrderId;
        });
      } else {
        await ctrl.updateItem(_currentId!, payload);
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
        content: const Text('Delete this send order?'),
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
      await context.read<SendOrderController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final orders = context.watch<PurchaseOrderController>().items;
    final accounts = context.watch<AccountsController>().typedItems;

    return InvoicingFormDialog(
      title: 'Send Purchase Order',
      badgeText: _sendOrderId.isNotEmpty ? 'Order ID: $_sendOrderId' : null,
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
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _poDocId.isEmpty ? null : _poDocId,
                    decoration: _dec('Purchase Order'),
                    isExpanded: true,
                    items: orders
                        .map(
                          (o) => DropdownMenuItem<String>(
                            value: o.id,
                            child: Text(
                              o.orderId.isNotEmpty
                                  ? '${o.orderId}  •  ${o.vendorName}'
                                  : o.vendorName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (docId) {
                      if (docId == null) return;
                      final po = orders.firstWhere((o) => o.id == docId);
                      setState(() {
                        _poDocId = docId;
                        _vendorId = po.vendorId;
                      });
                      _vendorNameCtrl.text = po.vendorName;
                      _itemsNotifier.value =
                          List<Map<String, dynamic>>.from(po.items);
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _vendorNameCtrl,
                      decoration: _dec('Vendor Name'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _draftNoCtrl,
                    decoration: _dec('Draft No'),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _draftDateCtrl,
                    decoration: _dec('Draft Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_draftDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _draftDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _draftAmountCtrl,
                    decoration: _dec('Draft Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _bankAccountId.isEmpty ? null : _bankAccountId,
                    decoration: _dec('Bank Account'),
                    isExpanded: true,
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.text('accountName'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final account = accounts.firstWhere((x) => x.id == val);
                      setState(() => _bankAccountId = val);
                      _bankAcNoCtrl.text = account.text('accountCode');
                      _bankAccountNameCtrl.text = account.text('accountName');
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _descriptionCtrl,
                    decoration: _dec('Description'),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _includeAllProductsWhenPrinting,
                      onChanged: (v) => setState(
                        () => _includeAllProductsWhenPrinting = v,
                      ),
                      activeColor: AppTheme.terra400,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Include All Products When Printing',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _itemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No items. Select a purchase order to populate.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              if (isMobile) {
                return Column(
                  children: items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final it = entry.value;
                    final qtyPacks =
                        ((it['qtyPacks'] as num?)?.toDouble() ?? 0);
                    final qtyLoose =
                        ((it['qtyLoose'] as num?)?.toDouble() ?? 0);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx == items.length - 1 ? 0 : 8,
                      ),
                      child: DetailLineCard(
                        index: idx,
                        title: '${it['productName'] ?? ''}',
                        subtitle: '${it['packingName'] ?? ''}',
                        amount: AppUtils.fmtAmt2(
                          ((it['lineGross'] as num?)?.toDouble() ?? 0),
                        ),
                        amountLabel:
                            'Price ${AppUtils.fmtAmt2(((it['price'] as num?)?.toDouble() ?? 0))}',
                        chips: [
                          'Qty(P) ${qtyPacks.toStringAsFixed(0)}',
                          'Qty(L) ${qtyLoose.toStringAsFixed(0)}',
                        ],
                      ),
                    );
                  }).toList(),
                );
              }
              return Container(
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
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Packing')),
                      DataColumn(label: Text('Qty(P)')),
                      DataColumn(label: Text('Qty(L)')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Gross')),
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
                          DataCell(Text('${it['productName'] ?? ''}')),
                          DataCell(Text('${it['packingName'] ?? ''}')),
                          DataCell(Text('${it['qtyPacks'] ?? ''}')),
                          DataCell(Text('${it['qtyLoose'] ?? ''}')),
                          DataCell(
                            Text(
                              ((it['price'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          DataCell(
                            Text(
                              ((it['lineGross'] as num?)?.toDouble() ?? 0)
                                  .toStringAsFixed(2),
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
