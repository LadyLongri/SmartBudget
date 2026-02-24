const fs = require("fs");
const path = require("path");

let admin = null;
let db = null;
let initialized = false;

function envBool(name) {
  const value = (process.env[name] || "").toLowerCase().trim();
  return value === "1" || value === "true" || value === "yes";
}

function getAdminModule() {
  if (!admin) {
    admin = require("firebase-admin");
  }
  return admin;
}

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
  if (envBool("FIREBASE_DISABLE_AUTO_INIT")) {
    return;
  }

  const serviceAccountPath = resolveServiceAccountPath();
  const hasRuntimeCredentials = Boolean(process.env.GOOGLE_APPLICATION_CREDENTIALS);

  // Avoid loading firebase-admin when no credentials are available.
  if (!serviceAccountPath && !hasRuntimeCredentials) {
    return;
  }

  const firebaseAdmin = getAdminModule();

  if (firebaseAdmin.apps.length) {
    db = firebaseAdmin.firestore();
    initialized = true;
    return;
  }

  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    const raw = fs.readFileSync(serviceAccountPath, "utf8");
    const serviceAccount = JSON.parse(raw);
    firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.cert(serviceAccount),
    });
    db = firebaseAdmin.firestore();
    initialized = true;
    return;
  }

  // Support runtime credentials (for CI/hosting environments).
  if (hasRuntimeCredentials) {
    firebaseAdmin.initializeApp();
    db = firebaseAdmin.firestore();
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
