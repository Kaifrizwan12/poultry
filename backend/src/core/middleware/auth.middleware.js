const jwt = require('jsonwebtoken');

const { jwtSecret } = require('../config');
const { getDb } = require('../firebase/firebase');

async function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'unauth' });
  }

  const token = header.slice(7);
  let payload;

  try {
    payload = jwt.verify(token, jwtSecret);
  } catch (e) {
    const code = e.name === 'TokenExpiredError' ? 'expired' : 'invalid';
    return res.status(401).json({ error: code });
  }

  const db = getDb();
  if (!db) {
    return res.status(503).json({ error: 'auth_unavailable' });
  }

  if (payload.jti) {
    const doc = await db.collection('revokedTokens').doc(payload.jti).get();
    if (doc.exists) {
      return res.status(401).json({ error: 'revoked' });
    }
  }

  req.user = { uid: payload.uid, farmId: payload.farmId || null };
  return next();
}

module.exports = { authenticate };