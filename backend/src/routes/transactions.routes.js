const express = require("express");
const { admin, db, isFirebaseReady } = require("../config/firebase");
const { success, error } = require("../utils/api-response");
const { encodePageToken, decodePageToken } = require("../utils/pagination");
const {
  ALLOWED_CURRENCIES,
  ALLOWED_TYPES,
  isValidCurrency,
  isValidType,
  isValidMonth,
  getMonthRange,
  parseStrictIsoDate,
} = require("../utils/validators");

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
  console.error("transactions route error:", routeError);
  return error(res, "server_error", "Unexpected server error.", 500);
}

function parseLimit(rawLimit) {
  const parsedLimit = rawLimit === undefined ? 50 : Number(rawLimit);
  if (!Number.isInteger(parsedLimit) || parsedLimit < 1) {
    return null;
  }
  return Math.min(parsedLimit, 200);
}

function parseTransactionToken(rawToken) {
  const cursor = decodePageToken(rawToken);
  if (!cursor || cursor.v !== 1) {
    return null;
  }
  if (typeof cursor.id !== "string") {
    return null;
  }
  return cursor;
}

async function validateCategoryOwnership(uid, categoryId) {
  if (categoryId === null) {
    return { valid: true, normalized: null };
  }

  if (typeof categoryId !== "string" || !categoryId.trim()) {
    return { valid: false };
  }

  const normalized = categoryId.trim();
  const categoryDoc = await db.collection("categories").doc(normalized).get();
  if (!categoryDoc.exists) {
    return { valid: false };
  }

  const categoryData = categoryDoc.data();
  if (!categoryData || categoryData.uid !== uid) {
    return { valid: false };
  }

  return { valid: true, normalized };
}

router.post("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { type, amount, currency, categoryId = null, note = "", date } = req.body;

    if (!isValidType(type)) {
      return error(
        res,
        "invalid_type",
        "Transaction type must be one of the supported values.",
        400,
        { expected: ALLOWED_TYPES },
      );
    }

    const numAmount = Number(amount);
    if (!Number.isFinite(numAmount) || numAmount <= 0) {
      return error(res, "invalid_amount", "Amount must be a positive number.", 400);
    }

    if (!isValidCurrency(currency)) {
      return error(
        res,
        "invalid_currency",
        "Currency must be one of the supported values.",
        400,
        { expected: ALLOWED_CURRENCIES },
      );
    }

    const parsedDate = date === undefined ? new Date() : parseStrictIsoDate(date);
    if (!parsedDate) {
      return error(
        res,
        "invalid_date",
        "Date must be an ISO-8601 datetime string (example: 2026-02-24T12:00:00Z).",
        400,
      );
    }

    const categoryValidation = await validateCategoryOwnership(uid, categoryId);
    if (!categoryValidation.valid) {
      return error(
        res,
        "invalid_category",
        "categoryId must reference a category owned by the authenticated user.",
        400,
      );
    }

    const doc = {
      uid,
      type,
      amount: numAmount,
      currency,
      categoryId: categoryValidation.normalized,
      note: String(note),
      date: admin.firestore.Timestamp.fromDate(parsedDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection("transactions").add(doc);
    return success(res, { id: ref.id, ...doc }, 201);
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { month, currency, type, categoryId, limit, pageToken } = req.query;

    if (currency && !isValidCurrency(currency)) {
      return error(
        res,
        "invalid_currency",
        "Currency must be one of the supported values.",
        400,
        { expected: ALLOWED_CURRENCIES },
      );
    }

    if (type && !isValidType(type)) {
      return error(
        res,
        "invalid_type",
        "Transaction type must be one of the supported values.",
        400,
        { expected: ALLOWED_TYPES },
      );
    }

    if (month && !isValidMonth(month)) {
      return error(
        res,
        "invalid_month",
        "Month must use YYYY-MM format.",
        400,
        { example: "2026-02" },
      );
    }

    const parsedLimit = parseLimit(limit);
    if (!parsedLimit) {
      return error(res, "invalid_limit", "Limit must be an integer >= 1.", 400);
    }

    let query = db.collection("transactions").where("uid", "==", uid);

    if (currency) query = query.where("currency", "==", currency);
    if (type) query = query.where("type", "==", type);
    if (categoryId) query = query.where("categoryId", "==", categoryId);

    if (month) {
      const { start, end } = getMonthRange(month);
      query = query
        .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
        .where("date", "<", admin.firestore.Timestamp.fromDate(end));
    }

    query = query
      .orderBy("date", "desc")
      .limit(parsedLimit + 1);

    if (pageToken) {
      const cursor = parseTransactionToken(pageToken);
      if (!cursor) {
        return error(
          res,
          "invalid_page_token",
          "Page token is invalid or expired.",
          400,
        );
      }

      const cursorDoc = await db.collection("transactions").doc(cursor.id).get();
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

    const doc = await db.collection("transactions").doc(id).get();
    if (!doc.exists) {
      return error(res, "not_found", "Transaction not found.", 404);
    }

    const data = doc.data();
    if (data.uid !== uid) {
      return error(res, "forbidden", "You cannot access this transaction.", 403);
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
    const ref = db.collection("transactions").doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return error(res, "not_found", "Transaction not found.", 404);
    }

    const current = doc.data();
    if (current.uid !== uid) {
      return error(res, "forbidden", "You cannot update this transaction.", 403);
    }

    const patch = {};
    const { type, amount, currency, categoryId, note, date } = req.body;

    if (type !== undefined) {
      if (!isValidType(type)) {
        return error(
          res,
          "invalid_type",
          "Transaction type must be one of the supported values.",
          400,
          { expected: ALLOWED_TYPES },
        );
      }
      patch.type = type;
    }

    if (amount !== undefined) {
      const numAmount = Number(amount);
      if (!Number.isFinite(numAmount) || numAmount <= 0) {
        return error(res, "invalid_amount", "Amount must be a positive number.", 400);
      }
      patch.amount = numAmount;
    }

    if (currency !== undefined) {
      if (!isValidCurrency(currency)) {
        return error(
          res,
          "invalid_currency",
          "Currency must be one of the supported values.",
          400,
          { expected: ALLOWED_CURRENCIES },
        );
      }
      patch.currency = currency;
    }

    if (categoryId !== undefined) {
      const categoryValidation = await validateCategoryOwnership(uid, categoryId);
      if (!categoryValidation.valid) {
        return error(
          res,
          "invalid_category",
          "categoryId must reference a category owned by the authenticated user.",
          400,
        );
      }
      patch.categoryId = categoryValidation.normalized;
    }

    if (note !== undefined) {
      patch.note = String(note);
    }

    if (date !== undefined) {
      const parsedDate = parseStrictIsoDate(date);
      if (!parsedDate) {
        return error(
          res,
          "invalid_date",
          "Date must be an ISO-8601 datetime string (example: 2026-02-24T12:00:00Z).",
          400,
        );
      }
      patch.date = admin.firestore.Timestamp.fromDate(parsedDate);
    }

    if (!Object.keys(patch).length) {
      return error(res, "invalid_patch", "No updatable transaction fields provided.", 400);
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
    const ref = db.collection("transactions").doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return error(res, "not_found", "Transaction not found.", 404);
    }

    const data = doc.data();
    if (data.uid !== uid) {
      return error(res, "forbidden", "You cannot delete this transaction.", 403);
    }

    await ref.delete();
    return success(res, { id, deleted: true });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

module.exports = router;
