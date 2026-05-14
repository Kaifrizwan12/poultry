import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/utils/code_generators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/chicken_invoice_controller.dart';
import '../controllers/flock_controller.dart';
import '../models/flock_model.dart';
import '../models/chicken_invoice_model.dart';
import '../widgets/auto_calc_field.dart';

/// Used inside FlockDetailScreen (tab 2) with a specific flock context.
class ChickenInvoiceScreen extends StatelessWidget {
  const ChickenInvoiceScreen({super.key, required this.flockId, required this.flock});
  final String flockId;
  final FlockModel flock;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChickenInvoiceController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
        if (ctrl.error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ctrl.error!),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => ctrl.fetchByFlock(flockId), child: const Text('Retry')),
        ]));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(
                'Available: ${flock.currentBirdsCount} birds',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              )),
              ElevatedButton.icon(
                onPressed: flock.currentBirdsCount <= 0 ? null : () => _openEditor(context, ctrl),
                icon: const Icon(Icons.add),
                label: const Text('New Invoice'),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(child: ctrl.items.isEmpty
              ? const Center(child: Text('No sales invoices yet', style: TextStyle(color: AppTheme.textSecondary)))
              : _InvoiceList(items: ctrl.items, flock: flock, ctrl: ctrl)),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, ChickenInvoiceController ctrl, [ChickenInvoiceModel? item]) {
    final customerOpts = context.read<CustomersController>().items
        .map((c) => LookupOption(value: c.id, label: c.text('name'))).toList();
    final salesmanOpts = context.read<SalesmenController>().items
        .map((s) => LookupOption(value: s.id, label: s.text('name'))).toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width - 24 : 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _InvoiceForm(
              ctrl: ctrl,
              flock: flock,
              customerOptions: customerOpts,
              salesmanOptions: salesmanOpts,
              item: item,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({required this.items, required this.flock, required this.ctrl});
  final List<ChickenInvoiceModel> items;
  final FlockModel flock;
  final ChickenInvoiceController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: items.map((item) {
          final statusColor = item.paymentStatus == 'paid'
              ? AppTheme.successText
              : item.paymentStatus == 'partial'
                  ? AppTheme.terra600
                  : AppTheme.dangerText;
          final statusBg = item.paymentStatus == 'paid'
              ? AppTheme.successBg
              : item.paymentStatus == 'partial'
                  ? AppTheme.terra50
                  : const Color(0xFFFEF2F2);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.invoiceNo, style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_formatDate(item.invoiceDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(item.paymentStatus[0].toUpperCase() + item.paymentStatus.substring(1),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {
                    final screen = context.findAncestorWidgetOfExactType<ChickenInvoiceScreen>();
                    screen?._openEditor(context, ctrl, item);
                  }),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText),
                    onPressed: () => _delete(context, item),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  _chip('Birds', '${item.birdsCount}'),
                  if (item.saleType.isNotEmpty)
                    _chip('Type', labelFor(kSaleTypes, item.saleType)),
                  if (item.totalLiveWeightKg > 0)
                    _chip('Live Wt', '${item.totalLiveWeightKg.toStringAsFixed(1)} kg'),
                  if (item.pricePerKg > 0)
                    _chip('Rate', '${item.pricePerKg}/kg'),
                  _chip('Total', item.totalAmount.toStringAsFixed(2), AppTheme.terra600),
                  if (item.balanceDue > 0)
                    _chip('Balance', item.balanceDue.toStringAsFixed(2), AppTheme.dangerText),
                ]),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(String label, String value, [Color? valueColor]) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.pageBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.softBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return iso.split('T').first; }
  }

  Future<void> _delete(BuildContext context, ChickenInvoiceModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice ${item.invoiceNo}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.dangerText), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try { await ctrl.deleteItem(item.id); } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.dangerText, content: Text(e.toString())));
      }
    }
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _InvoiceForm extends StatefulWidget {
  const _InvoiceForm({
    required this.ctrl,
    required this.flock,
    required this.customerOptions,
    required this.salesmanOptions,
    this.item,
  });
  final ChickenInvoiceController ctrl;
  final FlockModel flock;
  final List<LookupOption> customerOptions;
  final List<LookupOption> salesmanOptions;
  final ChickenInvoiceModel? item;

  @override
  State<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<_InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;

  double _grossAmount = 0;
  double _discountAmount = 0;
  double _netAmount = 0;
  double _taxAmount = 0;
  double _totalAmount = 0;
  double _balanceDue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _v = widget.item!.toJson();
      _grossAmount = widget.item!.grossAmount;
      _discountAmount = widget.item!.discountAmount;
      _netAmount = widget.item!.netAmount;
      _taxAmount = widget.item!.taxAmount;
      _totalAmount = widget.item!.totalAmount;
      _balanceDue = widget.item!.balanceDue;
    } else {
      _v = {
        'invoiceNo': generatedInvoiceNo(),
        'flockId': widget.flock.id,
        'invoiceDate': DateTime.now().toIso8601String(),
        'birdsCount': widget.flock.currentBirdsCount,
        'saleType': 'live_weight',
        'discountPercent':     0,
        'taxPercent':          0,
        'advanceReceived':     0,
        'postToLedger':        false,
        'createSalesInvoice':  false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item == null ? 'New Invoice' : 'Edit Invoice',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (widget.item == null)
              Text('Available birds: ${widget.flock.currentBirdsCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),

            _section('Invoice Details'),
            _field('Invoice No *', _text('invoiceNo', required: true)),
            _field('Invoice Date *', _datePicker('invoiceDate', required: true)),
            _field('Customer *', _dropdown('customerId', widget.customerOptions, required: true)),
            _field('Salesman', _dropdown('salesmanId', widget.salesmanOptions)),

            _section('Sale Details'),
            _field('Sale Type *', _dropdown('saleType', kSaleTypes, required: true)),
            _field('Birds Count *', _number('birdsCount', required: true, integer: true,
                hint: 'Max: ${widget.flock.currentBirdsCount}')),
            _field('Total Live Weight (kg)', _number('totalLiveWeightKg', decimal: true)),
            _field('Dressed Weight (kg)', _number('dressedWeightKg', decimal: true)),
            _field('Price Per Kg *', _number('pricePerKg', required: true, decimal: true)),

            _section('Amounts'),
            if (_grossAmount > 0) AutoCalcField(label: 'Gross Amount', value: _grossAmount.toStringAsFixed(2)),
            _field('Discount (%)', _number('discountPercent', decimal: true)),
            if (_discountAmount > 0) AutoCalcField(label: 'Discount Amount', value: _discountAmount.toStringAsFixed(2)),
            if (_netAmount > 0) AutoCalcField(label: 'Net Amount', value: _netAmount.toStringAsFixed(2)),
            _field('Tax (%)', _number('taxPercent', decimal: true)),
            if (_taxAmount > 0) AutoCalcField(label: 'Tax Amount', value: _taxAmount.toStringAsFixed(2)),
            if (_totalAmount > 0) AutoCalcField(label: 'Total Amount', value: _totalAmount.toStringAsFixed(2)),
            _field('Advance Received', _number('advanceReceived', decimal: true)),
            if (_balanceDue >= 0 && _totalAmount > 0)
              AutoCalcField(label: 'Balance Due', value: _balanceDue.toStringAsFixed(2)),

            _section('Logistics'),
            _field('Vehicle No', _text('vehicleNo')),
            _field('Driver Name', _text('driverName')),
            _field('Notes', _textArea('notes')),

            _section('Accounting Integration'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.clayBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'These options post this sale automatically to the Invoicing and Accounts modules. '
                    'Requires Posting Configuration to be set in Settings.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.terra400,
                    title: const Text('Create Sales Invoice',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Auto-creates a Sales Invoice in the Invoicing module using the configured Chicken Product.',
                        style: TextStyle(fontSize: 11)),
                    value: _v['createSalesInvoice'] == true,
                    onChanged: (v) => setState(() => _v['createSalesInvoice'] = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.terra400,
                    title: const Text('Post to Ledger',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Auto-posts Debit Accounts Receivable + Credit Sales Revenue entries to the accounts ledger.',
                        style: TextStyle(fontSize: 11)),
                    value: _v['postToLedger'] == true,
                    onChanged: (v) => setState(() => _v['postToLedger'] = v),
                  ),
                  if (_v['linkedSalesInvoiceId'] != null &&
                      (_v['linkedSalesInvoiceId'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.link, size: 14, color: AppTheme.successText),
                        const SizedBox(width: 4),
                        Text('Linked Sales Invoice created',
                            style: const TextStyle(fontSize: 11, color: AppTheme.successText)),
                      ]),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppTheme.terra600, fontWeight: FontWeight.w700, fontSize: 14)),
  );

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, height: 1)),
      const SizedBox(height: 6), child,
    ]),
  );

  Widget _text(String key, {bool required = false}) => TextFormField(
    initialValue: '${_v[key] ?? ''}', decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) => _v[key] = v,
  );

  Widget _textArea(String key) => TextFormField(
    initialValue: '${_v[key] ?? ''}', minLines: 2, maxLines: 4,
    decoration: const InputDecoration(), onChanged: (v) => _v[key] = v,
  );

  Widget _number(String key, {bool required = false, bool integer = false, bool decimal = false, String? hint}) =>
      TextFormField(
    initialValue: _v[key] != null ? '${_v[key]}' : '',
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(hintText: hint),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) {
      setState(() {
        _v[key] = integer
            ? (int.tryParse(v.trim()) ?? 0)
            : (double.tryParse(v.trim()) ?? 0);
        _recompute();
      });
    },
  );

  Widget _dropdown(String key, List<LookupOption> opts, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      items: opts.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      decoration: const InputDecoration(),
      validator: required ? (v) => (v ?? '').isEmpty ? 'Required' : null : null,
      onChanged: (v) => setState(() { _v[key] = v ?? ''; _recompute(); }),
    );
  }

  Widget _datePicker(String key, {bool required = false}) {
    final raw = '${_v[key] ?? ''}';
    String display = '';
    if (raw.isNotEmpty) {
      try {
        final d = DateTime.parse(raw);
        display = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      } catch (_) { display = raw.split('T').first; }
    }
    return TextFormField(
      key: ValueKey('$key:$raw'), readOnly: true, initialValue: display,
      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
      onTap: () async {
        final picked = await showDatePicker(context: context,
            initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) setState(() => _v[key] = picked.toIso8601String());
      },
    );
  }

  void _recompute() {
    final birds = (_v['birdsCount'] is num) ? (_v['birdsCount'] as num).toDouble() : 0.0;
    final liveWt = (_v['totalLiveWeightKg'] is num) ? (_v['totalLiveWeightKg'] as num).toDouble() : 0.0;
    final pricePerKg = (_v['pricePerKg'] is num) ? (_v['pricePerKg'] as num).toDouble() : 0.0;
    final discPct = (_v['discountPercent'] is num) ? (_v['discountPercent'] as num).toDouble() : 0.0;
    final taxPct = (_v['taxPercent'] is num) ? (_v['taxPercent'] as num).toDouble() : 0.0;
    final advance = (_v['advanceReceived'] is num) ? (_v['advanceReceived'] as num).toDouble() : 0.0;

    final saleType = '${_v['saleType'] ?? ''}';
    if (saleType == 'per_bird') {
      _grossAmount = birds * pricePerKg;
    } else {
      _grossAmount = liveWt * pricePerKg;
    }
    _discountAmount = _grossAmount * discPct / 100;
    _netAmount = _grossAmount - _discountAmount;
    _taxAmount = _netAmount * taxPct / 100;
    _totalAmount = _netAmount + _taxAmount;
    _balanceDue = _totalAmount - advance;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      if (widget.item == null) {
        await widget.ctrl.add(_v);
      } else {
        await widget.ctrl.updateItem(widget.item!.id, _v);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(backgroundColor: AppTheme.successText,
          content: const Text('Saved'), duration: const Duration(milliseconds: 2500)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppTheme.dangerText, content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
