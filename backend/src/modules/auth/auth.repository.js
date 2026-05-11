const { getDb } = require('../../core/firebase/firebase');

class AuthRepository {
  constructor() {
    this.db = getDb();
  }

  _ensureDb() {
    if (!this.db) {
      throw new Error('Firebase firestore not initialized');
    }

    return this.db;
  }

  async createUser(uid, data) {
    const db = this._ensureDb();
    await db.collection('users').doc(uid).set(data);
  }

  async getUser(uid) {
    const db = this._ensureDb();
    const doc = await db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  async updateUser(uid, data) {
    const db = this._ensureDb();
    await db.collection('users').doc(uid).update(data);
  }

  async createPasswordReset(token, data) {
    const db = this._ensureDb();
    await db.collection('passwordResets').doc(token).set(data);
  }

  async getPasswordReset(token) {
    const db = this._ensureDb();
    const doc = await db.collection('passwordResets').doc(token).get();
    return doc.exists ? doc.data() : null;
  }

  async deletePasswordReset(token) {
    const db = this._ensureDb();
    await db.collection('passwordResets').doc(token).delete();
  }

  async createRefreshToken(token, data) {
    const db = this._ensureDb();
    await db.collection('refreshTokens').doc(token).set(data);
  }

  async getRefreshToken(token) {
    const db = this._ensureDb();
    const doc = await db.collection('refreshTokens').doc(token).get();
    return doc.exists ? doc.data() : null;
  }

  async deleteRefreshToken(token) {
    const db = this._ensureDb();
    await db.collection('refreshTokens').doc(token).delete();
  }

  async revokeToken(jti, expUnix) {
    const db = this._ensureDb();
    await db.collection('revokedTokens').doc(jti).set({
      revokedAt: Date.now(),
      expiresAt: expUnix * 1000,
    });
  }
}

module.exports = { AuthRepository };
