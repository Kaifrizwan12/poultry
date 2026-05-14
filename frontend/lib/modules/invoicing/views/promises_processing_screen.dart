import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../models/payment_promise_model.dart';

class PromisesProcessingScreen extends StatefulWidget {
  const PromisesProcessingScreen({super.key});

  @override
  State<PromisesProcessingScreen> createState() => _PromisesProcessingScreenState();
}

class _PromisesProcessingScreenState extends State<PromisesProcessingScreen> {
  String _typeFilter = '';
  final _dueDateCtrl = TextEditingController();
  String _statusFilter = 'pending';
  List<PaymentPromiseModel> _loaded = [];

  @override
  void dispose() {
    _dueDateCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final ctrl = context.read<PaymentPromiseController>();
    var filtered = ctrl.items.toList();
    if (_typeFilter.isNotEmpty) filtered = filtered.where((p) => p.promiseType == _typeFilter).toList();
    if (_dueDateCtrl.text.isNotEmpty) filtered = filtered.where((p) => p.promiseDate.compareTo(_dueDateCtrl.text) <= 0).toList();
    if (_statusFilter.isNotEmpty) filtered = filtered.where((p) => p.status == _statusFilter).toList();
    setState(() => _loaded = filtered);
  }

  Future<void> _updateStatus(String id, String status) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      await context.read<PaymentPromiseController>().updateStatus(id, status, processedDate: today);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final totalDue = _loaded.fold<double>(0, (s, p) => s + p.amount);
    final cleared = _loaded.where((p) => p.status == 'cleared').fold<double>(0, (s, p) => s + p.amount);
    final bounced = _loaded.where((p) => p.status == 'bounced').fold<double>(0, (s, p) => s + p.amount);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Promises Processing', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecor, padding: AppTheme.cardPadding,
                child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _typeFilter.isEmpty ? null : _typeFilter,
                      decoration: _dec('Promise Type'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'recovery', child: Text('Recovery')),
                        DropdownMenuItem(value: 'payment', child: Text('Payment')),
                      ],
                      onChanged: (val) => setState(() => _typeFilter = val ?? ''),
                    ),
                  ),
                  SizedBox(width: 160, child: TextFormField(controller: _dueDateCtrl, decoration: _dec('Due Date (up to)'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _dueDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter.isEmpty ? null : _statusFilter,
                      decoration: _dec('Status'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'cleared', child: Text('Cleared')),
                        DropdownMenuItem(value: 'bounced', child: Text('Bounced')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) => setState(() => _statusFilter = val ?? ''),
                    ),
                  ),
                  ElevatedButton(onPressed: _load, child: const Text('Load')),
                ]),
              ),
              const SizedBox(height: 16),
              if (_loaded.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Apply filters and click Load.', style: TextStyle(color: AppTheme.textSecondary)))
              else Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RepaintBoundary(
                  child: Container(
                    decoration: AppTheme.cardDecor,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                        dataRowMinHeight: 44, dataRowMaxHeight: 56,
                        columns: const [
                          DataColumn(label: Text('Promise ID')), DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Date')), DataColumn(label: Text('Customer/Vendor')),
                          DataColumn(label: Text('Cheque No')), DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')), DataColumn(label: Text('Actions')),
                        ],
                        rows: _loaded.asMap().entries.map((en) {
                          final idx = en.key; final p = en.value;
                          final party = p.promiseType == 'recovery' ? p.customerName : p.vendorName;
                          final isPending = p.status == 'pending';
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((s) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.5) : Colors.transparent),
                            cells: [
                              DataCell(Text(p.promiseId.isNotEmpty ? p.promiseId : p.id)),
                              DataCell(Text(p.promiseType)),
                              DataCell(Text(p.promiseDate)),
                              DataCell(Text(party)),
                              DataCell(Text(p.chequeNo)),
                              DataCell(Text(p.amount.toStringAsFixed(2))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.status == 'cleared' ? AppTheme.successBg : p.status == 'bounced' ? AppTheme.dangerBg : AppTheme.warningBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(p.status, style: TextStyle(color: p.status == 'cleared' ? AppTheme.successText : p.status == 'bounced' ? AppTheme.dangerText : AppTheme.warningText, fontSize: 11, fontWeight: FontWeight.w600)),
                              )),
                              DataCell(isPending
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      TextButton(onPressed: () => _updateStatus(p.id, 'cleared'), child: const Text('Clear', style: TextStyle(color: AppTheme.successText, fontSize: 12))),
                                      TextButton(onPressed: () => _updateStatus(p.id, 'bounced'), child: const Text('Bounce', style: TextStyle(color: AppTheme.dangerText, fontSize: 12))),
                                      TextButton(onPressed: () => _updateStatus(p.id, 'cancelled'), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                    ])
                                  : Text(p.status, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: AppTheme.clayBg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Text('Total Due: ${totalDue.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 24),
                    Text('Cleared: ${cleared.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 24),
                    Text('Bounced: ${bounced.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.dangerText, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ]),
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
