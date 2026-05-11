const express = require('express');
const bodyParser = require('body-parser');
const rateLimit = require('express-rate-limit');
const authRoutes = require('./modules/auth/auth.routes');
const { authenticate } = require('./core/middleware/auth.middleware');
const { settingsRoutes } = require('./routes');
const { port } = require('./core/config');
const app = express();

// CORS middleware for Flutter Web and mobile clients
app.use((req, res, next) => {
  const origin = req.headers.origin || '*';
  res.header('Access-Control-Allow-Origin', origin);
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Access-Control-Allow-Credentials', 'true');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(bodyParser.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'too_many_attempts' },
});
const forgotLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { error: 'too_many_attempts' },
});
const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: { error: 'too_many_attempts' },
});

app.use('/api/v1/auth/login', loginLimiter);
app.use('/api/v1/auth/forgot', forgotLimiter);
app.use('/api/v1/auth/refresh', refreshLimiter);
app.use('/api/v1/auth', authRoutes);

app.use('/api/settings', authenticate, settingsRoutes);
app.use('/api/v1/settings', authenticate, settingsRoutes);

const poultryRoutes = require('./modules/poultry/poultry.routes');
app.use('/api/v1/poultry', authenticate, poultryRoutes);

const accountsRoutes = require('./modules/accounts/accounts.routes');
app.use('/api/v1/accounts', authenticate, accountsRoutes);

// minimal 404
app.use((req, res) => res.status(404).json({ error: 'not found' }));

if (require.main === module) {
  app.listen(port, () => console.log('Auth API listening on', port));
}

module.exports = app;
