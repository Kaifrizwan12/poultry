const { getDb } = require('../core/firebase/firebase');

function requireDb() {
  const db = getDb();
  if (!db) {
    const error = new Error('Firestore is not initialized');
    error.statusCode = 503;
    throw error;
  }
  return db;
}

function settingsEntityDoc(uid, entity) {
  return requireDb()
    .collection('users')
    .doc(uid)
    .collection('settings')
    .doc(entity);
}

function settingsCollection(uid, entity) {
  return settingsEntityDoc(uid, entity).collection('items');
}

async function ensureExists(uid, entity, id) {
  if (!id) {
    return false;
  }

  const snapshot = await settingsCollection(uid, entity).doc(id).get();
  return snapshot.exists;
}

module.exports = {
  requireDb,
  settingsEntityDoc,
  settingsCollection,
  ensureExists,
};
