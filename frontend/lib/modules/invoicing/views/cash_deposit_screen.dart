import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/core/responsive_add_button.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_deposit_controller.dart';
import '../models/bank_deposit_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';
import 'package:farm_mgt_auth/core/app_utils.dart';
import 'package:farm_mgt_auth/core/record_card.dart';

class CashDepositScreen extends StatefulWidget {
  const CashDepositScreen({super.key});

  @override
  State<CashDepositScreen> createState() => _CashDepositScreenState();
}

class _CashDepositScreenState extends State<CashDepositScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<BankDepositController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({BankDepositModel? initial}) async {
    await showInvoicingForm(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<BankDepositController>()),
          ChangeNotifierProvider.value(value: context.read<AccountsController>()),
        ],
        child: _CashDepositFormDialog(initial: initial),
      ),
    );
  }

  List<BankDepositModel> _visibleItems(BankDepositController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final deposits = ctrl.items.where((d) => d.depositType == 'cash').toList();
    if (q.isEmpty) return deposits;
    return deposits.where((item) {
      return item.depositId.toLowerCase().contains(q) ||
          item.bankAccountName.toLowerCase().contains(q) ||
          item.depositSlipNo.toLowerCase().contains(q) ||
          item.depositDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BankDepositController>(
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
                      'Cash Deposit in Bank',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ResponsiveAddButton(
                    onPressed: () => _openForm(),
                    label: 'New Cash Deposit',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by deposit ID, bank, slip no or date',
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
              if (ctrl.isLoading)
                const Expanded(child: SizedBox.shrink())
              else if (ctrl.items.where((e) => e.depositType == 'cash').isEmpty)
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create First Cash Deposit'),
                    ),
                  ),
                )
              else if (!ctrl.isLoading && items.isEmpty)
                const Expanded(child: Center(child: Text('No matching cash deposits found.', style: TextStyle(color: AppTheme.textSecondary))))
              else if (isMobile)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return RecordCard(
                        id: item.depositId,
                        subtitle: item.bankAccountName,
                        meta: AppUtils.formatDate(item.depositDate),
                        amount: AppUtils.fmtAmt(item.amount),
                        onTap: () => _openForm(initial: item),
                      );
                    },
                  )
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      decoration: AppTheme.cardDecor,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.clayBg),
                        columnSpacing: AppTheme.tableColSpacing,
                        horizontalMargin: AppTheme.tableHMargin,
                        dataRowMinHeight: AppTheme.tableRowMin,
                        dataRowMaxHeight: AppTheme.tableRowMax,
                        headingRowHeight: AppTheme.tableHeadingH,
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Deposit ID')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Bank')),
                          DataColumn(label: Text('Slip No')),
                          DataColumn(label: Text('Amount'), numeric: true),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return AppTheme.terra50;
                              }
                              return idx.isOdd
                                  ? AppTheme.clayBg.withValues(alpha: 0.4)
                                  : Colors.transparent;
                            }),
                            onSelectChanged: (_) => _openForm(initial: item),
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(Text(item.depositId)),
                              DataCell(Text(AppUtils.formatDate(item.depositDate))),
                              DataCell(Text(item.bankAccountName)),
                              DataCell(Text(item.depositSlipNo)),
                              DataCell(Text(AppUtils.fmtAmt(item.amount))),
                            ],
                          );
                        }).toList(),
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

class _CashDepositFormDialog extends StatefulWidget {
  const _CashDepositFormDialog({this.initial});
  final BankDepositModel? initial;

  @override
  State<_CashDepositFormDialog> createState() => _CashDepositFormDialogState();
}

class _CashDepositFormDialogState extends State<_CashDepositFormDialog> {
  String? _currentId;
  bool _isSaving = false;

  final _depositDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _bankAccountId = '';
  final _bankAccountNameCtrl = TextEditingController();
  final _depositSlipNoCtrl = TextEditingController();
  String _fromAccountId = '';
  final _fromAccountNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  String _depositId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    for (final c in [_depositDateCtrl, _bankAccountNameCtrl, _depositSlipNoCtrl, _fromAccountNameCtrl, _amountCtrl, _narrationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _depositId = '';
      _bankAccountId = '';
      _fromAccountId = '';
    });
    _depositDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _bankAccountNameCtrl.clear();
    _depositSlipNoCtrl.clear();
    _fromAccountNameCtrl.clear();
    _amountCtrl.text = '0';
    _narrationCtrl.clear();
  }

  void _loadFromModel(BankDepositModel m) {
    setState(() {
      _currentId = m.id;
      _depositId = m.depositId;
      _bankAccountId = m.bankAccountId;
      _fromAccountId = m.fromAccountId;
    });
    _depositDateCtrl.text = m.depositDate;
    _bankAccountNameCtrl.text = m.bankAccountName;
    _depositSlipNoCtrl.text = m.depositSlipNo;
    _fromAccountNameCtrl.text = m.fromAccountName;
    _amountCtrl.text = m.amount.toStringAsFixed(2);
    _narrationCtrl.text = m.narration;
  }

  Map<String, dynamic> _buildPayload() => {
        'depositType': 'cash',
        'depositDate': _depositDateCtrl.text,
        'bankAccountId': _bankAccountId,
        'bankAccountName': _bankAccountNameCtrl.text,
        'depositSlipNo': _depositSlipNoCtrl.text,
        'fromAccountId': _fromAccountId,
        'fromAccountName': _fromAccountNameCtrl.text,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'narration': _narrationCtrl.text,
        'status': 'saved',
      };

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<BankDepositController>();
      if (_currentId == null) {
        final r = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = r.id;
          _depositId = r.depositId;
        });
      } else {
        await ctrl.updateItem(_currentId!, _buildPayload());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Saved successfully')));
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this deposit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<BankDepositController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>().typedItems;
    return InvoicingFormDialog(
      title: 'Cash Deposit in Bank',
      badgeText: _depositId.isNotEmpty ? 'Deposit ID: $_depositId' : null,
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
                SizedBox(width: 150, child: TextFormField(controller: _depositDateCtrl, decoration: _dec('Deposit Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_depositDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _depositDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(width: 260, child: DropdownButtonFormField<String>(value: _bankAccountId.isEmpty ? null : _bankAccountId, decoration: _dec('Bank Account'), isExpanded: true, items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) { if (val == null) return; final a = accounts.firstWhere((x) => x.id == val); setState(() => _bankAccountId = val); _bankAccountNameCtrl.text = a.text('accountName'); })),
                SizedBox(width: 150, child: TextFormField(controller: _depositSlipNoCtrl, decoration: _dec('Deposit Slip No'))),
                SizedBox(width: 260, child: DropdownButtonFormField<String>(value: _fromAccountId.isEmpty ? null : _fromAccountId, decoration: _dec('From Account (optional)'), isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('None')), ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis)))], onChanged: (val) { setState(() => _fromAccountId = val ?? ''); if (val != null && val.isNotEmpty) { _fromAccountNameCtrl.text = accounts.firstWhere((a) => a.id == val).text('accountName'); } else { _fromAccountNameCtrl.clear(); } })),
                SizedBox(width: 150, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number)),
                SizedBox(width: 260, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
              ],
            ),
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
