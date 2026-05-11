import 'package:flutter/material.dart';

class AccountsReportsNavItem {
  const AccountsReportsNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.comingSoonNote,
  });

  final String   id;
  final String   label;
  final IconData icon;
  final bool     enabled;
  final String?  comingSoonNote;
}

const List<AccountsReportsNavItem> kAccountsReportsNavItems = [
  AccountsReportsNavItem(
    id:    'ledger_entries',
    label: 'Ledger Entries',
    icon:  Icons.menu_book_outlined,
  ),
  AccountsReportsNavItem(
    id:    'account_ledger_view',
    label: 'By Account',
    icon:  Icons.account_balance_outlined,
  ),
  // ── Coming soon — require Transactions module ──────────────────────────────
  AccountsReportsNavItem(
    id:             'cash_book',
    label:          'Cash Book',
    icon:           Icons.receipt_outlined,
    enabled:        false,
    comingSoonNote: 'Requires Transactions module',
  ),
  AccountsReportsNavItem(
    id:             'cash_flow',
    label:          'Cash Flow',
    icon:           Icons.waterfall_chart_outlined,
    enabled:        false,
    comingSoonNote: 'Requires Transactions module',
  ),
  AccountsReportsNavItem(
    id:             'bank_statement',
    label:          'Bank Statement',
    icon:           Icons.account_balance_wallet_outlined,
    enabled:        false,
    comingSoonNote: 'Requires Transactions module',
  ),
  AccountsReportsNavItem(
    id:             'trial_balance',
    label:          'Trial Balance',
    icon:           Icons.balance_outlined,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing + Transactions',
  ),
  AccountsReportsNavItem(
    id:             'profit_loss',
    label:          'P & L',
    icon:           Icons.trending_up_outlined,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing + Transactions',
  ),
];
