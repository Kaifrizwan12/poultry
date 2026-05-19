const express = require('express');
const { log } = require('../../core/logger');
const {
  invoicingCollection,
  stampNew, stampUpdated, nowIso,
} = require('./invoicing.validators');
const { poultryCollection } = require('../poultry/poultry.validators');
const { getDb } = require('../../core/firebase/firebase');

const purchaseOrderConfig              = require('./entities/purchase_order.config');
const sendOrderConfig                  = require('./entities/send_order.config');
const purchaseInvoiceConfig            = require('./entities/purchase_invoice.config');
const purchaseReturnConfig             = require('./entities/purchase_return.config');
const salesInvoiceConfig               = require('./entities/sales_invoice.config');
const salesReturnConfig                = require('./entities/sales_return.config');
const stockIssueConfig                 = require('./entities/stock_issue.config');
const stockExpiryConfig                = require('./entities/stock_expiry.config');
const expiryClaimConfig                = require('./entities/expiry_claim.config');
const stockWastageConfig               = require('./entities/stock_wastage.config');
const recoveryInvoiceConfig            = require('./entities/recovery_invoice.config');
const recoveryInvoiceWiseConfig        = require('./entities/recovery_invoice_wise.config');
const recoveryReceivableWiseConfig     = require('./entities/recovery_receivable_wise.config');
const cashVoucherConfig                = require('./entities/cash_voucher.config');
const salesmanCashReconciliationConfig = require('./entities/salesman_cash_reconciliation.config');
const bankChequeConfig                 = require('./entities/bank_cheque.config');
const bankDepositConfig                = require('./entities/bank_deposit.config');
const paymentPromiseConfig             = require('./entities/payment_promise.config');

const router = express.Router();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function ok(res, data, code) { return res.status(code || 200).json({ success: true, data }); }
function err(res, msg, code) { return res.status(code || 400).json({ success: false, error: msg }); }

function createCrudRouter(config) {
  const e = config.entity;
  const r = express.Router();

  // List
  r.get('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /invoicing/${e}`, { uid, query: req.query });
    try {
      let query = invoicingCollection(uid, e).orderBy('createdAt', 'desc');
      if (req.query.status)     query = query.where('status', '==', req.query.status);
      if (req.query.salesmanId) query = query.where('salesmanId', '==', req.query.salesmanId);
      if (req.query.customerId) query = query.where('customerId', '==', req.query.customerId);
      if (req.query.vendorId)   query = query.where('vendorId', '==', req.query.vendorId);
      const snap  = await query.get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      log('INFO', `GET /invoicing/${e} → ${items.length} records`, { uid });
      return ok(res, items);
    } catch (e2) {
      log('ERROR', `GET /invoicing/${e} failed`, { uid, error: e2.message });
      return err(res, e2.message || 'Failed to fetch', e2.statusCode || 500);
    }
  });

  // Get single
  r.get('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /invoicing/${e}/${req.params.id}`, { uid });
    try {
      const snap = await invoicingCollection(uid, e).doc(req.params.id).get();
      if (!snap.exists) { log('WARN', `GET /invoicing/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      log('INFO', `GET /invoicing/${e}/${req.params.id} → found`, { uid });
      return ok(res, { id: snap.id, ...snap.data() });
    } catch (e2) {
      log('ERROR', `GET /invoicing/${e}/${req.params.id} failed`, { uid, error: e2.message });
      return err(res, e2.message || 'Failed to fetch', e2.statusCode || 500);
    }
  });

  // Create
  r.post('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `POST /invoicing/${e}`, { uid, body: req.body });
    try {
      const { data, errors } = await config.sanitize({ uid, body: req.body || {} });
      if (errors.length) { log('WARN', `POST /invoicing/${e} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
      const col    = invoicingCollection(uid, e);
      const docRef = col.doc();
      const payload = stampNew(uid, data);
      await docRef.set(payload);
      log('INFO', `POST /invoicing/${e} → created ${docRef.id}`, { uid });
      return ok(res, { id: docRef.id, ...payload }, 201);
    } catch (e2) {
      log('ERROR', `POST /invoicing/${e} failed`, { uid, error: e2.message });
      return err(res, e2.message || 'Failed to create', e2.statusCode || 500);
    }
  });

  // Update
  r.put('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `PUT /invoicing/${e}/${req.params.id}`, { uid, body: req.body });
    try {
      const docRef = invoicingCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) { log('WARN', `PUT /invoicing/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      const { data, errors } = await config.sanitize({ uid, body: req.body || {}, id: req.params.id });
      if (errors.length) { log('WARN', `PUT /invoicing/${e}/${req.params.id} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
      const payload = stampUpdated(snap.data(), data);
      await docRef.set(payload, { merge: false });
      log('INFO', `PUT /invoicing/${e}/${req.params.id} → updated`, { uid });
      return ok(res, { id: docRef.id, ...payload });
    } catch (e2) {
      log('ERROR', `PUT /invoicing/${e}/${req.params.id} failed`, { uid, error: e2.message });
      return err(res, e2.message || 'Failed to update', e2.statusCode || 500);
    }
  });

  // Delete
  r.delete('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `DELETE /invoicing/${e}/${req.params.id}`, { uid });
    try {
      const docRef = invoicingCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) { log('WARN', `DELETE /invoicing/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      await docRef.delete();
      log('INFO', `DELETE /invoicing/${e}/${req.params.id} → deleted`, { uid });
      return ok(res, { id: req.params.id });
    } catch (e2) {
      log('ERROR', `DELETE /invoicing/${e}/${req.params.id} failed`, { uid, error: e2.message });
      return err(res, e2.message || 'Failed to delete', e2.statusCode || 500);
    }
  });

  return r;
}

// ─── Standard CRUD routers ────────────────────────────────────────────────────
router.use('/purchase-orders',               createCrudRouter(purchaseOrderConfig));
router.use('/send-orders',                   createCrudRouter(sendOrderConfig));
router.use('/purchase-invoices',             createCrudRouter(purchaseInvoiceConfig));
router.use('/purchase-returns',              createCrudRouter(purchaseReturnConfig));

// Sales invoice delete — clears dangling linkedSalesInvoiceId on the linked chicken invoice
router.delete('/sales-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  const siId = req.params.id;
  log('INFO', `DELETE /invoicing/salesInvoices/${siId}`, { uid });
  try {
    const siRef  = invoicingCollection(uid, 'salesInvoices').doc(siId);
    const siSnap = await siRef.get();
    if (!siSnap.exists) { log('WARN', `DELETE /invoicing/salesInvoices/${siId} → 404`, { uid }); return err(res, 'Not found', 404); }
    const si = siSnap.data();

    // Clear the back-reference on the linked chicken invoice, if any
    if (si.linkedChickenInvoiceId) {
      try {
        const ciRef  = poultryCollection(uid, 'chickenInvoices').doc(si.linkedChickenInvoiceId);
        const ciSnap = await ciRef.get();
        if (ciSnap.exists) {
          await ciRef.update({ linkedSalesInvoiceId: '', updatedAt: nowIso() });
          log('INFO', `DELETE /invoicing/salesInvoices/${siId} → cleared linkedSalesInvoiceId on CI ${si.linkedChickenInvoiceId}`, { uid });
        }
      } catch (unlinkErr) {
        log('WARN', `DELETE /invoicing/salesInvoices/${siId} → failed to unlink CI: ${unlinkErr.message}`, { uid });
      }
    }

    await siRef.delete();
    log('INFO', `DELETE /invoicing/salesInvoices/${siId} → deleted`, { uid });
    return ok(res, { id: siId });
  } catch (e) {
    log('ERROR', `DELETE /invoicing/salesInvoices/${siId} failed`, { uid, error: e.message });
    return err(res, e.message || 'Failed to delete', e.statusCode || 500);
  }
});

router.use('/sales-invoices',                createCrudRouter(salesInvoiceConfig));
router.use('/sales-returns',                 createCrudRouter(salesReturnConfig));
router.use('/stock-issues',                  createCrudRouter(stockIssueConfig));
router.use('/stock-expiries',                createCrudRouter(stockExpiryConfig));
router.use('/expiry-claims',                 createCrudRouter(expiryClaimConfig));
router.use('/stock-wastages',                createCrudRouter(stockWastageConfig));
// ─── Recovery invoice SI balance sync ─────────────────────────────────────────
// When a recovery is posted, the linked sales invoice's paidAmount + remBalance
// must update so the farm owner can see the real outstanding balance.

async function _applyRecoveryToSI(uid, saleId, deltaCredit) {
  if (!saleId || !deltaCredit) return;
  const siRef  = invoicingCollection(uid, 'salesInvoices').doc(saleId);
  const siSnap = await siRef.get();
  if (!siSnap.exists) return;
  const si = siSnap.data();
  const newPaid    = Math.max(0, (si.paidAmount || 0) + deltaCredit);
  const newBalance = Math.max(0, (si.totalPayable || 0) - newPaid);
  await siRef.update({ paidAmount: newPaid, remBalance: newBalance, updatedAt: nowIso() });
}

// Recovery invoice (simple — one saleId per customer row)
router.post('/recovery-invoices', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'POST /invoicing/recovery-invoices', { uid });
  try {
    const { data, errors } = await recoveryInvoiceConfig.sanitize({ uid, body: req.body || {}, id: null });
    if (errors.length) return err(res, errors.join('; '), 400);
    const docRef  = invoicingCollection(uid, 'recoveryInvoices').doc();
    const payload = stampNew(uid, data);
    await docRef.set(payload);
    // Update SI balances for each customer recovery
    await Promise.all((data.customerRecoveries || []).map(cr =>
      _applyRecoveryToSI(uid, cr.saleId, cr.finalCredit || 0).catch(e =>
        log('WARN', `POST /recovery-invoices → SI update failed for ${cr.saleId}: ${e.message}`, { uid })
      )
    ));
    log('INFO', `POST /invoicing/recovery-invoices → ${docRef.id}`, { uid });
    return ok(res, { id: docRef.id, ...payload });
  } catch (e) { log('ERROR', 'POST /invoicing/recovery-invoices failed', { uid, error: e.message }); return err(res, e.message || 'Failed', 500); }
});

router.delete('/recovery-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `DELETE /invoicing/recovery-invoices/${req.params.id}`, { uid });
  try {
    const docRef = invoicingCollection(uid, 'recoveryInvoices').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) return err(res, 'Not found', 404);
    const data = snap.data();
    await docRef.delete();
    // Reverse SI balance changes
    await Promise.all((data.customerRecoveries || []).map(cr =>
      _applyRecoveryToSI(uid, cr.saleId, -((cr.finalCredit || 0))).catch(e =>
        log('WARN', `DELETE /recovery-invoices → SI reverse failed for ${cr.saleId}: ${e.message}`, { uid })
      )
    ));
    log('INFO', `DELETE /invoicing/recovery-invoices/${req.params.id} → deleted + SI balances reversed`, { uid });
    return ok(res, { id: req.params.id });
  } catch (e) { log('ERROR', `DELETE /invoicing/recovery-invoices/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed', 500); }
});

// Recovery invoice wise (nested invoices per customer)
router.post('/recovery-invoices-wise', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'POST /invoicing/recovery-invoices-wise', { uid });
  try {
    const { data, errors } = await recoveryInvoiceWiseConfig.sanitize({ uid, body: req.body || {}, id: null });
    if (errors.length) return err(res, errors.join('; '), 400);
    const docRef  = invoicingCollection(uid, 'recoveryInvoicesWise').doc();
    const payload = stampNew(uid, data);
    await docRef.set(payload);
    const allInvs = (data.customerRecoveries || []).flatMap(cr => cr.invoices || []);
    await Promise.all(allInvs.map(inv =>
      _applyRecoveryToSI(uid, inv.saleId, (inv.received || 0) + (inv.discount || 0)).catch(e =>
        log('WARN', `POST /recovery-invoices-wise → SI update failed for ${inv.saleId}: ${e.message}`, { uid })
      )
    ));
    log('INFO', `POST /invoicing/recovery-invoices-wise → ${docRef.id}`, { uid });
    return ok(res, { id: docRef.id, ...payload });
  } catch (e) { log('ERROR', 'POST /invoicing/recovery-invoices-wise failed', { uid, error: e.message }); return err(res, e.message || 'Failed', 500); }
});

router.delete('/recovery-invoices-wise/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `DELETE /invoicing/recovery-invoices-wise/${req.params.id}`, { uid });
  try {
    const docRef = invoicingCollection(uid, 'recoveryInvoicesWise').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) return err(res, 'Not found', 404);
    const data = snap.data();
    await docRef.delete();
    const allInvs = (data.customerRecoveries || []).flatMap(cr => cr.invoices || []);
    await Promise.all(allInvs.map(inv =>
      _applyRecoveryToSI(uid, inv.saleId, -((inv.received || 0) + (inv.discount || 0))).catch(e =>
        log('WARN', `DELETE /recovery-invoices-wise → SI reverse failed for ${inv.saleId}: ${e.message}`, { uid })
      )
    ));
    log('INFO', `DELETE /invoicing/recovery-invoices-wise/${req.params.id} → deleted + SI balances reversed`, { uid });
    return ok(res, { id: req.params.id });
  } catch (e) { log('ERROR', `DELETE /invoicing/recovery-invoices-wise/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed', 500); }
});

router.use('/recovery-invoices',             createCrudRouter(recoveryInvoiceConfig));
router.use('/recovery-invoices-wise',        createCrudRouter(recoveryInvoiceWiseConfig));
router.use('/recovery-receivable-wise',      createCrudRouter(recoveryReceivableWiseConfig));
router.use('/cash-vouchers',                 createCrudRouter(cashVoucherConfig));
router.use('/salesman-cash-reconciliations', createCrudRouter(salesmanCashReconciliationConfig));
router.use('/bank-cheques',                  createCrudRouter(bankChequeConfig));
router.use('/bank-deposits',                 createCrudRouter(bankDepositConfig));
router.use('/payment-promises',              createCrudRouter(paymentPromiseConfig));

// ─── Custom PATCH endpoints ────────────────────────────────────────────────────

// Bank cheque status update — when cleared, post ledger entries (debit AP / credit bank)
router.patch('/bank-cheques/:id/status', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PATCH /invoicing/bank-cheques/${req.params.id}/status`, { uid, body: req.body });
  try {
    const docRef = invoicingCollection(uid, 'bankCheques').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PATCH /invoicing/bank-cheques/${req.params.id}/status → 404`, { uid }); return err(res, 'Not found', 404); }
    const cheque = snap.data();

    const allowed = ['cleared', 'bounced', 'cancelled'];
    const status  = req.body.status;
    if (!allowed.includes(status)) return err(res, `status must be one of: ${allowed.join(', ')}`, 400);

    if (cheque.status === status) return err(res, `Cheque is already ${status}`, 400);

    const ts     = nowIso();
    const update = { status, updatedAt: ts };
    if (status === 'cleared' && req.body.clearedDate) update.clearedDate = req.body.clearedDate;
    await docRef.update(update);

    // On cleared: create balancing ledger entries so the bank account reflects reality
    if (status === 'cleared' && cheque.bankAccountId) {
      const { accountsCollection } = require('../accounts/accounts.validators');
      const entryDate = req.body.clearedDate || ts.substring(0, 10);
      const batch = getDb().batch();
      // Debit AP (reduces the payable we owe the vendor)
      const apRef = accountsCollection(uid, 'ledgerEntries').doc();
      batch.set(apRef, {
        entryNo: `CHQ-${cheque.chequeNo}-CLR-DR`, entryDate,
        accountId: cheque.bankAccountId, // debit bank account that issued the cheque
        entryType: 'credit', amount: cheque.amount,
        description: `Cheque cleared — ${cheque.chequeNo} to ${cheque.payeeName || ''}`,
        referenceType: 'other', referenceId: req.params.id, referenceNo: cheque.chequeNo || '',
        tags: ['bank-cheque', 'cleared'], isReconciled: false,
        uid, createdAt: ts, updatedAt: ts,
      });
      await batch.commit();
      log('INFO', `PATCH /bank-cheques/${req.params.id}/status → ledger entry posted for cleared cheque`, { uid });
    }

    log('INFO', `PATCH /invoicing/bank-cheques/${req.params.id}/status → ${status}`, { uid });
    return ok(res, { id: req.params.id, ...cheque, ...update });
  } catch (e2) {
    log('ERROR', `PATCH /invoicing/bank-cheques/${req.params.id}/status failed`, { uid, error: e2.message });
    return err(res, e2.message || 'Failed to update status', e2.statusCode || 500);
  }
});

// Bank deposit confirmation
router.patch('/bank-deposits/:id/confirm', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PATCH /invoicing/bank-deposits/${req.params.id}/confirm`, { uid });
  try {
    const docRef = invoicingCollection(uid, 'bankDeposits').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PATCH /invoicing/bank-deposits/${req.params.id}/confirm → 404`, { uid }); return err(res, 'Not found', 404); }
    const update = { isConfirmed: true, confirmedDate: nowIso(), updatedAt: nowIso() };
    await docRef.update(update);
    log('INFO', `PATCH /invoicing/bank-deposits/${req.params.id}/confirm → confirmed`, { uid });
    return ok(res, { id: req.params.id, ...snap.data(), ...update });
  } catch (e2) {
    log('ERROR', `PATCH /invoicing/bank-deposits/${req.params.id}/confirm failed`, { uid, error: e2.message });
    return err(res, e2.message || 'Failed to confirm', e2.statusCode || 500);
  }
});

// Bank deposit reconciliation
router.patch('/bank-deposits/:id/reconcile', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PATCH /invoicing/bank-deposits/${req.params.id}/reconcile`, { uid });
  try {
    const docRef = invoicingCollection(uid, 'bankDeposits').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PATCH /invoicing/bank-deposits/${req.params.id}/reconcile → 404`, { uid }); return err(res, 'Not found', 404); }
    const update = {
      isReconciled: true,
      reconciledDate: nowIso(),
      updatedAt: nowIso(),
    };
    if (req.body.bankStatementRef) update.bankStatementRef = String(req.body.bankStatementRef).trim();
    await docRef.update(update);
    log('INFO', `PATCH /invoicing/bank-deposits/${req.params.id}/reconcile → reconciled`, { uid });
    return ok(res, { id: req.params.id, ...snap.data(), ...update });
  } catch (e2) {
    log('ERROR', `PATCH /invoicing/bank-deposits/${req.params.id}/reconcile failed`, { uid, error: e2.message });
    return err(res, e2.message || 'Failed to reconcile', e2.statusCode || 500);
  }
});

// Cash voucher confirmation
router.patch('/cash-vouchers/:id/confirm', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PATCH /invoicing/cash-vouchers/${req.params.id}/confirm`, { uid });
  try {
    const docRef = invoicingCollection(uid, 'cashVouchers').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PATCH /invoicing/cash-vouchers/${req.params.id}/confirm → 404`, { uid }); return err(res, 'Not found', 404); }
    const update = {
      isConfirmed: true,
      confirmedDate: nowIso(),
      confirmedBy: (req.user && req.user.email) ? req.user.email : '',
      updatedAt: nowIso(),
    };
    await docRef.update(update);
    log('INFO', `PATCH /invoicing/cash-vouchers/${req.params.id}/confirm → confirmed`, { uid });
    return ok(res, { id: req.params.id, ...snap.data(), ...update });
  } catch (e2) {
    log('ERROR', `PATCH /invoicing/cash-vouchers/${req.params.id}/confirm failed`, { uid, error: e2.message });
    return err(res, e2.message || 'Failed to confirm', e2.statusCode || 500);
  }
});

// Payment promise status update
router.patch('/payment-promises/:id/status', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PATCH /invoicing/payment-promises/${req.params.id}/status`, { uid, body: req.body });
  try {
    const docRef = invoicingCollection(uid, 'paymentPromises').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PATCH /invoicing/payment-promises/${req.params.id}/status → 404`, { uid }); return err(res, 'Not found', 404); }
    const allowed = ['cleared', 'bounced', 'cancelled'];
    const status  = req.body.status;
    if (!allowed.includes(status)) return err(res, `status must be one of: ${allowed.join(', ')}`, 400);
    const update = { status, updatedAt: nowIso() };
    if (req.body.processedDate) update.processedDate = req.body.processedDate;
    await docRef.update(update);
    log('INFO', `PATCH /invoicing/payment-promises/${req.params.id}/status → ${status}`, { uid });
    return ok(res, { id: req.params.id, ...snap.data(), ...update });
  } catch (e2) {
    log('ERROR', `PATCH /invoicing/payment-promises/${req.params.id}/status failed`, { uid, error: e2.message });
    return err(res, e2.message || 'Failed to update status', e2.statusCode || 500);
  }
});

module.exports = router;
