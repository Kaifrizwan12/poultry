import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/stock_issue_controller.dart';
import '../models/stock_issue_model.dart';

class StockIssueScreen extends StatefulWidget {
  const StockIssueScreen({super.key, required this.issueType});
  final String issueType;

  @override
  State<StockIssueScreen> createState() => _StockIssueScreenState();
}

class _StockIssueScreenState extends State<StockIssueScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _itemsNotifier = ValueNotifier([]);

  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _salesmanNameCtrl = TextEditingController();
  String _salesmanId = '';
  String _originalIssueId = '';

  // Line entry state
  String? _lineProductId;
  String _linePackingId = '';
  double _linePack = 1;
  final _lineQtyPacksCtrl = TextEditingController(text: '0');
  final _lineQtyLooseCtrl = TextEditingController(text: '0');
  double _lineCost = 0;
  double _lineValue = 0;

  @override
  void dispose() {
    _dateCtrl.dispose(); _salesmanNameCtrl.dispose();
    _lineQtyPacksCtrl.dispose(); _lineQtyLooseCtrl.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _salesmanId = ''; _originalIssueId = ''; _lineProductId = null; _linePackingId = ''; _linePack = 1; _lineCost = 0; _lineValue = 0; });
    _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear(); _lineQtyPacksCtrl.text = '0'; _lineQtyLooseCtrl.text = '0';
    _itemsNotifier.value = [];
  }

  void _loadFromModel(StockIssueModel m) {
    setState(() { _currentId = m.id; _salesmanId = m.salesmanId; _originalIssueId = m.originalIssueId; });
    _dateCtrl.text = m.date; _salesmanNameCtrl.text = m.salesmanName;
    _itemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
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
      try { final pk = packings.firstWhere((p) => p.id == packingId); pack = pk.number('quantity'); } catch (_) {}
      final qtyPacks = double.tryParse(_lineQtyPacksCtrl.text) ?? 0;
      final qtyLoose = double.tryParse(_lineQtyLooseCtrl.text) ?? 0;
      final value = (qtyPacks * pack + qtyLoose) * cost;
      setState(() { _lineProductId = productId; _linePackingId = packingId; _linePack = pack; _lineCost = cost; _lineValue = value; });
      // store packing name for later use
      _linePackingId = packingId;
    } catch (_) {}
  }

  void _recalcLineValue() {
    final qtyPacks = double.tryParse(_lineQtyPacksCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_lineQtyLooseCtrl.text) ?? 0;
    setState(() => _lineValue = (qtyPacks * _linePack + qtyLoose) * _lineCost);
  }

  void _addLineItem() {
    if (_lineProductId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product'))); return; }
    final qtyPacks = double.tryParse(_lineQtyPacksCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_lineQtyLooseCtrl.text) ?? 0;
    if (qtyPacks + qtyLoose <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be > 0'))); return; }
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    String productName = '';
    String packingName = '';
    try { productName = products.firstWhere((p) => p.id == _lineProductId).text('name'); } catch (_) {}
    try { packingName = packings.firstWhere((p) => p.id == _linePackingId).text('name'); } catch (_) {}
    final value = (qtyPacks * _linePack + qtyLoose) * _lineCost;
    _itemsNotifier.value = [..._itemsNotifier.value, {
      'productId': _lineProductId, 'productName': productName,
      'packingId': _linePackingId, 'packingName': packingName,
      'pack': _linePack, 'qtyPacks': qtyPacks, 'qtyLoose': qtyLoose,
      'cost': _lineCost, 'value': value,
    }];
    setState(() { _lineProductId = null; _linePackingId = ''; _linePack = 1; _lineCost = 0; _lineValue = 0; });
    _lineQtyPacksCtrl.text = '0'; _lineQtyLooseCtrl.text = '0';
  }

  Map<String, dynamic> _buildPayload() {
    final items = _itemsNotifier.value;
    final netValue = items.fold<double>(0, (s, it) => s + ((it['value'] as num?)?.toDouble() ?? 0));
    return { 'issueType': widget.issueType, 'date': _dateCtrl.text, 'salesmanId': _salesmanId, 'salesmanName': _salesmanNameCtrl.text, 'originalIssueId': _originalIssueId, 'items': items, 'netValue': netValue, 'status': 'saved' };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<StockIssueController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() => _currentId = r.id); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this stock issue?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<StockIssueController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<StockIssueController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<StockIssueModel>(
      context: context,
      records: ctrl.items,
      title: 'Stock Issues',
      getBusinessId: (m) => m.issueId,
      getTitle: (m) => '${m.issueId}  -  ${m.salesmanName}',
      getSubtitle: (m) => '${m.date.isNotEmpty ? m.date.substring(0,10) : "?"}  |  ${m.issueType}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.read<SalesmenController>().typedItems;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    final issues = context.read<StockIssueController>().items;
    final isReturn = widget.issueType == 'return';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isReturn ? 'Stock Return from Salesman' : 'Stock Issue to Salesman', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _dateCtrl, decoration: _dec('Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _salesmanId.isEmpty ? null : _salesmanId, decoration: _dec('Salesman'), isExpanded: true, items: salesmen.map((s) => DropdownMenuItem(value: s.id, child: Text(s.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; setState(() => _salesmanId = val); _salesmanNameCtrl.text = salesmen.firstWhere((s) => s.id == val).text('name'); })),
                if (isReturn)
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _originalIssueId.isEmpty ? null : _originalIssueId, decoration: _dec('Original Issue (optional)'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('None')), ...issues.where((i) => i.issueType == 'issue').map((i) => DropdownMenuItem(value: i.id, child: Text(i.issueId.isNotEmpty ? 'Issue: ${i.issueId}' : i.id, overflow: TextOverflow.ellipsis)))], onChanged: (val) => setState(() => _originalIssueId = val ?? ''))),
              ])),
              const SizedBox(height: 16),
              // Custom line entry
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)),
                child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _lineProductId, decoration: _dec('Product'), isExpanded: true, items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: _onLineProductChanged)),
                  SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _linePackingId.isEmpty ? null : _linePackingId, decoration: _dec('Packing'), isExpanded: true, items: packings.map((p) => DropdownMenuItem(value: p.id, child: Text(p.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; final pk = packings.firstWhere((p) => p.id == val); setState(() { _linePackingId = val; _linePack = pk.number('quantity'); }); _recalcLineValue(); })),
                  SizedBox(width: 70, child: AbsorbPointer(child: TextFormField(decoration: _dec('Pack'), controller: TextEditingController(text: _linePack.toStringAsFixed(0)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  SizedBox(width: 90, child: TextFormField(controller: _lineQtyPacksCtrl, decoration: _dec('Qty(P)'), keyboardType: TextInputType.number, onChanged: (_) => _recalcLineValue())),
                  SizedBox(width: 90, child: TextFormField(controller: _lineQtyLooseCtrl, decoration: _dec('Qty(L)'), keyboardType: TextInputType.number, onChanged: (_) => _recalcLineValue())),
                  SizedBox(width: 100, child: AbsorbPointer(child: TextFormField(decoration: _dec('Cost'), controller: TextEditingController(text: _lineCost.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  SizedBox(width: 100, child: AbsorbPointer(child: TextFormField(decoration: _dec('Value'), controller: TextEditingController(text: _lineValue.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  ElevatedButton.icon(onPressed: _addLineItem, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                ]),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _itemsNotifier,
                  builder: (context, items, _) {
                    final netValue = items.fold<double>(0, (s, it) => s + ((it['value'] as num?)?.toDouble() ?? 0));
                    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No items added yet.', style: TextStyle(color: AppTheme.textSecondary)));
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                        columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Packing')), DataColumn(label: Text('Pack')), DataColumn(label: Text('Qty(P)')), DataColumn(label: Text('Qty(L)')), DataColumn(label: Text('Cost')), DataColumn(label: Text('Value')), DataColumn(label: Text(''))],
                        rows: items.asMap().entries.map((e) { final idx = e.key; final it = e.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')), DataCell(Text(it['packingName'] ?? '')), DataCell(Text('${it['pack'] ?? ''}')), DataCell(Text('${it['qtyPacks'] ?? ''}')), DataCell(Text('${it['qtyLoose'] ?? ''}')), DataCell(Text((it['cost'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['value'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _itemsNotifier.value = u; }))],
                        ); }).toList(),
                      ))),
                      const SizedBox(height: 8),
                      Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [const Text('Net Value: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), Text(netValue.toStringAsFixed(2), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))])),
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite, padding: const EdgeInsets.all(12),
          child: Row(children: [
            TextButton(onPressed: _clearForm, child: const Text('Clear')),
            TextButton(onPressed: _openRecords, child: const Text('Records')),
            TextButton(onPressed: _currentId != null ? _remove : null, child: const Text('Remove')),
            const Spacer(),
            ElevatedButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _clearForm, child: const Text('Close')),
          ]),
        ),
      ],
    );
  }
}
