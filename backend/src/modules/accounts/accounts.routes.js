const express = require('express');
const { accountsCollection, stampNew, stampUpdated } = require('./accounts.validators');
const { settingsCollection } = require('../../utils/firestore');
const { log } = require('../../core/logger');

const ledgerEntryConfig = require('./entities/ledger_entry.config');

const router = express.Router();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function ok(res, data, code)  { return res.status(code || 200).json({ success: true, data }); }
function fail(res, msg, code) { return res.status(code || 400).json({ success: false, error: msg }); }

function parseDate(value) {
  if (!value) return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

// ─── Special ledger endpoints (must come BEFORE the CRUD sub-router) ──────────

// GET /ledger/by-account/:accountId
// Uses Firestore for accountId + optional entryDate range (requires 1 composite index).
// Filters entryType + isReconciled in-memory to avoid N×M composite index combinations.
router.get('/ledger/by-account/:accountId', async (req, res) => {
  const uid       = req.user.uid;
  const accountId = req.params.accountId;
  log('INFO', `GET /accounts/ledger/by-account/${accountId}`, { uid, query: req.query });
  try {
    const accountSnap = await settingsCollection(uid, 'accounts').doc(accountId).get();
    if (!accountSnap.exists) {
      log('WARN', `GET /accounts/ledger/by-account/${accountId} — account not found`, { uid });
      return fail(res, 'Account not found', 404);
    }
    const account = { id: accountSnap.id, ...accountSnap.data() };

    // Firestore query: accountId equality + optional date range (same-field inequalities are fine)
    // Firestore rule: all inequality filters must be on the same field.
    // entryType and isReconciled are filtered in JS to avoid requiring N×M composite indexes.
    let query = accountsCollection(uid, 'ledgerEntries')
      .where('accountId', '==', accountId)
      .orderBy('entryDate', 'asc')
      .orderBy('createdAt', 'asc');

    const startDate = parseDate(req.query.startDate);
    const endDate   = parseDate(req.query.endDate);

    if (startDate) {
      query = query.where('entryDate', '>=', startDate.toISOString());
    }
    if (endDate) {
      endDate.setHours(23, 59, 59, 999);
      query = query.where('entryDate', '<=', endDate.toISOString());
    }

    const snap = await query.get();
    let rawEntries = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    // In-memory filters for fields that would require N×M composite indexes
    if (req.query.entryType) {
      rawEntries = rawEntries.filter((e) => e.entryType === req.query.entryType);
    }
    if (req.query.isReconciled !== undefined && req.query.isReconciled !== '') {
      const wantReconciled = req.query.isReconciled === 'true';
      rawEntries = rawEntries.filter((e) => Boolean(e.isReconciled) === wantReconciled);
    }

    // Compute running balance from opening balance
    const openingBalance = Number(account.openingBalance) || 0;
    const balanceType    = account.balanceType || 'debit';
    let runningBalance   = openingBalance;
    let totalDebits      = 0;
    let totalCredits     = 0;

    const entries = rawEntries.map((entry) => {
      const amount = Number(entry.amount) || 0;
      if (entry.entryType === 'debit') {
        totalDebits   += amount;
        // Debit-normal accounts: debits increase, credits decrease
        runningBalance = balanceType === 'debit'
          ? runningBalance + amount
          : runningBalance - amount;
      } else {
        totalCredits  += amount;
        // Credit-normal accounts: credits increase, debits decrease
        runningBalance = balanceType === 'credit'
          ? runningBalance + amount
          : runningBalance - amount;
      }
      return { ...entry, runningBalance };
    });

    log('INFO', `GET /accounts/ledger/by-account/${accountId} → ${entries.length} entries`, { uid });
    return ok(res, {
      account,
      entries,
      openingBalance,
      totalDebits,
      totalCredits,
      closingBalance: runningBalance,
    });
  } catch (e) {
    log('ERROR', `GET /accounts/ledger/by-account/${accountId} failed`, { uid, error: e.message });
    return fail(res, e.message || 'Failed to fetch ledger', e.statusCode || 500);
  }
});

// GET /ledger/summary — aggregate totals per account for all accounts that have entries
router.get('/ledger/summary', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'GET /accounts/ledger/summary', { uid });
  try {
    const [entriesSnap, accountsSnap] = await Promise.all([
      accountsCollection(uid, 'ledgerEntries').get(),
      settingsCollection(uid, 'accounts').get(),
    ]);

    const accountMap = {};
    accountsSnap.docs.forEach((d) => { accountMap[d.id] = { id: d.id, ...d.data() }; });

    const byAccount = {};
    entriesSnap.docs.forEach((d) => {
      const entry = d.data();
      const aId   = entry.accountId;
      if (!aId) return;
      if (!byAccount[aId]) byAccount[aId] = { totalDebits: 0, totalCredits: 0 };
      const amount = Number(entry.amount) || 0;
      if (entry.entryType === 'debit')  byAccount[aId].totalDebits  += amount;
      if (entry.entryType === 'credit') byAccount[aId].totalCredits += amount;
    });

    const summary = Object.keys(byAccount).map((aId) => {
      const acc         = accountMap[aId] || {};
      const openingBal  = Number(acc.openingBalance) || 0;
      const balanceType = acc.balanceType || 'debit';
      const { totalDebits, totalCredits } = byAccount[aId];
      const closing = balanceType === 'debit'
        ? openingBal + totalDebits - totalCredits
        : openingBal + totalCredits - totalDebits;
      return {
        accountId:      aId,
        accountName:    acc.accountName  || '',
        accountCode:    acc.accountCode  || '',
        accountType:    acc.accountType  || '',
        openingBalance: openingBal,
        totalDebits,
        totalCredits,
        closingBalance: closing,
      };
    });

    log('INFO', `GET /accounts/ledger/summary → ${summary.length} accounts`, { uid });
    return ok(res, summary);
  } catch (e) {
    log('ERROR', 'GET /accounts/ledger/summary failed', { uid, error: e.message });
    return fail(res, e.message || 'Failed to fetch summary', e.statusCode || 500);
  }
});

// POST /ledger/next-entry-no — suggest next JV-NNNN number
router.post('/ledger/next-entry-no', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'POST /accounts/ledger/next-entry-no', { uid });
  try {
    const snap = await accountsCollection(uid, 'ledgerEntries').get();
    let max = 0;
    snap.docs.forEach((d) => {
      const no    = d.data().entryNo || '';
      const match = no.match(/^JV-(\d+)$/);
      if (match) {
        const n = parseInt(match[1], 10);
        if (n > max) max = n;
      }
    });
    const nextEntryNo = `JV-${String(max + 1).padStart(4, '0')}`;
    log('INFO', `POST /accounts/ledger/next-entry-no → ${nextEntryNo}`, { uid });
    return ok(res, { nextEntryNo });
  } catch (e) {
    log('ERROR', 'POST /accounts/ledger/next-entry-no failed', { uid, error: e.message });
    return fail(res, e.message || 'Failed to compute next entry no', e.statusCode || 500);
  }
});

// ─── CRUD sub-router ──────────────────────────────────────────────────────────
// Fetch-all then in-memory filter to avoid needing compound Firestore indexes.

function createCrudRouter(config) {
  const e = config.entity;
  const r = express.Router();

  // List — fetch all, sort desc by createdAt, filter in-memory
  r.get('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /accounts/${e}`, { uid, query: req.query });
    try {
      const snap  = await accountsCollection(uid, e).orderBy('createdAt', 'desc').get();
      let items   = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

      // In-memory filters (avoids N compound Firestore indexes)
      if (req.query.accountId) {
        items = items.filter((i) => i.accountId === req.query.accountId);
      }
      if (req.query.entryType) {
        items = items.filter((i) => i.entryType === req.query.entryType);
      }
      if (req.query.isReconciled !== undefined && req.query.isReconciled !== '') {
        const want = req.query.isReconciled === 'true';
        items = items.filter((i) => Boolean(i.isReconciled) === want);
      }

      log('INFO', `GET /accounts/${e} → ${items.length} records`, { uid });
      return ok(res, items);
    } catch (err2) {
      log('ERROR', `GET /accounts/${e} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to fetch', err2.statusCode || 500);
    }
  });

  // Get single
  r.get('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /accounts/${e}/${req.params.id}`, { uid });
    try {
      const snap = await accountsCollection(uid, e).doc(req.params.id).get();
      if (!snap.exists) {
        log('WARN', `GET /accounts/${e}/${req.params.id} → 404`, { uid });
        return fail(res, 'Not found', 404);
      }
      return ok(res, { id: snap.id, ...snap.data() });
    } catch (err2) {
      log('ERROR', `GET /accounts/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to fetch', err2.statusCode || 500);
    }
  });

  // Create
  r.post('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `POST /accounts/${e}`, { uid, body: req.body });
    try {
      const { data, errors } = await config.sanitize({ uid, body: req.body || {} });
      if (errors.length) {
        log('WARN', `POST /accounts/${e} validation failed`, { uid, errors });
        return fail(res, errors.join('; '), 400);
      }
      const docRef  = accountsCollection(uid, e).doc();
      const payload = stampNew(uid, data);
      await docRef.set(payload);
      log('INFO', `POST /accounts/${e} → created ${docRef.id}`, { uid });
      return ok(res, { id: docRef.id, ...payload }, 201);
    } catch (err2) {
      log('ERROR', `POST /accounts/${e} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to create', err2.statusCode || 500);
    }
  });

  // Update
  r.put('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `PUT /accounts/${e}/${req.params.id}`, { uid, body: req.body });
    try {
      const docRef = accountsCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) {
        log('WARN', `PUT /accounts/${e}/${req.params.id} → 404`, { uid });
        return fail(res, 'Not found', 404);
      }
      const { data, errors } = await config.sanitize({ uid, body: req.body || {}, id: req.params.id });
      if (errors.length) {
        log('WARN', `PUT /accounts/${e}/${req.params.id} validation failed`, { uid, errors });
        return fail(res, errors.join('; '), 400);
      }
      const payload = stampUpdated(snap.data(), data);
      await docRef.set(payload, { merge: false });
      log('INFO', `PUT /accounts/${e}/${req.params.id} → updated`, { uid });
      return ok(res, { id: docRef.id, ...payload });
    } catch (err2) {
      log('ERROR', `PUT /accounts/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to update', err2.statusCode || 500);
    }
  });

  // Delete
  r.delete('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `DELETE /accounts/${e}/${req.params.id}`, { uid });
    try {
      const docRef = accountsCollection(uid, e).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) {
        log('WARN', `DELETE /accounts/${e}/${req.params.id} → 404`, { uid });
        return fail(res, 'Not found', 404);
      }
      await docRef.delete();
      log('INFO', `DELETE /accounts/${e}/${req.params.id} → deleted`, { uid });
      return ok(res, { id: req.params.id });
    } catch (err2) {
      log('ERROR', `DELETE /accounts/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return fail(res, err2.message || 'Failed to delete', err2.statusCode || 500);
    }
  });

  return r;
}

// Mount AFTER the specific routes — Express checks in registration order.
// /ledger/by-account/:id, /ledger/summary, /ledger/next-entry-no are caught first.
// Remaining /ledger/* paths fall through to the CRUD sub-router.
router.use('/ledger', createCrudRouter(ledgerEntryConfig));

module.exports = router;
