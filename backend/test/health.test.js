const assert = require("node:assert/strict");
const test = require("node:test");

process.env.FIREBASE_DISABLE_AUTO_INIT = "1";

const app = require("../index");

test("GET /health returns ok", async (t) => {
  const server = app.listen(0);
  t.after(() => server.close());

  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();

  const response = await fetch(`http://127.0.0.1:${port}/health`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.ok, true);
  assert.equal(typeof body.data.firebaseReady, "boolean");
});

test("GET /me without token returns 401", async (t) => {
  const server = app.listen(0);
  t.after(() => server.close());

  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();

  const response = await fetch(`http://127.0.0.1:${port}/me`);
  const body = await response.json();

  assert.equal(response.status, 401);
  assert.equal(body.error, "missing_token");
  assert.equal(typeof body.message, "string");
});
