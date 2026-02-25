const assert = require("node:assert/strict");
const test = require("node:test");

process.env.FIREBASE_DISABLE_AUTO_INIT = "1";

const app = require("../index");

async function startServer(t) {
  const server = app.listen(0);
  t.after(() => server.close());
  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();
  return `http://127.0.0.1:${port}`;
}

function assertSuccessContract(body) {
  assert.equal(body.ok, true);
  assert.equal(typeof body.data, "object");
}

function assertErrorContract(body, expectedCode) {
  assert.equal(typeof body.error, "string");
  assert.equal(body.error, expectedCode);
  assert.equal(typeof body.message, "string");
  assert.equal("ok" in body, false);
}

test("QA smoke: root and health endpoints keep success contract", async (t) => {
  const baseUrl = await startServer(t);

  const rootRes = await fetch(`${baseUrl}/`);
  const rootBody = await rootRes.json();
  assert.equal(rootRes.status, 200);
  assertSuccessContract(rootBody);
  assert.equal(typeof rootBody.data.message, "string");

  const healthRes = await fetch(`${baseUrl}/health`);
  const healthBody = await healthRes.json();
  assert.equal(healthRes.status, 200);
  assertSuccessContract(healthBody);
  assert.equal(typeof healthBody.data.firebaseReady, "boolean");
});

test("QA errors: /me without token returns standardized missing_token", async (t) => {
  const baseUrl = await startServer(t);

  const response = await fetch(`${baseUrl}/me`);
  const body = await response.json();

  assert.equal(response.status, 401);
  assertErrorContract(body, "missing_token");
});

test("QA errors: token sent but Firebase unavailable returns auth_unavailable", async (t) => {
  const baseUrl = await startServer(t);

  const response = await fetch(`${baseUrl}/me`, {
    headers: { Authorization: "Bearer fake_token" },
  });
  const body = await response.json();

  assert.equal(response.status, 503);
  assertErrorContract(body, "auth_unavailable");
});

test("QA errors: protected feature routes keep standardized contract", async (t) => {
  const baseUrl = await startServer(t);
  const headers = { Authorization: "Bearer fake_token" };

  const transactionsRes = await fetch(`${baseUrl}/transactions?limit=5`, {
    headers,
  });
  const transactionsBody = await transactionsRes.json();
  assert.equal(transactionsRes.status, 503);
  assertErrorContract(transactionsBody, "auth_unavailable");

  const statsRes = await fetch(`${baseUrl}/stats/summary?month=2026-02`, {
    headers,
  });
  const statsBody = await statsRes.json();
  assert.equal(statsRes.status, 503);
  assertErrorContract(statsBody, "auth_unavailable");
});
