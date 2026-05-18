import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recovery_invoice_wise_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../models/recovery_invoice_wise_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/offline_banner.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class RecoveryInvoiceWiseScreen extends StatefulWidget {
  const RecoveryInvoiceWiseScreen({super.key});

  @override
  State<RecoveryInvoiceWiseScreen> createState() =>
      _RecoveryInvoiceWiseScreenState();
}

class _RecoveryInvoiceWiseScreenState extends State<RecoveryInvoiceWiseScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<RecoveryInvoiceWiseController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({RecoveryInvoiceWiseModel? initial}) async {
    final salesInvoiceCtrl = context.read<SalesInvoiceController>();
    if (salesInvoiceCtrl.items.isEmpty) {
      await salesInvoiceCtrl.fetchAll();
    }
    if (!mounted) return;
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<RecoveryInvoiceWiseController>(),
          ),
          ChangeNotifierProvider.value(value: salesInvoiceCtrl),
          ChangeNotifierProvider.value(
            value: context.read<SalesmenController>(),
          ),
          ChangeNotifierProvider.value(value: context.read<TownsController>()),
          ChangeNotifierProvider.value(
              value: context.read<SectorsController>()),
          ChangeNotifierProvider.value(
            value: context.read<CustomersController>(),
          ),
        ],
        child: _RecoveryInvoiceWiseFormDialog(initial: initial),
      ),
    );
  }

  List<RecoveryInvoiceWiseModel> _visibleItems(
    RecoveryInvoiceWiseController ctrl,
  ) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      return item.recoveryId.toLowerCase().contains(q) ||
          item.salesmanName.toLowerCase().contains(q) ||
          item.recoveryDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecoveryInvoiceWiseController>(
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
                      'Recovery (Invoice Wise)',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Recovery',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by recovery ID, salesman or date',
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
                          Icons.receipt_long_outlined,
                          size: 52,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No invoice-wise recoveries yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Recovery'),
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
                      id: item.recoveryId,
                      subtitle: item.salesmanName,
                      meta: AppUtils.formatDate(item.recoveryDate),
                      amount: AppUtils.fmtAmt(item.netReceived),
                      onTap: () => _openForm(initial: item),
                    );
                  },
                ))
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
                            DataColumn(label: Text('Recovery ID')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Salesman')),
                            DataColumn(label: Text('Customers'), numeric: true),
                            DataColumn(label: Text('Invoices'), numeric: true),
                            DataColumn(label: Text('Received'), numeric: true),
                            DataColumn(label: Text('Discount'), numeric: true),
                          ],
                          rows: items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final customerCount =
                                item.customerRecoveries.length;
                            final invoiceCount =
                                item.customerRecoveries.fold<int>(
                              0,
                              (sum, customer) =>
                                  sum +
                                  ((customer['invoices'] as List?)?.length ??
                                      0),
                            );
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
                                DataCell(Text(item.recoveryId)),
                                DataCell(Text(
                                    AppUtils.formatDate(item.recoveryDate))),
                                DataCell(Text(item.salesmanName)),
                                DataCell(Text('$customerCount')),
                                DataCell(Text('$invoiceCount')),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.netReceived)),
                                ),
                                DataCell(
                                  Text(AppUtils.fmtAmt(item.discount)),
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

class _RecoveryInvoiceWiseFormDialog extends StatefulWidget {
  const _RecoveryInvoiceWiseFormDialog({this.initial});

  final RecoveryInvoiceWiseModel? initial;

  @override
  State<_RecoveryInvoiceWiseFormDialog> createState() =>
      _RecoveryInvoiceWiseFormDialogState();
}

class _RecoveryInvoiceWiseFormDialogState
    extends State<_RecoveryInvoiceWiseFormDialog> {
  String? _currentId;
  bool _isSaving = false;

  final _recoveryDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  String _salesmanId = '';
  String _recoveryId = '';
  final _salesmanNameCtrl = TextEditingController();
  String _townId = '';
  String _sectorId = '';
  bool _showSalesmanInNarration = false;

  final Map<String, List<Map<String, dynamic>>> _customerInvoices = {};

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    _recoveryDateCtrl.dispose();
    _salesmanNameCtrl.dispose();
    _disposeCustomerInvoices();
    super.dispose();
  }

  void _disposeCustomerInvoices() {
    for (final invoices in _customerInvoices.values) {
      for (final invoice in invoices) {
        (invoice['receivedCtrl'] as TextEditingController?)?.dispose();
        (invoice['discountCtrl'] as TextEditingController?)?.dispose();
        (invoice['narrationCtrl'] as TextEditingController?)?.dispose();
      }
    }
  }

  void _clearForm() {
    _disposeCustomerInvoices();
    setState(() {
      _currentId = null;
      _salesmanId = '';
      _townId = '';
      _sectorId = '';
      _showSalesmanInNarration = false;
      _customerInvoices.clear();
      _recoveryId = '';
    });
    _recoveryDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _salesmanNameCtrl.clear();
  }

  List<Map<String, dynamic>> _invoiceRowsFromSaved(List<dynamic> invoices) {
    return invoices.map<Map<String, dynamic>>((raw) {
      final invoice = Map<String, dynamic>.from(raw as Map);
      final received = (invoice['received'] as num?)?.toDouble() ?? 0;
      final discount = (invoice['discount'] as num?)?.toDouble() ?? 0;
      final invoiceValue = (invoice['invoiceValue'] as num?)?.toDouble() ?? 0;
      return {
        'saleId': invoice['saleId'],
        'saleDisplayId': invoice['saleDisplayId'] ?? invoice['saleId'] ?? '',
        'date': '${invoice['date'] ?? ''}',
        'invoiceValue': invoiceValue,
        'adjusted': (invoice['adjusted'] as num?)?.toDouble() ?? 0,
        'receivable':
            (invoice['receivable'] as num?)?.toDouble() ?? invoiceValue,
        'receivedCtrl':
            TextEditingController(text: received.toStringAsFixed(2)),
        'discountCtrl':
            TextEditingController(text: discount.toStringAsFixed(2)),
        'narrationCtrl':
            TextEditingController(text: '${invoice['narration'] ?? ''}'),
      };
    }).toList();
  }

  void _loadFromModel(RecoveryInvoiceWiseModel model) {
    _disposeCustomerInvoices();
    _currentId = model.id;
    _salesmanId = model.salesmanId;
    _recoveryId = model.recoveryId;
    _townId = model.townId;
    _sectorId = model.sectorId;
    _showSalesmanInNarration = model.showSalesmanInNarration;
    _recoveryDateCtrl.text = model.recoveryDate;
    _salesmanNameCtrl.text = model.salesmanName;
    _customerInvoices.clear();
    for (final customer in model.customerRecoveries) {
      final customerId = '${customer['customerId'] ?? ''}';
      final invoices = (customer['invoices'] as List?) ?? const [];
      _customerInvoices[customerId] = _invoiceRowsFromSaved(invoices);
    }
  }

  void _populate() {
    final salesInvoices = context.read<SalesInvoiceController>().items;
    final filtered = _salesmanId.isEmpty
        ? salesInvoices
        : salesInvoices
            .where((invoice) => invoice.salesmanId == _salesmanId)
            .toList();
    _disposeCustomerInvoices();
    setState(() {
      _customerInvoices.clear();
      for (final sale in filtered) {
        _customerInvoices.putIfAbsent(sale.customerId, () => []).add({
          'saleId': sale.id,
          'saleDisplayId': sale.saleId,
          'date': sale.entryDate,
          'invoiceValue': sale.totalPayable,
          'adjusted': 0.0,
          'receivable': sale.totalPayable,
          'receivedCtrl': TextEditingController(text: '0'),
          'discountCtrl': TextEditingController(text: '0'),
          'narrationCtrl': TextEditingController(),
        });
      }
    });
  }

  Map<String, dynamic> _buildPayload() {
    final customerRecoveries = <Map<String, dynamic>>[];
    for (final entry in _customerInvoices.entries) {
      customerRecoveries.add({
        'customerId': entry.key,
        'invoices': entry.value.map((invoice) {
          final received = double.tryParse(
                (invoice['receivedCtrl'] as TextEditingController).text,
              ) ??
              0;
          final discount = double.tryParse(
                (invoice['discountCtrl'] as TextEditingController).text,
              ) ??
              0;
          return {
            'saleId': invoice['saleId'],
            'saleDisplayId': invoice['saleDisplayId'],
            'date': invoice['date'],
            'invoiceValue': invoice['invoiceValue'],
            'adjusted': invoice['adjusted'],
            'receivable': invoice['receivable'],
            'received': received,
            'discount': discount,
            'balance': ((invoice['receivable'] as num?)?.toDouble() ?? 0) -
                received -
                discount,
            'narration':
                (invoice['narrationCtrl'] as TextEditingController).text,
          };
        }).toList(),
      });
    }
    final netReceived = customerRecoveries.fold<double>(
      0,
      (sum, customer) =>
          sum +
          (customer['invoices'] as List).fold<double>(
            0,
            (inner, invoice) =>
                inner + ((invoice['received'] as num?)?.toDouble() ?? 0),
          ),
    );
    final discount = customerRecoveries.fold<double>(
      0,
      (sum, customer) =>
          sum +
          (customer['invoices'] as List).fold<double>(
            0,
            (inner, invoice) =>
                inner + ((invoice['discount'] as num?)?.toDouble() ?? 0),
          ),
    );
    return {
      'recoveryDate': _recoveryDateCtrl.text,
      'salesmanId': _salesmanId,
      'salesmanName': _salesmanNameCtrl.text,
      'townId': _townId,
      'sectorId': _sectorId,
      'showSalesmanInNarration': _showSalesmanInNarration,
      'customerRecoveries': customerRecoveries,
      'netReceived': netReceived,
      'discount': discount,
      'grossRecoveries': netReceived + discount,
      'status': 'saved',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<RecoveryInvoiceWiseController>();
      if (_currentId == null) {
        final record = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = record.id;
          _recoveryId = record.recoveryId;
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
        content: const Text('Delete this recovery?'),
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
      await context.read<RecoveryInvoiceWiseController>().deleteItem(
            _currentId!,
          );
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final salesmen = context.watch<SalesmenController>().typedItems;
    final towns = context.watch<TownsController>().typedItems;
    final sectors = context.watch<SectorsController>().typedItems;
    final customers = context.watch<CustomersController>().typedItems;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InvoicingFormDialog(
      title: 'Recovery (Invoice Wise)',
      badgeText: _recoveryId.isNotEmpty ? 'Recovery ID: $_recoveryId' : null,
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
                    controller: _recoveryDateCtrl,
                    decoration: _dec('Recovery Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_recoveryDateCtrl.text) ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _recoveryDateCtrl.text =
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
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: _townId.isEmpty ? null : _townId,
                    decoration: _dec('Town'),
                    isExpanded: true,
                    items: towns
                        .map(
                          (town) => DropdownMenuItem<String>(
                            value: town.id,
                            child: Text(
                              town.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _townId = value ?? ''),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: _sectorId.isEmpty ? null : _sectorId,
                    decoration: _dec('Sector'),
                    isExpanded: true,
                    items: sectors
                        .map(
                          (sector) => DropdownMenuItem<String>(
                            value: sector.id,
                            child: Text(
                              sector.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _sectorId = value ?? ''),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _showSalesmanInNarration,
                      onChanged: (value) => setState(
                        () => _showSalesmanInNarration = value ?? false,
                      ),
                    ),
                    const Text(
                      'Show Salesman in Narration',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _populate,
                  child: const Text('Populate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_customerInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Click Populate to load invoices.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ..._customerInvoices.entries.map((entry) {
              String customerName = entry.key;
              try {
                customerName = customers
                    .firstWhere((customer) => customer.id == entry.key)
                    .text('name');
              } catch (_) {}
              return ExpansionTile(
                title: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                tilePadding: isMobile
                    ? const EdgeInsets.symmetric(horizontal: 12)
                    : null,
                childrenPadding: isMobile
                    ? const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 8,
                        bottom: 12,
                      )
                    : EdgeInsets.zero,
                initiallyExpanded: true,
                children: [
                  if (isMobile)
                    Column(
                      children: entry.value.asMap().entries.map((invoiceEntry) {
                        final idx = invoiceEntry.key;
                        final invoice = invoiceEntry.value;
                        final received = double.tryParse(
                              (invoice['receivedCtrl'] as TextEditingController)
                                  .text,
                            ) ??
                            0;
                        final discount = double.tryParse(
                              (invoice['discountCtrl'] as TextEditingController)
                                  .text,
                            ) ??
                            0;
                        final invoiceValue =
                            (invoice['invoiceValue'] as num?)?.toDouble() ?? 0;
                        final receivable =
                            (invoice['receivable'] as num?)?.toDouble() ??
                                invoiceValue;
                        final balance = receivable - received - discount;
                        final saleId =
                            '${invoice['saleDisplayId'] ?? invoice['saleId'] ?? ''}';
                        final date = '${invoice['date'] ?? ''}';
                        final detailParts = <String>[];
                        if (date.isNotEmpty) detailParts.add(date);
                        detailParts.add(
                          'Inv ${AppUtils.fmtAmt2(invoiceValue)}',
                        );
                        detailParts.add(
                          'Recvbl ${AppUtils.fmtAmt2(receivable)}',
                        );
                        detailParts.add('Bal ${AppUtils.fmtAmt2(balance)}');
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: idx == entry.value.length - 1 ? 0 : 8,
                          ),
                          child: Container(
                            decoration: AppTheme.cardDecor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  saleId.isNotEmpty
                                      ? saleId
                                      : 'Sale ${idx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detailParts.join('  ·  '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 16, thickness: 1),
                                const SizedBox(height: 4),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final fieldWidth =
                                        (constraints.maxWidth - 8) / 2;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        SizedBox(
                                          width: fieldWidth,
                                          child: TextFormField(
                                            controller: invoice['receivedCtrl']
                                                as TextEditingController,
                                            decoration: _dec('Received'),
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        SizedBox(
                                          width: fieldWidth,
                                          child: TextFormField(
                                            controller: invoice['discountCtrl']
                                                as TextEditingController,
                                            decoration: _dec('Discount'),
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        SizedBox(
                                          width: constraints.maxWidth,
                                          child: TextFormField(
                                            controller: invoice['narrationCtrl']
                                                as TextEditingController,
                                            decoration: _dec('Narration'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    HorizontalScrollWheel(
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(AppTheme.clayBg),
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 52,
                        columns: const [
                          DataColumn(label: Text('Sale ID')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Inv Value')),
                          DataColumn(label: Text('Receivable')),
                          DataColumn(label: Text('Received')),
                          DataColumn(label: Text('Discount')),
                          DataColumn(label: Text('Balance')),
                          DataColumn(label: Text('Narration')),
                        ],
                        rows: entry.value.asMap().entries.map((invoiceEntry) {
                          final idx = invoiceEntry.key;
                          final invoice = invoiceEntry.value;
                          final received = double.tryParse(
                                (invoice['receivedCtrl']
                                        as TextEditingController)
                                    .text,
                              ) ??
                              0;
                          final discount = double.tryParse(
                                (invoice['discountCtrl']
                                        as TextEditingController)
                                    .text,
                              ) ??
                              0;
                          final receivable = (invoice['receivable'] as num?)
                                  ?.toDouble() ??
                              (invoice['invoiceValue'] as num?)?.toDouble() ??
                              0;
                          final balance = receivable - received - discount;
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
                              DataCell(
                                Text(
                                  '${invoice['saleDisplayId'] ?? invoice['saleId'] ?? ''}',
                                ),
                              ),
                              DataCell(Text('${invoice['date'] ?? ''}')),
                              DataCell(
                                Text(
                                  ((invoice['invoiceValue'] as num?)
                                              ?.toDouble() ??
                                          0)
                                      .toStringAsFixed(2),
                                ),
                              ),
                              DataCell(Text(receivable.toStringAsFixed(2))),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: invoice['receivedCtrl']
                                        as TextEditingController,
                                    decoration: _dec(''),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: invoice['discountCtrl']
                                        as TextEditingController,
                                    decoration: _dec(''),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                              DataCell(Text(balance.toStringAsFixed(2))),
                              DataCell(
                                SizedBox(
                                  width: 160,
                                  child: TextFormField(
                                    controller: invoice['narrationCtrl']
                                        as TextEditingController,
                                    decoration: _dec(''),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            }),
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
