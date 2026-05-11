const express = require('express');
const {
  register,
  login,
  me,
  logout,
  forgot,
  reset,
  change,
  refresh,
  getFirebaseConfig,
} = require('./auth.controller');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', me);
router.post('/logout', logout);
router.post('/refresh', refresh);
router.post('/forgot', forgot);
router.post('/reset', reset);
router.post('/change', change);

router.get('/test', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Backend is running and CORS is configured',
    timestamp: new Date().toISOString(),
  });
});

router.get('/diagnostic', (req, res) => {
  const firebaseConfig = getFirebaseConfig();
  res.json({
    backend: {
      status: 'ok',
      timestamp: new Date().toISOString(),
    },
    firebase: firebaseConfig,
    troubleshooting: {
      projectId: firebaseConfig.projectId,
      status: firebaseConfig.status,
      nextSteps:
        firebaseConfig.status === 'initialized'
          ? [
              `Firebase is initialized with Project ID: ${firebaseConfig.projectId}`,
              'If registration fails with "no configuration" error:',
              `  1. Go to Firebase Console > ${firebaseConfig.projectId}`,
              '  2. Click "Firestore Database" in left menu',
              '  3. If not present, click "Create Database"',
              '  4. Select "Production mode" and your region',
              '  5. Restart backend and try again',
            ]
          : [
              'Firebase Admin SDK not initialized',
              'Check serviceAccount.json in backend/ directory',
            ],
    },
  });
});

module.exports = router;
