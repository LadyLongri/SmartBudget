const express = require("express");
const cors = require("cors");

const { isFirebaseReady } = require("./src/config/firebase");
const auth = require("./src/middlewares/auth");
const transactionsRoutes = require("./src/routes/transactions.routes");
const categoriesRoutes = require("./src/routes/categories.routes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (_req, res) => res.send("SmartBudget API is running"));
app.get("/health", (_req, res) => {
  res.json({ ok: true, firebaseReady: isFirebaseReady });
});

app.use(auth);

app.get("/me", (req, res) => {
  res.json({ uid: req.user.uid, email: req.user.email ?? null });
});

app.use("/transactions", transactionsRoutes);
app.use("/categories", categoriesRoutes);

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, "0.0.0.0", () => {
    console.log(`API running on http://localhost:${port}`);
  });
}

module.exports = app;
