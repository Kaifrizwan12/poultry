import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/expiry_claim_controller.dart';
import '../models/expiry_claim_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';

class ExpiryClaimScreen extends StatefulWidget {
  const ExpiryClaimScreen({super.key, required this.direction});

  final String direction;

  @override
  State<ExpiryClaimScreen> createState() => _ExpiryClaimScreenState();
}

class _ExpiryClaimScreenState extends State<ExpiryClaimScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<ExpiryClaimController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({ExpiryClaimModel? initial}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<ExpiryClaimController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<CustomersController>(),
          ),
          ChangeNotifierProvider.value(value: context.read<VendorsController>()),
          ChangeNotifierProvider.value(
            value: context.read<ProductsController>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<PackingsController>(),
          ),
        ],
        child: _ExpiryClaimFormDialog(
          direction: widget.direction,
          initial: initial,
        ),
      ),
    );
  }

  List<ExpiryClaimModel> _visibleItems(ExpiryClaimController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final items = ctrl.items
        .where((item) => item.direction == widget.direction)
        .toList();
    if (q.isEmpty) return items;
    return items.where((item) {
      final party = widget.direction == 'from_customer'
          ? item.customerName
          : item.vendorName;
      return item.claimId.toLowerCase().contains(q) ||
          party.toLowerCase().contains(q) ||
          item.claimDate.toLowerCase().contains(q) ||
          item.replyDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isFromCustomer = widget.direction == 'from_customer';
    final title = isFromCustomer
        ? 'Expiry Claims from Customers'
        : 'Expiry Claims to Vendors';
    return Consumer<ExpiryClaimController>(
      builder: (context, ctrl, _) {
        final scopedItems = ctrl.items
            .where((item) => item.direction == widget.direction)
            .toList();
        final items = _visibleItems(ctrl);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Claim'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by claim ID, party, claim date or reply date',
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
              if (scopedItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_late_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isFromCustomer
                              ? 'No customer expiry claims yet.'
                              : 'No vendor expiry claims yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Claim'),
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
                            DataColumn(label: Text('Claim ID')),
                            DataColumn(label: Text('Party')),
                            DataColumn(label: Text('Claim Date')),
                            DataColumn(label: Text('Reply Date')),
                            DataColumn(label: Text('Claim Items'), numeric: true),
                            DataColumn(label: Text('Reply Items'), numeric: true),
                            DataColumn(label: Text('Claim Value'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final party = isFromCustomer
                                ? item.customerName
                                : item.vendorName;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
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
                                DataCell(Text(item.claimId)),
                                DataCell(Text(party)),
                                DataCell(Text(item.claimDate)),
                                DataCell(
                                  Text(
                                    item.replyDate.isEmpty ? '—' : item.replyDate,
                                  ),
                                ),
                                DataCell(Text('${item.items.length}')),
                                DataCell(Text('${item.replyItems.length}')),
                                DataCell(Text(item.netValue.toStringAsFixed(0))),
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

class _ExpiryClaimFormDialog extends StatefulWidget {
  const _ExpiryClaimFormDialog({required this.direction, this.initial});

  final String direction;
  final ExpiryClaimModel? initial;

  @override
  State<_ExpiryClaimFormDialog> createState() => _ExpiryClaimFormDialogState();
}

class _ExpiryClaimFormDialogState extends State<_ExpiryClaimFormDialog> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _claimItemsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _replyItemsNotifier =
      ValueNotifier([]);
  Map<String, dynamic>? _editingClaimItem;
  Map<String, dynamic>? _editingReplyItem;

  final _claimDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _replyDateCtrl = TextEditingController();
  final _repliedAmountCtrl = TextEditingController(text: '0');
  String _customerId = '';
  String _vendorId = '';
  bool _returnSameProducts = false;
  String _claimId = '';

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

  String? _replyProductId;
  final _rQtyPCtrl = TextEditingController(text: '0');
  final _rQtyLCtrl = TextEditingController(text: '0');
  double _replyPack = 1;
  final _replyPriceCtrl = TextEditingController(text: '0');
  double _replyLineValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _claimDateCtrl.dispose();
    _replyDateCtrl.dispose();
    _repliedAmountCtrl.dispose();
    _cExpPCtrl.dispose();
    _cExpLCtrl.dispose();
    _cDamPCtrl.dispose();
    _cDamLCtrl.dispose();
    _claimPriceCtrl.dispose();
    _rQtyPCtrl.dispose();
    _rQtyLCtrl.dispose();
    _replyPriceCtrl.dispose();
    _claimItemsNotifier.dispose();
    _replyItemsNotifier.dispose();
    super.dispose();
  }

  void _loadFromModel(ExpiryClaimModel model) {
    _currentId = model.id;
    _claimId = model.claimId;
    _customerId = model.customerId;
    _vendorId = model.vendorId;
    _returnSameProducts = model.returnSameProducts;
    _claimDateCtrl.text = model.claimDate;
    _replyDateCtrl.text = model.replyDate;
    _repliedAmountCtrl.text = model.repliedAmount.toStringAsFixed(2);
    _claimItemsNotifier.value = model.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _replyItemsNotifier.value = model.replyItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _clearClaimEntry() {
    setState(() {
      _editingClaimItem = null;
      _claimProductId = null;
      _claimPackingId = '';
      _claimPack = 1;
      _claimCostPerUnit = 0;
      _claimLineValue = 0;
    });
    _cExpPCtrl.text = '0';
    _cExpLCtrl.text = '0';
    _cDamPCtrl.text = '0';
    _cDamLCtrl.text = '0';
    _claimPriceCtrl.text = '0';
  }

  void _clearReplyEntry() {
    setState(() {
      _editingReplyItem = null;
      _replyProductId = null;
      _replyPack = 1;
      _replyLineValue = 0;
    });
    _rQtyPCtrl.text = '0';
    _rQtyLCtrl.text = '0';
    _replyPriceCtrl.text = '0';
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _claimId = '';
      _customerId = '';
      _vendorId = '';
      _returnSameProducts = false;
    });
    _claimDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _replyDateCtrl.clear();
    _repliedAmountCtrl.text = '0';
    _claimItemsNotifier.value = [];
    _replyItemsNotifier.value = [];
    _clearClaimEntry();
    _clearReplyEntry();
  }

  void _setClaimItem(Map<String, dynamic> item) {
    setState(() {
      _editingClaimItem = Map<String, dynamic>.from(item);
      _claimProductId = item['productId'] as String?;
      _claimPackingId = '${item['packingId'] ?? ''}';
      _claimPack = (item['pack'] as num?)?.toDouble() ?? 1;
      _claimCostPerUnit = (item['costPerUnit'] as num?)?.toDouble() ?? 0;
      _claimLineValue = (item['value'] as num?)?.toDouble() ?? 0;
    });
    _cExpPCtrl.text =
        ((item['expQtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _cExpLCtrl.text =
        ((item['expQtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _cDamPCtrl.text =
        ((item['damQtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _cDamLCtrl.text =
        ((item['damQtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _claimPriceCtrl.text =
        ((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
  }

  void _setReplyItem(Map<String, dynamic> item) {
    setState(() {
      _editingReplyItem = Map<String, dynamic>.from(item);
      _replyProductId = item['productId'] as String?;
      _replyPack = (item['pack'] as num?)?.toDouble() ?? 1;
      _replyLineValue = (item['value'] as num?)?.toDouble() ?? 0;
    });
    _rQtyPCtrl.text =
        ((item['qtyPacks'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _rQtyLCtrl.text =
        ((item['qtyLoose'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    _replyPriceCtrl.text =
        ((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
  }

  void _startEditingClaimItem(int index, Map<String, dynamic> item) {
    final updatedItems = [..._claimItemsNotifier.value];
    updatedItems.removeAt(index);
    _claimItemsNotifier.value = updatedItems;
    _setClaimItem(item);
  }

  void _startEditingReplyItem(int index, Map<String, dynamic> item) {
    final updatedItems = [..._replyItemsNotifier.value];
    updatedItems.removeAt(index);
    _replyItemsNotifier.value = updatedItems;
    _setReplyItem(item);
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
      try {
        pack = packings
            .firstWhere((packing) => packing.id == packingId)
            .number('quantity');
      } catch (_) {}
      setState(() {
        _claimProductId = productId;
        _claimPackingId = packingId;
        _claimPack = pack;
        _claimCostPerUnit = cost;
      });
      _claimPriceCtrl.text = cost.toStringAsFixed(2);
      _recalcClaimValue();
    } catch (_) {}
  }

  void _recalcClaimValue() {
    final expPacks = double.tryParse(_cExpPCtrl.text) ?? 0;
    final expLoose = double.tryParse(_cExpLCtrl.text) ?? 0;
    final damPacks = double.tryParse(_cDamPCtrl.text) ?? 0;
    final damLoose = double.tryParse(_cDamLCtrl.text) ?? 0;
    final price = double.tryParse(_claimPriceCtrl.text) ?? 0;
    setState(() {
      _claimLineValue =
          (expPacks * _claimPack + expLoose + damPacks * _claimPack + damLoose) *
              price;
    });
  }

  void _addClaimItem() {
    if (_claimProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product')),
      );
      return;
    }
    final expPacks = double.tryParse(_cExpPCtrl.text) ?? 0;
    final expLoose = double.tryParse(_cExpLCtrl.text) ?? 0;
    final damPacks = double.tryParse(_cDamPCtrl.text) ?? 0;
    final damLoose = double.tryParse(_cDamLCtrl.text) ?? 0;
    if (expPacks + expLoose + damPacks + damLoose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be > 0')),
      );
      return;
    }
    final price = double.tryParse(_claimPriceCtrl.text) ?? 0;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    String productName = '';
    String packingName = '';
    try {
      productName = products.firstWhere((p) => p.id == _claimProductId).text(
            'name',
          );
    } catch (_) {}
    try {
      packingName = packings.firstWhere((p) => p.id == _claimPackingId).text(
            'name',
          );
    } catch (_) {}
    final item = {
      'productId': _claimProductId,
      'productName': productName,
      'packingId': _claimPackingId,
      'packingName': packingName,
      'pack': _claimPack,
      'expQtyPacks': expPacks,
      'expQtyLoose': expLoose,
      'damQtyPacks': damPacks,
      'damQtyLoose': damLoose,
      'costPerUnit': _claimCostPerUnit,
      'price': price,
      'value': (expPacks * _claimPack +
              expLoose +
              damPacks * _claimPack +
              damLoose) *
          price,
    };
    _claimItemsNotifier.value = [..._claimItemsNotifier.value, item];
    _clearClaimEntry();
  }

  void _onReplyProductChanged(String? productId) {
    if (productId == null) return;
    final products = context.read<ProductsController>().typedItems;
    final packings = context.read<PackingsController>().typedItems;
    try {
      final product = products.firstWhere((p) => p.id == productId);
      double pack = 1;
      try {
        pack = packings
            .firstWhere((packing) => packing.id == product.salePackingId)
            .number('quantity');
      } catch (_) {}
      setState(() {
        _replyProductId = productId;
        _replyPack = pack;
      });
      _replyPriceCtrl.text = product.sale1Price.toStringAsFixed(2);
      _recalcReplyValue();
    } catch (_) {}
  }

  void _recalcReplyValue() {
    final qtyPacks = double.tryParse(_rQtyPCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_rQtyLCtrl.text) ?? 0;
    final price = double.tryParse(_replyPriceCtrl.text) ?? 0;
    setState(() {
      _replyLineValue = (qtyPacks * _replyPack + qtyLoose) * price;
    });
  }

  void _addReplyItem() {
    if (_replyProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product')),
      );
      return;
    }
    final qtyPacks = double.tryParse(_rQtyPCtrl.text) ?? 0;
    final qtyLoose = double.tryParse(_rQtyLCtrl.text) ?? 0;
    if (qtyPacks + qtyLoose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be > 0')),
      );
      return;
    }
    final price = double.tryParse(_replyPriceCtrl.text) ?? 0;
    final products = context.read<ProductsController>().typedItems;
    String productName = '';
    try {
      productName = products.firstWhere((p) => p.id == _replyProductId).text(
            'name',
          );
    } catch (_) {}
    final item = {
      'productId': _replyProductId,
      'productName': productName,
      'pack': _replyPack,
      'qtyPacks': qtyPacks,
      'qtyLoose': qtyLoose,
      'price': price,
      'value': (qtyPacks * _replyPack + qtyLoose) * price,
    };
    _replyItemsNotifier.value = [..._replyItemsNotifier.value, item];
    _clearReplyEntry();
  }

  Map<String, dynamic> _buildPayload() {
    final claimItems = _claimItemsNotifier.value;
    final replyItems = _replyItemsNotifier.value;
    final netValue = claimItems.fold<double>(
      0,
      (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0),
    );
    final replyNetValue = replyItems.fold<double>(
      0,
      (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0),
    );
    final customers = context.read<CustomersController>().typedItems;
    final vendors = context.read<VendorsController>().typedItems;
    String customerName = '';
    String vendorName = '';
    try {
      customerName =
          customers.firstWhere((item) => item.id == _customerId).text('name');
    } catch (_) {}
    try {
      vendorName =
          vendors.firstWhere((item) => item.id == _vendorId).text('name');
    } catch (_) {}
    return {
      'direction': widget.direction,
      'claimDate': _claimDateCtrl.text,
      'customerId': _customerId,
      'customerName': customerName,
      'vendorId': _vendorId,
      'vendorName': vendorName,
      'items': claimItems,
      'netValue': netValue,
      'replyDate': _replyDateCtrl.text,
      'returnSameProducts': _returnSameProducts,
      'replyItems': replyItems,
      'replyNetValue': replyNetValue,
      'repliedAmount': double.tryParse(_repliedAmountCtrl.text) ?? 0,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<ExpiryClaimController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _claimId = record.claimId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
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
        content: const Text('Delete this claim?'),
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
      await context.read<ExpiryClaimController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsController>().typedItems;
    final packings = context.watch<PackingsController>().typedItems;
    final customers = context.watch<CustomersController>().typedItems;
    final vendors = context.watch<VendorsController>().typedItems;
    final isFromCustomer = widget.direction == 'from_customer';

    return InvoicingFormDialog(
      title: isFromCustomer
          ? 'Expiry Claim from Customer'
          : 'Expiry Claim to Vendor',
      badgeText: _claimId.isNotEmpty ? 'Claim ID: $_claimId' : null,
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
                    controller: _claimDateCtrl,
                    decoration: _dec('Claim Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_claimDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _claimDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                if (isFromCustomer)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _customerId.isEmpty ? null : _customerId,
                      decoration: _dec('Customer'),
                      isExpanded: true,
                      items: customers
                          .map(
                            (customer) => DropdownMenuItem<String>(
                              value: customer.id,
                              child: Text(
                                customer.text('name'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _customerId = value ?? ''),
                    ),
                  )
                else
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
                      onChanged: (value) =>
                          setState(() => _vendorId = value ?? ''),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Claim Items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
                    value: _claimProductId,
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
                    onChanged: _onClaimProductChanged,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: _claimPackingId.isEmpty ? null : _claimPackingId,
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
                        _claimPackingId = value;
                        _claimPack = packing.number('quantity');
                      });
                      _recalcClaimValue();
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _cExpPCtrl,
                    decoration: _dec('Exp P'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcClaimValue(),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _cExpLCtrl,
                    decoration: _dec('Exp L'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcClaimValue(),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _cDamPCtrl,
                    decoration: _dec('Dam P'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcClaimValue(),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _cDamLCtrl,
                    decoration: _dec('Dam L'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcClaimValue(),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Cost'),
                      controller: TextEditingController(
                        text: _claimCostPerUnit.toStringAsFixed(2),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _claimPriceCtrl,
                    decoration: _dec('Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcClaimValue(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Value'),
                      controller: TextEditingController(
                        text: _claimLineValue.toStringAsFixed(2),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addClaimItem,
                  icon: Icon(
                    _editingClaimItem == null ? Icons.add : Icons.check,
                    size: 16,
                  ),
                  label: Text(_editingClaimItem == null ? 'Add' : 'Update'),
                ),
                if (_editingClaimItem != null)
                  OutlinedButton(
                    onPressed: _clearClaimEntry,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _claimItemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No claim items.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return Container(
                width: double.infinity,
                decoration: AppTheme.cardDecor,
                child: HorizontalScrollWheel(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Exp P')),
                      DataColumn(label: Text('Exp L')),
                      DataColumn(label: Text('Dam P')),
                      DataColumn(label: Text('Dam L')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Value')),
                      DataColumn(label: Text('')),
                    ],
                    rows: items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return DataRow(
                        color: WidgetStateProperty.resolveWith(
                          (states) => idx.isOdd
                              ? AppTheme.clayBg.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                        cells: [
                          DataCell(Text('${idx + 1}')),
                          DataCell(Text('${item['productName'] ?? ''}')),
                          DataCell(Text('${item['expQtyPacks'] ?? ''}')),
                          DataCell(Text('${item['expQtyLoose'] ?? ''}')),
                          DataCell(Text('${item['damQtyPacks'] ?? ''}')),
                          DataCell(Text('${item['damQtyLoose'] ?? ''}')),
                          DataCell(
                            Text(
                              ((item['price'] as num?)?.toDouble() ?? 0)
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
                                      _startEditingClaimItem(idx, item),
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
                                    _claimItemsNotifier.value = updatedItems;
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
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Reply Section',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
                    controller: _replyDateCtrl,
                    decoration: _dec('Reply Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _replyDateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _returnSameProducts,
                      onChanged: (value) =>
                          setState(() => _returnSameProducts = value),
                      activeColor: AppTheme.terra400,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Return Same Products',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _repliedAmountCtrl,
                    decoration: _dec('Replied Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                    value: _replyProductId,
                    decoration: _dec('Reply Product'),
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
                    onChanged: _onReplyProductChanged,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Pack'),
                      controller: TextEditingController(
                        text: _replyPack.toStringAsFixed(0),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _rQtyPCtrl,
                    decoration: _dec('Qty(P)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcReplyValue(),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _rQtyLCtrl,
                    decoration: _dec('Qty(L)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcReplyValue(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _replyPriceCtrl,
                    decoration: _dec('Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalcReplyValue(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _dec('Value'),
                      controller: TextEditingController(
                        text: _replyLineValue.toStringAsFixed(2),
                      ),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addReplyItem,
                  icon: Icon(
                    _editingReplyItem == null ? Icons.add : Icons.check,
                    size: 16,
                  ),
                  label: Text(_editingReplyItem == null ? 'Add' : 'Update'),
                ),
                if (_editingReplyItem != null)
                  OutlinedButton(
                    onPressed: _clearReplyEntry,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _replyItemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No reply items.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return Container(
                width: double.infinity,
                decoration: AppTheme.cardDecor,
                child: HorizontalScrollWheel(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Pack')),
                      DataColumn(label: Text('Qty(P)')),
                      DataColumn(label: Text('Qty(L)')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Value')),
                      DataColumn(label: Text('')),
                    ],
                    rows: items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return DataRow(
                        color: WidgetStateProperty.resolveWith(
                          (states) => idx.isOdd
                              ? AppTheme.clayBg.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                        cells: [
                          DataCell(Text('${idx + 1}')),
                          DataCell(Text('${item['productName'] ?? ''}')),
                          DataCell(Text('${item['pack'] ?? ''}')),
                          DataCell(Text('${item['qtyPacks'] ?? ''}')),
                          DataCell(Text('${item['qtyLoose'] ?? ''}')),
                          DataCell(
                            Text(
                              ((item['price'] as num?)?.toDouble() ?? 0)
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
                                      _startEditingReplyItem(idx, item),
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
                                    _replyItemsNotifier.value = updatedItems;
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
