import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/payment_promise_controller.dart';
import '../models/payment_promise_model.dart';

class PromisesProcessingScreen extends StatefulWidget {
  const PromisesProcessingScreen({super.key});

  @override
  State<PromisesProcessingScreen> createState() =>
      _PromisesProcessingScreenState();
}

class _PromisesProcessingScreenState extends State<PromisesProcessingScreen> {
  String _typeFilter = '';
  final _dueDateCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = context.read<PaymentPromiseController>();
      if (ctrl.items.isEmpty) {
        await ctrl.fetchAll();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dueDateCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PaymentPromiseModel> _visibleItems(PaymentPromiseController ctrl) {
    var items = ctrl.items.toList();
    if (_typeFilter.isNotEmpty) {
      items = items.where((item) => item.promiseType == _typeFilter).toList();
    }
    if (_dueDateCtrl.text.isNotEmpty) {
      items = items
          .where((item) => item.promiseDate.compareTo(_dueDateCtrl.text) <= 0)
          .toList();
    }
    if (_statusFilter.isNotEmpty) {
      items = items.where((item) => item.status == _statusFilter).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final party = item.promiseType == 'recovery'
          ? item.customerName
          : item.vendorName;
      return item.promiseId.toLowerCase().contains(q) ||
          party.toLowerCase().contains(q) ||
          item.chequeNo.toLowerCase().contains(q) ||
          item.promiseDate.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _updateStatus(String id, String status) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      await context.read<PaymentPromiseController>().updateStatus(
            id,
            status,
            processedDate: today,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentPromiseController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        final totalDue = items.fold<double>(0, (sum, item) => sum + item.amount);
        final cleared = items
            .where((item) => item.status == 'cleared')
            .fold<double>(0, (sum, item) => sum + item.amount);
        final bounced = items
            .where((item) => item.status == 'bounced')
            .fold<double>(0, (sum, item) => sum + item.amount);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promises Processing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by promise ID, party, cheque no, due date or status',
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
              Container(
                decoration: AppTheme.cardDecor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _typeFilter.isEmpty ? null : _typeFilter,
                        decoration: _dec('Promise Type'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text('All'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'recovery',
                            child: Text('Recovery'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'payment',
                            child: Text('Payment'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value ?? ''),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _dueDateCtrl,
                        decoration: _dec('Due Date (up to)'),
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
                              _dueDateCtrl.text =
                                  picked.toIso8601String().substring(0, 10);
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter.isEmpty ? null : _statusFilter,
                        decoration: _dec('Status'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text('All'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'cleared',
                            child: Text('Cleared'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'bounced',
                            child: Text('Bounced'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'cancelled',
                            child: Text('Cancelled'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value ?? ''),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _typeFilter = '';
                        _statusFilter = 'pending';
                        _dueDateCtrl.clear();
                        _searchCtrl.clear();
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (ctrl.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No promises found yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching promises.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                DataColumn(label: Text('Promise ID')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Customer/Vendor')),
                                DataColumn(label: Text('Cheque No')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final party = item.promiseType == 'recovery'
                                    ? item.customerName
                                    : item.vendorName;
                                final isPending = item.status == 'pending';
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith(
                                    (states) => idx.isOdd
                                        ? AppTheme.clayBg.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        item.promiseId.isNotEmpty
                                            ? item.promiseId
                                            : '—',
                                      ),
                                    ),
                                    DataCell(Text(item.promiseType)),
                                    DataCell(Text(item.promiseDate)),
                                    DataCell(Text(party)),
                                    DataCell(Text(item.chequeNo)),
                                    DataCell(
                                      Text(item.amount.toStringAsFixed(2)),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.status == 'cleared'
                                              ? AppTheme.successBg
                                              : item.status == 'bounced'
                                                  ? AppTheme.dangerBg
                                                  : AppTheme.warningBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(
                                            color: item.status == 'cleared'
                                                ? AppTheme.successText
                                                : item.status == 'bounced'
                                                    ? AppTheme.dangerText
                                                    : AppTheme.warningText,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      isPending
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _updateStatus(
                                                    item.id,
                                                    'cleared',
                                                  ),
                                                  child: const Text(
                                                    'Clear',
                                                    style: TextStyle(
                                                      color: AppTheme.successText,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _updateStatus(
                                                    item.id,
                                                    'bounced',
                                                  ),
                                                  child: const Text(
                                                    'Bounce',
                                                    style: TextStyle(
                                                      color: AppTheme.dangerText,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _updateStatus(
                                                    item.id,
                                                    'cancelled',
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              item.status,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
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
                              Text(
                                'Total Due: ${totalDue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Cleared: ${cleared.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.successText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                'Bounced: ${bounced.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.dangerText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
