import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import '../widgets/record_browser_dialog.dart';
import 'package:provider/provider.dart';

import '../controllers/cash_voucher_controller.dart';
import '../models/cash_voucher_model.dart';
import '../widgets/voucher_line_row.dart';

class CashVoucherScreen extends StatefulWidget {
  const CashVoucherScreen({super.key, required this.voucherType});
  final String voucherType;

  @override
  State<CashVoucherScreen> createState() => _CashVoucherScreenState();
}

class _CashVoucherScreenState extends State<CashVoucherScreen> {
  String? _currentId;
  bool _isSaving = false;
  final ValueNotifier<List<Map<String, dynamic>>> _linesNotifier = ValueNotifier([]);

  String _voucherNo = '';
  final _voucherDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));

  @override
  void dispose() {
    _voucherDateCtrl.dispose();
    _linesNotifier.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.voucherType) {
      case 'credit': return 'Cash Receiving Voucher';
      case 'debit': return 'Cash Payment Voucher';
      default: return 'Journal Voucher';
    }
  }

  void _clearForm() {
    setState(() { _currentId = null; _voucherNo = ''; });
    _voucherDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _linesNotifier.value = [];
  }

  void _loadFromModel(CashVoucherModel m) {
    setState(() { _currentId = m.id; _voucherNo = m.voucherNo; });
    _voucherDateCtrl.text = m.voucherDate;
    _linesNotifier.value = List<Map<String, dynamic>>.from(m.lines);
  }

  Map<String, dynamic> _buildPayload() {
    final lines = _linesNotifier.value;
    final debitSum = lines.fold<double>(0, (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0));
    final creditSum = lines.fold<double>(0, (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0));
    return { 'voucherType': widget.voucherType, 'voucherDate': _voucherDateCtrl.text, 'lines': lines, 'totals': { 'debit': debitSum, 'credit': creditSum }, 'status': 'saved' };
  }

  Future<void> _save() async {
    final lines = _linesNotifier.value;
    if (widget.voucherType == 'journal') {
      final debitSum = lines.fold<double>(0, (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0));
      final creditSum = lines.fold<double>(0, (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0));
      if ((debitSum - creditSum).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal voucher: Debit must equal Credit')));
        return;
      }
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<CashVoucherController>();
      if (_currentId == null) { final r = await ctrl.add(_buildPayload()); setState(() { _currentId = r.id; _voucherNo = r.voucherNo; }); }
      else { await ctrl.updateItem(_currentId!, _buildPayload()); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _remove() async {
    if (_currentId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm Delete'), content: const Text('Delete this voucher?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete'))]));
    if (ok == true) { await context.read<CashVoucherController>().deleteItem(_currentId!); _clearForm(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); }
  }

  Future<void> _openRecords() async {
    final ctrl = context.read<CashVoucherController>();
    if (ctrl.items.isEmpty) await ctrl.fetchAll();
    if (!mounted) return;
    final record = await RecordBrowserDialog.show<CashVoucherModel>(
      context: context,
      records: ctrl.items,
      title: 'Cash Vouchers',
      getBusinessId: (m) => m.voucherNo,
      getTitle: (m) => '${m.voucherNo}  -  ${m.voucherType}',
      getSubtitle: (m) => '${m.voucherDate.isNotEmpty ? m.voucherDate.substring(0,10) : "?"}  |  ${m.isConfirmed ? "confirmed" : "unconfirmed"}',
    );
    if (record != null && mounted) _loadFromModel(record);
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding, child: Wrap(spacing: 12, runSpacing: 12, children: [
                if (_voucherNo.isNotEmpty)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)), child: Text('Voucher No: $_voucherNo', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w700, fontSize: 14))),
                SizedBox(width: 160, child: TextFormField(controller: _voucherDateCtrl, decoration: _dec('Voucher Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_voucherDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _voucherDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
              ])),
              const SizedBox(height: 16),
              VoucherLineRow(voucherType: widget.voucherType, onAdd: (line) => _linesNotifier.value = [..._linesNotifier.value, line]),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _linesNotifier,
                  builder: (context, lines, _) {
                    if (lines.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No lines added.', style: TextStyle(color: AppTheme.textSecondary)));
                    final debitSum = lines.fold<double>(0, (s, l) => s + ((l['debit'] as num?)?.toDouble() ?? 0));
                    final creditSum = lines.fold<double>(0, (s, l) => s + ((l['credit'] as num?)?.toDouble() ?? 0));
                    final showDebit = widget.voucherType != 'credit';
                    final showCredit = widget.voucherType != 'debit';
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(decoration: AppTheme.cardDecor, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg), dataRowMinHeight: 36, dataRowMaxHeight: 44,
                        columns: [
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('Account No')),
                          const DataColumn(label: Text('Account Name')),
                          if (showDebit) const DataColumn(label: Text('Debit')),
                          if (showCredit) const DataColumn(label: Text('Credit')),
                          const DataColumn(label: Text('Narration')),
                          const DataColumn(label: Text('')),
                        ],
                        rows: lines.asMap().entries.map((en) { final idx = en.key; final l = en.value; return DataRow(
                          color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                          cells: [
                            DataCell(Text('${idx + 1}')),
                            DataCell(Text(l['accountCode'] ?? '')),
                            DataCell(Text(l['accountName'] ?? '')),
                            if (showDebit) DataCell(Text((l['debit'] as num?)?.toStringAsFixed(2) ?? '0')),
                            if (showCredit) DataCell(Text((l['credit'] as num?)?.toStringAsFixed(2) ?? '0')),
                            DataCell(Text(l['narration'] ?? '')),
                            DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText), onPressed: () { final u = [...lines]; u.removeAt(idx); _linesNotifier.value = u; })),
                          ],
                        ); }).toList(),
                      ))),
                      const SizedBox(height: 8),
                      Container(color: AppTheme.clayBg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
                        const Text('Totals: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (showDebit) ...[Text('Debit: ${debitSum.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 20)],
                        if (showCredit) Text('Credit: ${creditSum.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ])),
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
            TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not yet implemented'))), child: const Text('Print')),
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
