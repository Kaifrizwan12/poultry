import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/expiry_claim_controller.dart';
import '../models/expiry_claim_model.dart';

class ExpiryClaimScreen extends StatefulWidget {
  const ExpiryClaimScreen({super.key, required this.direction});
  final String direction;

  @override
  State<ExpiryClaimScreen> createState() => _ExpiryClaimScreenState();
}

class _ExpiryClaimScreenState extends State<ExpiryClaimScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _claimItemsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _replyItemsNotifier = ValueNotifier([]);

  final _claimDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _replyDateCtrl = TextEditingController();
  final _repliedAmountCtrl = TextEditingController(text: '0');
  String _customerId = '';
  String _vendorId = '';
  bool _returnSameProducts = false;
  String _claimId = '';

  // Claim line entry
  String? _claimProductId;
  String _claimPackingId = '';
  double _claimPack = 1;
  final _cExpPCtrl = TextEditingController(text: '0');
  final _cExpLCtrl = TextEditingController(text: '0');
  final _cDamPCtrl = TextEditingController(text: '0');
  final _cDamLCtrl = TextEditingController(text: '0');
  double _claimCostPerUnit = 0;
  final _claimPriceCtrl = TextEditingController(text: '0');
  double _claimLineValue = 0;

  // Reply line entry
  String? _replyProductId;
  final _rQtyPCtrl = TextEditingController(text: '0');
  final _rQtyLCtrl = TextEditingController(text: '0');
  double _replyPack = 1;
  final _replyPriceCtrl = TextEditingController(text: '0');
  double _replyLineValue = 0;

  @override
  void dispose() {
    _claimDateCtrl.dispose(); _replyDateCtrl.dispose(); _repliedAmountCtrl.dispose();
    for (final c in [_cExpPCtrl, _cExpLCtrl, _cDamPCtrl, _cDamLCtrl, _claimPriceCtrl, _rQtyPCtrl, _rQtyLCtrl, _replyPriceCtrl]) { c.dispose(); }
    _claimItemsNotifier.dispose(); _replyItemsNotifier.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { _currentId = null; _claimId = ''; _customerId = ''; _vendorId = ''; _returnSameProducts = false; _claimProductId = null; _claimPackingId = ''; _claimPack = 1; _claimCostPerUnit = 0; _claimLineValue = 0; _replyProductId = null; _replyPack = 1; _replyLineValue = 0; });
    _claimDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10); _replyDateCtrl.clear(); _repliedAmountCtrl.text = '0';
    for (final c in [_cExpPCtrl, _cExpLCtrl, _cDamPCtrl, _cDamLCtrl, _rQtyPCtrl, _rQtyLCtrl]) { c.text = '0'; }
    _claimPriceCtrl.text = '0'; _replyPriceCtrl.text = '0';
    _claimItemsNotifier.value = []; _replyItemsNotifier.value = [];
  }

  void _loadFromModel(ExpiryClaimModel m) {
    setState(() { _currentId = m.id; _claimId = m.claimId; _customerId = m.customerId; _vendorId = m.vendorId; _returnSameProducts = m.returnSameProducts; });
    _claimDateCtrl.text = m.claimDate; _replyDateCtrl.text = m.replyDate; _repliedAmountCtrl.text = m.repliedAmount.toStringAsFixed(2);
    _claimItemsNotifier.value = List<Map<String, dynamic>>.from(m.items);
    _replyItemsNotifier.value = List<Map<String, dynamic>>.from(m.replyItems);
  }

  void _onClaimProductChanged(String? productId) {
    if (productId == null) return;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    try {
      final product = products.firstWhere((p) => p.id == productId);
      final packingId = product.purPackingId;
      final cost = product.purchasePrice;
      double pack = 1;
      try { pack = packings.firstWhere((p) => p.id == packingId).number('quantity'); } catch (_) {}
      setState(() { _claimProductId = productId; _claimPackingId = packingId; _claimPack = pack; _claimCostPerUnit = cost; _claimPriceCtrl.text = cost.toStringAsFixed(2); });
      _recalcClaimValue();
    } catch (_) {}
  }

  void _recalcClaimValue() {
    final ep = double.tryParse(_cExpPCtrl.text) ?? 0; final el = double.tryParse(_cExpLCtrl.text) ?? 0;
    final dp = double.tryParse(_cDamPCtrl.text) ?? 0; final dl = double.tryParse(_cDamLCtrl.text) ?? 0;
    final price = double.tryParse(_claimPriceCtrl.text) ?? 0;
    setState(() => _claimLineValue = (ep * _claimPack + el + dp * _claimPack + dl) * price);
  }

  void _addClaimItem() {
    if (_claimProductId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product'))); return; }
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    String pname = ''; String pkname = '';
    try { pname = products.firstWhere((p) => p.id == _claimProductId).text('name'); } catch (_) {}
    try { pkname = packings.firstWhere((p) => p.id == _claimPackingId).text('name'); } catch (_) {}
    final ep = double.tryParse(_cExpPCtrl.text) ?? 0; final el = double.tryParse(_cExpLCtrl.text) ?? 0;
    final dp = double.tryParse(_cDamPCtrl.text) ?? 0; final dl = double.tryParse(_cDamLCtrl.text) ?? 0;
    if (ep + el + dp + dl <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be > 0'))); return; }
    final price = double.tryParse(_claimPriceCtrl.text) ?? 0;
    final value = (ep * _claimPack + el + dp * _claimPack + dl) * price;
    _claimItemsNotifier.value = [..._claimItemsNotifier.value, { 'productId': _claimProductId, 'productName': pname, 'packingId': _claimPackingId, 'packingName': pkname, 'pack': _claimPack, 'expQtyPacks': ep, 'expQtyLoose': el, 'damQtyPacks': dp, 'damQtyLoose': dl, 'costPerUnit': _claimCostPerUnit, 'price': price, 'value': value }];
    setState(() { _claimProductId = null; _claimPackingId = ''; _claimPack = 1; _claimCostPerUnit = 0; _claimLineValue = 0; });
    for (final c in [_cExpPCtrl, _cExpLCtrl, _cDamPCtrl, _cDamLCtrl]) { c.text = '0'; } _claimPriceCtrl.text = '0';
  }

  void _onReplyProductChanged(String? productId) {
    if (productId == null) return;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    try {
      final product = products.firstWhere((p) => p.id == productId);
      double pack = 1;
      try { pack = packings.firstWhere((p) => p.id == product.salePackingId).number('quantity'); } catch (_) {}
      setState(() { _replyProductId = productId; _replyPack = pack; _replyPriceCtrl.text = product.sale1Price.toStringAsFixed(2); });
      _recalcReplyValue();
    } catch (_) {}
  }

  void _recalcReplyValue() {
    final qtyP = double.tryParse(_rQtyPCtrl.text) ?? 0; final qtyL = double.tryParse(_rQtyLCtrl.text) ?? 0;
    final price = double.tryParse(_replyPriceCtrl.text) ?? 0;
    setState(() => _replyLineValue = (qtyP * _replyPack + qtyL) * price);
  }

  void _addReplyItem() {
    if (_replyProductId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product'))); return; }
    final products = context.read<ProductsController>().typedItems;
    String pname = '';
    try { pname = products.firstWhere((p) => p.id == _replyProductId).text('name'); } catch (_) {}
    final qtyP = double.tryParse(_rQtyPCtrl.text) ?? 0; final qtyL = double.tryParse(_rQtyLCtrl.text) ?? 0;
    if (qtyP + qtyL <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be > 0'))); return; }
    final price = double.tryParse(_replyPriceCtrl.text) ?? 0;
    final value = (qtyP * _replyPack + qtyL) * price;
    _replyItemsNotifier.value = [..._replyItemsNotifier.value, { 'productId': _replyProductId, 'productName': pname, 'pack': _replyPack, 'qtyPacks': qtyP, 'qtyLoose': qtyL, 'price': price, 'value': value }];
    setState(() { _replyProductId = null; _replyPack = 1; _replyLineValue = 0; });
    _rQtyPCtrl.text = '0'; _rQtyLCtrl.text = '0'; _replyPriceCtrl.text = '0';
  }

  Map<String, dynamic> _buildPayload() {
    final claimItems = _claimItemsNotifier.value;
    final replyItems = _replyItemsNotifier.value;
    final netValue = claimItems.fold<double>(0, (s, it) => s + ((it['value'] as num?)?.toDouble() ?? 0));
    final replyNetValue = replyItems.fold<double>(0, (s, it) => s + ((it['value'] as num?)?.toDouble() ?? 0));
    return {
      'direction': widget.direction, 'claimDate': _claimDateCtrl.text,
      'customerId': _customerId, 'vendorId': _vendorId,
      'items': claimItems, 'netValue': netValue,
      'replyDate': _replyDateCtrl.text, 'returnSameProducts': _returnSameProducts,
      'replyItems': replyItems, 'replyNetValue': replyNetValue,
      'repliedAmount': double.tryParse(_repliedAmountCtrl.text) ?? 0,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<ExpiryClaimController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _claimId = r.claimId; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this claim?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<ExpiryClaimController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<ExpiryClaimController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<ExpiryClaimModel>(
      context: context,
      records: ctrl.items,
      title: 'Expiry Claims',
      getBusinessId: (m) => m.claimId,
      getTitle: (m) => '${m.claimId}  -  ${m.direction == "from_customer" ? m.customerName : m.vendorName}',
      getSubtitle: (m) => m.claimDate.isNotEmpty ? m.claimDate.substring(0,10) : '?',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    final customers = context.read<CustomersController>().typedItems;
    final vendors = context.read<VendorsController>().typedItems;
    final isFromCustomer = widget.direction == 'from_customer';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(isFromCustomer ? 'Expiry Claim from Customer' : 'Expiry Claim to Vendor', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                if (_claimId.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.terra50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.terra200)), child: Text('Claim ID: $_claimId', style: const TextStyle(color: AppTheme.terra800, fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _claimDateCtrl, decoration: _dec('Claim Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_claimDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _claimDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                if (isFromCustomer)
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _customerId.isEmpty ? null : _customerId, decoration: _dec('Customer'), isExpanded: true, items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _customerId = val ?? '')))
                else
                  SizedBox(width: 220, child: DropdownButtonFormField<String>(value: _vendorId.isEmpty ? null : _vendorId, decoration: _dec('Vendor'), isExpanded: true, items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _vendorId = val ?? ''))),
              ])),
              const SizedBox(height: 16),
              Text('Claim Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)),
                child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _claimProductId, decoration: _dec('Product'), isExpanded: true, items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: _onClaimProductChanged)),
                  SizedBox(width: 150, child: DropdownButtonFormField<String>(value: _claimPackingId.isEmpty ? null : _claimPackingId, decoration: _dec('Packing'), isExpanded: true, items: packings.map((p) => DropdownMenuItem(value: p.id, child: Text(p.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; final pk = packings.firstWhere((p) => p.id == val); setState(() { _claimPackingId = val; _claimPack = pk.number('quantity'); }); _recalcClaimValue(); })),
                  SizedBox(width: 80, child: TextFormField(controller: _cExpPCtrl, decoration: _dec('Exp P'), keyboardType: TextInputType.number, onChanged: (_) => _recalcClaimValue())),
                  SizedBox(width: 80, child: TextFormField(controller: _cExpLCtrl, decoration: _dec('Exp L'), keyboardType: TextInputType.number, onChanged: (_) => _recalcClaimValue())),
                  SizedBox(width: 80, child: TextFormField(controller: _cDamPCtrl, decoration: _dec('Dam P'), keyboardType: TextInputType.number, onChanged: (_) => _recalcClaimValue())),
                  SizedBox(width: 80, child: TextFormField(controller: _cDamLCtrl, decoration: _dec('Dam L'), keyboardType: TextInputType.number, onChanged: (_) => _recalcClaimValue())),
                  SizedBox(width: 90, child: AbsorbPointer(child: TextFormField(decoration: _dec('Cost'), controller: TextEditingController(text: _claimCostPerUnit.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  SizedBox(width: 100, child: TextFormField(controller: _claimPriceCtrl, decoration: _dec('Price'), keyboardType: TextInputType.number, onChanged: (_) => _recalcClaimValue())),
                  SizedBox(width: 100, child: AbsorbPointer(child: TextFormField(decoration: _dec('Value'), controller: TextEditingController(text: _claimLineValue.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  ElevatedButton.icon(onPressed: _addClaimItem, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                ]),
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _claimItemsNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('No claim items.', style: TextStyle(color: AppTheme.textSecondary)));
                    return Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                      columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Exp P')), DataColumn(label: Text('Exp L')), DataColumn(label: Text('Dam P')), DataColumn(label: Text('Dam L')), DataColumn(label: Text('Price')), DataColumn(label: Text('Value')), DataColumn(label: Text(''))],
                      rows: items.asMap().entries.map((e) { final idx = e.key; final it = e.value; return DataRow(
                        color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                        cells: [DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')), DataCell(Text('${it['expQtyPacks'] ?? ''}')), DataCell(Text('${it['expQtyLoose'] ?? ''}')), DataCell(Text('${it['damQtyPacks'] ?? ''}')), DataCell(Text('${it['damQtyLoose'] ?? ''}')), DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['value'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _claimItemsNotifier.value = u; }))],
                      ); }).toList(),
                    )));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Reply Section', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 160, child: TextFormField(controller: _replyDateCtrl, decoration: _dec('Reply Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _replyDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: _returnSameProducts, onChanged: (v) => setState(() => _returnSameProducts = v), activeColor: AppTheme.terra400), const SizedBox(width: 8), const Text('Return Same Products', style: TextStyle(fontSize: 13))]),
                SizedBox(width: 140, child: TextFormField(controller: _repliedAmountCtrl, decoration: _dec('Replied Amount'), keyboardType: TextInputType.number)),
              ])),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.clayBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.softBorder)),
                child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _replyProductId, decoration: _dec('Reply Product'), isExpanded: true, items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: _onReplyProductChanged)),
                  SizedBox(width: 80, child: AbsorbPointer(child: TextFormField(decoration: _dec('Pack'), controller: TextEditingController(text: _replyPack.toStringAsFixed(0)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  SizedBox(width: 90, child: TextFormField(controller: _rQtyPCtrl, decoration: _dec('Qty(P)'), keyboardType: TextInputType.number, onChanged: (_) => _recalcReplyValue())),
                  SizedBox(width: 90, child: TextFormField(controller: _rQtyLCtrl, decoration: _dec('Qty(L)'), keyboardType: TextInputType.number, onChanged: (_) => _recalcReplyValue())),
                  SizedBox(width: 100, child: TextFormField(controller: _replyPriceCtrl, decoration: _dec('Price'), keyboardType: TextInputType.number, onChanged: (_) => _recalcReplyValue())),
                  SizedBox(width: 100, child: AbsorbPointer(child: TextFormField(decoration: _dec('Value'), controller: TextEditingController(text: _replyLineValue.toStringAsFixed(2)), style: const TextStyle(color: AppTheme.textSecondary)))),
                  ElevatedButton.icon(onPressed: _addReplyItem, icon: const Icon(Icons.add, size: 16), label: const Text('Add Reply Item'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                ]),
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _replyItemsNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('No reply items.', style: TextStyle(color: AppTheme.textSecondary)));
                    return Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                      columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Pack')), DataColumn(label: Text('Qty(P)')), DataColumn(label: Text('Qty(L)')), DataColumn(label: Text('Price')), DataColumn(label: Text('Value')), DataColumn(label: Text(''))],
                      rows: items.asMap().entries.map((e) { final idx = e.key; final it = e.value; return DataRow(
                        color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                        cells: [DataCell(Text('${idx + 1}')), DataCell(Text(it['productName'] ?? '')), DataCell(Text('${it['pack'] ?? ''}')), DataCell(Text('${it['qtyPacks'] ?? ''}')), DataCell(Text('${it['qtyLoose'] ?? ''}')), DataCell(Text((it['price'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(Text((it['value'] as num?)?.toStringAsFixed(2) ?? '0')), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...items]; u.removeAt(idx); _replyItemsNotifier.value = u; }))],
                      ); }).toList(),
                    )));
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
