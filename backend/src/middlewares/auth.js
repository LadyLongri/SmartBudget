const { admin, isFirebaseReady } = require("../config/firebase");
const { error } = require("../utils/api-response");

/**
 * Firebase auth middleware.
 * Expects: Authorization: Bearer <FIREBASE_ID_TOKEN>
 */
module.exports = async function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const match = header.match(/^Bearer (.+)$/);

  if (!match) {
    return error(
      res,
      "missing_token",
      "Authorization: Bearer <Firebase ID token> is required.",
      401,
    );
  }

  if (!isFirebaseReady || !admin) {
    return error(
      res,
      "auth_unavailable",
      "Firebase Admin is not configured on the server.",
      503,
    );
  }

  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? null,
    };
    return next();
  } catch (_error) {
    return error(res, "invalid_token", "Firebase ID token is invalid.", 401);
  }
};
