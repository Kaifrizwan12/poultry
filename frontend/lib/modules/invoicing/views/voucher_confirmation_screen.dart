import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cash_voucher_controller.dart';
import '../models/cash_voucher_model.dart';

class VoucherConfirmationScreen extends StatefulWidget {
  const VoucherConfirmationScreen({super.key});

  @override
  State<VoucherConfirmationScreen> createState() => _VoucherConfirmationScreenState();
}

class _VoucherConfirmationScreenState extends State<VoucherConfirmationScreen> {
  String _typeFilter = '';
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  List<CashVoucherModel> _loaded = [];

  @override
  void dispose() {
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final ctrl = context.read<CashVoucherController>();
    var filtered = ctrl.items.where((v) => !v.isConfirmed).toList();
    if (_typeFilter.isNotEmpty) filtered = filtered.where((v) => v.voucherType == _typeFilter).toList();
    if (_dateFromCtrl.text.isNotEmpty) filtered = filtered.where((v) => v.voucherDate.compareTo(_dateFromCtrl.text) >= 0).toList();
    if (_dateToCtrl.text.isNotEmpty) filtered = filtered.where((v) => v.voucherDate.compareTo(_dateToCtrl.text) <= 0).toList();
    setState(() => _loaded = filtered);
  }

  Future<void> _confirm(String id) async {
    try {
      await context.read<CashVoucherController>().confirmVoucher(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher confirmed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  String _typeLabel(String type) {
    switch (type) {
      case 'credit': return 'Cash Receiving';
      case 'debit': return 'Cash Payment';
      case 'journal': return 'Journal';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Voucher Confirmation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding,
                child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _typeFilter.isEmpty ? null : _typeFilter,
                      decoration: _dec('Voucher Type'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'credit', child: Text('Cash Receiving')),
                        DropdownMenuItem(value: 'debit', child: Text('Cash Payment')),
                        DropdownMenuItem(value: 'journal', child: Text('Journal')),
                      ],
                      onChanged: (val) => setState(() => _typeFilter = val ?? ''),
                    ),
                  ),
                  SizedBox(width: 160, child: TextFormField(controller: _dateFromCtrl, decoration: _dec('Date From'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateFromCtrl.text = p.toIso8601String().substring(0, 10)); })),
                  SizedBox(width: 160, child: TextFormField(controller: _dateToCtrl, decoration: _dec('Date To'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dateToCtrl.text = p.toIso8601String().substring(0, 10)); })),
                  ElevatedButton(onPressed: _load, child: const Text('Load')),
                ]),
              ),
              const SizedBox(height: 16),
              if (_loaded.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No unconfirmed vouchers. Apply filters and click Load.', style: TextStyle(color: AppTheme.textSecondary)))
              else RepaintBoundary(
                child: Container(
                  decoration: AppTheme.cardDecor,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                      dataRowMinHeight: 44, dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(label: Text('Voucher No')), DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Type')), DataColumn(label: Text('Debit')),
                        DataColumn(label: Text('Credit')), DataColumn(label: Text('Lines')),
                        DataColumn(label: Text('Confirmed')), DataColumn(label: Text('Action')),
                      ],
                      rows: _loaded.asMap().entries.map((en) {
                        final idx = en.key; final v = en.value;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [
                            DataCell(Text(v.voucherNo.isNotEmpty ? v.voucherNo : v.id)),
                            DataCell(Text(v.voucherDate)),
                            DataCell(Text(_typeLabel(v.voucherType))),
                            DataCell(Text(v.totalDebit.toStringAsFixed(2))),
                            DataCell(Text(v.totalCredit.toStringAsFixed(2))),
                            DataCell(Text('${v.lines.length}')),
                            DataCell(Icon(v.isConfirmed ? Icons.check_circle : Icons.pending, color: v.isConfirmed ? AppTheme.successText : AppTheme.textSecondary, size: 18)),
                            DataCell(v.isConfirmed
                                ? const Text('Confirmed', style: TextStyle(color: AppTheme.successText, fontSize: 12))
                                : ElevatedButton(
                                    onPressed: () => _confirm(v.id),
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), backgroundColor: AppTheme.terra400),
                                    child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                                  )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              if (_loaded.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  color: AppTheme.clayBg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Text('Pending Total (Debit): ${_loaded.where((v) => !v.isConfirmed).fold<double>(0, (s, v) => s + v.totalDebit).toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite, padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Spacer(),
            OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Close')),
          ]),
        ),
      ],
    );
  }
}
