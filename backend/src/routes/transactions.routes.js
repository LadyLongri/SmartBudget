const express = require("express");
const { admin, db, isFirebaseReady } = require("../config/firebase");

const router = express.Router();

router.use((_req, res, next) => {
  if (!db || !admin || !isFirebaseReady) {
    return res.status(503).json({
      error: "database_unavailable",
      message: "Firebase/Firestore is not configured on the server.",
    });
  }
  return next();
});

function isValidCurrency(value) {
  return value === "USD" || value === "CDF";
}

function isValidType(value) {
  return value === "income" || value === "expense";
}

function isValidMonth(value) {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(value);
}

function sendServerError(res, error) {
  console.error("transactions route error:", error);
  return res.status(500).json({ error: "server_error" });
}

router.post("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { type, amount, currency, categoryId = null, note = "", date } = req.body;

    if (!isValidType(type)) {
      return res.status(400).json({
        error: "invalid_type",
        expected: ["income", "expense"],
      });
    }

    const numAmount = Number(amount);
    if (!Number.isFinite(numAmount) || numAmount <= 0) {
      return res.status(400).json({ error: "invalid_amount" });
    }

    if (!isValidCurrency(currency)) {
      return res.status(400).json({
        error: "invalid_currency",
        expected: ["USD", "CDF"],
      });
    }

    const parsedDate = date ? new Date(date) : new Date();
    if (Number.isNaN(parsedDate.getTime())) {
      return res.status(400).json({ error: "invalid_date" });
    }

    const doc = {
      uid,
      type,
      amount: numAmount,
      currency,
      categoryId,
      note: String(note),
      date: admin.firestore.Timestamp.fromDate(parsedDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection("transactions").add(doc);
    return res.status(201).json({ id: ref.id, ...doc });
  } catch (error) {
    return sendServerError(res, error);
  }
});

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { month, currency, type, categoryId, limit } = req.query;

    if (currency && !isValidCurrency(currency)) {
      return res.status(400).json({
        error: "invalid_currency",
        expected: ["USD", "CDF"],
      });
    }

    if (type && !isValidType(type)) {
      return res.status(400).json({
        error: "invalid_type",
        expected: ["income", "expense"],
      });
    }

    if (month && !isValidMonth(month)) {
      return res.status(400).json({
        error: "invalid_month",
        example: "2026-02",
      });
    }

    const parsedLimit = limit === undefined ? 50 : Number(limit);
    if (!Number.isInteger(parsedLimit) || parsedLimit < 1) {
      return res.status(400).json({ error: "invalid_limit" });
    }

    let query = db.collection("transactions").where("uid", "==", uid);

    if (currency) query = query.where("currency", "==", currency);
    if (type) query = query.where("type", "==", type);
    if (categoryId) query = query.where("categoryId", "==", categoryId);

    if (month) {
      const start = new Date(`${month}-01T00:00:00.000Z`);
      const end = new Date(start);
      end.setUTCMonth(end.getUTCMonth() + 1);

      query = query
        .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
        .where("date", "<", admin.firestore.Timestamp.fromDate(end));
    }

    query = query.orderBy("date", "desc").limit(Math.min(parsedLimit, 200));

    const snap = await query.get();
    const items = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    return res.json({ items });
  } catch (error) {
    return sendServerError(res, error);
  }
});

router.get("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;

    const doc = await db.collection("transactions").doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: "not_found" });

    const data = doc.data();
    if (data.uid !== uid) return res.status(403).json({ error: "forbidden" });

    return res.json({ id: doc.id, ...data });
  } catch (error) {
    return sendServerError(res, error);
  }
});

router.patch("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("transactions").doc(id);
    const doc = await ref.get();

    if (!doc.exists) return res.status(404).json({ error: "not_found" });

    const current = doc.data();
    if (current.uid !== uid) return res.status(403).json({ error: "forbidden" });

    const patch = {};
    const { type, amount, currency, categoryId, note, date } = req.body;

    if (type !== undefined) {
      if (!isValidType(type)) return res.status(400).json({ error: "invalid_type" });
      patch.type = type;
    }

    if (amount !== undefined) {
      const numAmount = Number(amount);
      if (!Number.isFinite(numAmount) || numAmount <= 0) {
        return res.status(400).json({ error: "invalid_amount" });
      }
      patch.amount = numAmount;
    }

    if (currency !== undefined) {
      if (!isValidCurrency(currency)) {
        return res.status(400).json({ error: "invalid_currency" });
      }
      patch.currency = currency;
    }

    if (categoryId !== undefined) patch.categoryId = categoryId;
    if (note !== undefined) patch.note = String(note);

    if (date !== undefined) {
      const parsedDate = new Date(date);
      if (Number.isNaN(parsedDate.getTime())) {
        return res.status(400).json({ error: "invalid_date" });
      }
      patch.date = admin.firestore.Timestamp.fromDate(parsedDate);
    }

    patch.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await ref.update(patch);
    const updated = await ref.get();
    return res.json({ id, ...updated.data() });
  } catch (error) {
    return sendServerError(res, error);
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const uid = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("transactions").doc(id);
    const doc = await ref.get();

    if (!doc.exists) return res.status(404).json({ error: "not_found" });

    const data = doc.data();
    if (data.uid !== uid) return res.status(403).json({ error: "forbidden" });

    await ref.delete();
    return res.json({ ok: true, id });
  } catch (error) {
    return sendServerError(res, error);
  }
});

module.exports = router;
