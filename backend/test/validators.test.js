const assert = require("node:assert/strict");
const test = require("node:test");

const {
  isValidMonth,
  parseStrictIsoDate,
  getMonthRange,
} = require("../src/utils/validators");

test("isValidMonth accepts YYYY-MM and rejects invalid input", () => {
  assert.equal(isValidMonth("2026-02"), true);
  assert.equal(isValidMonth("2026-13"), false);
  assert.equal(isValidMonth("02-2026"), false);
});

test("parseStrictIsoDate accepts full ISO datetime", () => {
  const parsed = parseStrictIsoDate("2026-02-24T12:30:45.123Z");
  assert.ok(parsed instanceof Date);
  assert.equal(Number.isNaN(parsed.getTime()), false);
});

test("parseStrictIsoDate rejects non ISO datetime formats", () => {
  assert.equal(parseStrictIsoDate("2026-02-24"), null);
  assert.equal(parseStrictIsoDate("24/02/2026"), null);
  assert.equal(parseStrictIsoDate(12345), null);
});

test("getMonthRange returns next month exclusive end", () => {
  const { start, end } = getMonthRange("2026-02");
  assert.equal(start.toISOString(), "2026-02-01T00:00:00.000Z");
  assert.equal(end.toISOString(), "2026-03-01T00:00:00.000Z");
});
