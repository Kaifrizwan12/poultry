import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';

import '../config/accounts_reports_definitions.dart';
import '../controllers/accounts_reports_nav_controller.dart';
import 'ledger_list_screen.dart';
import 'ledger_by_account_screen.dart';

class AccountsReportsScreen extends StatelessWidget {
  const AccountsReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsReportsNavController>(
      builder: (context, nav, _) {
        final width = MediaQuery.of(context).size.width;

        if (width < 600) {
          return _MobileLayout(nav: nav);
        }

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChipBar(nav: nav),
              const SizedBox(height: 14),
              Expanded(child: _ContentArea(nav: nav)),
            ],
          ),
        );
      },
    );
  }
}

// ── Chip nav bar ──────────────────────────────────────────────────────────────

class _ChipBar extends StatelessWidget {
  const _ChipBar({required this.nav});
  final AccountsReportsNavController nav;

  @override
  Widget build(BuildContext context) {
    // Resolve effective section: 'account_ledger_view' maps to 'account_ledger_view' chip
    final active = nav.selectedSection;

    return HorizontalScrollWheel(child: Row(
        children: kAccountsReportsNavItems.map((item) {
          final selected = item.id == active;
          final iconColor =
              selected ? AppTheme.terra800 : AppTheme.textSecondary;

          if (!item.enabled) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: item.comingSoonNote ?? 'Coming soon',
                child: Opacity(
                  opacity: 0.38,
                  child: _buildChip(
                    icon: item.icon,
                    label: item.label,
                    iconColor: AppTheme.textTertiary,
                    selected: false,
                    extraIcon: const Icon(Icons.lock_outline,
                        size: 11, color: AppTheme.textTertiary),
                    onTap: null,
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(
              icon: item.icon,
              label: item.label,
              iconColor: iconColor,
              selected: selected,
              onTap: () {
                nav.selectSection(item.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool selected,
    Widget? extraIcon,
    VoidCallback? onTap,
  }) {
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 5),
        Text(label),
        if (extraIcon != null) ...[const SizedBox(width: 4), extraIcon],
      ]),
      selected: selected,
      selectedColor: AppTheme.terra100,
      backgroundColor: AppTheme.surfaceWhite,
      side: BorderSide(
        color: selected ? AppTheme.terra400 : AppTheme.softBorder,
        width: selected ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppTheme.terra800 : AppTheme.textSecondary,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onSelected: onTap != null ? (_) => onTap() : null,
    );
  }
}

// ── Content area ──────────────────────────────────────────────────────────────

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.nav});
  final AccountsReportsNavController nav;

  @override
  Widget build(BuildContext context) {
    if (nav.selectedSection == 'account_ledger_view' &&
        nav.selectedAccountId != null) {
      return LedgerByAccountScreen(accountId: nav.selectedAccountId!);
    }
    if (nav.selectedSection == 'account_ledger_view') {
      return _AccountPicker(nav: nav);
    }
    // Default + 'ledger_entries' → list
    return const LedgerListScreen();
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.nav});
  final AccountsReportsNavController nav;

  @override
  Widget build(BuildContext context) {
    final accounts = context
        .watch<AccountsController>()
        .typedItems
        .where((a) => a.boolean('isActive'))
        .toList();

    if (accounts.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecor,
          child: const Text(
            'No accounts found. Create accounts in Settings first.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Account',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Select an account to view its ledger.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: null,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Choose account'),
              items: accounts.map((a) {
                final code = a.text('accountCode');
                final name = a.text('accountName');
                final type = a.text('accountType');
                final label = [
                  if (code.isNotEmpty) code,
                  if (name.isNotEmpty) name,
                  if (type.isNotEmpty) '($type)',
                ].join(' — ').replaceAll('—  —', '—');
                return DropdownMenuItem<String>(
                  value: a.id,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (id) {
                final next = (id ?? '').trim();
                if (next.isNotEmpty) nav.viewAccountLedger(next);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.nav});
  final AccountsReportsNavController nav;

  @override
  Widget build(BuildContext context) {
    // Drill-in: by-account view
    if (nav.selectedSection == 'account_ledger_view' &&
        nav.selectedAccountId != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Ledger'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: nav.backToList,
          ),
        ),
        body: Padding(
          padding: AppTheme.pagePadding(context),
          child: LedgerByAccountScreen(accountId: nav.selectedAccountId!),
        ),
      );
    }

    // Section selected (not menu) — show with back button
    if (nav.selectedSection != 'menu' &&
        nav.selectedSection != 'ledger_entries') {
      return Scaffold(
        appBar: AppBar(
          title: Text(_labelFor(nav.selectedSection)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => nav.selectSection('menu'),
          ),
        ),
        body: Padding(
          padding: AppTheme.pagePadding(context),
          child: _sectionWidget(nav.selectedSection),
        ),
      );
    }

    // Default / 'ledger_entries' section
    if (nav.selectedSection == 'ledger_entries') {
      return Padding(
        padding: AppTheme.pagePadding(context),
        child: const LedgerListScreen(),
      );
    }

    // Menu — list of all sections
    return ListView.builder(
      padding: AppTheme.pagePadding(context),
      itemCount: kAccountsReportsNavItems.length,
      itemBuilder: (context, index) {
        final item = kAccountsReportsNavItems[index];
        if (!item.enabled) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: AppTheme.cardDecor,
            child: ListTile(
              contentPadding: AppTheme.tilePadding,
              minLeadingWidth: 24,
              leading: CircleAvatar(
                backgroundColor: AppTheme.pageBg,
                child: Icon(item.icon, color: AppTheme.textTertiary, size: 20),
              ),
              title: Text(item.label,
                  style: const TextStyle(color: AppTheme.textTertiary)),
              trailing: Tooltip(
                message: item.comingSoonNote ?? 'Coming soon',
                child: const Icon(Icons.lock_outline,
                    color: AppTheme.textTertiary, size: 16),
              ),
              enabled: false,
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecor,
          child: ListTile(
            contentPadding: AppTheme.tilePadding,
            minLeadingWidth: 24,
            leading: CircleAvatar(
              backgroundColor: AppTheme.terra50,
              child: Icon(item.icon, color: AppTheme.terra600, size: 20),
            ),
            title: Text(item.label),
            trailing:
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => nav.selectSection(item.id),
          ),
        );
      },
    );
  }

  Widget _sectionWidget(String section) {
    switch (section) {
      case 'ledger_entries':
        return const LedgerListScreen();
      case 'account_ledger_view':
        return _AccountPicker(nav: nav);
      default:
        return const LedgerListScreen();
    }
  }

  String _labelFor(String section) {
    for (final item in kAccountsReportsNavItems) {
      if (item.id == section) return item.label;
    }
    return 'Reports';
  }
}
