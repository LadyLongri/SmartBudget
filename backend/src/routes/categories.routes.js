const express = require("express");
const { admin, db, isFirebaseReady } = require("../config/firebase");
const { success, error } = require("../utils/api-response");
const { encodePageToken, decodePageToken } = require("../utils/pagination");

const router = express.Router();

router.use((_req, res, next) => {
  if (!db || !admin || !isFirebaseReady) {
    return error(
      res,
      "database_unavailable",
      "Firebase/Firestore is not configured on the server.",
      503,
    );
  }
  return next();
});

function sendServerError(res, routeError) {
  console.error("categories route error:", routeError);
  return error(res, "server_error", "Unexpected server error.", 500);
}

function parseLimit(rawLimit) {
  const parsedLimit = rawLimit === undefined ? 50 : Number(rawLimit);
  if (!Number.isInteger(parsedLimit) || parsedLimit < 1) {
    return null;
  }
  return Math.min(parsedLimit, 200);
}

function parseCategoryToken(rawToken) {
  const cursor = decodePageToken(rawToken);
  if (!cursor || cursor.v !== 1) {
    return null;
  }
  if (typeof cursor.id !== "string") {
    return null;
  }
  return cursor;
}

function isValidOptionalString(value) {
  return value === null || value === undefined || typeof value === "string";
}

router.post("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { name, icon = null, color = null } = req.body;

    if (typeof name !== "string" || name.trim().length < 2 || name.trim().length > 64) {
      return error(
        res,
        "invalid_name",
        "Category name must be a string between 2 and 64 characters.",
        400,
      );
    }

    if (!isValidOptionalString(icon) || !isValidOptionalString(color)) {
      return error(
        res,
        "invalid_category_payload",
        "Category icon and color must be strings or null.",
        400,
      );
    }

    const doc = {
      uid,
      name: String(name).trim(),
      icon,
      color,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection("categories").add(doc);
    return success(res, { id: ref.id, ...doc }, 201);
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { limit, pageToken } = req.query;

    const parsedLimit = parseLimit(limit);
    if (!parsedLimit) {
      return error(res, "invalid_limit", "Limit must be an integer >= 1.", 400);
    }

    let query = db
      .collection("categories")
      .where("uid", "==", uid)
      .orderBy("name", "asc")
      .limit(parsedLimit + 1);

    if (pageToken) {
      const cursor = parseCategoryToken(pageToken);
      if (!cursor) {
        return error(
          res,
          "invalid_page_token",
          "Page token is invalid or expired.",
          400,
        );
      }

      const cursorDoc = await db.collection("categories").doc(cursor.id).get();
      if (!cursorDoc.exists || cursorDoc.data()?.uid !== uid) {
        return error(
          res,
          "invalid_page_token",
          "Page token is invalid or expired.",
          400,
        );
      }

      query = query.startAfter(cursorDoc);
    }

    const snap = await query.get();
    const hasMore = snap.docs.length > parsedLimit;
    const docs = hasMore ? snap.docs.slice(0, parsedLimit) : snap.docs;
    const items = docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const nextPageToken = hasMore
      ? encodePageToken({
          v: 1,
          id: docs[docs.length - 1].id,
        })
      : null;

    return success(res, {
      items,
      pageInfo: {
        limit: parsedLimit,
        hasMore,
        nextPageToken,
      },
    });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.get("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;
    const doc = await db.collection("categories").doc(id).get();

    if (!doc.exists) {
      return error(res, "not_found", "Category not found.", 404);
    }

    const data = doc.data();
    if (data.uid !== uid) {
      return error(res, "forbidden", "You cannot access this category.", 403);
    }

    return success(res, { id: doc.id, ...data });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.patch("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("categories").doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return error(res, "not_found", "Category not found.", 404);
    }

    const current = doc.data();
    if (current.uid !== uid) {
      return error(res, "forbidden", "You cannot update this category.", 403);
    }

    const patch = {};
    const { name, icon, color } = req.body;

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length < 2 || name.trim().length > 64) {
        return error(
          res,
          "invalid_name",
          "Category name must be a string between 2 and 64 characters.",
          400,
        );
      }
      patch.name = String(name).trim();
    }

    if (icon !== undefined) {
      if (!isValidOptionalString(icon)) {
        return error(res, "invalid_icon", "Icon must be a string or null.", 400);
      }
      patch.icon = icon;
    }

    if (color !== undefined) {
      if (!isValidOptionalString(color)) {
        return error(res, "invalid_color", "Color must be a string or null.", 400);
      }
      patch.color = color;
    }

    if (!Object.keys(patch).length) {
      return error(res, "invalid_patch", "No updatable category fields provided.", 400);
    }

    patch.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await ref.update(patch);
    const updated = await ref.get();
    return success(res, { id, ...updated.data() });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("categories").doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return error(res, "not_found", "Category not found.", 404);
    }

    const data = doc.data();
    if (data.uid !== uid) {
      return error(res, "forbidden", "You cannot delete this category.", 403);
    }

    await ref.delete();
    return success(res, { id, deleted: true });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

module.exports = router;
