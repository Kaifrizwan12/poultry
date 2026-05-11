import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/accounts_reports_nav_controller.dart';
import '../controllers/ledger_controller.dart';
import '../models/ledger_entry_model.dart';
import 'ledger_form_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────

class LedgerListScreen extends StatefulWidget {
  const LedgerListScreen({super.key});

  @override
  State<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends State<LedgerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LedgerController>().loadAll();
    });
  }

  void _openForm(LedgerEntry? entry) {
    if (context.read<SettingsController>().isBootstrapping) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Loading settings data, please wait a moment…'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final ctrl = context.read<LedgerController>();
    final allAccounts = context.read<AccountsController>().typedItems;
    // On create show active-only; on edit include all so inactive IDs aren't missing from dropdown
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
              onSaved: ctrl.loadAll,
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
        content: Text(
            'Delete "${entry.entryNo} — ${entry.description.length > 40 ? '${entry.description.substring(0, 40)}…' : entry.description}"?\nThis cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<LedgerController, AccountsReportsNavController>(
      builder: (context, ctrl, nav, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context, ctrl),
            const SizedBox(height: 12),
            _buildFilterRow(ctrl),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(context, ctrl, nav)),
          ],
        );
      },
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────────

  Widget _buildToolbar(BuildContext context, LedgerController ctrl) {
    final addBtn = ElevatedButton.icon(
      onPressed: () => _openForm(null),
      icon: const Icon(Icons.add),
      label: const Text('New Entry'),
    );
    return LayoutBuilder(builder: (_, constraints) {
      if (constraints.maxWidth < 520) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ledger Entries',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: addBtn),
        ]);
      }
      return Row(children: [
        Expanded(
            child: Text('Ledger Entries',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600))),
        _SearchField(ctrl: ctrl),
        const SizedBox(width: 12),
        addBtn,
      ]);
    });
  }

  // ── Filters ──────────────────────────────────────────────────────────────────

  Widget _buildFilterRow(LedgerController ctrl) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final opt in _kTypeFilters)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt.label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              selected: ctrl.filterEntryType == opt.value,
              selectedColor: opt.selectedBg,
              side: BorderSide(
                color: ctrl.filterEntryType == opt.value
                    ? opt.selectedBorder
                    : AppTheme.softBorder,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ctrl.filterEntryType == opt.value
                    ? opt.selectedText
                    : AppTheme.textSecondary,
              ),
              onSelected: (_) => ctrl.setFilterEntryType(opt.value),
            ),
          ),
      ]),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, LedgerController ctrl,
      AccountsReportsNavController nav) {
    if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());

    if (ctrl.error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerText),
        const SizedBox(height: 12),
        Text(ctrl.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.dangerText)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: ctrl.loadAll, child: const Text('Retry')),
      ]));
    }

    final items = ctrl.filteredItems;
    if (items.isEmpty) {
      final filtered =
          ctrl.searchQuery.isNotEmpty || ctrl.filterEntryType != null;
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.menu_book_outlined,
            size: 64, color: AppTheme.textTertiary),
        const SizedBox(height: 12),
        Text(
          filtered
              ? 'No entries match the current filters'
              : 'No ledger entries yet',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        if (!filtered) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openForm(null),
            icon: const Icon(Icons.add),
            label: const Text('New Entry'),
          ),
        ],
      ]));
    }

    void onToggleReconciled(LedgerEntry e) async {
      try {
        await ctrl.toggleReconciled(e);
      } catch (err) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppTheme.dangerText,
            content: Text(err.toString()),
          ));
      }
    }

    if (MediaQuery.of(context).size.width < 700) {
      return _MobileList(
        items: items,
        nav: nav,
        onEdit: _openForm,
        onDelete: _confirmDelete,
        onToggleReconciled: onToggleReconciled,
      );
    }
    return _DesktopTable(
      items: items,
      nav: nav,
      onEdit: _openForm,
      onDelete: _confirmDelete,
      onToggleReconciled: onToggleReconciled,
    );
  }
}

// ── Filter config ─────────────────────────────────────────────────────────────

class _TypeFilter {
  const _TypeFilter(this.value, this.label, this.selectedBg,
      this.selectedBorder, this.selectedText);
  final String? value;
  final String label;
  final Color selectedBg;
  final Color selectedBorder;
  final Color selectedText;
}

const _kTypeFilters = [
  _TypeFilter(
      null, 'All', AppTheme.terra100, AppTheme.terra400, AppTheme.terra800),
  _TypeFilter('debit', 'Debit', Color(0xFFFFEBEB), Color(0xFFE57373),
      Color(0xFFB71C1C)),
  _TypeFilter('credit', 'Credit', Color(0xFFE8F5E9), Color(0xFF66BB6A),
      Color(0xFF1B5E20)),
];

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl});
  final LedgerController ctrl;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: TextField(
          onChanged: ctrl.setSearchQuery,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 18),
            hintText: 'Search entries…',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
}

// ── Desktop table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.items,
    required this.nav,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleReconciled,
  });

  final List<LedgerEntry> items;
  final AccountsReportsNavController nav;
  final void Function(LedgerEntry?) onEdit;
  final void Function(LedgerEntry) onDelete;
  final void Function(LedgerEntry) onToggleReconciled;

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>().typedItems;
    String accName(String id) {
      try {
        return accounts.firstWhere((a) => a.id == id).text('accountName');
      } catch (_) {
        return id;
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: AppTheme.cardDecor,
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 10,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 60,
                headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
                // No onSelectChanged → no checkbox column
                columns: const [
                  DataColumn(
                      label: Text('Entry No',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Account',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Type',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: SizedBox(
                    width: 92,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Amount',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )),
                  DataColumn(
                      label: Text('Reference',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Rec.',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                      label: Text('Actions',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: items.map((e) {
                  final amtColor =
                      e.isDebit ? Colors.red.shade700 : Colors.green.shade700;
                  return DataRow(cells: [
                    // Entry No — clickable via InkWell; navigates to by-account view
                    DataCell(InkWell(
                      onTap: () => nav.viewAccountLedger(e.accountId),
                      child: Text(e.entryNo,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.terra600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.terra400,
                          )),
                    )),
                    DataCell(Text(fmtDate(e.entryDate),
                        style: const TextStyle(fontSize: 13))),
                    DataCell(SizedBox(
                      width: 140,
                      child: Text(accName(e.accountId),
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    )),
                    DataCell(LedgerTypeBadge(type: e.entryType)),
                    DataCell(SizedBox(
                      width: 92,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(fmtAmt(e.amount),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: amtColor,
                                fontSize: 13)),
                      ),
                    )),
                    DataCell(Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(e.referenceNo ?? '—',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
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
                                  color: Colors.blue.shade600, size: 18)
                              : Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400, size: 18),
                        ),
                      ),
                    )),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      LedgerActionBtn(
                          icon: Icons.edit_outlined,
                          color: AppTheme.textSecondary,
                          onTap: () => onEdit(e)),
                      const SizedBox(width: 6),
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
        ),
      );
    });
  }
}

// ── Mobile list ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.items,
    required this.nav,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleReconciled,
  });

  final List<LedgerEntry> items;
  final AccountsReportsNavController nav;
  final void Function(LedgerEntry?) onEdit;
  final void Function(LedgerEntry) onDelete;
  final void Function(LedgerEntry) onToggleReconciled;

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>().typedItems;
    String accName(String id) {
      try {
        return accounts.firstWhere((a) => a.id == id).text('accountName');
      } catch (_) {
        return id;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecor,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: InkWell(
              onTap: () => nav.viewAccountLedger(e.accountId),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(e.entryNo,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.terra600)),
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
                    const SizedBox(height: 4),
                    Text(fmtDate(e.entryDate),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 3),
                    Text(accName(e.accountId),
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(e.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text(fmtAmt(e.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: e.isDebit
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        )),
                  ]),
            )),
            const SizedBox(width: 8),
            Column(children: [
              LedgerActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppTheme.textSecondary,
                  onTap: () => onEdit(e)),
              const SizedBox(height: 6),
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
}

// ── Shared reusable widgets ───────────────────────────────────────────────────

class LedgerTypeBadge extends StatelessWidget {
  const LedgerTypeBadge({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isDebit = type == 'debit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDebit ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isDebit ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Text(isDebit ? 'Debit' : 'Credit',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
          )),
    );
  }
}

class LedgerActionBtn extends StatelessWidget {
  const LedgerActionBtn(
      {super.key,
      required this.icon,
      required this.color,
      required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.pageBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.softBorder),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );
}

// ── Shared format utils (used across screens) ─────────────────────────────────

String fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso.split('T').first;
  }
}

String fmtAmt(double v, {bool compact = true}) {
  if (!compact) return v.toStringAsFixed(2);
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(2)}M';
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(2)}K';
  return v.toStringAsFixed(2);
}
