import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

final _decimalFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

class VoucherLineRow extends StatefulWidget {
  const VoucherLineRow({
    super.key,
    required this.voucherType,
    required this.onAdd,
    this.initialValues,
  });

  final String voucherType;
  final void Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialValues;

  @override
  State<VoucherLineRow> createState() => _VoucherLineRowState();
}

class _VoucherLineRowState extends State<VoucherLineRow> {
  final _debitCtrl      = TextEditingController(text: '0');
  final _creditCtrl     = TextEditingController(text: '0');
  final _narrationCtrl  = TextEditingController();

  String _accountId   = '';
  String _accountCode = '';
  String _accountName = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null) _preloadFrom(widget.initialValues!);
  }

  void _preloadFrom(Map<String, dynamic> line) {
    _accountId   = '${line['accountId']   ?? ''}';
    _accountCode = '${line['accountCode'] ?? ''}';
    _accountName = '${line['accountName'] ?? ''}';
    _debitCtrl.text =
        ((line['debit']  as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _creditCtrl.text =
        ((line['credit'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _narrationCtrl.text = '${line['narration'] ?? ''}';
  }

  @override
  void dispose() {
    _debitCtrl.dispose();
    _creditCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  void _addLine() {
    if (_accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }
    final debit  = double.tryParse(_debitCtrl.text)  ?? 0;
    final credit = double.tryParse(_creditCtrl.text) ?? 0;
    if (debit <= 0 && credit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debit or Credit amount must be greater than 0'),
        ),
      );
      return;
    }
    widget.onAdd({
      'accountId':   _accountId,
      'accountCode': _accountCode,
      'accountName': _accountName,
      'debit':       debit,
      'credit':      credit,
      'narration':   _narrationCtrl.text.trim(),
    });
    setState(() {
      _accountId   = '';
      _accountCode = '';
      _accountName = '';
    });
    _debitCtrl.text  = '0';
    _creditCtrl.text = '0';
    _narrationCtrl.clear();
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final accounts  = context.watch<AccountsController>().typedItems;
    final showDebit  = widget.voucherType != 'credit';
    final showCredit = widget.voucherType != 'debit';

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
            width: 280,
            child: DropdownButtonFormField<String>(
              value: _accountId.isEmpty ? null : _accountId,
              decoration: _dec('Account'),
              isExpanded: true,
              items: accounts.map((a) {
                final code = a.text('accountCode');
                final name = a.text('accountName');
                return DropdownMenuItem<String>(
                  value: a.id,
                  child: Text(
                    code.isNotEmpty ? '$name ($code)' : name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final a = accounts.firstWhere((x) => x.id == val);
                setState(() {
                  _accountId   = val;
                  _accountCode = a.text('accountCode');
                  _accountName = a.text('accountName');
                });
              },
            ),
          ),
          if (showDebit)
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _debitCtrl,
                decoration: _dec('Debit'),
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalFormatter],
              ),
            ),
          if (showCredit)
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _creditCtrl,
                decoration: _dec('Credit'),
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalFormatter],
              ),
            ),
          SizedBox(
            width: 220,
            child: TextFormField(
              controller: _narrationCtrl,
              decoration: _dec('Narration'),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _addLine,
            icon: Icon(
              widget.initialValues != null ? Icons.check : Icons.add,
              size: 16,
            ),
            label: Text(widget.initialValues != null ? 'Update' : 'Add'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
