import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/packing.dart';
import 'package:farm_mgt_auth/modules/settings/models/product.dart';
import 'package:farm_mgt_auth/modules/settings/models/unit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';

class InvoiceLineItemRow extends StatefulWidget {
  const InvoiceLineItemRow({
    super.key,
    required this.isPurchase,
    required this.onAdd,
    required this.products,
  });

  final bool isPurchase;
  final void Function(Map<String, dynamic>) onAdd;
  final List<Product> products;

  @override
  State<InvoiceLineItemRow> createState() => _InvoiceLineItemRowState();
}

class _InvoiceLineItemRowState extends State<InvoiceLineItemRow> {
  String? _productId;
  String _packingId  = '';
  String _packingName = '';
  double _pack       = 1;
  String _unitName   = '';
  double _salesTaxPercent = 0;

  // Editable fields
  final _qtyPacksCtrl  = TextEditingController(text: '0');
  final _qtyLooseCtrl  = TextEditingController(text: '0');
  final _bonusCtrl     = TextEditingController(text: '0');
  final _priceCtrl     = TextEditingController(text: '0');
  final _discPctCtrl   = TextEditingController(text: '0');

  // Read-only display fields — persisted in state, updated programmatically.
  // NEVER create TextEditingController inside build(); it leaks on every rebuild.
  final _packCtrl      = TextEditingController(text: '1');
  final _unitCtrl      = TextEditingController();
  final _taxPctCtrl    = TextEditingController(text: '0.00');
  final _grossCtrl     = TextEditingController(text: '0.00');
  final _valIncSTCtrl  = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _qtyPacksCtrl.dispose();
    _qtyLooseCtrl.dispose();
    _bonusCtrl.dispose();
    _priceCtrl.dispose();
    _discPctCtrl.dispose();
    _packCtrl.dispose();
    _unitCtrl.dispose();
    _taxPctCtrl.dispose();
    _grossCtrl.dispose();
    _valIncSTCtrl.dispose();
    super.dispose();
  }

  void _onProductChanged(String? productId) {
    if (productId == null || productId.isEmpty) return;
    Product? product;
    try {
      product = widget.products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return;
    }

    final packings = context.read<PackingsController>().typedItems;
    final units    = context.read<UnitsController>().typedItems;

    final packingId = widget.isPurchase ? product.purPackingId : product.salePackingId;
    final price     = widget.isPurchase ? product.purchasePrice : product.sale1Price;
    final tax       = product.salesTaxPercent;

    Packing? packing;
    try { packing = packings.firstWhere((p) => p.id == packingId); } catch (_) {}
    Unit? unit;
    try { unit = units.firstWhere((u) => u.id == product!.unitId); } catch (_) {}

    final pack        = packing?.quantity ?? 1.0;
    final packingName = packing?.name ?? '';
    final unitName    = unit?.name ?? '';

    _packingId   = packingId;
    _packingName = packingName;
    _pack        = pack;
    _unitName    = unitName;
    _salesTaxPercent = tax;

    _priceCtrl.text   = price.toStringAsFixed(2);
    _packCtrl.text    = pack.toStringAsFixed(0);
    _unitCtrl.text    = unitName;
    _taxPctCtrl.text  = tax.toStringAsFixed(2);

    setState(() { _productId = productId; });
    _recalc();
  }

  void _recalc() {
    final qtyPacks   = double.tryParse(_qtyPacksCtrl.text) ?? 0;
    final qtyLoose   = double.tryParse(_qtyLooseCtrl.text) ?? 0;
    final price      = double.tryParse(_priceCtrl.text) ?? 0;
    final discPct    = double.tryParse(_discPctCtrl.text) ?? 0;
    final tax        = _salesTaxPercent;

    final lineGross      = (qtyPacks * _pack + qtyLoose) * price;
    final lineDisc       = lineGross * (discPct / 100);
    final lineNet        = lineGross - lineDisc;
    final lineTax        = lineNet * (tax / 100);
    final lineValueIncST = lineNet + lineTax;

    _grossCtrl.text    = lineGross.toStringAsFixed(2);
    _valIncSTCtrl.text = lineValueIncST.toStringAsFixed(2);

    // No setState needed — controllers notify their listeners directly.
    // Only call setState if we need to rebuild structural parts of the tree.
  }

  void _addItem() {
    if (_productId == null || _productId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    final qtyPacks = double.tryParse(_qtyPacksCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_qtyLooseCtrl.text) ?? 0;
    if (qtyPacks + qtyLoose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }

    final price      = double.tryParse(_priceCtrl.text) ?? 0;
    final discPct    = double.tryParse(_discPctCtrl.text) ?? 0;
    final bonus      = double.tryParse(_bonusCtrl.text) ?? 0;
    final lineGross  = (qtyPacks * _pack + qtyLoose) * price;
    final lineDisc   = lineGross * (discPct / 100);
    final lineNet    = lineGross - lineDisc;
    final lineTax    = lineNet * (_salesTaxPercent / 100);
    final lineValueIncST = lineNet + lineTax;

    String productName = '';
    try { productName = widget.products.firstWhere((p) => p.id == _productId).name; } catch (_) {}

    widget.onAdd({
      'productId':       _productId,
      'productName':     productName,
      'packingId':       _packingId,
      'packingName':     _packingName,
      'pack':            _pack,
      'unit':            _unitName,
      'qtyPacks':        qtyPacks,
      'qtyLoose':        qtyLoose,
      'bonus':           bonus,
      'price':           price,
      'discPercent':     discPct,
      'salesTaxPercent': _salesTaxPercent,
      'lineGross':       lineGross,
      'lineDisc':        lineDisc,
      'lineNet':         lineNet,
      'lineTax':         lineTax,
      'lineValueIncST':  lineValueIncST,
    });

    // Reset to blank entry
    setState(() {
      _productId       = null;
      _packingId       = '';
      _packingName     = '';
      _pack            = 1;
      _unitName        = '';
      _salesTaxPercent = 0;
    });
    _qtyPacksCtrl.text = '0';
    _qtyLooseCtrl.text = '0';
    _bonusCtrl.text    = '0';
    _priceCtrl.text    = '0';
    _discPctCtrl.text  = '0';
    _packCtrl.text     = '1';
    _unitCtrl.text     = '';
    _taxPctCtrl.text   = '0.00';
    _grossCtrl.text    = '0.00';
    _valIncSTCtrl.text = '0.00';
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  InputDecoration _readOnlyDec(String label) =>
      AppTheme.inputDecoration(label, readOnly: true);

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _productId,
              decoration: _dec('Product'),
              isExpanded: true,
              items: widget.products.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _onProductChanged,
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _qtyPacksCtrl,
              decoration: _dec('Qty(P)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _qtyLooseCtrl,
              decoration: _dec('Qty(L)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _bonusCtrl,
              decoration: _dec('Bonus'),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _packCtrl,
              decoration: _readOnlyDec('Pack'),
              readOnly: true,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _unitCtrl,
              decoration: _readOnlyDec('Unit'),
              readOnly: true,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _priceCtrl,
              decoration: _dec('Price'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _discPctCtrl,
              decoration: _dec('Disc%'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _taxPctCtrl,
              decoration: _readOnlyDec('Tax%'),
              readOnly: true,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _grossCtrl,
              decoration: _readOnlyDec('Gross'),
              readOnly: true,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: _valIncSTCtrl,
              decoration: _readOnlyDec('Val incl ST'),
              readOnly: true,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
