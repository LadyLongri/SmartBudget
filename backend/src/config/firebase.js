const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

let db = null;
let initialized = false;

function resolveServiceAccountPath() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    return path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
  }
  const directCandidates = [
    path.resolve(__dirname, "../../serviceAccountKey.json"),
    path.resolve(__dirname, "../../../firebase-secrets/serviceAccountKey.json"),
    path.resolve(__dirname, "../../../firebase-secrets/my-smart-budget-admin.json"),
  ];

  for (const candidate of directCandidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  const secretsDir = path.resolve(__dirname, "../../../firebase-secrets");
  if (fs.existsSync(secretsDir)) {
    const jsonFiles = fs
      .readdirSync(secretsDir)
      .filter((name) => name.toLowerCase().endsWith(".json"));

    if (jsonFiles.length > 0) {
      return path.join(secretsDir, jsonFiles[0]);
    }
  }

  return null;
}

function initFirebase() {
  if (admin.apps.length) {
    db = admin.firestore();
    initialized = true;
    return;
  }

  const serviceAccountPath = resolveServiceAccountPath();

  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    const raw = fs.readFileSync(serviceAccountPath, "utf8");
    const serviceAccount = JSON.parse(raw);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
    initialized = true;
    return;
  }

  // Support runtime credentials (for CI/hosting environments).
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp();
    db = admin.firestore();
    initialized = true;
  }
}

try {
  initFirebase();
} catch (error) {
  console.warn("Firebase initialization failed:", error.message);
}

module.exports = {
  admin: initialized ? admin : null,
  db,
  isFirebaseReady: initialized,
};
