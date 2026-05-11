const { getDb } = require('./firebase');

/**
 * Returns a scoped collection reference: farms/{farmId}/{collection}
 * Use in all business repositories.
 */
function farmCol(farmId, col) {
  const db = getDb();
  if (!db) {
    throw new Error('Firebase not initialized');
  }

  return db.collection('farms').doc(farmId).collection(col);
}

module.exports = { farmCol };