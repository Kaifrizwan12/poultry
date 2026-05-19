const express = require('express');
const { poultryCollection } = require('./poultry.validators');
const { stampNew, stampUpdated } = require('./poultry.validators');
const { getFlockStatus, getDemandAnalysis, updateFlockCurrentBirds } = require('./poultry.service');
const { getDb } = require('../../core/firebase/firebase');
const { log } = require('../../core/logger');
const { settingsEntityDoc, settingsCollection } = require('../../utils/firestore');
const { nowIso } = require('./poultry.validators');

const feedScheduleConfig   = require('./entities/feed_schedule.config');
const vaccineScheduleConfig = require('./entities/vaccine_schedule.config');
const flockConfig           = require('./entities/flock.config');
const flockFeedConfig       = require('./entities/flock_feed.config');
const flockVaccineConfig    = require('./entities/flock_vaccine.config');
const chickenInvoiceConfig  = require('./entities/chicken_invoice.config');

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
    log('INFO', `GET /poultry/${e}`, { uid, query: req.query });
    try {
      let query = poultryCollection(uid, e).orderBy('createdAt', 'desc');
      if (req.query.status) query = query.where('status', '==', req.query.status);
      if (req.query.flockId) query = query.where('flockId', '==', req.query.flockId);
      const snap = await query.get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      log('INFO', `GET /poultry/${e} → ${items.length} records`, { uid });
      return ok(res, items);
    } catch (err2) {
      log('ERROR', `GET /poultry/${e} failed`, { uid, error: err2.message });
      return err(res, err2.message || 'Failed to fetch', err2.statusCode || 500);
    }
  });

  // Get single
  r.get('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `GET /poultry/${e}/${req.params.id}`, { uid });
    try {
      const snap = await poultryCollection(uid, e).doc(req.params.id).get();
      if (!snap.exists) { log('WARN', `GET /poultry/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      log('INFO', `GET /poultry/${e}/${req.params.id} → found`, { uid });
      return ok(res, { id: snap.id, ...snap.data() });
    } catch (err2) {
      log('ERROR', `GET /poultry/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return err(res, err2.message || 'Failed to fetch', err2.statusCode || 500);
    }
  });

  // Create
  r.post('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `POST /poultry/${e}`, { uid, body: req.body });
    try {
      const { data, errors } = await config.sanitize({ uid, body: req.body || {} });
      if (errors.length) { log('WARN', `POST /poultry/${e} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
      const col = poultryCollection(uid, e);
      const docRef = col.doc();
      const payload = stampNew(uid, data);
      await docRef.set(payload);
      log('INFO', `POST /poultry/${e} → created ${docRef.id}`, { uid });
      return ok(res, { id: docRef.id, ...payload });
    } catch (err2) {
      log('ERROR', `POST /poultry/${e} failed`, { uid, error: err2.message });
      return err(res, err2.message || 'Failed to create', err2.statusCode || 500);
    }
  });

  // Update
  r.put('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `PUT /poultry/${e}/${req.params.id}`, { uid, body: req.body });
    try {
      const docRef = poultryCollection(uid, e).doc(req.params.id);
      const snap = await docRef.get();
      if (!snap.exists) { log('WARN', `PUT /poultry/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      const { data, errors } = await config.sanitize({ uid, body: req.body || {}, id: req.params.id });
      if (errors.length) { log('WARN', `PUT /poultry/${e}/${req.params.id} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
      const payload = stampUpdated(snap.data(), data);
      await docRef.set(payload, { merge: false });
      log('INFO', `PUT /poultry/${e}/${req.params.id} → updated`, { uid });
      return ok(res, { id: docRef.id, ...payload });
    } catch (err2) {
      log('ERROR', `PUT /poultry/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return err(res, err2.message || 'Failed to update', err2.statusCode || 500);
    }
  });

  // Delete
  r.delete('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `DELETE /poultry/${e}/${req.params.id}`, { uid });
    try {
      const docRef = poultryCollection(uid, e).doc(req.params.id);
      const snap = await docRef.get();
      if (!snap.exists) { log('WARN', `DELETE /poultry/${e}/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      await docRef.delete();
      log('INFO', `DELETE /poultry/${e}/${req.params.id} → deleted`, { uid });
      return ok(res, { id: req.params.id });
    } catch (err2) {
      log('ERROR', `DELETE /poultry/${e}/${req.params.id} failed`, { uid, error: err2.message });
      return err(res, err2.message || 'Failed to delete', err2.statusCode || 500);
    }
  });

  return r;
}

// ─── Feed Schedules ───────────────────────────────────────────────────────────
router.use('/feed-schedules', createCrudRouter(feedScheduleConfig));

// ─── Vaccine Schedules ────────────────────────────────────────────────────────
router.use('/vaccine-schedules', createCrudRouter(vaccineScheduleConfig));

// ─── Flocks (custom: prevent delete when child records exist) ─────────────────
const flockCrudRouter = createCrudRouter(flockConfig);

// Override DELETE to check child records
flockCrudRouter.delete('/:id', async (req, res) => {
  const uid = req.user.uid;
  const id  = req.params.id;
  log('INFO', `DELETE /poultry/flocks/${id} (with child-check)`, { uid });
  try {
    const docRef = poultryCollection(uid, 'flocks').doc(id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `DELETE /poultry/flocks/${id} → 404`, { uid }); return err(res, 'Not found', 404); }

    const [feedSnap, vacSnap, invSnap] = await Promise.all([
      poultryCollection(uid, 'flockFeeds').where('flockId', '==', id).limit(1).get(),
      poultryCollection(uid, 'flockVaccines').where('flockId', '==', id).limit(1).get(),
      poultryCollection(uid, 'chickenInvoices').where('flockId', '==', id).limit(1).get(),
    ]);
    if (!feedSnap.empty || !vacSnap.empty || !invSnap.empty) {
      log('WARN', `DELETE /poultry/flocks/${id} blocked — child records exist`, { uid });
      return err(res, 'Cannot delete flock with existing feed, vaccine or invoice records', 409);
    }

    await docRef.delete();
    log('INFO', `DELETE /poultry/flocks/${id} → deleted`, { uid });
    return ok(res, { id });
  } catch (e) { log('ERROR', `DELETE /poultry/flocks/${id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to delete', e.statusCode || 500); }
});

router.use('/flocks', flockCrudRouter);

// ─── Flock Feeds (after save: update flock currentBirdsCount) ─────────────────
const flockFeedRouter = createCrudRouter(flockFeedConfig);

// Override POST/PUT to update flock count after save
function withFlockCountUpdate(handler) {
  return async (req, res) => {
    const origJson = res.json.bind(res);
    let savedFlockId = null;
    res.json = (body) => {
      if (body && body.success && body.data && body.data.flockId) {
        savedFlockId = body.data.flockId;
      }
      return origJson(body);
    };
    await handler(req, res);
    if (savedFlockId) {
      try { await updateFlockCurrentBirds(req.user.uid, savedFlockId); } catch (_) {}
    }
  };
}

router.use('/flock-feeds', (() => {
  const r = express.Router();
  r.get('/',    async (req, res) => flockFeedRouter.handle(req, res));
  r.get('/:id', async (req, res) => flockFeedRouter.handle(req, res));
  r.post('/', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', 'POST /poultry/flock-feeds', { uid, body: req.body });
    try {
      const { data, errors } = await flockFeedConfig.sanitize({ uid, body: req.body || {} });
      if (errors.length) { log('WARN', 'POST /poultry/flock-feeds validation failed', { uid, errors }); return err(res, errors.join('; '), 400); }
      const col    = poultryCollection(uid, flockFeedConfig.entity);
      const docRef = col.doc();
      const payload = stampNew(uid, data);
      await docRef.set(payload);
      await updateFlockCurrentBirds(uid, data.flockId);
      log('INFO', `POST /poultry/flock-feeds → created ${docRef.id}`, { uid, flockId: data.flockId });
      return ok(res, { id: docRef.id, ...payload });
    } catch (e) { log('ERROR', 'POST /poultry/flock-feeds failed', { uid, error: e.message }); return err(res, e.message || 'Failed to create', e.statusCode || 500); }
  });
  r.put('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `PUT /poultry/flock-feeds/${req.params.id}`, { uid, body: req.body });
    try {
      const docRef = poultryCollection(uid, flockFeedConfig.entity).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) { log('WARN', `PUT /poultry/flock-feeds/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      const { data, errors } = await flockFeedConfig.sanitize({ uid, body: req.body || {}, id: req.params.id });
      if (errors.length) { log('WARN', `PUT /poultry/flock-feeds/${req.params.id} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
      const payload = stampUpdated(snap.data(), data);
      await docRef.set(payload, { merge: false });
      await updateFlockCurrentBirds(uid, data.flockId);
      log('INFO', `PUT /poultry/flock-feeds/${req.params.id} → updated`, { uid, flockId: data.flockId });
      return ok(res, { id: docRef.id, ...payload });
    } catch (e) { log('ERROR', `PUT /poultry/flock-feeds/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to update', e.statusCode || 500); }
  });
  r.delete('/:id', async (req, res) => {
    const uid = req.user.uid;
    log('INFO', `DELETE /poultry/flock-feeds/${req.params.id}`, { uid });
    try {
      const docRef = poultryCollection(uid, flockFeedConfig.entity).doc(req.params.id);
      const snap   = await docRef.get();
      if (!snap.exists) { log('WARN', `DELETE /poultry/flock-feeds/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
      const flockId = snap.data().flockId;
      await docRef.delete();
      if (flockId) await updateFlockCurrentBirds(uid, flockId);
      log('INFO', `DELETE /poultry/flock-feeds/${req.params.id} → deleted`, { uid, flockId });
      return ok(res, { id: req.params.id });
    } catch (e) { log('ERROR', `DELETE /poultry/flock-feeds/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to delete', e.statusCode || 500); }
  });
  return r;
})());

// ─── Flock Vaccines ───────────────────────────────────────────────────────────
router.use('/flock-vaccines', createCrudRouter(flockVaccineConfig));

// ─── Chicken Invoices (transactional bird count decrement) ────────────────────
router.get('/chicken-invoices', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'GET /poultry/chicken-invoices', { uid, query: req.query });
  try {
    let query = poultryCollection(uid, 'chickenInvoices').orderBy('createdAt', 'desc');
    if (req.query.flockId) query = query.where('flockId', '==', req.query.flockId);
    const snap = await query.get();
    const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    log('INFO', `GET /poultry/chicken-invoices → ${items.length} records`, { uid });
    return ok(res, items);
  } catch (e) { log('ERROR', 'GET /poultry/chicken-invoices failed', { uid, error: e.message }); return err(res, e.message || 'Failed to fetch', e.statusCode || 500); }
});

router.get('/chicken-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `GET /poultry/chicken-invoices/${req.params.id}`, { uid });
  try {
    const snap = await poultryCollection(uid, 'chickenInvoices').doc(req.params.id).get();
    if (!snap.exists) { log('WARN', `GET /poultry/chicken-invoices/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
    log('INFO', `GET /poultry/chicken-invoices/${req.params.id} → found`, { uid });
    return ok(res, { id: snap.id, ...snap.data() });
  } catch (e) { log('ERROR', `GET /poultry/chicken-invoices/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to fetch', e.statusCode || 500); }
});

router.post('/chicken-invoices', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'POST /poultry/chicken-invoices', { uid, body: req.body });
  try {
    const { data, errors } = await chickenInvoiceConfig.sanitize({ uid, body: req.body || {} });
    if (errors.length) { log('WARN', 'POST /poultry/chicken-invoices validation failed', { uid, errors }); return err(res, errors.join('; '), 400); }

    const db = getDb();
    let savedId;
    let savedPayload;

    await db.runTransaction(async (tx) => {
      const flockRef = poultryCollection(uid, 'flocks').doc(data.flockId);
      const flockSnap = await tx.get(flockRef);
      if (!flockSnap.exists) throw Object.assign(new Error('Flock not found'), { statusCode: 404 });

      const currentBirds = flockSnap.data().currentBirdsCount ?? 0;
      log('INFO', `POST /poultry/chicken-invoices — flock ${data.flockId} has ${currentBirds} birds, selling ${data.birdsCount}`, { uid });
      if (data.birdsCount > currentBirds) {
        throw Object.assign(
          new Error(`Only ${currentBirds} birds available in this flock`),
          { statusCode: 400 }
        );
      }

      const newCount = currentBirds - data.birdsCount;
      const flockUpdate = { currentBirdsCount: newCount };
      if (newCount <= 0) {
        flockUpdate.status = 'sold';
        flockUpdate.closureDate = data.invoiceDate;
        log('INFO', `POST /poultry/chicken-invoices — flock ${data.flockId} marked sold`, { uid });
      }

      const invRef = poultryCollection(uid, 'chickenInvoices').doc();
      const payload = stampNew(uid, data);
      tx.set(invRef, payload);
      tx.update(flockRef, flockUpdate);

      savedId      = invRef.id;
      savedPayload = payload;
    });

    log('INFO', `POST /poultry/chicken-invoices → created ${savedId}`, { uid, flockId: data.flockId });

    // ── Optional cross-module integrations ────────────────────────────────────
    const postUpdates = {};

    // 1. Create Sales Invoice in invoicing module (when toggle is on)
    if (data.createSalesInvoice) {
      try {
        const linkedSiId = await _chickenInvoiceToSalesInvoice(uid, savedId, savedPayload);
        if (linkedSiId) {
          postUpdates.linkedSalesInvoiceId = linkedSiId;
          log('INFO', `POST /poultry/chicken-invoices → created linked SI ${linkedSiId}`, { uid });
        }
      } catch (siErr) {
        log('WARN', `POST /poultry/chicken-invoices → createSalesInvoice failed: ${siErr.message}`, { uid });
      }
    }

    // 2. Post ledger entries (when toggle is on)
    if (data.postToLedger) {
      try {
        const entryIds = await _chickenInvoiceToLedger(uid, savedId, savedPayload, postUpdates.linkedSalesInvoiceId);
        postUpdates.linkedLedgerEntryIds = entryIds;
        log('INFO', `POST /poultry/chicken-invoices → posted ${entryIds.length} ledger entries`, { uid });
      } catch (ledgerErr) {
        log('WARN', `POST /poultry/chicken-invoices → postToLedger failed: ${ledgerErr.message}`, { uid });
      }
    }

    // Persist integration references back on the chicken invoice document
    if (Object.keys(postUpdates).length) {
      await poultryCollection(uid, 'chickenInvoices').doc(savedId).update({
        ...postUpdates, updatedAt: nowIso(),
      });
      Object.assign(savedPayload, postUpdates);
    }

    return ok(res, { id: savedId, ...savedPayload });
  } catch (e) { log('ERROR', 'POST /poultry/chicken-invoices failed', { uid, error: e.message }); return err(res, e.message || 'Failed to create', e.statusCode || 500); }
});

// ── Chicken invoice integration helpers ────────────────────────────────────────

async function _getPostingConfig(uid) {
  const snap = await settingsEntityDoc(uid, 'postingConfig').get();
  return snap.exists ? snap.data() : {};
}

async function _chickenInvoiceToSalesInvoice(uid, chickenInvId, ci) {
  const db      = getDb();
  const cfg     = await _getPostingConfig(uid);
  const { invoicingCollection, nextBusinessId, stampNew: iStampNew } =
    require('../invoicing/invoicing.validators');

  const chickenProductId = cfg.chickenProductId || '';
  if (!chickenProductId) {
    log('WARN', '_chickenInvoiceToSalesInvoice — chickenProductId not configured in postingConfig', { uid });
    return null;
  }

  // Fetch product, customer, and salesman details in parallel
  const [productSnap, customerSnap, salesmanSnap] = await Promise.all([
    settingsCollection(uid, 'products').doc(chickenProductId).get(),
    ci.customerId  ? settingsCollection(uid, 'customers').doc(ci.customerId).get()  : Promise.resolve(null),
    ci.salesmanId  ? settingsCollection(uid, 'salesmen').doc(ci.salesmanId).get()   : Promise.resolve(null),
  ]);

  if (!productSnap.exists) {
    log('WARN', `_chickenInvoiceToSalesInvoice — product ${chickenProductId} not found`, { uid });
    return null;
  }
  const product      = productSnap.data();
  const customerName = (customerSnap && customerSnap.exists) ? (customerSnap.data().name || '') : '';
  const salesmanName = (salesmanSnap && salesmanSnap.exists) ? (salesmanSnap.data().name || '') : '';

  const saleId   = await nextBusinessId(uid, 'salesInvoices', 'SI');
  const ts       = nowIso();

  // Build a single-line Sales Invoice mirroring the chicken sale
  const lineGross = ci.totalAmount;
  const siPayload = {
    saleId,
    entryDate:    ci.invoiceDate ? ci.invoiceDate.substring(0, 10) : ts.substring(0, 10),
    customerId:   ci.customerId,
    customerName,
    salesmanId:   ci.salesmanId || '',
    salesmanName,
    townId: '', sectorId: '',
    prevDebit:    0,
    status:       'saved',
    items: [{
      sNo:           1,
      productId:     chickenProductId,
      productName:   product.name || 'Live Chickens',
      packingName:   '',
      pack:          1,
      unit:          '',
      qtyPacks:      ci.birdsCount || 0,
      qtyLoose:      0,
      bonus:         0,
      price:         ci.pricePerKg || 0,
      discPercent:   ci.discountPercent || 0,
      salesTaxPercent: ci.taxPercent || 0,
      lineGross,
      lineDisc:      ci.discountAmount || 0,
      lineNet:       ci.netAmount || 0,
      lineTax:       ci.taxAmount || 0,
      lineValueIncST: ci.totalAmount || 0,
    }],
    gross:        lineGross,
    disc2Percent: 0,
    discounts:    ci.discountAmount || 0,
    invoiceValue: ci.netAmount || 0,
    salesTax:     ci.taxAmount || 0,
    fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue:     ci.totalAmount || 0,
    totalPayable: ci.totalAmount || 0,
    ttlQty:       ci.birdsCount || 0,
    paidAmount:   ci.advanceReceived || 0,
    remBalance:   ci.balanceDue || 0,
    description:  `Auto-created from Chicken Invoice ${ci.invoiceNo}`,
    remarks:      '',
    linkedChickenInvoiceId: chickenInvId,
    uid, createdAt: ts, updatedAt: ts,
  };

  const siCol  = invoicingCollection(uid, 'salesInvoices');
  const siRef  = siCol.doc();
  await siRef.set(siPayload);
  return siRef.id;
}

async function _chickenInvoiceToLedger(uid, chickenInvId, ci, linkedSiId) {
  const db  = getDb();
  const cfg = await _getPostingConfig(uid);
  const { accountsCollection } = require('../accounts/accounts.validators');

  const arAccountId       = cfg.arAccountId || '';
  const salesRevAccountId = cfg.salesRevenueAccountId || '';

  if (!arAccountId || !salesRevAccountId) {
    log('WARN', '_chickenInvoiceToLedger — arAccountId or salesRevenueAccountId not configured', { uid });
    return [];
  }

  const ts      = nowIso();
  const entryIds = [];
  const baseNo   = `CI-${ci.invoiceNo}-`;

  // 1. Debit Accounts Receivable (money owed by customer)
  const arRef = accountsCollection(uid, 'ledgerEntries').doc();
  await arRef.set({
    entryNo:       baseNo + 'AR',
    entryDate:     ci.invoiceDate ? ci.invoiceDate.substring(0, 10) : ts.substring(0, 10),
    accountId:     arAccountId,
    entryType:     'debit',
    amount:        ci.totalAmount || 0,
    description:   `Chicken sale — ${ci.invoiceNo} — ${ci.customerName || ''}`,
    referenceType: 'other',
    referenceId:   linkedSiId || chickenInvId,
    referenceNo:   ci.invoiceNo,
    tags:          ['auto-post', 'chicken-invoice'],
    isReconciled:  false,
    reconciledAt:  null,
    notes:         null,
    uid, createdAt: ts, updatedAt: ts,
  });
  entryIds.push(arRef.id);

  // 2. Credit Sales Revenue (must equal the AR debit to keep the journal balanced)
  const srRef = accountsCollection(uid, 'ledgerEntries').doc();
  await srRef.set({
    entryNo:       baseNo + 'SR',
    entryDate:     ci.invoiceDate ? ci.invoiceDate.substring(0, 10) : ts.substring(0, 10),
    accountId:     salesRevAccountId,
    entryType:     'credit',
    amount:        ci.totalAmount || 0,
    description:   `Chicken sale revenue — ${ci.invoiceNo}`,
    referenceType: 'other',
    referenceId:   linkedSiId || chickenInvId,
    referenceNo:   ci.invoiceNo,
    tags:          ['auto-post', 'chicken-invoice'],
    isReconciled:  false,
    reconciledAt:  null,
    notes:         null,
    uid, createdAt: ts, updatedAt: ts,
  });
  entryIds.push(srRef.id);

  // 3. If advance was received, also debit Cash
  if (ci.advanceReceived > 0 && cfg.cashAccountId) {
    const cashRef = accountsCollection(uid, 'ledgerEntries').doc();
    await cashRef.set({
      entryNo:       baseNo + 'CASH',
      entryDate:     ci.invoiceDate ? ci.invoiceDate.substring(0, 10) : ts.substring(0, 10),
      accountId:     cfg.cashAccountId,
      entryType:     'debit',
      amount:        ci.advanceReceived,
      description:   `Advance received — ${ci.invoiceNo}`,
      referenceType: 'other',
      referenceId:   linkedSiId || chickenInvId,
      referenceNo:   ci.invoiceNo,
      tags:          ['auto-post', 'chicken-invoice', 'advance'],
      isReconciled:  false,
      reconciledAt:  null,
      notes:         null,
      uid, createdAt: ts, updatedAt: ts,
    });
    entryIds.push(cashRef.id);

    // Credit AR for advance portion
    const arAdvRef = accountsCollection(uid, 'ledgerEntries').doc();
    await arAdvRef.set({
      entryNo:       baseNo + 'AR-ADV',
      entryDate:     ci.invoiceDate ? ci.invoiceDate.substring(0, 10) : ts.substring(0, 10),
      accountId:     arAccountId,
      entryType:     'credit',
      amount:        ci.advanceReceived,
      description:   `AR reduced by advance — ${ci.invoiceNo}`,
      referenceType: 'other',
      referenceId:   linkedSiId || chickenInvId,
      referenceNo:   ci.invoiceNo,
      tags:          ['auto-post', 'chicken-invoice', 'advance'],
      isReconciled:  false,
      reconciledAt:  null,
      notes:         null,
      uid, createdAt: ts, updatedAt: ts,
    });
    entryIds.push(arAdvRef.id);
  }

  return entryIds;
}

router.put('/chicken-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `PUT /poultry/chicken-invoices/${req.params.id}`, { uid, body: req.body });
  try {
    const docRef = poultryCollection(uid, 'chickenInvoices').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `PUT /poultry/chicken-invoices/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
    const { data, errors } = await chickenInvoiceConfig.sanitize({ uid, body: req.body || {}, id: req.params.id });
    if (errors.length) { log('WARN', `PUT /poultry/chicken-invoices/${req.params.id} validation failed`, { uid, errors }); return err(res, errors.join('; '), 400); }
    const payload = stampUpdated(snap.data(), data);
    await docRef.set(payload, { merge: false });
    log('INFO', `PUT /poultry/chicken-invoices/${req.params.id} → updated`, { uid });
    return ok(res, { id: docRef.id, ...payload });
  } catch (e) { log('ERROR', `PUT /poultry/chicken-invoices/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to update', e.statusCode || 500); }
});

router.delete('/chicken-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `DELETE /poultry/chicken-invoices/${req.params.id}`, { uid });
  try {
    const db      = getDb();
    const docRef  = poultryCollection(uid, 'chickenInvoices').doc(req.params.id);
    const snap    = await docRef.get();
    if (!snap.exists) { log('WARN', `DELETE /poultry/chicken-invoices/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
    const ci = snap.data();

    const { invoicingCollection } = require('../invoicing/invoicing.validators');
    const { accountsCollection }  = require('../accounts/accounts.validators');

    await db.runTransaction(async (tx) => {
      // 1. Restore bird count and flock status
      if (ci.flockId) {
        const flockRef  = poultryCollection(uid, 'flocks').doc(ci.flockId);
        const flockSnap = await tx.get(flockRef);
        if (flockSnap.exists) {
          const fd       = flockSnap.data();
          const restored = (fd.currentBirdsCount || 0) + (ci.birdsCount || 0);
          const flockUpd = { currentBirdsCount: restored, updatedAt: nowIso() };
          if (fd.status === 'sold') { flockUpd.status = 'active'; flockUpd.closureDate = null; }
          tx.update(flockRef, flockUpd);
        }
      }
      // 2. Delete linked sales invoice
      if (ci.linkedSalesInvoiceId) {
        tx.delete(invoicingCollection(uid, 'salesInvoices').doc(ci.linkedSalesInvoiceId));
      }
      // 3. Delete linked ledger entries
      for (const entryId of (ci.linkedLedgerEntryIds || [])) {
        tx.delete(accountsCollection(uid, 'ledgerEntries').doc(entryId));
      }
      // 4. Hard-delete the chicken invoice
      tx.delete(docRef);
    });

    log('INFO', `DELETE /poultry/chicken-invoices/${req.params.id} → deleted (birds restored, SI+ledger cascade)`, { uid });
    return ok(res, { id: req.params.id });
  } catch (e) { log('ERROR', `DELETE /poultry/chicken-invoices/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to delete', e.statusCode || 500); }
});

// ─── Reports ──────────────────────────────────────────────────────────────────

router.get('/reports/flock-status', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'GET /poultry/reports/flock-status', { uid, flockId: req.query.flockId });
  try {
    const { flockId } = req.query;
    if (!flockId) { log('WARN', 'GET /poultry/reports/flock-status — missing flockId', { uid }); return err(res, 'flockId is required', 400); }
    const report = await getFlockStatus(uid, flockId);
    log('INFO', 'GET /poultry/reports/flock-status → generated', { uid, flockId });
    return ok(res, report);
  } catch (e) { log('ERROR', 'GET /poultry/reports/flock-status failed', { uid, error: e.message }); return err(res, e.message || 'Failed to generate report', e.statusCode || 500); }
});

router.get('/reports/demand-analysis', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', 'GET /poultry/reports/demand-analysis', { uid, query: req.query });
  try {
    let flockIds = req.query['flockIds[]'] || req.query.flockIds || [];
    if (!Array.isArray(flockIds)) flockIds = [flockIds];
    const daysAhead = Math.max(1, parseInt(req.query.daysAhead || '7', 10));
    if (!flockIds.length) { log('WARN', 'GET /poultry/reports/demand-analysis — no flockIds', { uid }); return err(res, 'At least one flockId is required', 400); }
    const report = await getDemandAnalysis(uid, flockIds, daysAhead);
    log('INFO', 'GET /poultry/reports/demand-analysis → generated', { uid, flockIds, daysAhead });
    return ok(res, report);
  } catch (e) { log('ERROR', 'GET /poultry/reports/demand-analysis failed', { uid, error: e.message }); return err(res, e.message || 'Failed to generate report', e.statusCode || 500); }
});

module.exports = router;
