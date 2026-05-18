import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';

import '../controllers/accounts_reports_nav_controller.dart';
import '../controllers/ledger_controller.dart';
import '../models/ledger_entry_model.dart';
import '../models/ledger_view_model.dart';
import 'ledger_form_dialog.dart';
import 'ledger_list_screen.dart'
    show fmtDate, fmtAmt, LedgerTypeBadge, LedgerActionBtn;

class LedgerByAccountScreen extends StatefulWidget {
  const LedgerByAccountScreen({super.key, required this.accountId});
  final String accountId;

  @override
  State<LedgerByAccountScreen> createState() => _LedgerByAccountScreenState();
}

class _LedgerByAccountScreenState extends State<LedgerByAccountScreen> {
  // Filter state local to this screen
  DateTime? _startDate;
  DateTime? _endDate;
  String? _entryType; // null = all
  bool? _isReconciled; // null = all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant LedgerByAccountScreen old) {
    super.didUpdateWidget(old);
    if (old.accountId != widget.accountId) {
      _startDate = _endDate = null;
      _entryType = null;
      _isReconciled = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() {
    if (!mounted) return;
    context.read<LedgerController>().loadByAccount(
          widget.accountId,
          startDate: _startDate?.toIso8601String(),
          endDate: _endDate?.toIso8601String(),
          entryType: _entryType,
          isReconciled: _isReconciled,
        );
  }

  void _applyFilters() {
    _load();
  }

  void _clearFilters() {
    setState(() {
      _startDate = _endDate = null;
      _entryType = null;
      _isReconciled = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _openForm([LedgerEntry? entry]) {
    if (context.read<SettingsController>().isBootstrapping) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Loading settings data, please wait a moment…'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final ctrl = context.read<LedgerController>();
    final allAccounts = context.read<AccountsController>().typedItems;
    final accounts = entry == null
        ? allAccounts.where((a) => a.boolean('isActive')).toList()
        : allAccounts;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LedgerFormDialog(
              controller: ctrl,
              accounts: accounts,
              entry: entry,
              prefilledAccountId: widget.accountId,
              onSaved: _load,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(LedgerEntry entry) {
    final ctrl = context.read<LedgerController>();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete "${entry.entryNo}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerText),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ctrl.deleteEntry(entry.id);
                _load(); // refresh running balance
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: AppTheme.dangerText,
                    content: Text(e.toString()),
                  ));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Date picker helper ────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isStart) async {
    final initial =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Ensure end >= start
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        // Ensure start <= end
        if (_startDate != null && _startDate!.isAfter(picked))
          _startDate = picked;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LedgerController, AccountsReportsNavController>(
      builder: (context, ctrl, nav, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            _Header(
                nav: nav,
                ctrl: ctrl,
                view: ctrl.accountView,
                onAdd: () => _openForm()),
            const SizedBox(height: 12),

            // ── Summary card ───────────────────────────────────────────────────
            if (ctrl.accountView != null) ...[
              _SummaryCard(view: ctrl.accountView!),
              const SizedBox(height: 12),
            ],

            // ── Filters ────────────────────────────────────────────────────────
            _FilterBar(
              startDate: _startDate,
              endDate: _endDate,
              entryType: _entryType,
              isReconciled: _isReconciled,
              onPickStart: () => _pickDate(true),
              onPickEnd: () => _pickDate(false),
              onEntryType: (v) {
                setState(() => _entryType = v);
                _applyFilters();
              },
              onReconciled: (v) {
                setState(() => _isReconciled = v);
                _applyFilters();
              },
              onClear: _clearFilters,
            ),
            const SizedBox(height: 12),

            // ── Content ────────────────────────────────────────────────────────
            Expanded(child: _buildContent(context, ctrl)),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LedgerController ctrl) {
    if (ctrl.error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerText),
        const SizedBox(height: 12),
        Text(ctrl.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.dangerText)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }

    final view = ctrl.accountView;
    if (view == null) {
      return ctrl.isLoading
          ? Column(
              children: [
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.terra400,
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            )
          : const SizedBox.shrink();
    }
    if (ctrl.isLoading) {
      return Column(
        children: [
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppTheme.terra400,
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    }
    if (view.entries.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_long_outlined,
            size: 64, color: AppTheme.textTertiary),
        const SizedBox(height: 12),
        const Text('No entries found for this account',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ]));
    }

    return Column(
      children: [
        if (ctrl.isLoading)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppTheme.terra400,
          ),
        Expanded(
          child: _LedgerTable(
            view: view,
            balanceType: view.balanceType,
            onEdit: _openForm,
            onDelete: _confirmDelete,
            onToggleReconciled: (e) async {
              try {
                await ctrl.toggleReconciled(e);
              } catch (err) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: AppTheme.dangerText,
                    content: Text(err.toString()),
                  ));
                return;
              }
              _load();
            },
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header(
      {required this.nav,
      required this.ctrl,
      required this.view,
      required this.onAdd});
  final AccountsReportsNavController nav;
  final LedgerController ctrl;
  final LedgerViewModel? view;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final name = view?.accountName ?? '…';
    final code = view?.accountCode ?? '';
    final type = view?.accountType ?? '';
    final isMobile = MediaQuery.of(context).size.width < 700;
    return LayoutBuilder(builder: (_, constraints) {
      final compact = constraints.maxWidth < 520;
      return Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: nav.backToList,
          tooltip: 'Back to entries',
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
                child: Text(name,
                    style: isMobile
                        ? Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)
                        : null,
                    overflow: TextOverflow.ellipsis)),
            if (!compact && code.isNotEmpty) ...[
              const SizedBox(width: 8),
              _Chip(code, AppTheme.terra100, AppTheme.terra800),
            ],
            if (!compact && type.isNotEmpty) ...[
              const SizedBox(width: 6),
              _Chip(type, AppTheme.pageBg, AppTheme.textSecondary),
            ],
          ]),
          if (compact && code.isNotEmpty)
            Text('$code · $type',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: compact ? const Text('New') : const Text('New Entry'),
        ),
      ]);
    });
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withAlpha(64)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.view});
  final LedgerViewModel view;

  @override
  Widget build(BuildContext context) {
    final closingColor =
        view.closingBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor,
      child: LayoutBuilder(builder: (_, constraints) {
        if (constraints.maxWidth < 480) {
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _SummaryCell('Opening', view.openingBalance, Colors.grey.shade700),
            _SummaryCell('Total Dr', view.totalDebits, Colors.red.shade700),
            _SummaryCell('Total Cr', view.totalCredits, Colors.green.shade700),
            _SummaryCell('Balance', view.closingBalance, closingColor),
          ]);
        }
        return Row(children: [
          Expanded(
              child: _SummaryCell('Opening Balance', view.openingBalance,
                  Colors.grey.shade700)),
          _Divider(),
          Expanded(
              child: _SummaryCell(
                  'Total Debits', view.totalDebits, Colors.red.shade700)),
          _Divider(),
          Expanded(
              child: _SummaryCell(
                  'Total Credits', view.totalCredits, Colors.green.shade700)),
          _Divider(),
          Expanded(
              child: _SummaryCell(
                  'Closing Balance', view.closingBalance, closingColor)),
        ]);
      }),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 40,
      color: AppTheme.softBorder,
      margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            fmtAmt(value, compact: false),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      );
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.startDate,
    required this.endDate,
    required this.entryType,
    required this.isReconciled,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onEntryType,
    required this.onReconciled,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? entryType;
  final bool? isReconciled;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String?> onEntryType;
  final ValueChanged<bool?> onReconciled;
  final VoidCallback onClear;

  bool get _hasFilter =>
      startDate != null ||
      endDate != null ||
      entryType != null ||
      isReconciled != null;

  String _dateLabel(DateTime? d) => d == null
      ? 'Select'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return HorizontalScrollWheel(child: Row(children: [
        // Date range
        _DateBtn('From: ${_dateLabel(startDate)}', onPickStart),
        const SizedBox(width: 6),
        _DateBtn('To: ${_dateLabel(endDate)}', onPickEnd),
        const SizedBox(width: 10),
        // Entry type
        for (final opt in _kTypeOpts)
          Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                selected: entryType == opt.value,
                selectedColor: opt.selectedBg,
                side: BorderSide(
                    color: entryType == opt.value
                        ? opt.selectedBorder
                        : AppTheme.softBorder),
                labelStyle: TextStyle(
                    color: entryType == opt.value
                        ? opt.selectedBorder
                        : AppTheme.textSecondary),
                onSelected: (_) =>
                    onEntryType(entryType == opt.value ? null : opt.value),
              )),
        // Reconciled
        Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Reconciled', style: TextStyle(fontSize: 12)),
              selected: isReconciled == true,
              selectedColor: Colors.blue.shade50,
              side: BorderSide(
                  color: isReconciled == true
                      ? Colors.blue.shade400
                      : AppTheme.softBorder),
              labelStyle: TextStyle(
                  color: isReconciled == true
                      ? Colors.blue.shade700
                      : AppTheme.textSecondary),
              onSelected: (_) =>
                  onReconciled(isReconciled == true ? null : true),
            )),
        Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Unreconciled', style: TextStyle(fontSize: 12)),
              selected: isReconciled == false,
              selectedColor: Colors.orange.shade50,
              side: BorderSide(
                  color: isReconciled == false
                      ? Colors.orange.shade400
                      : AppTheme.softBorder),
              labelStyle: TextStyle(
                  color: isReconciled == false
                      ? Colors.orange.shade700
                      : AppTheme.textSecondary),
              onSelected: (_) =>
                  onReconciled(isReconciled == false ? null : false),
            )),
        if (_hasFilter) ...[
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ]),
    );
  }
}

class _TypeOpt {
  const _TypeOpt(this.label, this.value, this.selectedBg, this.selectedBorder);
  final String label;
  final String value;
  final Color selectedBg;
  final Color selectedBorder;
}

const _kTypeOpts = [
  _TypeOpt('Debit', 'debit', Color(0xFFFFEBEE), Color(0xFFE57373)),
  _TypeOpt('Credit', 'credit', Color(0xFFE8F5E9), Color(0xFF66BB6A)),
];

class _DateBtn extends StatelessWidget {
  const _DateBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today_outlined, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          side: const BorderSide(color: AppTheme.softBorder),
        ),
      );
}

// ── Ledger table ──────────────────────────────────────────────────────────────

class _LedgerTable extends StatelessWidget {
  const _LedgerTable({
    required this.view,
    required this.balanceType,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleReconciled,
  });

  final LedgerViewModel view;
  final String balanceType;
  final void Function(LedgerEntry?) onEdit;
  final void Function(LedgerEntry) onDelete;
  final void Function(LedgerEntry) onToggleReconciled;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(children: [
      Expanded(
        child: Container(
          decoration: AppTheme.cardDecor,
          child: isMobile ? _mobileRows(context) : _desktopTable(context),
        ),
      ),
      // Footer totals row
      _FooterRow(view: view, balanceType: balanceType),
    ]);
  }

  Widget _desktopTable(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: HorizontalScrollWheel(child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 8,
              horizontalMargin: 10,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
              columns: const [
                DataColumn(
                    label: Text('Date',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Entry No',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Description',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Reference',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: SizedBox(
                  width: 96,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Debit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB71C1C))),
                  ),
                )),
                DataColumn(
                    label: SizedBox(
                  width: 96,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Credit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20))),
                  ),
                )),
                DataColumn(
                    label: SizedBox(
                  width: 116,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Balance',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                )),
                DataColumn(
                    label: Text('Rec.',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: view.entries.map((e) {
                final bal = e.runningBalance ?? 0.0;
                final balSign = _balSign(bal, balanceType);
                final balColor = balSign == 'Dr'
                    ? Colors.red.shade700
                    : Colors.green.shade700;
                return DataRow(cells: [
                  DataCell(Text(fmtDate(e.entryDate),
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(e.entryNo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12))),
                  DataCell(SizedBox(
                    width: 160,
                    child: Text(e.description,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12)),
                  )),
                  DataCell(Text(e.referenceNo ?? '—',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary))),
                  DataCell(SizedBox(
                    width: 96,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: e.isDebit
                          ? Text(fmtAmt(e.amount, compact: false),
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))
                          : const Text('—',
                              style: TextStyle(
                                  color: AppTheme.textTertiary, fontSize: 12)),
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 96,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: !e.isDebit
                          ? Text(fmtAmt(e.amount, compact: false),
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))
                          : const Text('—',
                              style: TextStyle(
                                  color: AppTheme.textTertiary, fontSize: 12)),
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 116,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${fmtAmt(bal.abs(), compact: false)} $balSign',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: balColor,
                            fontSize: 12),
                      ),
                    ),
                  )),
                  DataCell(Tooltip(
                    message: e.isReconciled
                        ? 'Mark unreconciled'
                        : 'Mark reconciled',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onToggleReconciled(e),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: e.isReconciled
                            ? Icon(Icons.check_circle_outline,
                                color: Colors.blue.shade600, size: 16)
                            : Icon(Icons.radio_button_unchecked,
                                color: Colors.grey.shade400, size: 16),
                      ),
                    ),
                  )),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    LedgerActionBtn(
                        icon: Icons.edit_outlined,
                        color: AppTheme.textSecondary,
                        onTap: () => onEdit(e)),
                    const SizedBox(width: 4),
                    LedgerActionBtn(
                        icon: Icons.delete_outline,
                        color: AppTheme.dangerText,
                        onTap: () => onDelete(e)),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ),
      );
    });
  }

  Widget _mobileRows(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: view.entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = view.entries[i];
        final bal = e.runningBalance ?? 0.0;
        final balSign = _balSign(bal, balanceType);
        final balColor =
            balSign == 'Dr' ? Colors.red.shade700 : Colors.green.shade700;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(e.entryNo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    LedgerTypeBadge(type: e.entryType),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: e.isReconciled
                          ? 'Mark unreconciled'
                          : 'Mark reconciled',
                      child: GestureDetector(
                        onTap: () => onToggleReconciled(e),
                        child: e.isReconciled
                            ? Icon(Icons.check_circle_outline,
                                color: Colors.blue.shade600, size: 15)
                            : Icon(Icons.radio_button_unchecked,
                                color: Colors.grey.shade300, size: 15),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(fmtDate(e.entryDate),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 3),
                  Text(e.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    // Amount (Dr or Cr)
                    Text(
                      e.isDebit
                          ? 'Dr ${fmtAmt(e.amount, compact: false)}'
                          : 'Cr ${fmtAmt(e.amount, compact: false)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: e.isDebit
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bal: ${fmtAmt(bal.abs(), compact: false)} $balSign',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: balColor),
                    ),
                  ]),
                ])),
            Column(children: [
              LedgerActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppTheme.textSecondary,
                  onTap: () => onEdit(e)),
              const SizedBox(height: 4),
              LedgerActionBtn(
                  icon: Icons.delete_outline,
                  color: AppTheme.dangerText,
                  onTap: () => onDelete(e)),
            ]),
          ]),
        );
      },
    );
  }

  String _balSign(double bal, String balanceType) {
    if (bal == 0) return balanceType == 'debit' ? 'Dr' : 'Cr';
    // For debit-normal accounts: positive balance → Dr; negative → Cr
    if (balanceType == 'debit') return bal >= 0 ? 'Dr' : 'Cr';
    // For credit-normal accounts: positive balance → Cr; negative → Dr
    return bal >= 0 ? 'Cr' : 'Dr';
  }
}

// ── Footer totals ─────────────────────────────────────────────────────────────

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.view, required this.balanceType});
  final LedgerViewModel view;
  final String balanceType;

  @override
  Widget build(BuildContext context) {
    final closing = view.closingBalance;
    final closingSign = balanceType == 'debit'
        ? (closing >= 0 ? 'Dr' : 'Cr')
        : (closing >= 0 ? 'Cr' : 'Dr');
    final closingColor =
        (closingSign == 'Dr') ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.pageBg,
        border: Border(top: BorderSide(color: AppTheme.softBorder)),
      ),
      child: LayoutBuilder(builder: (_, constraints) {
        if (constraints.maxWidth < 480) {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Dr',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  Text(fmtAmt(view.totalDebits, compact: false),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Cr',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  Text(fmtAmt(view.totalCredits, compact: false),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Balance',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  Text('${fmtAmt(closing.abs(), compact: false)} $closingSign',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: closingColor)),
                ]),
              ]);
        }
        return Row(children: [
          const Text('Totals: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const Spacer(),
          Text('Dr: ${fmtAmt(view.totalDebits, compact: false)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.red.shade700)),
          const SizedBox(width: 24),
          Text('Cr: ${fmtAmt(view.totalCredits, compact: false)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.green.shade700)),
          const SizedBox(width: 24),
          Text('Balance: ${fmtAmt(closing.abs(), compact: false)} $closingSign',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: closingColor)),
        ]);
      }),
    );
  }
}
