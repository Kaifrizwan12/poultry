import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/detail_line_card.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stock_expiry_controller.dart';
import '../models/stock_expiry_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class StockExpiryScreen extends StatefulWidget {
  const StockExpiryScreen({super.key});

  @override
  State<StockExpiryScreen> createState() => _StockExpiryScreenState();
}

class _StockExpiryScreenState extends State<StockExpiryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<StockExpiryController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({StockExpiryModel? initial}) async {
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<StockExpiryController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<ProductsController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<PackingsController>(),
          ),
        ],
        child: _StockExpiryFormDialog(initial: initial),
      ),
    );
  }

  List<StockExpiryModel> _visibleItems(StockExpiryController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      return item.expiryId.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockExpiryController>(
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
                      'Stock Expiry Invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Expiry Invoice',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by expiry ID or date',
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
                          Icons.event_busy_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No stock expiry invoices yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Expiry Invoice'),
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
                        id: item.expiryId,
                        meta: AppUtils.formatDate(item.date),
                        subtitle: '${item.items.length} item${item.items.length == 1 ? '' : 's'}',
                        amount: AppUtils.fmtAmt(item.netValue),
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
                            DataColumn(label: Text('Expiry ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Items'), numeric: true),
                            DataColumn(label: Text('Net Value'), numeric: true),
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
                                DataCell(Text(item.expiryId)),
                                DataCell(Text(AppUtils.formatDate(item.date))),
                                DataCell(Text('${item.items.length}')),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.netValue)),
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

class _StockExpiryFormDialog extends StatefulWidget {
  const _StockExpiryFormDialog({this.initial});

  final StockExpiryModel? initial;

  @override
  State<_StockExpiryFormDialog> createState() => _StockExpiryFormDialogState();
}

class _StockExpiryFormDialogState extends State<_StockExpiryFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingItem;
  int? _editingItemOriginalIndex;

  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  String _expiryId = '';

  String? _lineProductId;
  String _linePackingId = '';
  double _linePack = 1;
  final _expQtyPacksCtrl = TextEditingController(text: '0');
  final _expQtyLooseCtrl = TextEditingController(text: '0');
  final _damQtyPacksCtrl = TextEditingController(text: '0');
  final _damQtyLooseCtrl = TextEditingController(text: '0');
  double _lineCost = 0;
  double _lineValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _expQtyPacksCtrl.dispose();
    _expQtyLooseCtrl.dispose();
    _damQtyPacksCtrl.dispose();
    _damQtyLooseCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _loadFromModel(StockExpiryModel model) {
    _currentId = model.id;
    _expiryId = model.expiryId;
    _dateCtrl.text = model.date;
    _itemsNotifier.value = List<Map<String, dynamic>>.from(model.items);
  }

  void _clearLineEntry() {
    setState(() {
      _editingItem = null;
      _editingItemOriginalIndex = null;
      _lineProductId = null;
      _linePackingId = '';
      _linePack = 1;
      _lineCost = 0;
      _lineValue = 0;
    });
    _expQtyPacksCtrl.text = '0';
    _expQtyLooseCtrl.text = '0';
    _damQtyPacksCtrl.text = '0';
    _damQtyLooseCtrl.text = '0';
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _expiryId = '';
    });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _itemsNotifier.value = [];
    _clearLineEntry();
  }

  void _setLineFromItem(Map<String, dynamic> item) {
    setState(() {
      _editingItem = Map<String, dynamic>.from(item);
      _lineProductId = item['productId'] as String?;
      _linePackingId = '${item['packingId'] ?? ''}';
      _linePack = (item['pack'] as num?)?.toDouble() ?? 1;
      _lineCost = (item['cost'] as num?)?.toDouble() ?? 0;
      _lineValue = (item['value'] as num?)?.toDouble() ?? 0;
    });
    _expQtyPacksCtrl.text =
        ((item['expQtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _expQtyLooseCtrl.text =
        ((item['expQtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _damQtyPacksCtrl.text =
        ((item['damQtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _damQtyLooseCtrl.text =
        ((item['damQtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
  }

  void _startEditingItem(int index, Map<String, dynamic> item) {
    final updatedItems = [..._itemsNotifier.value];
    updatedItems.removeAt(index);
    _editingItemOriginalIndex = index;
    _itemsNotifier.value = updatedItems;
    _setLineFromItem(item);
  }

  void _cancelEditLineEntry() {
    final item = _editingItem;
    final idx = _editingItemOriginalIndex;
    _clearLineEntry();
    if (item == null) return;
    final items = [..._itemsNotifier.value];
    items.insert((idx ?? items.length).clamp(0, items.length), item);
    _itemsNotifier.value = items;
  }

  void _onLineProductChanged(String? productId) {
    if (productId == null) return;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    try {
      final product = products.firstWhere((p) => p.id == productId);
      final packingId = product.purPackingId;
      final cost = product.purchasePrice;
      double pack = 1;
      try {
        pack = packings
            .firstWhere((packing) => packing.id == packingId)
            .number('quantity');
      } catch (_) {}
      setState(() {
        _lineProductId = productId;
        _linePackingId = packingId;
        _linePack = pack;
        _lineCost = cost;
      });
      _recalcLineValue();
    } catch (_) {}
  }

  void _recalcLineValue() {
    final expPacks = double.tryParse(_expQtyPacksCtrl.text) ?? 0;
    final expLoose = double.tryParse(_expQtyLooseCtrl.text) ?? 0;
    final damPacks = double.tryParse(_damQtyPacksCtrl.text) ?? 0;
    final damLoose = double.tryParse(_damQtyLooseCtrl.text) ?? 0;
    setState(() {
      _lineValue =
          (expPacks * _linePack + expLoose + damPacks * _linePack + damLoose) *
              _lineCost;
    });
  }

  void _addLineItem() {
    if (_lineProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product')),
      );
      return;
    }
    final expPacks = double.tryParse(_expQtyPacksCtrl.text) ?? 0;
    final expLoose = double.tryParse(_expQtyLooseCtrl.text) ?? 0;
    final damPacks = double.tryParse(_damQtyPacksCtrl.text) ?? 0;
    final damLoose = double.tryParse(_damQtyLooseCtrl.text) ?? 0;
    if (expPacks + expLoose + damPacks + damLoose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be > 0')),
      );
      return;
    }
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    String productName = '';
    String packingName = '';
    try {
      productName = products.firstWhere((p) => p.id == _lineProductId).text(
            'name',
          );
    } catch (_) {}
    try {
      packingName = packings.firstWhere((p) => p.id == _linePackingId).text(
            'name',
          );
    } catch (_) {}
    final item = {
      'productId': _lineProductId,
      'productName': productName,
      'packingId': _linePackingId,
      'packingName': packingName,
      'pack': _linePack,
      'expQtyPacks': expPacks,
      'expQtyLoose': expLoose,
      'damQtyPacks': damPacks,
      'damQtyLoose': damLoose,
      'cost': _lineCost,
      'value': (expPacks * _linePack +
              expLoose +
              damPacks * _linePack +
              damLoose) *
          _lineCost,
    };
    _itemsNotifier.value = [..._itemsNotifier.value, item];
    _clearLineEntry();
  }

  Map<String, dynamic> _buildPayload() {
    final items = _itemsNotifier.value;
    final netValue = items.fold<double>(
      0,
      (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0),
    );
    return {
      'date': _dateCtrl.text,
      'items': items,
      'netValue': netValue,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<StockExpiryController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _expiryId = record.expiryId;
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
        content: const Text('Delete this expiry record?'),
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
      await context.read<StockExpiryController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final products = context.watch<ProductsController>().typedItems;
    final packings = context.watch<PackingsController>().typedItems;

    return InvoicingFormDialog(
      title: 'Stock Expiry Invoice',
      badgeText: _expiryId.isNotEmpty ? 'Expiry ID: $_expiryId' : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.cardDecor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
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
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _lineProductId,
                    decoration: _dec('Product'),
                    isExpanded: true,
                    items: products
                        .map(
                          (product) => DropdownMenuItem<String>(
                            value: product.id,
                            child: Text(
                              product.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onLineProductChanged,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _linePackingId.isEmpty ? null : _linePackingId,
                    decoration: _dec('Packing'),
                    isExpanded: true,
                    items: packings
                        .map(
                          (packing) => DropdownMenuItem<String>(
                            value: packing.id,
                            child: Text(
                              packing.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final packing =
                          packings.firstWhere((item) => item.id == value);
                      setState(() {
                        _linePackingId = value;
                        _linePack = packing.number('quantity');
                      });
                      _recalcLineValue();
                    },
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Pack'),
                      controller: TextEditingController(
                        text: _linePack.toStringAsFixed(0),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _expQtyPacksCtrl,
                    decoration: _dec('Exp Qty(P)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcLineValue(),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _expQtyLooseCtrl,
                    decoration: _dec('Exp Qty(L)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcLineValue(),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: TextFormField(
                    controller: _damQtyPacksCtrl,
                    decoration: _dec('Dam Qty(P)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcLineValue(),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: TextFormField(
                    controller: _damQtyLooseCtrl,
                    decoration: _dec('Dam Qty(L)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcLineValue(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Cost'),
                      controller: TextEditingController(
                        text: _lineCost.toStringAsFixed(2),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Value'),
                      controller: TextEditingController(
                        text: _lineValue.toStringAsFixed(2),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addLineItem,
                  icon: Icon(
                    _editingItem == null ? Icons.add : Icons.check,
                    size: 16,
                  ),
                  label: Text(_editingItem == null ? 'Add' : 'Update'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                if (_editingItem != null)
                  OutlinedButton(
                    onPressed: _cancelEditLineEntry,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _itemsNotifier,
            builder: (context, items, _) {
              final netValue = items.fold<double>(
                0,
                (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0),
              );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      children: items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx == items.length - 1 ? 0 : 8,
                          ),
                          child: DetailLineCard(
                            index: idx,
                            title: '${item['productName'] ?? ''}',
                            subtitle: '${item['packingName'] ?? ''}',
                            amount: AppUtils.fmtAmt2(
                              ((item['value'] as num?)?.toDouble() ?? 0),
                            ),
                            amountLabel:
                                'Cost ${AppUtils.fmtAmt2(((item['cost'] as num?)?.toDouble() ?? 0))}',
                            chips: [
                              'Pack ${item['pack'] ?? ''}',
                              'Exp(P) ${item['expQtyPacks'] ?? ''}',
                              'Exp(L) ${item['expQtyLoose'] ?? ''}',
                              'Dam(P) ${item['damQtyPacks'] ?? ''}',
                              'Dam(L) ${item['damQtyLoose'] ?? ''}',
                            ],
                            onEdit: () => _startEditingItem(idx, item),
                            onDelete: () {
                              final updatedItems = [...items];
                              updatedItems.removeAt(idx);
                              _itemsNotifier.value = updatedItems;
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
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 36,
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Packing')),
                          DataColumn(label: Text('Pack')),
                          DataColumn(label: Text('Exp Qty(P)')),
                          DataColumn(label: Text('Exp Qty(L)')),
                          DataColumn(label: Text('Dam Qty(P)')),
                          DataColumn(label: Text('Dam Qty(L)')),
                          DataColumn(label: Text('Cost')),
                          DataColumn(label: Text('Value')),
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
                              ? AppTheme.clayBg.withValues(alpha: 0.5)
                              : Colors.transparent;
                        }),
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(Text('${item['productName'] ?? ''}')),
                              DataCell(Text('${item['packingName'] ?? ''}')),
                              DataCell(Text('${item['pack'] ?? ''}')),
                              DataCell(Text('${item['expQtyPacks'] ?? ''}')),
                              DataCell(Text('${item['expQtyLoose'] ?? ''}')),
                              DataCell(Text('${item['damQtyPacks'] ?? ''}')),
                              DataCell(Text('${item['damQtyLoose'] ?? ''}')),
                              DataCell(
                                Text(
                                  ((item['cost'] as num?)?.toDouble() ?? 0)
                                      .toStringAsFixed(2),
                                ),
                              ),
                              DataCell(
                                Text(
                                  ((item['value'] as num?)?.toDouble() ?? 0)
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
                  Container(
                    color: AppTheme.clayBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Net Value: ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          netValue.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
