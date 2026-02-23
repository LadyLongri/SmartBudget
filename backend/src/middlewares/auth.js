const { admin, isFirebaseReady } = require("../config/firebase");

/**
 * Firebase auth middleware.
 * Expects: Authorization: Bearer <FIREBASE_ID_TOKEN>
 */
module.exports = async function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const match = header.match(/^Bearer (.+)$/);

  if (!match) {
    return res.status(401).json({
      error: "missing_token",
      message: "Authorization: Bearer <Firebase ID token> is required.",
    });
  }

  if (!isFirebaseReady || !admin) {
    return res.status(503).json({
      error: "auth_unavailable",
      message: "Firebase Admin is not configured on the server.",
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? null,
    };
    return next();
  } catch (_error) {
    return res.status(401).json({ error: "invalid_token" });
  }
};
