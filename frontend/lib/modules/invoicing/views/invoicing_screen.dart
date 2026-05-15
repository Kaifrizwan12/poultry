import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/invoicing_definitions.dart';
import '../config/invoicing_nav_config.dart';
import '../controllers/invoicing_nav_controller.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';
import 'sales_invoice_screen.dart';
import 'purchase_order_screen.dart';
import 'send_order_screen.dart';
import 'purchase_invoice_screen.dart';
import 'purchase_return_screen.dart';
import 'sales_return_screen.dart';
import 'stock_issue_screen.dart';
import 'stock_expiry_screen.dart';
import 'expiry_claim_screen.dart';
import 'stock_wastage_screen.dart';

class InvoicingScreen extends StatelessWidget {
  const InvoicingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoicingNavController>(
      builder: (context, nav, _) {
        final width = MediaQuery.of(context).size.width;
        if (width < 600) {
          return _MobileInvoicingLayout(nav: nav);
        }

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InvoicingChipBar(nav: nav),
              const SizedBox(height: 14),
              Expanded(child: _InvoicingContentArea(nav: nav)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Chip Bar ─────────────────────────────────────────────────────────────────

class _InvoicingChipBar extends StatelessWidget {
  const _InvoicingChipBar({required this.nav});
  final InvoicingNavController nav;

  @override
  Widget build(BuildContext context) {
    final groups = invoicingScreenGroups();
    return HorizontalScrollWheel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                group.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
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
                  side: BorderSide(
                    color: nav.selectedSection == item.section
                        ? AppTheme.terra400
                        : AppTheme.softBorder,
                    width: nav.selectedSection == item.section ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: nav.selectedSection == item.section
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: nav.selectedSection == item.section
                        ? AppTheme.terra800
                        : AppTheme.textSecondary,
                  ),
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

class _InvoicingContentArea extends StatelessWidget {
  const _InvoicingContentArea({required this.nav});
  final InvoicingNavController nav;

  @override
  Widget build(BuildContext context) {
    switch (nav.selectedSection) {
      case InvoicingSection.salesInvoice:
        return const SalesInvoiceScreen();
      case InvoicingSection.purchaseOrder:
        return const PurchaseOrderScreen();
      case InvoicingSection.sendPurchaseOrder:
        return const SendOrderScreen();
      case InvoicingSection.purchaseInvoice:
        return const PurchaseInvoiceScreen();
      case InvoicingSection.purchaseReturnWithInvoice:
        return const PurchaseReturnScreen(returnType: 'with_invoice');
      case InvoicingSection.purchaseReturnWithoutInvoice:
        return const PurchaseReturnScreen(returnType: 'without_invoice');
      case InvoicingSection.salesReturnWithInvoice:
        return const SalesReturnScreen(returnType: 'with_invoice');
      case InvoicingSection.salesReturnWithoutInvoice:
        return const SalesReturnScreen(returnType: 'without_invoice');
      case InvoicingSection.stockIssueToSalesman:
        return const StockIssueScreen(issueType: 'issue');
      case InvoicingSection.stockReturnFromSalesman:
        return const StockIssueScreen(issueType: 'return');
      case InvoicingSection.stockExpiryInvoice:
        return const StockExpiryScreen();
      case InvoicingSection.expiryClaimFromCustomer:
        return const ExpiryClaimScreen(direction: 'from_customer');
      case InvoicingSection.expiryClaimToVendor:
        return const ExpiryClaimScreen(direction: 'to_vendor');
      case InvoicingSection.stockWastageInvoice:
        return const StockWastageScreen();
      default:
        return _ComingSoonPlaceholder(label: nav.selectedSection.name);
    }
  }
}

// ─── Mobile Layout ─────────────────────────────────────────────────────────────

class _MobileInvoicingLayout extends StatelessWidget {
  const _MobileInvoicingLayout({required this.nav});
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
          child: _InvoicingContentArea(nav: nav),
        ),
      );
    }

    final groups = invoicingScreenGroups();
    return ListView(
      padding: AppTheme.pagePadding(context),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              group.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
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
    for (final g in invoicingScreenGroups()) {
      for (final i in g.items) {
        if (i.section == section) return i.label;
      }
    }
    return 'Invoicing';
  }
}

// ─── Coming Soon Placeholder ──────────────────────────────────────────────────

class _ComingSoonPlaceholder extends StatelessWidget {
  const _ComingSoonPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — coming soon',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
