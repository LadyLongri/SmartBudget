const express = require("express");
const { admin, db, isFirebaseReady } = require("../config/firebase");
const { success, error } = require("../utils/api-response");
const {
  ALLOWED_CURRENCIES,
  ALLOWED_TYPES,
  isValidCurrency,
  isValidType,
  isValidMonth,
  getMonthRange,
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
  console.error("stats route error:", routeError);
  return error(res, "server_error", "Unexpected server error.", 500);
}

function normalizeMonth(month) {
  if (!month || !isValidMonth(month)) {
    return null;
  }
  return month;
}

function parseTimestampToDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function dateKeyUTC(date) {
  return date.toISOString().slice(0, 10);
}

function weekStartKeyUTC(date) {
  const normalized = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0),
  );
  const weekday = (normalized.getUTCDay() + 6) % 7;
  normalized.setUTCDate(normalized.getUTCDate() - weekday);
  return dateKeyUTC(normalized);
}

async function fetchMonthlyTransactions(uid, month, extraFilters = {}) {
  const { start, end } = getMonthRange(month);

  let query = db
    .collection("transactions")
    .where("uid", "==", uid)
    .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
    .where("date", "<", admin.firestore.Timestamp.fromDate(end));

  for (const [field, value] of Object.entries(extraFilters)) {
    query = query.where(field, "==", value);
  }

  query = query.orderBy("date", "desc");

  const snap = await query.get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

router.get("/summary", async (req, res) => {
  try {
    const uid = req.user.uid;
    const month = normalizeMonth(req.query.month);
    const { currency } = req.query;

    if (!month) {
      return error(
        res,
        "invalid_month",
        "month is required and must use YYYY-MM format.",
        400,
        { example: "2026-02" },
      );
    }

    if (currency && !isValidCurrency(currency)) {
      return error(
        res,
        "invalid_currency",
        "Currency must be one of the supported values.",
        400,
        { expected: ALLOWED_CURRENCIES },
      );
    }

    const transactions = await fetchMonthlyTransactions(
      uid,
      month,
      currency ? { currency } : {},
    );

    let totalExpense = 0;
    let totalIncome = 0;

    for (const tx of transactions) {
      const amount = Number(tx.amount) || 0;
      if (tx.type === "expense") totalExpense += amount;
      if (tx.type === "income") totalIncome += amount;
    }

    return success(res, {
      month,
      currency: currency || null,
      totalExpense,
      totalIncome,
      balance: totalIncome - totalExpense,
      transactionCount: transactions.length,
    });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.get("/by-category", async (req, res) => {
  try {
    const uid = req.user.uid;
    const month = normalizeMonth(req.query.month);
    const { currency } = req.query;
    const type = req.query.type || "expense";

    if (!month) {
      return error(
        res,
        "invalid_month",
        "month is required and must use YYYY-MM format.",
        400,
        { example: "2026-02" },
      );
    }

    if (!currency || !isValidCurrency(currency)) {
      return error(
        res,
        "invalid_currency",
        "currency is required and must be a supported value.",
        400,
        { expected: ALLOWED_CURRENCIES },
      );
    }

    if (!isValidType(type)) {
      return error(
        res,
        "invalid_type",
        "Transaction type must be one of the supported values.",
        400,
        { expected: ALLOWED_TYPES },
      );
    }

    const transactions = await fetchMonthlyTransactions(uid, month, { currency, type });
    const grouped = new Map();
    const categoryIds = new Set();

    for (const tx of transactions) {
      const amount = Number(tx.amount) || 0;
      const categoryId = tx.categoryId || null;
      const key = categoryId || "__none__";
      grouped.set(key, (grouped.get(key) || 0) + amount);
      if (categoryId) categoryIds.add(categoryId);
    }

    const categoryNameMap = new Map();
    if (categoryIds.size) {
      const categoryDocs = await Promise.all(
        [...categoryIds].map((id) => db.collection("categories").doc(id).get()),
      );

      for (const doc of categoryDocs) {
        if (!doc.exists) continue;
        const categoryData = doc.data();
        if (categoryData.uid !== uid) continue;
        categoryNameMap.set(doc.id, categoryData.name || "Categorie");
      }
    }

    const items = [...grouped.entries()]
      .map(([groupKey, total]) => {
        if (groupKey === "__none__") {
          return { categoryId: null, categoryName: "Sans categorie", total };
        }
        return {
          categoryId: groupKey,
          categoryName: categoryNameMap.get(groupKey) || "Categorie inconnue",
          total,
        };
      })
      .sort((a, b) => b.total - a.total);

    return success(res, {
      month,
      currency,
      type,
      items,
    });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

router.get("/trend", async (req, res) => {
  try {
    const uid = req.user.uid;
    const month = normalizeMonth(req.query.month);
    const { currency } = req.query;
    const granularity = req.query.granularity || "day";

    if (!month) {
      return error(
        res,
        "invalid_month",
        "month is required and must use YYYY-MM format.",
        400,
        { example: "2026-02" },
      );
    }

    if (currency && !isValidCurrency(currency)) {
      return error(
        res,
        "invalid_currency",
        "Currency must be one of the supported values.",
        400,
        { expected: ALLOWED_CURRENCIES },
      );
    }

    if (granularity !== "day" && granularity !== "week") {
      return error(
        res,
        "invalid_granularity",
        "granularity must be either day or week.",
        400,
      );
    }

    const transactions = await fetchMonthlyTransactions(
      uid,
      month,
      currency ? { currency } : {},
    );

    const grouped = new Map();
    for (const tx of transactions) {
      const txDate = parseTimestampToDate(tx.date);
      if (!txDate) continue;

      const key = granularity === "week" ? weekStartKeyUTC(txDate) : dateKeyUTC(txDate);
      const current = grouped.get(key) || { totalExpense: 0, totalIncome: 0 };
      const amount = Number(tx.amount) || 0;

      if (tx.type === "expense") current.totalExpense += amount;
      if (tx.type === "income") current.totalIncome += amount;
      grouped.set(key, current);
    }

    const items = [...grouped.entries()]
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([date, totals]) => ({ date, ...totals }));

    return success(res, {
      month,
      currency: currency || null,
      granularity,
      items,
    });
  } catch (routeError) {
    return sendServerError(res, routeError);
  }
});

module.exports = router;
