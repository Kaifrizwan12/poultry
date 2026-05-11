import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/account.dart';
import 'package:flutter/material.dart';

import '../controllers/ledger_controller.dart';
import '../models/ledger_entry_model.dart';

const _kEntryTypes = [
  _Opt('debit', 'Debit'),
  _Opt('credit', 'Credit'),
];

const _kReferenceTypes = [
  _Opt('manual', 'Manual'),
  _Opt('chicken_invoice', 'Chicken Invoice'),
  _Opt('opening_receivable', 'Opening Receivable'),
  _Opt('opening_payable', 'Opening Payable'),
  _Opt('other', 'Other'),
];

class _Opt {
  const _Opt(this.value, this.label);
  final String value;
  final String label;
}

class LedgerFormDialog extends StatefulWidget {
  const LedgerFormDialog({
    super.key,
    required this.controller,
    required this.accounts,
    this.entry,
    this.prefilledAccountId,
    required this.onSaved,
  });

  final LedgerController controller;
  final List<Account>
      accounts; // passed in before showDialog — avoids Provider lookup inside dialog context
  final LedgerEntry? entry;
  final String? prefilledAccountId;
  final VoidCallback onSaved;

  @override
  State<LedgerFormDialog> createState() => _LedgerFormDialogState();
}

class _LedgerFormDialogState extends State<LedgerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagCtrl = TextEditingController();
  // Stable key for amount field — not tied to the value so editing doesn't flicker
  final _amountKey = GlobalKey<FormFieldState<String>>();

  late Map<String, dynamic> _v;
  bool _saving = false;
  List<String> _tags = [];

  bool get _isNew => widget.entry == null;

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      final e = widget.entry!;
      _v = {
        'entryNo': e.entryNo,
        'entryDate': e.entryDate,
        'accountId': e.accountId,
        'entryType': e.entryType,
        'amount': e.amount,
        'description': e.description,
        'referenceType': e.referenceType,
        'referenceId': e.referenceId ?? '',
        'referenceNo': e.referenceNo ?? '',
        'isReconciled': e.isReconciled,
        'notes': e.notes ?? '',
      };
      _tags = List<String>.from(e.tags);
    } else {
      _v = {
        'entryNo': '',
        'entryDate': '',
        'accountId': widget.prefilledAccountId ?? '',
        'entryType': 'debit',
        'amount': '',
        'description': '',
        'referenceType': 'manual',
        'referenceId': '',
        'referenceNo': '',
        'isReconciled': false,
        'notes': '',
      };
      _tags = [];
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNextNo());
    }
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNextNo() async {
    try {
      final no = await widget.controller.nextEntryNo();
      if (mounted) setState(() => _v['entryNo'] = no);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // widget.accounts is passed from the caller before showDialog — safe inside dialog context.
    // On create: caller passes active-only; on edit: caller passes all accounts.
    final accounts = widget.accounts;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isNew ? 'New Ledger Entry' : 'Edit Ledger Entry',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _section('Entry Details'),
            _field('Entry No *', _entryNoField()),
            _field('Entry Date *', _datePicker('entryDate', required: true)),
            _field('Account *', _accountDropdown(accounts)),
            _field('Entry Type *',
                _enumDropdown('entryType', _kEntryTypes, required: true)),
            _field('Amount *', _amountField()),
            _field('Description', _textArea('description', maxLength: 500)),
            _section('Reference'),
            _field('Reference Type',
                _enumDropdown('referenceType', _kReferenceTypes)),
            _field('Reference No',
                _text('referenceNo', hint: 'Invoice number or reference')),
            _field('Tags', _tagsField()),
            _field('Notes', _textArea('notes')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Layout helpers ───────────────────────────────────────────────────────────

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.terra600,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      );

  Widget _field(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  height: 1)),
          const SizedBox(height: 6),
          child,
        ]),
      );

  // ── Form fields ──────────────────────────────────────────────────────────────

  // Entry No: key is tied to the displayed value (changes once after nextEntryNo fetch)
  Widget _entryNoField() => TextFormField(
        key: ValueKey('entryNo:${_v['entryNo']}'),
        initialValue: '${_v['entryNo'] ?? ''}',
        decoration: const InputDecoration(),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
        onChanged: (v) => _v['entryNo'] = v,
      );

  Widget _text(String key, {bool required = false, String? hint}) =>
      TextFormField(
        initialValue: '${_v[key] ?? ''}',
        decoration: InputDecoration(hintText: hint),
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
        onChanged: (v) => _v[key] = v,
      );

  Widget _textArea(String key, {bool required = false, int? maxLength}) =>
      TextFormField(
        initialValue: '${_v[key] ?? ''}',
        minLines: 2,
        maxLines: 4,
        maxLength: maxLength,
        decoration: const InputDecoration(),
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
        onChanged: (v) => _v[key] = v,
      );

  // Amount: stable key (never changes) + validates > 0 client-side
  Widget _amountField() {
    final initial = _v['amount'];
    final initialStr =
        (initial != null && initial != '') ? _fmtAmountDisplay(initial) : '';
    return TextFormField(
      key: _amountKey,
      initialValue: initialStr,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'Required';
        final n = double.tryParse(s);
        if (n == null) return 'Must be a valid number';
        if (n <= 0) return 'Must be greater than zero';
        return null;
      },
      onChanged: (v) => _v['amount'] = double.tryParse(v.trim()) ?? 0.0,
    );
  }

  Widget _datePicker(String key, {bool required = false}) {
    final raw = '${_v[key] ?? ''}';
    final display = _fmtDateDisplay(raw);
    return TextFormField(
      key: ValueKey('$key:$raw'),
      readOnly: true,
      initialValue: display,
      decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined)),
      validator:
          required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
      onTap: () async {
        DateTime initial = DateTime.now();
        if (raw.isNotEmpty) {
          try {
            initial = DateTime.parse(raw);
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _v[key] = picked.toIso8601String());
      },
    );
  }

  Widget _accountDropdown(List<Account> accounts) {
    final current = '${_v['accountId'] ?? ''}';
    // Validate that current value exists in the list to prevent Flutter assertion
    final validValue = accounts.any((a) => a.id == current) ? current : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: const InputDecoration(),
      isExpanded: true,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      items: accounts.map((a) {
        final code = a.text('accountCode');
        final name = a.text('accountName');
        final type = a.text('accountType');
        final inactive = !a.boolean('isActive');
        return DropdownMenuItem<String>(
          value: a.id,
          child: Text(
            inactive
                ? '$code — $name ($type) [inactive]'
                : '$code — $name ($type)',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14, color: inactive ? AppTheme.textTertiary : null),
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _v['accountId'] = v ?? ''),
    );
  }

  Widget _enumDropdown(String key, List<_Opt> opts, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    final validValue = opts.any((o) => o.value == current) ? current : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: const InputDecoration(),
      validator:
          required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      items: opts
          .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
          .toList(),
      onChanged: (v) => setState(() => _v[key] = v ?? ''),
    );
  }

  Widget _tagsField() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.inputRadius),
          border: Border.all(color: AppTheme.inputBorderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .map(
                    (t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _tags.remove(t)),
                      backgroundColor: AppTheme.terra50,
                      side: const BorderSide(color: AppTheme.terra200),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _tagCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Add tag, press Enter',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty && !_tags.contains(t)) {
                setState(() {
                  _tags.add(t);
                  _tagCtrl.clear();
                });
              } else {
                _tagCtrl.clear();
              }
            },
          ),
        ]),
      );

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = Map<String, dynamic>.from(_v)
        ..['tags'] = List<String>.from(_tags);
      final messenger = ScaffoldMessenger.of(context);
      if (_isNew) {
        await widget.controller.createEntry(payload);
      } else {
        await widget.controller.updateEntry(widget.entry!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.successText,
        content: const Text('Saved successfully'),
        duration: const Duration(milliseconds: 2500),
      ));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.dangerText,
        content: Text(e.toString()),
        duration: const Duration(milliseconds: 3000),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

String _fmtDateDisplay(String raw) {
  if (raw.isEmpty) return '';
  try {
    final d = DateTime.parse(raw);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw.split('T').first;
  }
}

String _fmtAmountDisplay(dynamic v) {
  final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
  // Remove unnecessary trailing zeros: 1500.00 → "1500", 1500.50 → "1500.5"
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toString();
}
