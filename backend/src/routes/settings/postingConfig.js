// Singleton GET/PUT for posting configuration.
// Stored as a single document at: users/{uid}/settings/postingConfig (not a subcollection).
const express = require('express');
const { settingsEntityDoc } = require('../../utils/firestore');
const { settingsConfigs, stampNewDocument, stampUpdatedDocument } = require('../../models/settings.config');

const router = express.Router();

function ok(res, data) { return res.status(200).json({ success: true, data }); }
function fail(res, msg, code) { return res.status(code || 400).json({ success: false, error: msg }); }

// GET /settings/posting-config
router.get('/', async (req, res) => {
  try {
    const ref  = settingsEntityDoc(req.user.uid, 'postingConfig');
    const snap = await ref.get();
    if (!snap.exists) return ok(res, {});
    return ok(res, { id: snap.id, ...snap.data() });
  } catch (e) {
    return fail(res, e.message || 'Failed to fetch posting config', 500);
  }
});

// PUT /settings/posting-config  (create or replace)
router.put('/', async (req, res) => {
  const uid = req.user.uid;
  try {
    const { data, errors } = await settingsConfigs.postingConfig.sanitize({ uid, body: req.body || {} });
    if (errors.length) return fail(res, errors.join('; '), 400);

    const ref  = settingsEntityDoc(uid, 'postingConfig');
    const snap = await ref.get();
    const payload = snap.exists
      ? stampUpdatedDocument(snap.data(), data)
      : stampNewDocument(uid, data);

    await ref.set(payload, { merge: false });
    return ok(res, { id: ref.id, ...payload });
  } catch (e) {
    return fail(res, e.message || 'Failed to save posting config', 500);
  }
});

module.exports = router;
