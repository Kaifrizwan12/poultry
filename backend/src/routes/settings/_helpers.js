const express = require('express');
const {
  settingsCollection,
  settingsEntityDoc,
} = require('../../utils/firestore');
const {
  settingsConfigs,
  stampNewDocument,
  stampUpdatedDocument,
} = require('../../models/settings.config');

function success(res, data, statusCode) {
  return res.status(statusCode || 200).json({ success: true, data });
}

function failure(res, error, statusCode) {
  return res.status(statusCode || 400).json({ success: false, error });
}

function createEntityRouter(configKey) {
  const router = express.Router();
  const config = settingsConfigs[configKey];

  if (!config) {
    throw new Error(`Unknown settings config: ${configKey}`);
  }

  router.get('/', async (req, res) => {
    try {
      const snapshot = await settingsCollection(req.user.uid, config.entity)
        .orderBy('createdAt', 'desc')
        .get();

      const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      return success(res, data);
    } catch (error) {
      return failure(res, error.message || 'Failed to fetch items', error.statusCode || 500);
    }
  });

  router.post('/', async (req, res) => {
    try {
      const { data, errors } = await config.sanitize({
        uid: req.user.uid,
        body: req.body || {},
      });

      if (errors.length) {
        return failure(res, errors.join(', '), 400);
      }

      const collection = settingsCollection(req.user.uid, config.entity);
      const docRef = collection.doc();
      const payload = stampNewDocument(req.user.uid, data);

      await docRef.set(payload);
      await settingsEntityDoc(req.user.uid, config.entity).set(
        {
          entity: config.entity,
          updatedAt: payload.updatedAt,
        },
        { merge: true }
      );

      return success(res, { id: docRef.id, ...payload }, 200);
    } catch (error) {
      return failure(res, error.message || 'Failed to create item', error.statusCode || 500);
    }
  });

  router.put('/:id', async (req, res) => {
    try {
      const docRef = settingsCollection(req.user.uid, config.entity).doc(req.params.id);
      const snapshot = await docRef.get();
      if (!snapshot.exists) {
        return failure(res, 'Record not found', 404);
      }

      const { data, errors } = await config.sanitize({
        uid: req.user.uid,
        body: req.body || {},
        id: req.params.id,
      });

      if (errors.length) {
        return failure(res, errors.join(', '), 400);
      }

      const payload = stampUpdatedDocument(snapshot.data(), data);
      await docRef.set(payload, { merge: false });

      return success(res, { id: docRef.id, ...payload });
    } catch (error) {
      return failure(res, error.message || 'Failed to update item', error.statusCode || 500);
    }
  });

  router.delete('/:id', async (req, res) => {
    try {
      const docRef = settingsCollection(req.user.uid, config.entity).doc(req.params.id);
      const snapshot = await docRef.get();
      if (!snapshot.exists) {
        return failure(res, 'Record not found', 404);
      }
      await docRef.delete();
      return success(res, { id: req.params.id });
    } catch (error) {
      return failure(res, error.message || 'Failed to delete item', error.statusCode || 500);
    }
  });

  return router;
}

module.exports = {
  createEntityRouter,
  success,
  failure,
};
