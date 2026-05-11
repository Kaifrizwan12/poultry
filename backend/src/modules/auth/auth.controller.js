const jwt = require('jsonwebtoken');
const { AuthService } = require('./auth.service');
const { getFirebaseConfig } = require('../../core/firebase/firebase');
const { jwtSecret } = require('../../core/config');
const { log } = require('../../core/logger');

const service = new AuthService();

exports.getFirebaseConfig = getFirebaseConfig;

exports.register = async (req, res) => {
  const { name, email, password, farmType } = req.body;
  log('INFO', 'POST /register received', { name, email, farmType });

  if (!name || !email || !password || !farmType) {
    log('WARN', 'Missing required fields', { name, email, farmType });
    return res.status(400).json({ error: 'missing' });
  }

  try {
    const response = await service.register({ name, email, password, farmType });
    log('INFO', 'Registration successful', { uid: response.user.uid });
    return res.json(response);
  } catch (e) {
    log('ERROR', 'Registration failed', {
      error: e.message,
      details: e.message.includes('configuration')
        ? 'Firestore may not be enabled or project ID mismatch'
        : 'Check logs for details',
    });
    return res.status(500).json({ error: e.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  log('INFO', 'POST /login received', { email });

  if (!email || !password) {
    log('WARN', 'Missing email or password');
    return res.status(400).json({ error: 'missing' });
  }

  try {
    const response = await service.login({ email, password });
    if (response.error) {
      return res.status(response.status || 500).json({ error: response.error });
    }

    log('INFO', 'Login successful', { email });
    return res.json(response);
  } catch (e) {
    log('ERROR', 'Login failed', { error: e.message });
    return res.status(500).json({ error: e.message });
  }
};

exports.me = async (req, res) => {
  const auth = req.headers.authorization;
  log('INFO', 'GET /me received', { auth: !!auth });

  if (!auth) {
    log('WARN', 'No authorization header');
    return res.status(401).json({ error: 'unauth' });
  }

  const token = auth.replace('Bearer ', '');
  try {
    const payload = jwt.verify(token, jwtSecret);
    log('INFO', 'Token verified', { uid: payload.uid });

    const response = await service.getProfile(payload.uid);
    if (response.error) {
      return res.status(response.status || 500).json({ error: response.error });
    }

    log('INFO', 'User data retrieved', { uid: payload.uid });
    return res.json(response);
  } catch (e) {
    log('ERROR', 'GET /me failed', { error: e.message });
    return res.status(401).json({ error: 'invalid' });
  }
};

exports.logout = async (req, res) => {
  log('INFO', 'POST /logout received');
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const result = await service.logout(token);
  return res.json(result);
};

exports.refresh = async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'missing' });
  }

  try {
    const result = await service.refresh(refreshToken);
    if (result.error) {
      return res.status(result.status || 500).json({ error: result.error });
    }

    return res.json(result);
  } catch (e) {
    log('ERROR', 'Refresh failed', { error: e.message });
    return res.status(500).json({ error: e.message });
  }
};

exports.change = async (req, res) => {
  const auth = req.headers.authorization;
  log('INFO', 'POST /change received', { auth: !!auth });

  if (!auth) {
    log('WARN', 'No authorization header');
    return res.status(401).json({ error: 'unauth' });
  }

  const token = auth.replace('Bearer ', '');
  try {
    const payload = jwt.verify(token, jwtSecret);
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      log('WARN', 'Missing old or new password', { uid: payload.uid });
      return res.status(400).json({ error: 'missing' });
    }

    const response = await service.changePassword(payload.uid, oldPassword, newPassword);
    if (response.error) {
      return res.status(response.status || 500).json({ error: response.error });
    }

    log('INFO', 'Password changed successfully', { uid: payload.uid });
    return res.json({ ok: true });
  } catch (e) {
    log('ERROR', 'Password change failed', { error: e.message });
    return res.status(401).json({ error: 'invalid' });
  }
};

exports.forgot = async (req, res) => {
  const { email } = req.body;
  log('INFO', 'POST /forgot received', { email });

  if (!email) {
    log('WARN', 'Missing email');
    return res.status(400).json({ error: 'missing' });
  }

  try {
    const response = await service.forgot(email);
    log('INFO', 'Password reset token created', { email });
    return res.json(response);
  } catch (e) {
    log('ERROR', 'Forgot password failed', { error: e.message });
    return res.status(500).json({ error: e.message });
  }
};

exports.reset = async (req, res) => {
  const { token, newPassword } = req.body;
  log('INFO', 'POST /reset received', { token: !!token });

  if (!token || !newPassword) {
    log('WARN', 'Missing token or newPassword');
    return res.status(400).json({ error: 'missing' });
  }

  try {
    const response = await service.reset(token, newPassword);
    if (response.error) {
      return res.status(response.status || 500).json({ error: response.error });
    }

    log('INFO', 'Password reset successful');
    return res.json({ ok: true });
  } catch (e) {
    log('ERROR', 'Password reset failed', { error: e.message });
    return res.status(500).json({ error: e.message });
  }
};
