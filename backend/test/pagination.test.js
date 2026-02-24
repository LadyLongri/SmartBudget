const assert = require("node:assert/strict");
const test = require("node:test");

const { encodePageToken, decodePageToken } = require("../src/utils/pagination");

test("encodePageToken/decodePageToken roundtrip", () => {
  const payload = { v: 1, id: "tx_123", dateMs: 1767225600000 };
  const token = encodePageToken(payload);
  const decoded = decodePageToken(token);

  assert.deepEqual(decoded, payload);
});

test("decodePageToken returns null for invalid token", () => {
  const decoded = decodePageToken("not-a-valid-token");
  assert.equal(decoded, null);
});
