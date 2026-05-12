# CLAUDE CODE PROMPT — CASH BOOK MODULE + SCAFFOLD ARCHITECTURE
## Farm Management System — Poultry Edition

---

## 0. CONTEXT & READING ORDER

You are working inside an existing Flutter + Node.js/Firestore monorepo.

**Read these files FIRST before writing a single line:**
```
frontend/lib/core/app_theme.dart               ← all colors, spacing, radii — use ONLY these
frontend/lib/services/api_service.dart          ← HTTP layer pattern
frontend/lib/modules/shell/main_shell.dart      ← navigation shell, module index positions
frontend/lib/modules/accounts_reports/accounts_reports_scope.dart   ← scope/provider pattern
frontend/lib/modules/accounts_reports/config/accounts_reports_definitions.dart ← nav item pattern
frontend/lib/modules/accounts_reports/controllers/ledger_controller.dart       ← controller pattern
frontend/lib/modules/accounts_reports/services/ledger_service.dart             ← service pattern
frontend/lib/modules/accounts_reports/views/ledger_list_screen.dart            ← list screen pattern
frontend/lib/modules/accounts_reports/views/accounts_reports_screen.dart       ← tab/chip nav pattern
frontend/lib/modules/poultry/poultry_scope.dart                                ← multi-controller scope
frontend/lib/modules/poultry/config/poultry_definitions.dart                   ← enum/const pattern
backend/src/modules/accounts/accounts.routes.js                                ← CRUD router pattern
backend/src/modules/accounts/entities/ledger_entry.config.js                   ← entity config pattern
backend/src/models/settings.config.js                                           ← validators, enums
backend/src/index.js                                                             ← route registration
```

**Existing module index map in MainShell:**
```
0 = Home
1 = Settings
2 = Invoicing      ← placeholder, not yet built
3 = Transactions   ← placeholder, not yet built
4 = Poultry        ← fully built
5 = Reports (AccountsReports) ← partially built: Ledger Entries + By Account
```

---

## 1. THE GRAND ARCHITECTURE STRATEGY (READ BEFORE CODING)

### 1.1 Data Flow Graph — The Iron Rule

Every financial number in this system flows in ONE direction only:

```
SETTINGS (master data)
  └── accounts, customers, vendors, products, salesmen
        │
        ▼
INVOICING (creates stock movements + receivables/payables)
  ├── SalesInvoice → creates → AccountsReceivable record + LedgerEntry(debit AR, credit Sales)
  ├── PurchaseInvoice → creates → AccountsPayable record + LedgerEntry(debit Purchase, credit AP)
  ├── SalesReturn → reverses → SalesInvoice entries
  └── PurchaseReturn → reverses → PurchaseInvoice entries
        │
        ▼
TRANSACTIONS (records cash/cheque movements + reconciles invoices)
  ├── CashReceivingVoucher → settles → AccountsReceivable + LedgerEntry(debit Cash, credit AR)
  ├── CashPaymentVoucher   → settles → AccountsPayable   + LedgerEntry(debit AP, credit Cash)
  ├── JournalVoucher       → direct double-entry → two LedgerEntries
  ├── BankChequeIssuing    → LedgerEntry(debit AP, credit Bank) + ChequeRecord
  ├── BankChequeReconciliation → marks ChequeRecord as cleared
  ├── CashDepositInBank    → LedgerEntry(debit Bank, credit Cash)
  ├── ChequeDepositInBank  → LedgerEntry(debit Bank, credit Cheque-in-hand)
  └── RecoveryInvoice      → special: recovers from customer against invoice(s)
        │
        ▼
ACCOUNTS REPORTS (read-only aggregations — NEVER write data here)
  ├── Cash Book    ← TODAY'S TARGET: filter ledger entries where accountId = Cash account
  ├── Bank Statement ← filter where accountId = Bank account(s)
  ├── Account Ledger ← already built (any account)
  ├── Cash Flow Register ← aggregate cash in/out by period
  ├── Trial Balance ← sum all account balances
  ├── P&L Statement ← income accounts vs expense accounts
  └── Balance Sheet ← assets vs liabilities vs equity
```

### 1.2 Today's Scope vs Later Scope

**TODAY — Build these (no invoice/transaction prereqs needed for Cash Book):**
- `Transactions` module scaffold with:
  - `CashReceivingVoucher` (CR voucher) — full CRUD
  - `CashPaymentVoucher` (CP voucher) — full CRUD
  - `JournalVoucher` — full CRUD
- `AccountsReports` — unlock `Cash Book` tab (reads existing LedgerEntries filtered by cash account)
- Backend entity configs for all three vouchers
- The `cashAccounts` concept (mark an account as `isCashAccount: true` in Settings → Accounts)

**LATER — Build after Invoicing is done:**
- `SalesInvoice`, `PurchaseInvoice` (require: products, customers, vendors, stock)
- `Recovery (Invoice-wise)` (requires SalesInvoice IDs)
- `BankChequeIssuing`, `BankChequeReconciliation` (require: bank account designation)
- `CashDepositInBank`, `ChequeDepositInBank`
- `PostDatedRecoveryPromise`, `PostDatedPaymentPromise`

### 1.3 The Scaffold Rule — Lock These Models NOW

These Firestore collection paths and field contracts MUST NOT change after today.
Any future module that writes to them MUST conform to this schema.

```
users/{uid}/accounts/         ← Settings accounts (already exists)
users/{uid}/ledgerEntries/    ← already exists, extend referenceType enum only
users/{uid}/cashVouchers/     ← NEW TODAY: CRV + CPV + JV all in one collection
users/{uid}/invoices/         ← SCAFFOLD TODAY: empty collection, locked schema
users/{uid}/stockMovements/   ← SCAFFOLD TODAY: empty collection, locked schema
users/{uid}/cheques/          ← SCAFFOLD TODAY: empty collection, locked schema
users/{uid}/recoveries/       ← SCAFFOLD TODAY: empty collection, locked schema
users/{uid}/paymentPromises/  ← SCAFFOLD TODAY: empty collection, locked schema
```

---

## 2. BACKEND TASKS

### 2.1 Extend `ledger_entry.config.js` — Extend referenceType

Open `backend/src/modules/accounts/entities/ledger_entry.config.js`.

Change the `REFERENCE_TYPES` array from:
```javascript
const REFERENCE_TYPES = ['manual', 'chicken_invoice', 'opening_receivable', 'opening_payable', 'other'];
```
To:
```javascript
const REFERENCE_TYPES = [
  'manual',
  'cash_receiving_voucher',   // CR voucher
  'cash_payment_voucher',     // CP voucher
  'journal_voucher',          // JV
  'sales_invoice',            // future
  'purchase_invoice',         // future
  'sales_return',             // future
  'purchase_return',          // future
  'bank_cheque',              // future
  'cash_deposit',             // future
  'cheque_deposit',           // future
  'recovery_invoice',         // future
  'chicken_invoice',          // existing poultry
  'opening_receivable',       // existing opening
  'opening_payable',          // existing opening
  'stock_expiry',             // future
  'other',
];
```

### 2.2 Extend Settings Account model — Add `isCashAccount` + `isBankAccount`

Open `backend/src/models/settings.config.js`.
In the `accounts` sanitize function, add two boolean fields:

```javascript
accounts: {
  entity: 'accounts',
  sanitize: async ({ uid, body, id }) => {
    // ... existing code unchanged ...
    return {
      data: {
        // ... existing fields unchanged ...
        isCashAccount: asBoolean(body.isCashAccount, false),  // ADD THIS
        isBankAccount: asBoolean(body.isBankAccount, false),  // ADD THIS
        isSystemAccount: asBoolean(body.isSystemAccount, false), // ADD THIS — system accounts cannot be deleted
      },
      errors,
    };
  },
},
```

### 2.3 Create `backend/src/modules/transactions/` directory structure

```
backend/src/modules/transactions/
  entities/
    cash_voucher.config.js     ← NEW
  transactions.routes.js       ← NEW
  transactions.validators.js   ← NEW
```

### 2.4 Create `backend/src/modules/transactions/transactions.validators.js`

```javascript
// transactions.validators.js
// Mirrors accounts.validators.js but for the transactions sub-system.

const { db } = require('../../core/firebase/firebaseAdmin');

const TRANSACTIONS_ROOT = (uid) =>
  db.collection('users').doc(uid).collection('transactions');

function transactionsCollection(uid, entity) {
  return TRANSACTIONS_ROOT(uid).doc('__root__').collection(entity);
}

// Re-export shared validators (keep DRY — these are identical to accounts.validators.js)
const {
  asRequiredString,
  asNullableString,
  asNumber,
  asEnum,
  asDateString,
  asBoolean,
  cleanStringList,
  nowIso,
} = require('../accounts/accounts.validators');

const { settingsCollection } = require('../../utils/firestore');

async function requireSettingsRef(uid, entity, id, field, errors) {
  if (!id) return;
  const snap = await settingsCollection(uid, entity).doc(id).get();
  if (!snap.exists) errors.push(`${field} references a non-existent ${entity} record`);
}

async function requireAccountExists(uid, accountId, field, errors) {
  if (!accountId) { errors.push(`${field} is required`); return; }
  await requireSettingsRef(uid, 'accounts', accountId, field, errors);
}

function stampNew(uid, data) {
  const ts = nowIso();
  return { ...data, uid, createdAt: ts, updatedAt: ts };
}

function stampUpdated(existing, data) {
  return { ...existing, ...data, updatedAt: nowIso() };
}

module.exports = {
  transactionsCollection,
  asRequiredString,
  asNullableString,
  asNumber,
  asEnum,
  asDateString,
  asBoolean,
  cleanStringList,
  nowIso,
  requireSettingsRef,
  requireAccountExists,
  stampNew,
  stampUpdated,
};
```

### 2.5 Create `backend/src/modules/transactions/entities/cash_voucher.config.js`

This is the CORE entity. CashReceivingVoucher, CashPaymentVoucher, and JournalVoucher all
live in the SAME Firestore collection `cashVouchers` differentiated by `voucherType`.

```javascript
// cash_voucher.config.js
const {
  transactionsCollection,
  asRequiredString,
  asNullableString,
  asNumber,
  asEnum,
  asDateString,
  asBoolean,
  cleanStringList,
  requireAccountExists,
  nowIso,
  stampNew,
  stampUpdated,
} = require('../transactions.validators');

const { settingsCollection } = require('../../../utils/firestore');
const { accountsCollection } = require('../../accounts/accounts.validators');

// ─── Constants ────────────────────────────────────────────────────────────────

const VOUCHER_TYPES = [
  'cash_receiving',   // CRV — money coming IN to cash account
  'cash_payment',     // CPV — money going OUT of cash account
  'journal',          // JV  — free double-entry, no cash constraint
];

const VOUCHER_STATUSES = ['draft', 'confirmed', 'cancelled'];

const PARTY_TYPES = [
  'customer',
  'vendor',
  'salesman',
  'account',   // direct ledger account reference (for JV lines)
  'none',
];

// ─── Voucher Line Schema ──────────────────────────────────────────────────────
// Each voucher has 1..N lines. For CRV/CPV, minimum 1 line.
// For JV, minimum 2 lines (debits must equal credits).
//
// Line fields:
//   lineNo:       number — display order, auto-assigned
//   accountId:    required — the account this line posts to
//   entryType:    'debit' | 'credit'
//   amount:       required > 0
//   description:  optional
//   partyType:    'customer' | 'vendor' | 'salesman' | 'account' | 'none'
//   partyId:      optional — FK to the party table named by partyType
//   referenceNo:  optional — invoice number or other reference being settled
//   referenceId:  optional — FK to the invoice/recovery document

function sanitizeLine(raw, index, errors) {
  const prefix = `lines[${index}]`;
  const accountId   = asRequiredString(raw.accountId,  `${prefix}.accountId`,  errors);
  const entryType   = asEnum(raw.entryType, `${prefix}.entryType`, errors, ['debit','credit'], '');
  const amount      = asNumber(raw.amount,  `${prefix}.amount`,    errors, { required: true, min: 0.000001 });
  const description = asNullableString(raw.description);
  const partyType   = asEnum(raw.partyType || 'none', `${prefix}.partyType`, errors, PARTY_TYPES, 'none');
  const partyId     = asNullableString(raw.partyId) || null;
  const referenceNo = asNullableString(raw.referenceNo) || null;
  const referenceId = asNullableString(raw.referenceId) || null;
  return {
    lineNo:       index + 1,
    accountId,
    entryType,
    amount:       amount || 0,
    description,
    partyType,
    partyId,
    referenceNo,
    referenceId,
  };
}

// ─── Auto Voucher Number ──────────────────────────────────────────────────────

async function nextVoucherNo(uid, voucherType) {
  const prefixMap = {
    cash_receiving: 'CRV',
    cash_payment:   'CPV',
    journal:        'JV',
  };
  const prefix = prefixMap[voucherType] || 'V';
  const snap = await transactionsCollection(uid, 'cashVouchers')
    .where('voucherType', '==', voucherType)
    .get();
  let max = 0;
  snap.docs.forEach((d) => {
    const no    = d.data().voucherNo || '';
    const match = no.match(new RegExp(`^${prefix}-(\\d+)$`));
    if (match) {
      const n = parseInt(match[1], 10);
      if (n > max) max = n;
    }
  });
  return `${prefix}-${String(max + 1).padStart(4, '0')}`;
}

// ─── Validate double-entry balance for JV ────────────────────────────────────

function validateDoubleEntry(lines, errors) {
  if (!Array.isArray(lines) || lines.length < 2) {
    errors.push('Journal voucher requires at least 2 lines');
    return;
  }
  const totalDebit  = lines.reduce((s, l) => s + (l.entryType === 'debit'  ? (l.amount || 0) : 0), 0);
  const totalCredit = lines.reduce((s, l) => s + (l.entryType === 'credit' ? (l.amount || 0) : 0), 0);
  const diff = Math.abs(totalDebit - totalCredit);
  if (diff > 0.001) {
    errors.push(`Journal voucher is not balanced: debits=${totalDebit.toFixed(2)}, credits=${totalCredit.toFixed(2)}`);
  }
}

// ─── Main Entity Config ───────────────────────────────────────────────────────

module.exports = {
  entity: 'cashVouchers',

  async nextVoucherNo,

  async sanitize({ uid, body, id }) {
    const errors = [];

    // ── Type ──────────────────────────────────────────────────────────────────
    const voucherType = asEnum(body.voucherType, 'voucherType', errors, VOUCHER_TYPES, '');

    // ── Voucher No (auto-suggest, must be unique) ─────────────────────────────
    const voucherNo = asRequiredString(body.voucherNo, 'voucherNo', errors);
    if (voucherNo) {
      const snap = await transactionsCollection(uid, 'cashVouchers')
        .where('voucherNo', '==', voucherNo)
        .limit(1)
        .get();
      if (!snap.empty && snap.docs[0].id !== id) {
        errors.push('voucherNo must be unique');
      }
    }

    // ── Date ──────────────────────────────────────────────────────────────────
    const voucherDate = asDateString(body.voucherDate, 'voucherDate', errors, { required: true });

    // ── Cash Account (required for CRV and CPV, optional for JV) ─────────────
    // This is the "main" cash account — the bank/cash side of the entry.
    // For JV it must still be provided if the voucher involves a cash account.
    const cashAccountId = asNullableString(body.cashAccountId) || null;
    if (voucherType !== 'journal' && !cashAccountId) {
      errors.push('cashAccountId is required for cash vouchers');
    }
    if (cashAccountId) {
      await requireAccountExists(uid, cashAccountId, 'cashAccountId', errors);
    }

    // ── Amount (for CRV/CPV — single amount, auto-creates two lines) ──────────
    // For JV the amount is derived from lines.
    const amount = asNumber(body.amount, 'amount', errors, {
      required: voucherType !== 'journal',
      min: 0.000001,
      defaultValue: 0,
    });

    // ── Counter Account (for CRV/CPV — the "other side" account) ─────────────
    // e.g. for CRV: debit Cash, credit Accounts Receivable (or Income account)
    // e.g. for CPV: debit Expense/AP account, credit Cash
    const counterAccountId = asNullableString(body.counterAccountId) || null;
    // Counter account is NOT required at create time (can be set later via lines)
    if (counterAccountId) {
      await requireAccountExists(uid, counterAccountId, 'counterAccountId', errors);
    }

    // ── Party ─────────────────────────────────────────────────────────────────
    const partyType = asEnum(body.partyType || 'none', 'partyType', errors, PARTY_TYPES, 'none');
    const partyId   = asNullableString(body.partyId) || null;

    // ── Lines (for JV — required; for CRV/CPV — optional, auto-built if absent) ─
    let lines = [];
    if (Array.isArray(body.lines) && body.lines.length > 0) {
      lines = body.lines.map((raw, i) => sanitizeLine(raw, i, errors));
      if (voucherType === 'journal') {
        validateDoubleEntry(lines, errors);
      }
    } else if (voucherType === 'journal') {
      errors.push('Journal voucher must include lines array');
    }
    // For CRV/CPV: lines will be auto-built by the route handler after creation
    // (so the ledger entries can be created atomically with the voucher)

    // ── Narration / Description ───────────────────────────────────────────────
    const narration     = asNullableString(body.narration) || null;
    const referenceNo   = asNullableString(body.referenceNo) || null;
    const referenceId   = asNullableString(body.referenceId) || null;
    const referenceType = asNullableString(body.referenceType) || 'manual';

    // ── Status ────────────────────────────────────────────────────────────────
    const status = asEnum(body.status || 'confirmed', 'status', errors, VOUCHER_STATUSES, 'confirmed');

    // ── Cheque info (for CPV where payment is by cheque) ─────────────────────
    const isChequePayment = asBoolean(body.isChequePayment, false);
    const chequeNo        = asNullableString(body.chequeNo)   || null;
    const chequeDate      = asNullableString(body.chequeDate) || null;
    const bankName        = asNullableString(body.bankName)   || null;

    if (isChequePayment && !chequeNo) {
      errors.push('chequeNo is required when isChequePayment is true');
    }

    // ── Tags ──────────────────────────────────────────────────────────────────
    const tags = cleanStringList(body.tags);

    const data = {
      voucherType,
      voucherNo,
      voucherDate,
      cashAccountId,
      counterAccountId,
      amount,
      partyType,
      partyId,
      lines,
      narration,
      referenceNo,
      referenceId,
      referenceType,
      status,
      isChequePayment,
      chequeNo,
      chequeDate,
      bankName,
      tags,
      // Computed summary fields — updated on create/update
      totalDebits:  0,
      totalCredits: 0,
      isPosted:     status === 'confirmed',
    };

    return { data, errors };
  },
};
```

### 2.6 Create `backend/src/modules/transactions/transactions.routes.js`

Model this EXACTLY after `accounts.routes.js`. Key differences:
- Uses `transactionsCollection` instead of `accountsCollection`
- After creating/updating a CRV or CPV, automatically creates the corresponding
  `ledgerEntries` in the accounts sub-system (the double-entry posting logic)
- Exposes special endpoints: `/cashVouchers/next-voucher-no/:type`

```javascript
// transactions.routes.js
const express = require('express');
const {
  transactionsCollection,
  stampNew,
  stampUpdated,
  asEnum,
  nowIso,
} = require('./transactions.validators');
const { accountsCollection } = require('../accounts/accounts.validators');
const { settingsCollection } = require('../../utils/firestore');
const { log } = require('../../core/logger');

const cashVoucherConfig = require('./entities/cash_voucher.config');

const router = express.Router();

function ok(res, data, code)  { return res.status(code || 200).json({ success: true, data }); }
function fail(res, msg, code) { return res.status(code || 400).json({ success: false, error: msg }); }

// ─── LEDGER POSTING HELPER ───────────────────────────────────────────────────
// Called after create or update of CRV/CPV to write double-entry ledger lines.
// For CRV (cash_receiving):  DEBIT cashAccount, CREDIT counterAccount
// For CPV (cash_payment):    DEBIT counterAccount, CREDIT cashAccount
// For JV: one ledger entry per line in voucher.lines[]
// NOTE: This is a simple synchronous write — in production you'd want a Firestore
// transaction (batch write) to make it atomic.

async function postLedgerEntries(uid, voucherId, voucher) {
  const ledgerColl = accountsCollection(uid, 'ledgerEntries');
  const voucherTypeMap = {
    cash_receiving: 'cash_receiving_voucher',
    cash_payment:   'cash_payment_voucher',
    journal:        'journal_voucher',
  };
  const refType = voucherTypeMap[voucher.voucherType] || 'other';

  // Delete any existing ledger entries for this voucher (re-post on update)
  const existing = await ledgerColl
    .where('referenceId', '==', voucherId)
    .get();
  const deletePromises = existing.docs.map((d) => d.ref.delete());
  await Promise.all(deletePromises);

  if (voucher.status !== 'confirmed') return; // Only post confirmed vouchers

  const ts = nowIso();
  const baseEntry = {
    uid,
    entryDate:     voucher.voucherDate,
    referenceType: refType,
    referenceId:   voucherId,
    referenceNo:   voucher.voucherNo,
    isReconciled:  false,
    reconciledAt:  null,
    tags:          voucher.tags || [],
    notes:         voucher.narration || null,
    createdAt:     ts,
    updatedAt:     ts,
  };

  const entryDocs = [];

  if (voucher.voucherType === 'journal') {
    // JV: one ledger entry per line
    (voucher.lines || []).forEach((line, i) => {
      entryDocs.push({
        ...baseEntry,
        entryNo:     `${voucher.voucherNo}-L${String(i + 1).padStart(2, '0')}`,
        accountId:   line.accountId,
        entryType:   line.entryType,
        amount:      line.amount,
        description: line.description || voucher.narration || '',
      });
    });
  } else {
    // CRV / CPV: two-line double entry
    const { cashAccountId, counterAccountId, amount, voucherType, narration, voucherNo } = voucher;
    if (!cashAccountId || !counterAccountId || !amount) return;

    const isCRV = voucherType === 'cash_receiving';
    // CRV: debit cash (money in), credit counter (AR or income)
    // CPV: debit counter (AP or expense), credit cash (money out)
    entryDocs.push({
      ...baseEntry,
      entryNo:     `${voucherNo}-DR`,
      accountId:   isCRV ? cashAccountId : counterAccountId,
      entryType:   'debit',
      amount,
      description: narration || (isCRV ? 'Cash received' : 'Cash paid'),
    });
    entryDocs.push({
      ...baseEntry,
      entryNo:     `${voucherNo}-CR`,
      accountId:   isCRV ? counterAccountId : cashAccountId,
      entryType:   'credit',
      amount,
      description: narration || (isCRV ? 'Cash received' : 'Cash paid'),
    });
  }

  const writePromises = entryDocs.map((entry) => ledgerColl.doc().set(entry));
  await Promise.all(writePromises);
  log('INFO', `postLedgerEntries: wrote ${entryDocs.length} entries for ${voucherId}`, { uid });
}

// ─── SPECIAL ENDPOINTS (before CRUD router) ────────────────────────────────

// GET /cashVouchers/next-voucher-no/:type
router.get('/cashVouchers/next-voucher-no/:type', async (req, res) => {
  const uid  = req.user.uid;
  const type = req.params.type;
  const allowedTypes = ['cash_receiving', 'cash_payment', 'journal'];
  if (!allowedTypes.includes(type)) {
    return fail(res, `Invalid voucher type. Must be one of: ${allowedTypes.join(', ')}`, 400);
  }
  log('INFO', `GET /transactions/cashVouchers/next-voucher-no/${type}`, { uid });
  try {
    const no = await cashVoucherConfig.nextVoucherNo(uid, type);
    return ok(res, { nextVoucherNo: no });
  } catch (e) {
    log('ERROR', `next-voucher-no failed`, { uid, error: e.message });
    return fail(res, e.message || 'Failed', 500);
  }
});

// ─── CRUD SUB-ROUTER ──────────────────────────────────────────────────────────

function createCrudRouter(config) {
  const e = config.entity;
  const r = express.Router();

  // List — fetch all with optional filters
  r.get('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /transactions/${e}`, { uid, query: req.query });
    try {
      const snap  = await transactionsCollection(uid, e).orderBy('createdAt', 'desc').get();
      let items   = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

      // In-memory filters (avoids compound Firestore indexes)
      if (req.query.voucherType) {
        items = items.filter((i) => i.voucherType === req.query.voucherType);
      }
      if (req.query.status) {
        items = items.filter((i) => i.status === req.query.status);
      }
      if (req.query.cashAccountId) {
        items = items.filter((i) => i.cashAccountId === req.query.cashAccountId);
      }
      if (req.query.partyId) {
        items = items.filter((i) => i.partyId === req.query.partyId);
      }
      if (req.query.startDate) {
        const start = new Date(req.query.startDate).toISOString();
        items = items.filter((i) => i.voucherDate >= start);
      }
      if (req.query.endDate) {
        const end = new Date(req.query.endDate);
        end.setHours(23, 59, 59, 999);
        items = items.filter((i) => i.voucherDate <= end.toISOString());
      }

      log('INFO', `GET /transactions/${e} → ${items.length} records`, { uid });
      return ok(res, items);
    } catch (err2) {
      log('ERROR', `GET /transactions/${e} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to fetch', err2.statusCode || 500);
    }
  });

  // Get single
  r.get('/:id', async (req, res) => {
    const uid = req.user.uid;
    try {
      const snap = await transactionsCollection(uid, e).doc(req.params.id).get();
      if (!snap.exists) return fail(res, 'Not found', 404);
      return ok(res, { id: snap.id, ...snap.data() });
    } catch (err2) {
      return fail(res, err2.message || 'Failed to fetch', 500);
    }
  });

  // Create + post ledger entries
  r.post('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `POST /transactions/${e}`, { uid });
    try {
      const { data, errors } = await config.sanitize({ uid, body: req.body || {} });
      if (errors.length) return fail(res, errors.join('; '), 400);

      const docRef  = transactionsCollection(uid, e).doc();
      const payload = stampNew(uid, data);
      await docRef.set(payload);

      // Post double-entry ledger entries
      if (e === 'cashVouchers') {
        await postLedgerEntries(uid, docRef.id, payload);
      }

      log('INFO', `POST /transactions/${e} → created ${docRef.id}`, { uid });
      return ok(res, { id: docRef.id, ...payload }, 201);
    } catch (err2) {
      log('ERROR', `POST /transactions/${e} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to create', 500);
    }
  });

  // Update + re-post ledger entries
  r.put('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `PUT /transactions/${e}/${req.params.id}`, { uid });
    try {
      const docRef = transactionsCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) return fail(res, 'Not found', 404);

      const { data, errors } = await config.sanitize({ uid, body: req.body || {}, id: req.params.id });
      if (errors.length) return fail(res, errors.join('; '), 400);

      const payload = stampUpdated(snap.data(), data);
      await docRef.set(payload, { merge: false });

      // Re-post double-entry ledger entries
      if (e === 'cashVouchers') {
        await postLedgerEntries(uid, req.params.id, payload);
      }

      log('INFO', `PUT /transactions/${e}/${req.params.id} → updated`, { uid });
      return ok(res, { id: docRef.id, ...payload });
    } catch (err2) {
      log('ERROR', `PUT /transactions/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to update', 500);
    }
  });

  // Delete + remove ledger entries
  r.delete('/:id', async (req, res) => {
    const uid = req.user.uid;
    try {
      const docRef = transactionsCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) return fail(res, 'Not found', 404);

      // Remove associated ledger entries first
      if (e === 'cashVouchers') {
        const ledgerColl = accountsCollection(uid, 'ledgerEntries');
        const existing   = await ledgerColl.where('referenceId', '==', req.params.id).get();
        await Promise.all(existing.docs.map((d) => d.ref.delete()));
      }

      await docRef.delete();
      log('INFO', `DELETE /transactions/${e}/${req.params.id} → deleted`, { uid });
      return ok(res, { id: req.params.id });
    } catch (err2) {
      return fail(res, err2.message || 'Failed to delete', 500);
    }
  });

  return r;
}

// Mount CRUD router AFTER specific routes
router.use('/cashVouchers', createCrudRouter(cashVoucherConfig));

module.exports = router;
```

### 2.7 Create Firestore Scaffold Collections (empty with schema docs)

Create `backend/src/modules/transactions/entities/scaffold_schemas.js`.
This file is documentation + used in seeding. It defines the locked schemas for
future collections so all future developers (and Claude) know what fields are expected.

```javascript
// scaffold_schemas.js
// LOCKED DATA MODELS — do not change field names without a migration plan.
// These schemas are created as empty collections in Firestore during setup.
// Future modules MUST use these exact field names.

module.exports = {

  // ── invoices ─────────────────────────────────────────────────────────────
  // Written by: Invoicing module (SalesInvoice, PurchaseInvoice, etc.)
  // Read by: Transactions (recovery), AccountsReports (AR, AP, P&L)
  invoices: {
    _scaffoldOnly: true,
    schema: {
      invoiceType:    'sales | purchase | sales_return | purchase_return | stock_expiry | chicken',
      invoiceNo:      'string — unique, e.g. SI-0001',
      invoiceDate:    'ISO8601 string',
      partyType:      'customer | vendor',
      partyId:        'FK → customers | vendors',
      items:          'Array<InvoiceItem>',
      subtotal:       'number',
      discountAmount: 'number',
      taxAmount:      'number',
      totalAmount:    'number',
      paidAmount:     'number — sum of recovery vouchers',
      balanceAmount:  'number — totalAmount - paidAmount',
      status:         'draft | confirmed | partial | paid | cancelled',
      salesmanId:     'FK → salesmen | null',
      narration:      'string | null',
      referenceNo:    'string | null',
      uid:            'string',
      createdAt:      'ISO8601',
      updatedAt:      'ISO8601',
      // InvoiceItem shape:
      // { lineNo, productId, productName, quantity, unit, rate, discount, taxPercent, amount }
    },
  },

  // ── stockMovements ────────────────────────────────────────────────────────
  // Written by: Invoicing (purchase increases stock, sale decreases stock)
  // Read by: TradeReports (stock report, daily delivery)
  stockMovements: {
    _scaffoldOnly: true,
    schema: {
      movementType:  'purchase_in | sale_out | return_in | return_out | expiry | wastage | adjustment',
      invoiceId:     'FK → invoices | null',
      invoiceNo:     'string | null',
      movementDate:  'ISO8601 string',
      productId:     'FK → products',
      quantity:      'number',
      rate:          'number',
      amount:        'number',
      uid:           'string',
      createdAt:     'ISO8601',
      updatedAt:     'ISO8601',
    },
  },

  // ── cheques ────────────────────────────────────────────────────────────────
  // Written by: Transactions (BankChequeIssuing, ChequeDepositInBank)
  // Read by: AccountsReports (Uncleared, Lost, Bounced, In Danger cheques)
  cheques: {
    _scaffoldOnly: true,
    schema: {
      chequeType:    'issued | received',   // issued = we gave, received = customer gave us
      chequeNo:      'string',
      chequeDate:    'ISO8601 — the date on the cheque (may be post-dated)',
      bankName:      'string',
      amount:        'number',
      partyType:     'customer | vendor | other',
      partyId:       'FK | null',
      accountId:     'FK → accounts (bank account)',
      voucherId:     'FK → cashVouchers | null',
      status:        'pending | cleared | bounced | cancelled | lost',
      clearedDate:   'ISO8601 | null',
      bouncedDate:   'ISO8601 | null',
      notes:         'string | null',
      uid:           'string',
      createdAt:     'ISO8601',
      updatedAt:     'ISO8601',
    },
  },

  // ── recoveries ────────────────────────────────────────────────────────────
  // Written by: Transactions (RecoveryInvoice, RecoveryReceivableWise)
  // Read by: AccountsReports (AR aging, recovery reports)
  recoveries: {
    _scaffoldOnly: true,
    schema: {
      recoveryType:   'invoice_wise | receivable_wise | salesman_reconciliation',
      recoveryNo:     'string — unique, e.g. REC-0001',
      recoveryDate:   'ISO8601',
      customerId:     'FK → customers',
      salesmanId:     'FK → salesmen | null',
      items:          'Array<RecoveryItem>',
      // RecoveryItem: { invoiceId, invoiceNo, invoiceAmount, recoveredAmount }
      totalAmount:    'number',
      paymentMode:    'cash | cheque | bank_transfer',
      chequeId:       'FK → cheques | null',
      voucherId:      'FK → cashVouchers | null',
      status:         'draft | confirmed | cancelled',
      narration:      'string | null',
      uid:            'string',
      createdAt:      'ISO8601',
      updatedAt:      'ISO8601',
    },
  },

  // ── paymentPromises ────────────────────────────────────────────────────────
  // Written by: Transactions (PostDatedRecoveryPromise, PostDatedPaymentPromise)
  // Read by: Quick Links "Payment Promises" dashboard widget
  paymentPromises: {
    _scaffoldOnly: true,
    schema: {
      promiseType:    'recovery_promise | payment_promise',
      promiseNo:      'string — unique',
      promiseDate:    'ISO8601 — date of the promise (when it was made)',
      dueDate:        'ISO8601 — when the payment is due',
      partyType:      'customer | vendor',
      partyId:        'FK',
      amount:         'number',
      chequeNo:       'string | null',
      bankName:       'string | null',
      status:         'pending | fulfilled | cancelled | overdue',
      notes:          'string | null',
      fulfilledDate:  'ISO8601 | null',
      uid:            'string',
      createdAt:      'ISO8601',
      updatedAt:      'ISO8601',
    },
  },
};
```

### 2.8 Register Transactions Routes in `backend/src/index.js`

Add after the existing accounts route registration:

```javascript
const transactionsRoutes = require('./modules/transactions/transactions.routes');
app.use('/api/v1/transactions', authenticate, transactionsRoutes);
```

### 2.9 Update `firestore.indexes.json`

Add these indexes (append to the `indexes` array):

```json
{
  "collectionGroup": "cashVouchers",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "uid", "order": "ASCENDING" },
    { "fieldPath": "voucherType", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "cashVouchers",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "uid", "order": "ASCENDING" },
    { "fieldPath": "voucherDate", "order": "ASCENDING" },
    { "fieldPath": "cashAccountId", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "ledgerEntries",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "uid", "order": "ASCENDING" },
    { "fieldPath": "referenceId", "order": "ASCENDING" }
  ]
}
```

---

## 3. FRONTEND TASKS

### 3.1 New Files to Create

```
frontend/lib/modules/transactions/
  config/
    transactions_definitions.dart    ← nav items + enum constants
  controllers/
    transactions_nav_controller.dart  ← mirrors accounts_reports_nav_controller.dart
    cash_voucher_controller.dart      ← CRV + CPV + JV CRUD
  models/
    cash_voucher_model.dart           ← mirrors ledger_entry_model.dart
    voucher_line_model.dart           ← line item model
  services/
    cash_voucher_service.dart         ← mirrors ledger_service.dart
  views/
    transactions_screen.dart          ← top-level screen, mirrors accounts_reports_screen.dart
    crv_list_screen.dart              ← Cash Receiving Voucher list
    cpv_list_screen.dart              ← Cash Payment Voucher list
    jv_list_screen.dart               ← Journal Voucher list
    voucher_form_dialog.dart          ← Unified create/edit dialog for all voucher types
    voucher_detail_screen.dart        ← Full detail view of a posted voucher
  transactions_scope.dart             ← MultiProvider scope

frontend/lib/modules/accounts_reports/
  controllers/
    cash_book_controller.dart         ← NEW: fetches/filters cash book data
  models/
    cash_book_entry_model.dart        ← NEW: extended entry with voucher info
  services/
    cash_book_service.dart            ← NEW: calls ledger by-account endpoint
  views/
    cash_book_screen.dart             ← NEW: the main Cash Book UI
    cash_book_filter_bar.dart         ← NEW: date range + account selector
```

### 3.2 `transactions_definitions.dart`

```dart
// frontend/lib/modules/transactions/config/transactions_definitions.dart
import 'package:flutter/material.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';

// ── Nav Items ─────────────────────────────────────────────────────────────────

class TransactionsNavItem {
  const TransactionsNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.voucherType,
    this.enabled = true,
    this.comingSoonNote,
  });
  final String   id;
  final String   label;
  final IconData icon;
  final String?  voucherType; // null for non-voucher sections
  final bool     enabled;
  final String?  comingSoonNote;
}

const List<TransactionsNavItem> kTransactionsNavItems = [
  // ── Cash Vouchers (TODAY) ──────────────────────────────────────────────────
  TransactionsNavItem(
    id:          'cash_receiving',
    label:       'Cash Receiving',
    icon:        Icons.arrow_downward_rounded,
    voucherType: 'cash_receiving',
  ),
  TransactionsNavItem(
    id:          'cash_payment',
    label:       'Cash Payment',
    icon:        Icons.arrow_upward_rounded,
    voucherType: 'cash_payment',
  ),
  TransactionsNavItem(
    id:          'journal',
    label:       'Journal Voucher',
    icon:        Icons.swap_horiz_outlined,
    voucherType: 'journal',
  ),
  // ── Future (require Invoicing module) ─────────────────────────────────────
  TransactionsNavItem(
    id:             'recovery_invoice',
    label:          'Recovery (Invoice-wise)',
    icon:           Icons.receipt_long_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing module',
  ),
  TransactionsNavItem(
    id:             'recovery_receivable',
    label:          'Recovery (Receivable-wise)',
    icon:           Icons.account_balance_wallet_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing module',
  ),
  TransactionsNavItem(
    id:             'salesman_reconciliation',
    label:          'Salesman Cash Reconciliation',
    icon:           Icons.people_outline,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing module',
  ),
  TransactionsNavItem(
    id:             'bank_cheque_issuing',
    label:          'Bank Cheque Issuing',
    icon:           Icons.book_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Bank Account setup',
  ),
  TransactionsNavItem(
    id:             'bank_reconciliation',
    label:          'Bank Cheques Reconciliation',
    icon:           Icons.check_circle_outline,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Bank Account setup',
  ),
  TransactionsNavItem(
    id:             'cash_deposit',
    label:          'Cash Deposit in Bank',
    icon:           Icons.savings_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Bank Account setup',
  ),
  TransactionsNavItem(
    id:             'cheque_deposit',
    label:          'Cheque Deposit in Bank',
    icon:           Icons.post_add_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Bank Account setup',
  ),
  TransactionsNavItem(
    id:             'post_dated_recovery',
    label:          'Post-Dated Recovery Promise',
    icon:           Icons.event_note_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing module',
  ),
  TransactionsNavItem(
    id:             'post_dated_payment',
    label:          'Post-Dated Payment Promise',
    icon:           Icons.event_available_outlined,
    voucherType:    null,
    enabled:        false,
    comingSoonNote: 'Requires Invoicing module',
  ),
];

// ── Enum Constants ────────────────────────────────────────────────────────────

const List<LookupOption> kVoucherTypes = [
  LookupOption(value: 'cash_receiving', label: 'Cash Receiving Voucher (CRV)'),
  LookupOption(value: 'cash_payment',   label: 'Cash Payment Voucher (CPV)'),
  LookupOption(value: 'journal',        label: 'Journal Voucher (JV)'),
];

const List<LookupOption> kVoucherStatuses = [
  LookupOption(value: 'draft',     label: 'Draft'),
  LookupOption(value: 'confirmed', label: 'Confirmed'),
  LookupOption(value: 'cancelled', label: 'Cancelled'),
];

const List<LookupOption> kPartyTypes = [
  LookupOption(value: 'none',     label: 'None'),
  LookupOption(value: 'customer', label: 'Customer'),
  LookupOption(value: 'vendor',   label: 'Vendor'),
  LookupOption(value: 'salesman', label: 'Salesman'),
  LookupOption(value: 'account',  label: 'Account'),
];

const List<LookupOption> kJvEntryTypes = [
  LookupOption(value: 'debit',  label: 'Debit (Dr)'),
  LookupOption(value: 'credit', label: 'Credit (Cr)'),
];

// ── Label helpers ─────────────────────────────────────────────────────────────

String voucherTypeLabel(String type) {
  switch (type) {
    case 'cash_receiving': return 'CRV';
    case 'cash_payment':   return 'CPV';
    case 'journal':        return 'JV';
    default:               return type.toUpperCase();
  }
}

String voucherStatusLabel(String status) {
  switch (status) {
    case 'draft':     return 'Draft';
    case 'confirmed': return 'Confirmed';
    case 'cancelled': return 'Cancelled';
    default:          return status;
  }
}
```

### 3.3 `cash_voucher_model.dart`

```dart
// frontend/lib/modules/transactions/models/cash_voucher_model.dart

import 'voucher_line_model.dart';

class CashVoucherModel {
  const CashVoucherModel({
    required this.id,
    required this.voucherType,
    required this.voucherNo,
    required this.voucherDate,
    this.cashAccountId,
    this.counterAccountId,
    required this.amount,
    required this.partyType,
    this.partyId,
    required this.lines,
    this.narration,
    this.referenceNo,
    this.referenceId,
    required this.referenceType,
    required this.status,
    required this.isChequePayment,
    this.chequeNo,
    this.chequeDate,
    this.bankName,
    required this.tags,
    required this.totalDebits,
    required this.totalCredits,
    required this.isPosted,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String voucherType;   // 'cash_receiving' | 'cash_payment' | 'journal'
  final String voucherNo;
  final String voucherDate;
  final String? cashAccountId;
  final String? counterAccountId;
  final double amount;
  final String partyType;
  final String? partyId;
  final List<VoucherLine> lines;
  final String? narration;
  final String? referenceNo;
  final String? referenceId;
  final String referenceType;
  final String status;        // 'draft' | 'confirmed' | 'cancelled'
  final bool isChequePayment;
  final String? chequeNo;
  final String? chequeDate;
  final String? bankName;
  final List<String> tags;
  final double totalDebits;
  final double totalCredits;
  final bool isPosted;
  final String uid;
  final String createdAt;
  final String updatedAt;

  bool get isCRV => voucherType == 'cash_receiving';
  bool get isCPV => voucherType == 'cash_payment';
  bool get isJV  => voucherType == 'journal';
  bool get isConfirmed => status == 'confirmed';
  bool get isDraft     => status == 'draft';

  factory CashVoucherModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final lines = rawLines is List
        ? rawLines.map((l) => VoucherLine.fromJson(Map<String, dynamic>.from(l as Map))).toList()
        : <VoucherLine>[];
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((t) => '$t').toList() : <String>[];
    return CashVoucherModel(
      id:               '${json['id'] ?? ''}',
      voucherType:      '${json['voucherType'] ?? ''}',
      voucherNo:        '${json['voucherNo'] ?? ''}',
      voucherDate:      '${json['voucherDate'] ?? ''}',
      cashAccountId:    json['cashAccountId'] as String?,
      counterAccountId: json['counterAccountId'] as String?,
      amount:           _toDouble(json['amount']),
      partyType:        '${json['partyType'] ?? 'none'}',
      partyId:          json['partyId'] as String?,
      lines:            lines,
      narration:        json['narration'] as String?,
      referenceNo:      json['referenceNo'] as String?,
      referenceId:      json['referenceId'] as String?,
      referenceType:    '${json['referenceType'] ?? 'manual'}',
      status:           '${json['status'] ?? 'confirmed'}',
      isChequePayment:  json['isChequePayment'] == true,
      chequeNo:         json['chequeNo'] as String?,
      chequeDate:       json['chequeDate'] as String?,
      bankName:         json['bankName'] as String?,
      tags:             tags,
      totalDebits:      _toDouble(json['totalDebits']),
      totalCredits:     _toDouble(json['totalCredits']),
      isPosted:         json['isPosted'] == true,
      uid:              '${json['uid'] ?? ''}',
      createdAt:        '${json['createdAt'] ?? ''}',
      updatedAt:        '${json['updatedAt'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
    'voucherType':      voucherType,
    'voucherNo':        voucherNo,
    'voucherDate':      voucherDate,
    'cashAccountId':    cashAccountId,
    'counterAccountId': counterAccountId,
    'amount':           amount,
    'partyType':        partyType,
    'partyId':          partyId,
    'lines':            lines.map((l) => l.toJson()).toList(),
    'narration':        narration,
    'referenceNo':      referenceNo,
    'referenceId':      referenceId,
    'referenceType':    referenceType,
    'status':           status,
    'isChequePayment':  isChequePayment,
    'chequeNo':         chequeNo,
    'chequeDate':       chequeDate,
    'bankName':         bankName,
    'tags':             tags,
  };

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
```

### 3.4 `voucher_line_model.dart`

```dart
// frontend/lib/modules/transactions/models/voucher_line_model.dart

class VoucherLine {
  const VoucherLine({
    required this.lineNo,
    required this.accountId,
    required this.entryType,
    required this.amount,
    this.description,
    required this.partyType,
    this.partyId,
    this.referenceNo,
    this.referenceId,
  });

  final int    lineNo;
  final String accountId;
  final String entryType;  // 'debit' | 'credit'
  final double amount;
  final String? description;
  final String partyType;
  final String? partyId;
  final String? referenceNo;
  final String? referenceId;

  bool get isDebit  => entryType == 'debit';
  bool get isCredit => entryType == 'credit';

  factory VoucherLine.fromJson(Map<String, dynamic> json) => VoucherLine(
    lineNo:       (json['lineNo'] as num?)?.toInt() ?? 0,
    accountId:    '${json['accountId'] ?? ''}',
    entryType:    '${json['entryType'] ?? 'debit'}',
    amount:       _toDouble(json['amount']),
    description:  json['description'] as String?,
    partyType:    '${json['partyType'] ?? 'none'}',
    partyId:      json['partyId'] as String?,
    referenceNo:  json['referenceNo'] as String?,
    referenceId:  json['referenceId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'lineNo':      lineNo,
    'accountId':   accountId,
    'entryType':   entryType,
    'amount':      amount,
    'description': description,
    'partyType':   partyType,
    'partyId':     partyId,
    'referenceNo': referenceNo,
    'referenceId': referenceId,
  };

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
```

### 3.5 `cash_voucher_service.dart`

Mirror `ledger_service.dart` exactly in structure. Base path: `/transactions/cashVouchers`.

Key methods:
- `fetchAll({Map<String, String>? filters})` — returns `List<CashVoucherModel>`
- `fetchById(String id)` — returns `CashVoucherModel`
- `create(Map<String, dynamic> body)` — returns `CashVoucherModel`
- `update(String id, Map<String, dynamic> body)` — returns `CashVoucherModel`
- `delete(String id)` — void
- `nextVoucherNo(String voucherType)` — returns String (e.g. 'CRV-0001')

All use `await _api.get/post/put/delete(path, auth: true)`.
Use `_unwrapList` and `_unwrapItem` helpers identical to `LedgerService`.

### 3.6 `cash_voucher_controller.dart`

Mirror `ledger_controller.dart`. State:
```dart
List<CashVoucherModel> _items = [];
bool _isLoading = false;
String? _error;
String _searchQuery = '';
String? _filterVoucherType;   // null = all
String? _filterStatus;         // null = all
String? _filterPartyId;
DateTime? _filterStartDate;
DateTime? _filterEndDate;
```

Computed getter `filteredItems` applies all filters in-memory.

Methods:
- `loadAll({String? voucherType})` — calls fetchAll with optional type filter
- `createVoucher(Map<String, dynamic> body)` — create + prepend to list
- `updateVoucher(String id, Map<String, dynamic> body)` — update in list
- `deleteVoucher(String id)` — remove from list
- `nextVoucherNo(String type)` — delegates to service
- `setFilterVoucherType(String? v)`, `setFilterStatus(String? v)`, `setDateRange(DateTime?, DateTime?)`, `clearFilters()`

### 3.7 `transactions_scope.dart`

```dart
// Mirrors poultry_scope.dart exactly.
// Providers: TransactionsNavController, CashVoucherController
// Bootstrap: loadAll() on CashVoucherController with no type filter (loads all)
```

### 3.8 `transactions_nav_controller.dart`

```dart
// Mirrors accounts_reports_nav_controller.dart.
// selectedSection: String — default 'cash_receiving'
// Methods: selectSection(String id), backToList()
```

### 3.9 `transactions_screen.dart`

Mirror `accounts_reports_screen.dart` EXACTLY:
- Same chip bar pattern using `kTransactionsNavItems`
- Disabled items show lock icon + tooltip with `comingSoonNote`
- Content area switches on `nav.selectedSection`
- Mobile layout: list menu → drill in

Content routing:
```dart
Widget _buildContent(String section) {
  switch (section) {
    case 'cash_receiving': return CrvListScreen();
    case 'cash_payment':   return CpvListScreen();
    case 'journal':        return JvListScreen();
    default:               return CrvListScreen();
  }
}
```

### 3.10 `crv_list_screen.dart`, `cpv_list_screen.dart`, `jv_list_screen.dart`

All three use the SAME underlying widget — `VoucherListScreen(voucherType: 'cash_receiving')`.
Each list screen simply passes its `voucherType` to the shared widget.

The shared `VoucherListScreen` widget:
- Toolbar: title (e.g. "Cash Receiving Vouchers"), search field, "New CRV" button
- Filter chips: All | Draft | Confirmed | Cancelled
- Filter row (secondary): Date range pickers (start date, end date)
- Content: Desktop DataTable + Mobile ListView (pattern from `ledger_list_screen.dart`)

**Desktop table columns for CRV/CPV:**
```
Voucher No | Date | Party | Cash Account | Counter Account | Amount | Status | Actions
```

**Desktop table columns for JV:**
```
Voucher No | Date | Narration | Total Dr | Total Cr | Balanced? | Status | Actions
```

**Row actions:** Edit (pencil), Delete (trash), View Detail (eye icon)

**Status badges:**
- Draft: amber background, `#8A5A1A` text (use `AppTheme.warningBg` + `AppTheme.warningText`)
- Confirmed: green background, green text (use `AppTheme.successBg` + `AppTheme.successText`)
- Cancelled: red background, red text (use `AppTheme.dangerBg` + `AppTheme.dangerText`)

### 3.11 `voucher_form_dialog.dart` — THE MOST IMPORTANT SCREEN

This is a full-screen dialog (on desktop: max-width 680px, on mobile: full screen).
It handles all three voucher types via the `voucherType` parameter.

**Structure:**
```
┌─────────────────────────────────────────────────────────────────┐
│  [Icon] New Cash Receiving Voucher (CRV)          [×] Close     │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Voucher No*  [CRV-0001]  Date*  [12/05/2026]            │   │
│  │ Status       [Confirmed▾]                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ─────────────────────────────────────────────────────────────  │
│  CRV/CPV SECTION (hidden for JV):                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Cash Account*  [Select cash account ▾]                   │   │
│  │ Amount*        [PKR ___________]                         │   │
│  │ Counter Acct*  [Select account ▾] (the "other side")     │   │
│  │ Party Type     [None▾]  Party  [Select▾]                 │   │
│  │ Reference No   [Invoice# or other ref]                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ─────────────────────────────────────────────────────────────  │
│  JV LINES SECTION (shown only for JV):                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  #  Account          Dr/Cr   Amount       [+ Add Line]   │   │
│  │  1  [Select acct▾]  [Dr▾]   [_______]  [×]              │   │
│  │  2  [Select acct▾]  [Cr▾]   [_______]  [×]              │   │
│  │  ─────────────────────────────────────────────────────── │   │
│  │  Total Debits: 0.00    Total Credits: 0.00               │   │
│  │  ✓ Balanced  /  ✗ Not balanced (diff: X.XX)              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ─────────────────────────────────────────────────────────────  │
│  CHEQUE SECTION (shown only for CPV when isChequePayment=true): │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ [✓] Payment by Cheque                                    │   │
│  │ Cheque No  [_______]  Date  [_______]  Bank [_______]    │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ─────────────────────────────────────────────────────────────  │
│  Narration  [Free text, 500 chars max                    ]      │
│  ─────────────────────────────────────────────────────────────  │
│                    [Cancel]          [Save & Confirm]           │
└─────────────────────────────────────────────────────────────────┘
```

**Form field details:**

1. `Voucher No` — TextFormField, pre-populated via `controller.nextVoucherNo(type)` on open, editable, validated unique on submit
2. `Date` — TextFormField + date picker, defaults to today
3. `Status` — DropdownButtonFormField with `kVoucherStatuses`; "Save as Draft" sets to draft; main button sets to confirmed
4. `Cash Account` — DropdownButtonFormField; items are accounts where `isCashAccount == true`; shows `accountCode — accountName`; if no cash accounts exist, shows warning: "No cash accounts found. Go to Settings → Accounts and mark an account as Cash Account."
5. `Amount` — TextFormField with `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]`; prefix shows "PKR"
6. `Counter Account` — DropdownButtonFormField; ALL active accounts EXCEPT the selected cash account
7. `Party Type / Party` — cascading dropdowns; party dropdown items load from `customers` / `vendors` / `salesmen` based on party type selection; `account` type shows accounts dropdown
8. `Reference No` — free text, optional
9. **JV Lines** — a `ListView` of line rows inside a `Column`. Each row:
   - Account dropdown (all active accounts)
   - Dr/Cr dropdown (`kJvEntryTypes`)
   - Amount field
   - Remove button
   - Below rows: running balance indicator: "Dr: X.XX  |  Cr: X.XX  |  [✓ Balanced / ✗ Diff: X.XX]"
   - "Add Line" button appends a new empty row
   - Minimum 2 lines for JV
10. `Cheque section` — Checkbox toggle, then conditional cheque fields
11. `Narration` — multiline TextFormField

**Button behavior:**
- `Save as Draft` — sets status to 'draft', saves
- `Save & Confirm` / `Update` — sets status to 'confirmed', saves; triggers backend to post ledger entries
- On success: close dialog + show SnackBar "CRV-0001 posted successfully"
- On error: show inline error banner at top of dialog (NOT a SnackBar)

### 3.12 `voucher_detail_screen.dart`

Full read-only view of a posted voucher. Layout:

```
┌──────────────────────────────────────────────────────────────┐
│  Cash Receiving Voucher                    [Edit] [Delete]   │
│  CRV-0001                                 12 May 2026        │
│  ● Confirmed                                                  │
├──────────────────────────────────────────────────────────────┤
│  Cash Account:   Cash-in-Hand (1001)                         │
│  Amount:         PKR 50,000.00                               │
│  Counter Acct:   Accounts Receivable — Muhammad Ali          │
│  Narration:      Recovery from Muhammad Ali for May invoice  │
├──────────────────────────────────────────────────────────────┤
│  Posted Ledger Entries                                        │
│  ┌──────┬────────────────────────┬──────┬──────────────┐    │
│  │ No.  │ Account                │ Dr   │ Cr           │    │
│  │CRV.. │ Cash-in-Hand           │50,000│              │    │
│  │CRV.. │ Accounts Receivable    │      │ 50,000       │    │
│  └──────┴────────────────────────┴──────┴──────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

### 3.13 Cash Book Screen — `cash_book_screen.dart`

This lives in `accounts_reports/views/`. It is a **report view only** — never writes data.
It reads from the existing `LedgerController.loadByAccount()` but adds Cash Book-specific
presentation: date range filtering, opening balance, running balance, totals footer.

**Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│ Cash Book                                                        │
│ ─────────────────────────────────────────────────────────────── │
│ [Cash Account: Cash-in-Hand (1001) ▾]  [From: __/__/____]      │
│ [To: __/__/____]  [Filter]  [Clear]  [Print/Export]             │
├─────────────────────────────────────────────────────────────────┤
│ Opening Balance: PKR 100,000.00 Dr                              │
├────────────────────────────────────────────────────────────────┤
│ Date       Particulars              Ref No  Dr (In)  Cr (Out)  Balance│
│ ─────────────────────────────────────────────────────────────── │
│ 01/05/2026 Opening Balance                           100,000.00 │
│ 02/05/2026 Cash Received from Ali   CRV-0001  50,000             150,000.00│
│ 03/05/2026 Payment to XYZ Feed      CPV-0001          30,000    120,000.00│
│ 03/05/2026 Journal Adj              JV-0001   10,000             130,000.00│
│ ─────────────────────────────────────────────────────────────── │
│ Closing Balance: PKR 130,000.00 Dr  │ Total Receipts: 60,000   │
│                                     │ Total Payments: 30,000   │
└─────────────────────────────────────────────────────────────────┘
```

**Implementation details:**
- `CashBookController` extends `LedgerController` logic but adds:
  - `List<Account> cashAccounts` — filtered from `AccountsController` where `isCashAccount == true`
  - `String? selectedCashAccountId` — which cash account is being viewed
  - Date range state: `DateTime? filterStart`, `DateTime? filterEnd`
- Calls `LedgerService.fetchByAccount(accountId, startDate, endDate)` when account + dates selected
- Displays entries sorted by date ASC with running balance column
- Running balance sign: shows "Dr" if debit-normal account has positive balance, "Cr" if credit
- Balance row colors: Dr balance = green, Cr balance (overdraft) = red
- "Particulars" column: shows `description` from ledger entry, falling back to `referenceNo`
- Ref No column: shows `referenceNo` (e.g. "CRV-0001")
- Clicking Ref No navigates to that voucher detail (using `voucherId` in `referenceId` field)
- **Mobile**: switches to card-based list with compact format
- **Print**: uses `flutter_print` or PDF export (out of scope for today, but add a disabled Print button as placeholder)

**"Particulars" smart display logic:**
```dart
String particulars(LedgerEntry entry) {
  // Use description if meaningful
  if (entry.description.trim().isNotEmpty &&
      entry.description != 'Cash received' &&
      entry.description != 'Cash paid') {
    return entry.description;
  }
  // Fall back to reference type label
  switch (entry.referenceType) {
    case 'cash_receiving_voucher': return 'Cash Receipt';
    case 'cash_payment_voucher':   return 'Cash Payment';
    case 'journal_voucher':        return 'Journal Entry';
    case 'chicken_invoice':        return 'Poultry Invoice';
    case 'opening_receivable':     return 'Opening Balance (Receivable)';
    case 'opening_payable':        return 'Opening Balance (Payable)';
    default:                       return entry.referenceType.replaceAll('_', ' ');
  }
}
```

### 3.14 Update `accounts_reports_definitions.dart` — Unlock Cash Book

Find the Cash Book nav item and change `enabled: false` to `enabled: true`:
```dart
AccountsReportsNavItem(
  id:    'cash_book',
  label: 'Cash Book',
  icon:  Icons.receipt_outlined,
  enabled: true,    // ← change from false to true
  // remove comingSoonNote
),
```

### 3.15 Update `accounts_reports_scope.dart`

Add `CashBookController` to providers:
```dart
ChangeNotifierProvider(create: (_) => CashBookController()),
```

### 3.16 Update `accounts_reports_screen.dart`

Add Cash Book routing in `_ContentArea._buildContent`:
```dart
case 'cash_book':
  return const CashBookScreen();
```

### 3.17 Update `main_shell.dart`

1. Import `TransactionsScope` and `TransactionsScreen`
2. In `_buildBody()` case 3 (Transactions placeholder), replace with:
```dart
case 3:
  return const TransactionsScope(child: TransactionsScreen());
```

---

## 4. SETTINGS MODULE UPDATES

### 4.1 Update Account Form in Settings

The account form dialog (in `settings/views/settings_screen.dart` or wherever the accounts
form is) needs two new checkbox fields:

- **Is Cash Account** — checkbox, default false. When checked, this account appears
  in the "Cash Account" dropdown in all CRV/CPV forms and in the Cash Book account selector.
- **Is Bank Account** — checkbox, default false. When checked, this account appears
  in Bank-related transaction dropdowns (future use).

These fields use the same `AppTheme.checkboxTheme` style already defined.
Add them in the "Account Settings" section of the account form, below `isActive`.

### 4.2 Update `AccountModel` (or `BaseSettingsModel`) in Flutter

The existing `BaseSettingsModel` (used for all settings items) stores fields as
`Map<String, dynamic>`. The `isCashAccount` and `isBankAccount` are accessed via
`account.boolean('isCashAccount')` — this ALREADY works because `BaseSettingsModel.boolean()`
reads from the raw map. No new model class needed, just use the existing accessor pattern.

To query cash accounts in the controller:
```dart
List<BaseSettingsModel> get cashAccounts =>
    typedItems.where((a) => a.boolean('isCashAccount') && a.boolean('isActive')).toList();
```

Add this getter to `AccountsController`.

---

## 5. UI DESIGN SPECIFICATIONS

### 5.1 Voucher Type Color Coding (consistent across ALL screens)

Use these throughout — on badges, row highlights, icons:
```
CRV (Cash Receiving — money IN):
  background: Color(0xFFE8F5E9)  // green-50
  border:     Color(0xFF66BB6A)  // green-400
  text:       Color(0xFF1B5E20)  // green-900
  icon:       Icons.arrow_downward_rounded, color: green-700

CPV (Cash Payment — money OUT):
  background: Color(0xFFFFEBEB)  // red-50
  border:     Color(0xFFE57373)  // red-300
  text:       Color(0xFFB71C1C)  // red-900
  icon:       Icons.arrow_upward_rounded, color: red-700

JV (Journal — neutral):
  background: AppTheme.terra100  // existing terra color
  border:     AppTheme.terra400
  text:       AppTheme.terra800
  icon:       Icons.swap_horiz_outlined, color: AppTheme.terra600
```

### 5.2 Cash Book Balance Color Rules

```
Positive Dr balance (normal for cash): AppTheme.successText (#3A6B35)
Zero balance:                          AppTheme.textSecondary
Negative / Cr balance (overdraft):     AppTheme.dangerText (#8A3828)
```

### 5.3 Amount Formatting

Use the existing `fmtAmt()` function from `ledger_list_screen.dart` (already exported).
Import it in all new screens: `import '../accounts_reports/views/ledger_list_screen.dart' show fmtAmt, fmtDate;`

For Cash Book specifically, show full precision (no K/M abbreviation):
```dart
String fmtFullAmt(double v) => v.toStringAsFixed(2);
```

### 5.4 Empty States

Follow the exact pattern from `ledger_list_screen.dart`:
- Center column with icon (64px, `AppTheme.textTertiary`)
- Text message
- CTA button if appropriate

For Cash Book empty state when no cash account selected:
```
icon: Icons.account_balance_outlined
text: "Select a cash account and date range to view the Cash Book"
```

For Cash Book empty state when account selected but no entries:
```
icon: Icons.receipt_long_outlined
text: "No transactions found for the selected period"
subtext: "Create Cash Receiving or Payment Vouchers in Transactions"
```

### 5.5 Loading States

Use `CircularProgressIndicator()` centered — identical to all other screens.

### 5.6 Error States

Use the exact error widget pattern from `ledger_list_screen.dart` (icon + message + Retry button).

---

## 6. VALIDATION RULES SUMMARY

### Backend Validators

| Field | Rule |
|-------|------|
| voucherNo | required, unique per uid |
| voucherDate | required, valid ISO date |
| voucherType | required, enum |
| cashAccountId | required for CRV/CPV, must exist in accounts |
| counterAccountId | optional, must exist if provided |
| amount | required for CRV/CPV, > 0 |
| lines | required for JV, min 2, must balance (debits == credits ± 0.001) |
| chequeNo | required if isChequePayment == true |
| status | enum: draft/confirmed/cancelled |

### Frontend Validators

- All `required` fields show error text below field (not SnackBar)
- Amount: reject non-numeric, allow decimal point
- Date: must be parseable, not more than 1 year in future (warn, don't block)
- JV balance: show live balance indicator; block submission if unbalanced
- Voucher No: debounce-check uniqueness 500ms after user stops typing (optional UX enhancement)

---

## 7. API ENDPOINTS REFERENCE

### Transactions Module (`/api/v1/transactions/`)

```
GET    /cashVouchers                       List all vouchers (filterable)
GET    /cashVouchers/:id                   Get single voucher
POST   /cashVouchers                       Create voucher + post ledger entries
PUT    /cashVouchers/:id                   Update voucher + re-post ledger entries
DELETE /cashVouchers/:id                   Delete voucher + remove ledger entries
GET    /cashVouchers/next-voucher-no/:type Auto-suggest next voucher number
```

### Query params for GET /cashVouchers:
```
voucherType:   cash_receiving | cash_payment | journal
status:        draft | confirmed | cancelled
cashAccountId: account ID
partyId:       party ID
startDate:     ISO date string
endDate:       ISO date string
```

### Existing Accounts Module (already works, used by Cash Book):
```
GET    /accounts/ledger/by-account/:accountId   Used by Cash Book
  ?startDate=&endDate=&entryType=&isReconciled=
```

---

## 8. FIRESTORE COLLECTION PATHS REFERENCE

```
users/{uid}/                           ← Settings root
  units/{id}
  packings/{id}
  companies/{id}
  productGroups/{id}
  productSubGroups/{id}
  products/{id}
  discountSchemes/{id}
  vendors/{id}
  towns/{id}
  sectors/{id}
  customers/{id}
  salesmen/{id}
  accounts/{id}                        ← accountType, isCashAccount, isBankAccount

users/{uid}/accounts/__root__/         ← Accounts module root
  ledgerEntries/{id}

users/{uid}/transactions/__root__/     ← Transactions module root (NEW TODAY)
  cashVouchers/{id}

users/{uid}/poultry/__root__/          ← Poultry module root (already exists)
  flocks/{id}
  flockFeeds/{id}
  flockVaccines/{id}
  feedSchedules/{id}
  vaccineSchedules/{id}
  chickenInvoices/{id}

SCAFFOLD (create empty, locked schema):
users/{uid}/invoicing/__root__/
  invoices/{id}
  stockMovements/{id}

users/{uid}/transactions/__root__/
  cheques/{id}
  recoveries/{id}
  paymentPromises/{id}
```

---

## 9. WHAT NOT TO BUILD TODAY (DON'T TOUCH)

These depend on Invoicing module data that doesn't exist yet. Leave them as
disabled nav items with lock icon and `comingSoonNote`. Do NOT create any
routes, controllers, or screens for them today:

- Recovery Invoice
- Recovery (Invoice-wise)
- Recovery (Receivable-wise)
- Salesman Cash Reconciliation
- Bank Cheque Issuing
- Bank Cheques Reconciliation
- Cash Deposit in Bank
- Cheque Deposit in Bank
- Deposit Confirmation
- Deposit Reconciliation
- Voucher Confirmation
- Post Dated Recovery Promise
- Post Dated Payment Promise
- Promises Processing
- All Trade Reports sub-items
- Bank Statement
- G/L Journal (report)
- Uncleared/Lost/Bounced/Danger Cheques
- Monthly Expense Chart
- Accounts Receivable / Payable reports
- Markup Calculation
- Trial Balance
- Profit & Loss Statement
- Balance Sheet

---

## 10. IMPLEMENTATION ORDER (CRITICAL — follow this sequence)

```
STEP 1: Backend
  1a. Update ledger_entry.config.js (extend REFERENCE_TYPES)
  1b. Update settings.config.js accounts entity (add isCashAccount, isBankAccount, isSystemAccount)
  1c. Create transactions.validators.js
  1d. Create cash_voucher.config.js
  1e. Create transactions.routes.js
  1f. Register route in index.js
  1g. Update firestore.indexes.json
  TEST: curl POST /api/v1/transactions/cashVouchers with a sample CRV body
  VERIFY: ledger entry auto-created in Firestore

STEP 2: Settings UI — Account flags
  2a. Add isCashAccount + isBankAccount checkboxes to account form
  2b. Add cashAccounts getter to AccountsController
  TEST: Create a "Cash-in-Hand" account with isCashAccount=true in Settings

STEP 3: Transactions Module — Models + Services
  3a. Create cash_voucher_model.dart
  3b. Create voucher_line_model.dart
  3c. Create cash_voucher_service.dart
  3d. Create cash_voucher_controller.dart

STEP 4: Transactions Module — UI
  4a. Create transactions_definitions.dart
  4b. Create transactions_nav_controller.dart
  4c. Create transactions_scope.dart
  4d. Create transactions_screen.dart (with chip nav)
  4e. Create voucher_form_dialog.dart (most complex — do this carefully)
  4f. Create crv_list_screen.dart, cpv_list_screen.dart, jv_list_screen.dart
  4g. Create voucher_detail_screen.dart

STEP 5: Wire into Shell
  5a. Update main_shell.dart case 3 to render TransactionsScope + TransactionsScreen

STEP 6: Cash Book in AccountsReports
  6a. Create cash_book_controller.dart
  6b. Create cash_book_screen.dart
  6c. Update accounts_reports_definitions.dart (unlock cash_book)
  6d. Update accounts_reports_scope.dart (add CashBookController)
  6e. Update accounts_reports_screen.dart (add case 'cash_book')

STEP 7: End-to-End Test
  7a. Create CRV → verify ledger entry created → verify Cash Book shows it
  7b. Create CPV → verify ledger entry created → verify Cash Book shows it
  7c. Create JV → verify 2 ledger entries created → verify both appear in their account ledgers
  7d. Delete a voucher → verify ledger entries removed → verify Cash Book no longer shows it
```

---

## 11. QUALITY CHECKLIST

Before considering this PR done, verify each item:

**Backend:**
- [ ] POST /cashVouchers CRV creates 2 ledger entries (DR cash, CR counter)
- [ ] POST /cashVouchers CPV creates 2 ledger entries (DR counter, CR cash)
- [ ] POST /cashVouchers JV creates N ledger entries per lines array
- [ ] PUT /cashVouchers/:id deletes old ledger entries and re-creates new ones
- [ ] DELETE /cashVouchers/:id deletes associated ledger entries
- [ ] Draft vouchers do NOT create ledger entries (status !== 'confirmed')
- [ ] Confirming a draft (PUT status=confirmed) DOES create ledger entries
- [ ] voucherNo uniqueness enforced
- [ ] JV imbalance returns 400 with clear error message
- [ ] isCashAccount flag saved correctly on accounts

**Frontend:**
- [ ] Transactions module appears in sidebar as index 3
- [ ] Chip bar shows all items; locked items have lock icon
- [ ] CRV form pre-fills voucher number
- [ ] Cash Account dropdown only shows accounts with isCashAccount=true
- [ ] JV form shows live balance indicator (Dr total vs Cr total)
- [ ] JV submit blocked if debits ≠ credits
- [ ] Cash Book only shows when isCashAccount accounts exist
- [ ] Cash Book displays opening balance row first
- [ ] Cash Book running balance column recalculates correctly
- [ ] Cash Book respects date range filter
- [ ] Delete voucher requires confirmation dialog
- [ ] All screens work on mobile (<600px) — cards not tables
- [ ] All screens work on tablet (600–1024px)
- [ ] No hardcoded colors — all use AppTheme constants
- [ ] No hardcoded strings — all error messages from API response
- [ ] Loading states on all async operations
- [ ] Error states with Retry button on all list screens