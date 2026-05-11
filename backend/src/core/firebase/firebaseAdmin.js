const admin = require('firebase-admin');
const path = require('path');

let serviceAccount;
try {
  serviceAccount = require(path.resolve(__dirname, '../../../serviceAccount.json'));
} catch (e) {
  throw new Error(
    `Failed to load serviceAccount.json. Ensure it exists in backend/: ${e.message}`
  );
}

let initialized = false;
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  initialized = true;
} else {
  initialized = true;
}

function getFirebaseConfig() {
  return {
    projectId: serviceAccount.project_id,
    serviceAccountEmail: serviceAccount.client_email,
    status: initialized ? 'initialized' : 'not initialized',
  };
}

function getFirestore() {
  return admin.firestore();
}

function getAuth() {
  return admin.auth();
}

module.exports = {
  admin,
  getAuth,
  getFirestore,
  getFirebaseConfig,
};
