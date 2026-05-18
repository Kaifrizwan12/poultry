import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/models/account.dart';
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
  final _accountCodeCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _debitCtrl = TextEditingController(text: '0');
  final _creditCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();

  String _accountId = '';
  String _accountName = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null) _preloadFrom(widget.initialValues!);
  }

  void _preloadFrom(Map<String, dynamic> line) {
    _accountId = '${line['accountId'] ?? ''}';
    _accountName = '${line['accountName'] ?? ''}';
    _accountCodeCtrl.text = '${line['accountCode'] ?? ''}';
    _accountNameCtrl.text = _accountName;
    _debitCtrl.text =
        ((line['debit'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _creditCtrl.text =
        ((line['credit'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    _narrationCtrl.text = '${line['narration'] ?? ''}';
  }

  @override
  void dispose() {
    _accountCodeCtrl.dispose();
    _accountNameCtrl.dispose();
    _debitCtrl.dispose();
    _creditCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  void _lookupAccount() {
    final code = _accountCodeCtrl.text.trim();
    if (code.isEmpty) return;
    final accounts = context.read<AccountsController>().typedItems;
    Account? account;
    try {
      account = accounts.firstWhere((a) => a.text('accountCode') == code);
    } catch (_) {
      account = null;
    }
    if (account != null) {
      setState(() {
        _accountId = account!.id;
        _accountName = account.text('accountName');
      });
      _accountNameCtrl.text = _accountName;
    } else {
      setState(() {
        _accountId = '';
        _accountName = 'Not found';
      });
      _accountNameCtrl.text = _accountName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account "$code" not found')),
      );
    }
  }

  void _addLine() {
    if (_accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid account code')),
      );
      return;
    }
    final debit = double.tryParse(_debitCtrl.text) ?? 0;
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
      'accountId': _accountId,
      'accountCode': _accountCodeCtrl.text.trim(),
      'accountName': _accountName,
      'debit': debit,
      'credit': credit,
      'narration': _narrationCtrl.text.trim(),
    });
    // Clear
    setState(() {
      _accountId = '';
      _accountName = '';
    });
    _accountCodeCtrl.clear();
    _accountNameCtrl.clear();
    _debitCtrl.text = '0';
    _creditCtrl.text = '0';
    _narrationCtrl.clear();
  }

  InputDecoration _dec(String label) => AppTheme.inputDecoration(label);

  @override
  Widget build(BuildContext context) {
    final showDebit = widget.voucherType != 'credit';
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
            width: 130,
            child: TextFormField(
              controller: _accountCodeCtrl,
              decoration: _dec('Account No'),
              onFieldSubmitted: (_) => _lookupAccount(),
              onEditingComplete: _lookupAccount,
            ),
          ),
          SizedBox(
            width: 200,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: _dec('Account Name'),
                controller: _accountNameCtrl,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
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
