import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/invoicing_nav_controller.dart';
import 'controllers/sales_invoice_controller.dart';
import 'controllers/purchase_order_controller.dart';
import 'controllers/send_order_controller.dart';
import 'controllers/purchase_invoice_controller.dart';
import 'controllers/purchase_return_controller.dart';
import 'controllers/sales_return_controller.dart';
import 'controllers/stock_issue_controller.dart';
import 'controllers/stock_expiry_controller.dart';
import 'controllers/expiry_claim_controller.dart';
import 'controllers/stock_wastage_controller.dart';
import 'controllers/recovery_invoice_controller.dart';
import 'controllers/recovery_invoice_wise_controller.dart';
import 'controllers/recovery_receivable_wise_controller.dart';
import 'controllers/cash_voucher_controller.dart';
import 'controllers/salesman_cash_reconciliation_controller.dart';
import 'controllers/bank_cheque_controller.dart';
import 'controllers/bank_deposit_controller.dart';
import 'controllers/payment_promise_controller.dart';

class InvoicingScope extends StatefulWidget {
  const InvoicingScope({super.key, required this.child});
  final Widget child;

  @override
  State<InvoicingScope> createState() => _InvoicingScopeState();
}

class _InvoicingScopeState extends State<InvoicingScope> {
  bool _loaded = false;

  // Bootstrap only the two primary lists on startup.
  // All other controllers fetch lazily when their screen is opened.
  Future<void> _bootstrap(BuildContext context) async {
    await Future.wait([
      context.read<SalesInvoiceController>().fetchAll(),
      context.read<PurchaseOrderController>().fetchAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoicingNavController()),
        ChangeNotifierProvider(create: (_) => SalesInvoiceController()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderController()),
        ChangeNotifierProvider(create: (_) => SendOrderController()),
        ChangeNotifierProvider(create: (_) => PurchaseInvoiceController()),
        ChangeNotifierProvider(create: (_) => PurchaseReturnController()),
        ChangeNotifierProvider(create: (_) => SalesReturnController()),
        ChangeNotifierProvider(create: (_) => StockIssueController()),
        ChangeNotifierProvider(create: (_) => StockExpiryController()),
        ChangeNotifierProvider(create: (_) => ExpiryClaimController()),
        ChangeNotifierProvider(create: (_) => StockWastageController()),
        ChangeNotifierProvider(create: (_) => RecoveryInvoiceController()),
        ChangeNotifierProvider(create: (_) => RecoveryInvoiceWiseController()),
        ChangeNotifierProvider(create: (_) => RecoveryReceivableWiseController()),
        ChangeNotifierProvider(create: (_) => CashVoucherController()),
        ChangeNotifierProvider(create: (_) => SalesmanCashReconciliationController()),
        ChangeNotifierProvider(create: (_) => BankChequeController()),
        ChangeNotifierProvider(create: (_) => BankDepositController()),
        ChangeNotifierProvider(create: (_) => PaymentPromiseController()),
      ],
      child: Builder(
        builder: (context) {
          if (!_loaded) {
            _loaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _bootstrap(context);
            });
          }
          return widget.child;
        },
      ),
    );
  }
}
