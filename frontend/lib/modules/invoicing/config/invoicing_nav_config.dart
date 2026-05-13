import 'invoicing_definitions.dart';

// ─── Nav item model ────────────────────────────────────────────────────────────

class InvoicingNavItem {
  const InvoicingNavItem({required this.label, required this.section});
  final String label;
  final InvoicingSection section;
}

class InvoicingNavGroup {
  const InvoicingNavGroup({required this.title, required this.items});
  final String title;
  final List<InvoicingNavItem> items;
}

// ─── Navigation groups ─────────────────────────────────────────────────────────

const List<InvoicingNavGroup> kInvoicingNavGroups = [
  InvoicingNavGroup(
    title: 'Invoicing',
    items: [
      InvoicingNavItem(label: 'Purchase Order',                   section: InvoicingSection.purchaseOrder),
      InvoicingNavItem(label: 'Send Purchase Order',              section: InvoicingSection.sendPurchaseOrder),
      InvoicingNavItem(label: 'Purchase Invoice',                 section: InvoicingSection.purchaseInvoice),
      InvoicingNavItem(label: 'Purchase Return (With Invoice)',   section: InvoicingSection.purchaseReturnWithInvoice),
      InvoicingNavItem(label: 'Purchase Return (Without Invoice)',section: InvoicingSection.purchaseReturnWithoutInvoice),
      InvoicingNavItem(label: 'Sales Invoice',                    section: InvoicingSection.salesInvoice),
      InvoicingNavItem(label: 'Sales Return (With Invoice)',      section: InvoicingSection.salesReturnWithInvoice),
      InvoicingNavItem(label: 'Sales Return (Without Invoice)',   section: InvoicingSection.salesReturnWithoutInvoice),
    ],
  ),
  InvoicingNavGroup(
    title: 'Stock',
    items: [
      InvoicingNavItem(label: 'Stock Issue to Salesman',    section: InvoicingSection.stockIssueToSalesman),
      InvoicingNavItem(label: 'Stock Return from Salesman', section: InvoicingSection.stockReturnFromSalesman),
      InvoicingNavItem(label: 'Stock Expiry Invoice',       section: InvoicingSection.stockExpiryInvoice),
      InvoicingNavItem(label: 'Expiry Claim From Customer', section: InvoicingSection.expiryClaimFromCustomer),
      InvoicingNavItem(label: 'Expiry Claim To Vendor',     section: InvoicingSection.expiryClaimToVendor),
      InvoicingNavItem(label: 'Stock Wastage Invoice',      section: InvoicingSection.stockWastageInvoice),
    ],
  ),
  InvoicingNavGroup(
    title: 'Recovery',
    items: [
      InvoicingNavItem(label: 'Recovery Invoice',          section: InvoicingSection.recoveryInvoice),
      InvoicingNavItem(label: 'Recovery (Invoice Wise)',   section: InvoicingSection.recoveryInvoiceWise),
      InvoicingNavItem(label: 'Recovery (Receivable Wise)',section: InvoicingSection.recoveryReceivableWise),
      InvoicingNavItem(label: 'Salesman Cash Reconciliation', section: InvoicingSection.salesmanCashReconciliation),
    ],
  ),
  InvoicingNavGroup(
    title: 'Vouchers',
    items: [
      InvoicingNavItem(label: 'Cash Receiving Voucher', section: InvoicingSection.cashReceivingVoucher),
      InvoicingNavItem(label: 'Cash Payment Voucher',   section: InvoicingSection.cashPaymentVoucher),
      InvoicingNavItem(label: 'Journal Voucher',        section: InvoicingSection.journalVoucher),
    ],
  ),
  InvoicingNavGroup(
    title: 'Banking',
    items: [
      InvoicingNavItem(label: 'Bank Cheque Issuing',       section: InvoicingSection.bankChequeIssuing),
      InvoicingNavItem(label: 'Bank Cheques Reconciliation',section: InvoicingSection.bankChequesReconciliation),
      InvoicingNavItem(label: 'Cash Deposit in Bank',      section: InvoicingSection.cashDepositInBank),
      InvoicingNavItem(label: 'Cheque Deposit in Bank',    section: InvoicingSection.chequeDepositInBank),
      InvoicingNavItem(label: 'Deposit Confirmation',      section: InvoicingSection.depositConfirmation),
      InvoicingNavItem(label: 'Deposit Reconciliation',    section: InvoicingSection.depositReconciliation),
      InvoicingNavItem(label: 'Voucher Confirmation',      section: InvoicingSection.voucherConfirmation),
    ],
  ),
  InvoicingNavGroup(
    title: 'Promises',
    items: [
      InvoicingNavItem(label: 'Post Dated Recovery Promise', section: InvoicingSection.postDatedRecoveryPromise),
      InvoicingNavItem(label: 'Post Dated Payment Promise',  section: InvoicingSection.postDatedPaymentPromise),
      InvoicingNavItem(label: 'Promises Processing',         section: InvoicingSection.promisesProcessing),
    ],
  ),
];
