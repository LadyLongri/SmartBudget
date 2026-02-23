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

function sendServerError(res, error) {
  console.error("categories route error:", error);
  return res.status(500).json({ error: "server_error" });
}

router.post("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const { name, icon = null, color = null } = req.body;

    if (!name || String(name).trim().length < 2) {
      return res.status(400).json({ error: "invalid_name" });
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
    return res.status(201).json({ id: ref.id, ...doc });
  } catch (error) {
    return sendServerError(res, error);
  }
});

router.get("/", async (req, res) => {
  try {
    const uid = req.user.uid;
    const snap = await db
      .collection("categories")
      .where("uid", "==", uid)
      .orderBy("name", "asc")
      .get();

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
    const doc = await db.collection("categories").doc(id).get();

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
    const ref = db.collection("categories").doc(id);
    const doc = await ref.get();

    if (!doc.exists) return res.status(404).json({ error: "not_found" });

    const current = doc.data();
    if (current.uid !== uid) return res.status(403).json({ error: "forbidden" });

    const patch = {};
    const { name, icon, color } = req.body;

    if (name !== undefined) {
      if (!name || String(name).trim().length < 2) {
        return res.status(400).json({ error: "invalid_name" });
      }
      patch.name = String(name).trim();
    }

    if (icon !== undefined) patch.icon = icon;
    if (color !== undefined) patch.color = color;
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
    const ref = db.collection("categories").doc(id);
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
