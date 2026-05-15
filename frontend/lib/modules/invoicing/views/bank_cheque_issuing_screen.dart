import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/bank_cheque_controller.dart';
import '../models/bank_cheque_model.dart';
import '../widgets/invoicing_action_bar.dart';
import '../widgets/invoicing_form_dialog.dart';

class BankChequeIssuingScreen extends StatefulWidget {
  const BankChequeIssuingScreen({super.key});

  @override
  State<BankChequeIssuingScreen> createState() => _BankChequeIssuingScreenState();
}

class _BankChequeIssuingScreenState extends State<BankChequeIssuingScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<BankChequeController>();
      if (ctrl.items.isEmpty) ctrl.fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({BankChequeModel? initial}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<BankChequeController>()),
          ChangeNotifierProvider.value(value: context.read<AccountsController>()),
          ChangeNotifierProvider.value(value: context.read<VendorsController>()),
        ],
        child: _BankChequeFormDialog(initial: initial),
      ),
    );
  }

  List<BankChequeModel> _visibleItems(BankChequeController ctrl) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return ctrl.items;
    return ctrl.items.where((item) {
      final payee = item.vendorName.isNotEmpty ? item.vendorName : item.payeeName;
      return item.chequeId.toLowerCase().contains(q) ||
          item.chequeNo.toLowerCase().contains(q) ||
          payee.toLowerCase().contains(q) ||
          item.bankAccountName.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BankChequeController>(
      builder: (context, ctrl, _) {
        final items = _visibleItems(ctrl);
        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Bank Cheque Issuing', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Cheque'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _searchCtrl,
                decoration: AppTheme.inputDecoration(
                  null,
                  hintText: 'Search by cheque ID, cheque no, payee, bank or status',
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
              if (ctrl.items.isEmpty)
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create First Cheque'),
                    ),
                  ),
                )
              else if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No matching cheques found.', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
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
                          DataColumn(label: Text('Cheque ID')),
                          DataColumn(label: Text('Cheque No')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Bank')),
                          DataColumn(label: Text('Payee')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Amount'), numeric: true),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final payee = item.vendorName.isNotEmpty
                              ? item.vendorName
                              : item.payeeAccountName.isNotEmpty
                                  ? item.payeeAccountName
                                  : item.payeeName;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) => idx.isOdd ? AppTheme.clayBg.withValues(alpha: 0.4) : Colors.transparent),
                            onSelectChanged: (_) => _openForm(initial: item),
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(Text(item.chequeId)),
                              DataCell(Text(item.chequeNo)),
                              DataCell(Text(item.chequeDate)),
                              DataCell(Text(item.bankAccountName)),
                              DataCell(Text(payee)),
                              DataCell(Text(item.status)),
                              DataCell(Text(item.amount.toStringAsFixed(0))),
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

class _BankChequeFormDialog extends StatefulWidget {
  const _BankChequeFormDialog({this.initial});
  final BankChequeModel? initial;

  @override
  State<_BankChequeFormDialog> createState() => _BankChequeFormDialogState();
}

class _BankChequeFormDialogState extends State<_BankChequeFormDialog> {
  String? _currentId;
  bool _isSaving = false;

  final _chequeNoCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _bankAccountId = '';
  final _bankAcNoCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  String _payeeType = 'vendor';
  String _vendorId = '';
  String _payeeAccountId = '';
  final _payeeNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();
  bool _isPostDated = false;
  String _chequeId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _loadFromModel(widget.initial!);
  }

  @override
  void dispose() {
    for (final c in [_chequeNoCtrl, _chequeDateCtrl, _bankAcNoCtrl, _bankAccountNameCtrl, _payeeNameCtrl, _amountCtrl, _narrationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _currentId = null;
      _chequeId = '';
      _bankAccountId = '';
      _payeeType = 'vendor';
      _vendorId = '';
      _payeeAccountId = '';
      _isPostDated = false;
    });
    _chequeNoCtrl.clear();
    _chequeDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    _bankAcNoCtrl.clear();
    _bankAccountNameCtrl.clear();
    _payeeNameCtrl.clear();
    _amountCtrl.text = '0';
    _narrationCtrl.clear();
  }

  void _loadFromModel(BankChequeModel m) {
    setState(() {
      _currentId = m.id;
      _chequeId = m.chequeId;
      _bankAccountId = m.bankAccountId;
      _payeeType = m.payeeType.isNotEmpty ? m.payeeType : 'vendor';
      _vendorId = m.vendorId;
      _payeeAccountId = m.payeeAccountId;
      _isPostDated = m.isPostDated;
    });
    _chequeNoCtrl.text = m.chequeNo;
    _chequeDateCtrl.text = m.chequeDate;
    _bankAcNoCtrl.text = m.bankAcNo;
    _bankAccountNameCtrl.text = m.bankAccountName;
    _payeeNameCtrl.text = m.payeeName;
    _amountCtrl.text = m.amount.toStringAsFixed(2);
    _narrationCtrl.text = m.narration;
  }

  Map<String, dynamic> _buildPayload() => {
        'chequeNo': _chequeNoCtrl.text,
        'chequeDate': _chequeDateCtrl.text,
        'bankAccountId': _bankAccountId,
        'bankAcNo': _bankAcNoCtrl.text,
        'bankAccountName': _bankAccountNameCtrl.text,
        'payeeType': _payeeType,
        'vendorId': _vendorId,
        'payeeAccountId': _payeeAccountId,
        'payeeName': _payeeNameCtrl.text,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'narration': _narrationCtrl.text,
        'isPostDated': _isPostDated,
        'status': 'issued',
      };

  Future<void> _save() async {
    if (_chequeNoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cheque No is required')),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ctrl = context.read<BankChequeController>();
      if (_currentId == null) {
        final r = await ctrl.add(_buildPayload());
        setState(() {
          _currentId = r.id;
          _chequeId = r.chequeId;
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this cheque?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<BankChequeController>().deleteItem(_currentId!);
      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>().typedItems;
    final vendors = context.watch<VendorsController>().typedItems;
    return InvoicingFormDialog(
      title: 'Bank Cheque Issuing',
      badgeText: _chequeId.isNotEmpty ? 'Cheque ID: $_chequeId' : null,
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
                SizedBox(width: 150, child: TextFormField(controller: _chequeNoCtrl, decoration: _dec('Cheque No *'))),
                SizedBox(width: 150, child: TextFormField(controller: _chequeDateCtrl, decoration: _dec('Cheque Date'), readOnly: true, onTap: () async { final p = await showDatePicker(context: context, initialDate: DateTime.tryParse(_chequeDateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) setState(() => _chequeDateCtrl.text = p.toIso8601String().substring(0, 10)); })),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value: _bankAccountId.isEmpty ? null : _bankAccountId,
                    decoration: _dec('Bank Account'),
                    isExpanded: true,
                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final a = accounts.firstWhere((x) => x.id == val);
                      setState(() => _bankAccountId = val);
                      _bankAcNoCtrl.text = a.text('accountCode');
                      _bankAccountNameCtrl.text = a.text('accountName');
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _payeeType,
                    decoration: _dec('Payee Type'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                      DropdownMenuItem(value: 'account', child: Text('Account')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() {
                      _payeeType = val ?? 'vendor';
                      _vendorId = '';
                      _payeeAccountId = '';
                      _payeeNameCtrl.clear();
                    }),
                  ),
                ),
                if (_payeeType == 'vendor')
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _vendorId.isEmpty ? null : _vendorId, decoration: _dec('Vendor'), isExpanded: true, items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.text('name'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _vendorId = val ?? '')))
                else if (_payeeType == 'account')
                  SizedBox(width: 200, child: DropdownButtonFormField<String>(value: _payeeAccountId.isEmpty ? null : _payeeAccountId, decoration: _dec('Payee Account'), isExpanded: true, items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.text('accountName'), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _payeeAccountId = val ?? '')))
                else
                  SizedBox(width: 200, child: TextFormField(controller: _payeeNameCtrl, decoration: _dec('Payee Name'))),
                SizedBox(width: 150, child: TextFormField(controller: _amountCtrl, decoration: _dec('Amount *'), keyboardType: TextInputType.number)),
                SizedBox(width: 260, child: TextFormField(controller: _narrationCtrl, decoration: _dec('Narration'))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: _isPostDated, onChanged: (v) => setState(() => _isPostDated = v), activeColor: AppTheme.terra400),
                    const SizedBox(width: 8),
                    const Text('Post Dated', style: TextStyle(fontSize: 13)),
                  ],
                ),
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
