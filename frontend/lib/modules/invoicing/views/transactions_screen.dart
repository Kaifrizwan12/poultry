import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/invoicing_definitions.dart';
import '../config/invoicing_nav_config.dart';
import '../controllers/invoicing_nav_controller.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'recovery_invoice_screen.dart';
import 'recovery_invoice_wise_screen.dart';
import 'recovery_receivable_wise_screen.dart';
import 'salesman_cash_reconciliation_screen.dart';
import 'cash_voucher_screen.dart';
import 'bank_cheque_issuing_screen.dart';
import 'bank_cheques_reconciliation_screen.dart';
import 'cash_deposit_screen.dart';
import 'cheque_deposit_screen.dart';
import 'deposit_confirmation_screen.dart';
import 'deposit_reconciliation_screen.dart';
import 'voucher_confirmation_screen.dart';
import 'post_dated_recovery_promise_screen.dart';
import 'post_dated_payment_promise_screen.dart';
import 'promises_processing_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoicingNavController>(
      builder: (context, nav, _) {
        final width = MediaQuery.of(context).size.width;
        // On desktop/tablet only: auto-select first transactions section if
        // the controller still holds the default invoicing section.
        if (width >= 600 && !isTransactionsSection(nav.selectedSection)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              nav.selectSection(InvoicingSection.recoveryInvoice);
            }
          });
        }
        if (width < 600) {
          return _MobileTransactionsLayout(nav: nav);
        }

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TransactionsChipBar(nav: nav),
              const SizedBox(height: 14),
              Expanded(child: _TransactionsContentArea(nav: nav)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Chip Bar ─────────────────────────────────────────────────────────────────

class _TransactionsChipBar extends StatelessWidget {
  const _TransactionsChipBar({required this.nav});
  final InvoicingNavController nav;

  @override
  Widget build(BuildContext context) {
    final groups = transactionsScreenGroups();
    return HorizontalScrollWheel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                group.title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ),
            for (final item in group.items)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(item.label),
                  selected: nav.selectedSection == item.section,
                  selectedColor: AppTheme.terra100,
                  backgroundColor: AppTheme.surfaceWhite,
                  side: BorderSide(color: nav.selectedSection == item.section ? AppTheme.terra400 : AppTheme.softBorder, width: nav.selectedSection == item.section ? 1.5 : 1),
                  labelStyle: TextStyle(fontSize: 12, fontWeight: nav.selectedSection == item.section ? FontWeight.w700 : FontWeight.w500, color: nav.selectedSection == item.section ? AppTheme.terra800 : AppTheme.textSecondary),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  onSelected: (_) => nav.selectSection(item.section),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ─── Content Area ─────────────────────────────────────────────────────────────

class _TransactionsContentArea extends StatelessWidget {
  const _TransactionsContentArea({required this.nav});
  final InvoicingNavController nav;

  @override
  Widget build(BuildContext context) {
    switch (nav.selectedSection) {
      case InvoicingSection.recoveryInvoice:
        return const RecoveryInvoiceScreen();
      case InvoicingSection.recoveryInvoiceWise:
        return const RecoveryInvoiceWiseScreen();
      case InvoicingSection.recoveryReceivableWise:
        return const RecoveryReceivableWiseScreen();
      case InvoicingSection.salesmanCashReconciliation:
        return const SalesmanCashReconciliationScreen();
      case InvoicingSection.cashReceivingVoucher:
        return const CashVoucherScreen(voucherType: 'credit');
      case InvoicingSection.cashPaymentVoucher:
        return const CashVoucherScreen(voucherType: 'debit');
      case InvoicingSection.journalVoucher:
        return const CashVoucherScreen(voucherType: 'journal');
      case InvoicingSection.bankChequeIssuing:
        return const BankChequeIssuingScreen();
      case InvoicingSection.bankChequesReconciliation:
        return const BankChequesReconciliationScreen();
      case InvoicingSection.cashDepositInBank:
        return const CashDepositScreen();
      case InvoicingSection.chequeDepositInBank:
        return const ChequeDepositScreen();
      case InvoicingSection.depositConfirmation:
        return const DepositConfirmationScreen();
      case InvoicingSection.depositReconciliation:
        return const DepositReconciliationScreen();
      case InvoicingSection.voucherConfirmation:
        return const VoucherConfirmationScreen();
      case InvoicingSection.postDatedRecoveryPromise:
        return const PostDatedRecoveryPromiseScreen();
      case InvoicingSection.postDatedPaymentPromise:
        return const PostDatedPaymentPromiseScreen();
      case InvoicingSection.promisesProcessing:
        return const PromisesProcessingScreen();
      default:
        return Center(child: Text('${nav.selectedSection.name} — coming soon'));
    }
  }
}

// ─── Mobile Layout ─────────────────────────────────────────────────────────────

class _MobileTransactionsLayout extends StatelessWidget {
  const _MobileTransactionsLayout({required this.nav});
  final InvoicingNavController nav;

  @override
  Widget build(BuildContext context) {
    final isMenu = nav.showMobileMenu;

    if (!isMenu) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_labelFor(nav.selectedSection)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: nav.goBackToMenu,
          ),
        ),
        body: Padding(
          padding: AppTheme.pagePadding(context),
          child: _TransactionsContentArea(nav: nav),
        ),
      );
    }

    final groups = transactionsScreenGroups();
    return ListView(
      padding: AppTheme.pagePadding(context),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(group.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14)),
          ),
          for (final item in group.items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cardDecor,
              child: ListTile(
                contentPadding: AppTheme.tilePadding,
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                onTap: () => nav.selectSection(item.section),
              ),
            ),
        ],
      ],
    );
  }

  String _labelFor(InvoicingSection section) {
    for (final g in transactionsScreenGroups()) {
      for (final i in g.items) {
        if (i.section == section) return i.label;
      }
    }
    return 'Transactions';
  }
}
