import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';

// ─── Navigation section enum ──────────────────────────────────────────────────

enum InvoicingSection {
  // Invoicing group
  purchaseOrder,
  sendPurchaseOrder,
  purchaseInvoice,
  purchaseReturnWithInvoice,
  purchaseReturnWithoutInvoice,
  salesInvoice,
  salesReturnWithInvoice,
  salesReturnWithoutInvoice,
  // Stock group
  stockIssueToSalesman,
  stockReturnFromSalesman,
  stockExpiryInvoice,
  expiryClaimFromCustomer,
  expiryClaimToVendor,
  stockWastageInvoice,
  // Recovery group
  recoveryInvoice,
  recoveryInvoiceWise,
  recoveryReceivableWise,
  salesmanCashReconciliation,
  // Vouchers group
  cashReceivingVoucher,
  cashPaymentVoucher,
  journalVoucher,
  // Banking group
  bankChequeIssuing,
  bankChequesReconciliation,
  cashDepositInBank,
  chequeDepositInBank,
  depositConfirmation,
  depositReconciliation,
  voucherConfirmation,
  // Promises group
  postDatedRecoveryPromise,
  postDatedPaymentPromise,
  promisesProcessing,
}

// ─── Lookup option constants ───────────────────────────────────────────────────

const List<LookupOption> kReturnTypes = [
  LookupOption(value: 'with_invoice',    label: 'With Invoice'),
  LookupOption(value: 'without_invoice', label: 'Without Invoice'),
];

const List<LookupOption> kStockIssueTypes = [
  LookupOption(value: 'issue',  label: 'Issue to Salesman'),
  LookupOption(value: 'return', label: 'Return from Salesman'),
];

const List<LookupOption> kExpiryClaimDirections = [
  LookupOption(value: 'from_customer', label: 'From Customer'),
  LookupOption(value: 'to_vendor',     label: 'To Vendor'),
];

const List<LookupOption> kVoucherTypes = [
  LookupOption(value: 'credit',  label: 'Cash Receiving (Credit)'),
  LookupOption(value: 'debit',   label: 'Cash Payment (Debit)'),
  LookupOption(value: 'journal', label: 'Journal'),
];

const List<LookupOption> kChequeStatuses = [
  LookupOption(value: 'issued',    label: 'Issued'),
  LookupOption(value: 'cleared',   label: 'Cleared'),
  LookupOption(value: 'bounced',   label: 'Bounced'),
  LookupOption(value: 'cancelled', label: 'Cancelled'),
];

const List<LookupOption> kDepositTypes = [
  LookupOption(value: 'cash',   label: 'Cash Deposit'),
  LookupOption(value: 'cheque', label: 'Cheque Deposit'),
];

const List<LookupOption> kPromiseTypes = [
  LookupOption(value: 'recovery', label: 'Recovery Promise'),
  LookupOption(value: 'payment',  label: 'Payment Promise'),
];

const List<LookupOption> kPromiseStatuses = [
  LookupOption(value: 'pending',   label: 'Pending'),
  LookupOption(value: 'cleared',   label: 'Cleared'),
  LookupOption(value: 'bounced',   label: 'Bounced'),
  LookupOption(value: 'cancelled', label: 'Cancelled'),
];

const List<LookupOption> kBankPayeeTypes = [
  LookupOption(value: 'vendor',  label: 'Vendor'),
  LookupOption(value: 'account', label: 'Account'),
  LookupOption(value: 'other',   label: 'Other'),
];

const List<LookupOption> kInvoiceStatuses = [
  LookupOption(value: 'pending', label: 'Pending'),
  LookupOption(value: 'saved',   label: 'Saved'),
];

// ─── Label helper ─────────────────────────────────────────────────────────────

String labelFor(List<LookupOption> options, String value) {
  for (final o in options) {
    if (o.value == value) return o.label;
  }
  return value;
}
