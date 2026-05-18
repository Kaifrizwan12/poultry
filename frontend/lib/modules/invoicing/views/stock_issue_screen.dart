import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/core/line_item_card.dart';
import 'package:farm_mgt_auth/core/record_card.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stock_issue_controller.dart';
import '../models/stock_issue_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';

class StockIssueScreen extends StatefulWidget {
  const StockIssueScreen({super.key, required this.issueType});

  final String issueType;

  @override
  State<StockIssueScreen> createState() => _StockIssueScreenState();
}

class _StockIssueScreenState extends State<StockIssueScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<StockIssueController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({StockIssueModel? initial}) async {
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<StockIssueController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<SalesmenController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<ProductsController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<PackingsController>(),
          ),
        ],
        child: _StockIssueFormDialog(
          issueType: widget.issueType,
          initial: initial,
        ),
      ),
    );
  }

  List<StockIssueModel> _visibleItems(StockIssueController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final items =
        ctrl.items.where((item) => item.issueType == widget.issueType).toList();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.issueId.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isReturn = widget.issueType == 'return';
    final title =
        isReturn ? 'Stock Returns from Salesmen' : 'Stock Issues to Salesmen';
    return Consumer<StockIssueController>(
      builder: (context, ctrl, _) {
        final scopedItems = ctrl.items
            .where((item) => item.issueType == widget.issueType)
            .toList();
        final items = _visibleItems(ctrl);
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
                    label: isReturn ? 'New Stock Return' : 'New Stock Issue',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by issue ID, salesman or date',
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
              if (ctrl.isLoading)
                const Expanded(child: SizedBox.shrink())
              else if (scopedItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isReturn
                              ? 'No stock returns yet.'
                              : 'No stock issues yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            isReturn
                                ? 'Create First Stock Return'
                                : 'Create First Stock Issue',
                          ),
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
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return RecordCard(
                        id: item.issueId,
                        subtitle: item.salesmanName,
                        meta: AppUtils.formatDate(item.date),
                        amount: AppUtils.fmtAmt(item.netValue),
                        badge: _MiniBadge(
                          label:
                              '${item.items.length} item${item.items.length == 1 ? '' : 's'}',
                        ),
                        onTap: () => _openForm(initial: item),
                      );
                    },
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
                            DataColumn(label: Text('Issue ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Salesman')),
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
                                DataCell(Text(item.issueId)),
                                DataCell(Text(item.date)),
                                DataCell(Text(item.salesmanName)),
                                DataCell(Text('${item.items.length}')),
                                DataCell(
                                  Text(item.netValue.toStringAsFixed(0)),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.clayBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StockIssueFormDialog extends StatefulWidget {
  const _StockIssueFormDialog({required this.issueType, this.initial});

  final String issueType;
  final StockIssueModel? initial;

  @override
  State<_StockIssueFormDialog> createState() => _StockIssueFormDialogState();
}

class _StockIssueFormDialogState extends State<_StockIssueFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingItem;
  int? _editingItemOriginalIndex;

  final _dateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _salesmanNameCtrl = TextEditingController();
  String _salesmanId = '';
  String _originalIssueId = '';
  String _issueId = '';

  String? _lineProductId;
  String _linePackingId = '';
  double _linePack = 1;
  final _lineQtyPacksCtrl = TextEditingController(text: '0');
  final _lineQtyLooseCtrl = TextEditingController(text: '0');
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
    _salesmanNameCtrl.dispose();
    _lineQtyPacksCtrl.dispose();
    _lineQtyLooseCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _loadFromModel(StockIssueModel model) {
    _currentId = model.id;
    _salesmanId = model.salesmanId;
    _originalIssueId = model.originalIssueId;
    _issueId = model.issueId;
    _dateCtrl.text = model.date;
    _salesmanNameCtrl.text = model.salesmanName;
    _itemsNotifier.value = List<Map<String, dynamic>>.from(model.items);
  }

  void _clearLineEntry() {
    setState(() {
      _lineProductId = null;
      _linePackingId = '';
      _linePack = 1;
      _lineCost = 0;
      _lineValue = 0;
      _editingItem = null;
      _editingItemOriginalIndex = null;
    });
    _lineQtyPacksCtrl.text = '0';
    _lineQtyLooseCtrl.text = '0';
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _salesmanId = '';
      _originalIssueId = '';
      _issueId = '';
    });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear();
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
    _lineQtyPacksCtrl.text =
        ((item['qtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _lineQtyLooseCtrl.text =
        ((item['qtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
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
        final packing = packings.firstWhere((p) => p.id == packingId);
        pack = packing.number('quantity');
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
    final qtyPacks = double.tryParse(_lineQtyPacksCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_lineQtyLooseCtrl.text) ?? 0;
    setState(() {
      _lineValue = (qtyPacks * _linePack + qtyLoose) * _lineCost;
    });
  }

  void _addLineItem() {
    if (_lineProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product')),
      );
      return;
    }
    final qtyPacks = double.tryParse(_lineQtyPacksCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_lineQtyLooseCtrl.text) ?? 0;
    if (qtyPacks + qtyLoose <= 0) {
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
      'qtyPacks': qtyPacks,
      'qtyLoose': qtyLoose,
      'cost': _lineCost,
      'value': (qtyPacks * _linePack + qtyLoose) * _lineCost,
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
      'issueType': widget.issueType,
      'date': _dateCtrl.text,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'originalIssueId': _originalIssueId,
      'items': items,
      'netValue': netValue,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<StockIssueController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _issueId = record.issueId;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this stock issue?'),
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
      await context.read<StockIssueController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final salesmen = context.watch<SalesmenController>().typedItems;
    final products = context.watch<ProductsController>().typedItems;
    final packings = context.watch<PackingsController>().typedItems;
    final issues = context.watch<StockIssueController>().items;
    final isReturn = widget.issueType == 'return';
    final title =
        isReturn ? 'Stock Return from Salesman' : 'Stock Issue to Salesman';

    return InvoicingFormDialog(
      title: title,
      badgeText: _issueId.isNotEmpty ? 'Issue ID: $_issueId' : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.cardDecor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
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
                          salesmen.firstWhere((item) => item.id == value);
                      setState(() => _salesmanId = value);
                      _salesmanNameCtrl.text = salesman.text('name');
                    },
                  ),
                ),
                if (isReturn)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _originalIssueId.isEmpty ? null : _originalIssueId,
                      decoration: _dec('Original Issue (optional)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...issues
                            .where((item) => item.issueType == 'issue')
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(
                                  item.issueId.isNotEmpty
                                      ? item.issueId
                                      : item.id,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      ],
                      onChanged: (value) =>
                          setState(() => _originalIssueId = value ?? ''),
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
                    controller: _lineQtyPacksCtrl,
                    decoration: _dec('Qty(P)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcLineValue(),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _lineQtyLooseCtrl,
                    decoration: _dec('Qty(L)'),
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
                        final displayItem = {
                          'productName': item['productName'] ?? '',
                          'packingName': item['packingName'] ?? '',
                          'qtyPacks': item['qtyPacks'],
                          'qtyLoose': item['qtyLoose'],
                          'price': item['cost'],
                          'discPercent': 0,
                          'lineGross': item['value'],
                        };
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx == items.length - 1 ? 0 : 8,
                          ),
                          child: LineItemCard(
                            index: idx,
                            item: displayItem,
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
                            DataColumn(label: Text('Qty(P)')),
                            DataColumn(label: Text('Qty(L)')),
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
                                DataCell(Text('${item['qtyPacks'] ?? ''}')),
                                DataCell(Text('${item['qtyLoose'] ?? ''}')),
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
                                        tooltip: 'Edit',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppTheme.terra600,
                                        ),
                                        onPressed: () =>
                                            _startEditingItem(idx, item),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
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
