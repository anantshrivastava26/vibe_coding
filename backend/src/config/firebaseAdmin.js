const admin = require('firebase-admin');
const path = require('path');

// On Railway there is no local serviceAccountKey.json (it's gitignored and
// never pushed), so credentials come from an env var instead. Locally, the
// file is simplest. Supports either a raw JSON string or a base64-encoded
// one in FIREBASE_SERVICE_ACCOUNT_JSON.
function loadServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    const raw = inlineJson.trim().startsWith('{')
      ? inlineJson
      : Buffer.from(inlineJson, 'base64').toString('utf8');
    return JSON.parse(raw);
  }

  const serviceAccountPath = path.resolve(
    __dirname,
    '..',
    '..',
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 'serviceAccountKey.json'
  );
  return require(serviceAccountPath);
}

let initialized = false;
try {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  initialized = true;
} catch (err) {
  console.warn(
    '[firebaseAdmin] Could not load Firebase service account credentials. ' +
      'Auth verification and push notifications will fail until FIREBASE_SERVICE_ACCOUNT_JSON ' +
      `(or a local serviceAccountKey.json) is provided. (${err.message})`
  );
}

module.exports = { admin, isFirebaseInitialized: () => initialized };
