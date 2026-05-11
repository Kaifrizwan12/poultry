const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const { firebase, nodeEnv } = require('../config');

let db = null;
let bucket = null;
let initialised = false;
let projectId = null;
let auth = null;

function init() {
  if (initialised) return;

  let credential = null;

  if (firebase.projectId && firebase.clientEmail && firebase.privateKey) {
    projectId = firebase.projectId;
    credential = admin.credential.cert({
      projectId: firebase.projectId,
      clientEmail: firebase.clientEmail,
      privateKey: firebase.privateKey,
    });
  } else {
    const saPath = path.join(__dirname, '..', '..', '..', 'serviceAccount.json');

    if (fs.existsSync(saPath)) {
      console.log(`✓ Loading Firebase credentials from: ${saPath}`);
      const sa = JSON.parse(fs.readFileSync(saPath, 'utf-8'));
      projectId = sa.project_id;
      credential = admin.credential.cert(sa);
    }
  }

  if (!credential) {
    if (nodeEnv === 'production') {
      throw new Error('Firebase credentials missing in production');
    }

    console.warn(
      '\n⚠  Firebase credentials missing — add serviceAccount.json to the project root\n' +
      '   or set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY in .env\n' +
      '   The app will run but data will not be persisted to Firebase.\n'
    );
    initialised = true;
    return;
  }

  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.appspot.com`;

  if (!admin.apps.length) {
    admin.initializeApp({ credential, storageBucket });
  }

  auth = admin.auth();
  db = admin.firestore();
  bucket = admin.storage().bucket();
  initialised = true;
  console.log(`✓ Firebase connected — project: ${projectId}`);
}

/** Return the Auth instance (null if not configured). */
function getAuth() { if (!initialised) init(); return auth; }

/** Return the Firestore instance (null if not configured). */
function getDb()     { if (!initialised) init(); return db; }

/** Return the Storage bucket (null if not configured). */
function getBucket() { if (!initialised) init(); return bucket; }

/** True only when both Firestore and Storage are ready. */
function isReady()   { return db !== null && bucket !== null; }

function getFirebaseConfig() {
  if (!initialised) init();

  return {
    projectId,
    status: isReady() ? 'initialized' : 'not initialized',
    storageBucket: bucket ? bucket.name : null,
  };
}

module.exports = { init, getAuth, getDb, getBucket, isReady, getFirebaseConfig };
