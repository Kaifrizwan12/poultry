const express = require('express');
const { poultryCollection } = require('./poultry.validators');
const { stampNew, stampUpdated } = require('./poultry.validators');
const { getFlockStatus, getDemandAnalysis, updateFlockCurrentBirds } = require('./poultry.service');
const { getDb } = require('../../core/firebase/firebase');
const { log } = require('../../core/logger');

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
    return ok(res, { id: savedId, ...savedPayload });
  } catch (e) { log('ERROR', 'POST /poultry/chicken-invoices failed', { uid, error: e.message }); return err(res, e.message || 'Failed to create', e.statusCode || 500); }
});

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

// Soft-cancel only — set status to cancelled, do not restore bird count
router.delete('/chicken-invoices/:id', async (req, res) => {
  const uid = req.user.uid;
  log('INFO', `DELETE /poultry/chicken-invoices/${req.params.id} (soft-cancel)`, { uid });
  try {
    const docRef = poultryCollection(uid, 'chickenInvoices').doc(req.params.id);
    const snap   = await docRef.get();
    if (!snap.exists) { log('WARN', `DELETE /poultry/chicken-invoices/${req.params.id} → 404`, { uid }); return err(res, 'Not found', 404); }
    await docRef.update({ status: 'cancelled', cancelledAt: new Date().toISOString() });
    log('INFO', `DELETE /poultry/chicken-invoices/${req.params.id} → cancelled`, { uid });
    return ok(res, { id: req.params.id });
  } catch (e) { log('ERROR', `DELETE /poultry/chicken-invoices/${req.params.id} failed`, { uid, error: e.message }); return err(res, e.message || 'Failed to cancel', e.statusCode || 500); }
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
