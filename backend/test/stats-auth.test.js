const assert = require("node:assert/strict");
const test = require("node:test");

process.env.FIREBASE_DISABLE_AUTO_INIT = "1";

const app = require("../index");

test("GET /stats/summary without token returns standardized 401", async (t) => {
  const server = app.listen(0);
  t.after(() => server.close());

  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();

  const response = await fetch(`http://127.0.0.1:${port}/stats/summary?month=2026-02`);
  const body = await response.json();

  assert.equal(response.status, 401);
  assert.equal(body.error, "missing_token");
  assert.equal(typeof body.message, "string");
});
