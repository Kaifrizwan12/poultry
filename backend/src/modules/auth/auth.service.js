const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { randomBytes, randomUUID } = require('crypto');
const { getAuth, init } = require('../../core/firebase/firebase');
const { AuthRepository } = require('./auth.repository');
const { jwtSecret } = require('../../core/config');

const RESET_EXP_MS = 1000 * 60 * 60;
const ACCESS_TTL = '15m';
const REFRESH_TTL_MS = 30 * 24 * 3600 * 1000;

class AuthService {
  constructor(repository = new AuthRepository()) {
    this.repository = repository;
    init();
    this.auth = getAuth();
  }

  createToken(uid, farmId = null) {
    const jti = randomUUID();
    return jwt.sign({ uid, farmId, jti }, jwtSecret, { expiresIn: ACCESS_TTL });
  }

  tokenExpiry() {
    return new Date(Date.now() + 15 * 60 * 1000).toISOString();
  }

  async generateRefreshToken(uid, farmId = null) {
    const token = randomBytes(40).toString('hex');
    const expiresAt = Date.now() + REFRESH_TTL_MS;
    await this.repository.createRefreshToken(token, {
      uid,
      farmId,
      expiresAt,
      createdAt: Date.now(),
    });
    return token;
  }

  async register({ name, email, password, farmType }) {
    const user = await this.auth.createUser({
      email,
      password,
      displayName: name,
    });

    const passwordHash = await bcrypt.hash(password, 12);
    await this.repository.createUser(user.uid, {
      name,
      email,
      farmType,
      passwordHash,
      createdAt: new Date(),
    });

    return {
      token: this.createToken(user.uid),
      expiresAt: this.tokenExpiry(),
      refreshToken: await this.generateRefreshToken(user.uid),
      user: { uid: user.uid, name, email, farmType },
    };
  }

  async login({ email, password }) {
    const user = await this.auth.getUserByEmail(email);
    const data = await this.repository.getUser(user.uid);
    if (!data) {
      return { error: 'not found', status: 404 };
    }

    const ok = await bcrypt.compare(password, data.passwordHash);
    if (!ok) {
      return { error: 'invalid credentials', status: 401 };
    }

    return {
      token: this.createToken(user.uid, data.farmId || null),
      expiresAt: this.tokenExpiry(),
      refreshToken: await this.generateRefreshToken(user.uid, data.farmId || null),
      user: {
        uid: user.uid,
        name: data.name || user.displayName,
        email: data.email || user.email,
        farmType: data.farmType,
      },
    };
  }

  async getProfile(uid) {
    const data = await this.repository.getUser(uid);
    if (!data) {
      return { error: 'not found', status: 404 };
    }
    return { user: data };
  }

  async changePassword(uid, oldPassword, newPassword) {
    const data = await this.repository.getUser(uid);
    if (!data) {
      return { error: 'not found', status: 404 };
    }

    const ok = await bcrypt.compare(oldPassword, data.passwordHash);
    if (!ok) {
      return { error: 'invalid old password', status: 401 };
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.repository.updateUser(uid, { passwordHash });
    await this.auth.updateUser(uid, { password: newPassword });

    return { ok: true };
  }

  async forgot(email) {
    const user = await this.auth.getUserByEmail(email);
    const token = randomBytes(20).toString('hex');
    const expiresAt = Date.now() + RESET_EXP_MS;
    await this.repository.createPasswordReset(token, {
      uid: user.uid,
      expiresAt,
    });

    return { ok: true, token };
  }

  async refresh(refreshToken) {
    const data = await this.repository.getRefreshToken(refreshToken);
    if (!data) {
      return { error: 'invalid', status: 401 };
    }

    if (Date.now() > data.expiresAt) {
      await this.repository.deleteRefreshToken(refreshToken);
      return { error: 'expired', status: 401 };
    }

    await this.repository.deleteRefreshToken(refreshToken);
    const newRefresh = await this.generateRefreshToken(data.uid, data.farmId || null);

    return {
      token: this.createToken(data.uid, data.farmId || null),
      expiresAt: this.tokenExpiry(),
      refreshToken: newRefresh,
    };
  }

  async logout(token) {
    try {
      const payload = jwt.decode(token);
      if (payload?.jti) {
        await this.repository.revokeToken(payload.jti, payload.exp);
      }
    } catch (_) {}

    return { ok: true };
  }

  async reset(token, newPassword) {
    const data = await this.repository.getPasswordReset(token);
    if (!data) {
      return { error: 'invalid', status: 400 };
    }

    if (Date.now() > data.expiresAt) {
      return { error: 'expired', status: 400 };
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.repository.updateUser(data.uid, { passwordHash });
    await this.auth.updateUser(data.uid, { password: newPassword });
    await this.repository.deletePasswordReset(token);

    return { ok: true };
  }
}

module.exports = { AuthService };
