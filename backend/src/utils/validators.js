const ALLOWED_CURRENCIES = ["USD", "CDF"];
const ALLOWED_TYPES = ["income", "expense"];

function isValidCurrency(value) {
  return ALLOWED_CURRENCIES.includes(value);
}

function isValidType(value) {
  return ALLOWED_TYPES.includes(value);
}

function isValidMonth(value) {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(value);
}

function getMonthRange(month) {
  const start = new Date(`${month}-01T00:00:00.000Z`);
  const end = new Date(start);
  end.setUTCMonth(end.getUTCMonth() + 1);
  return { start, end };
}

function parseStrictIsoDate(value) {
  if (typeof value !== "string") {
    return null;
  }

  const isoRegex =
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?(?:Z|[+-]\d{2}:\d{2})$/;
  if (!isoRegex.test(value)) {
    return null;
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return parsed;
}

module.exports = {
  ALLOWED_CURRENCIES,
  ALLOWED_TYPES,
  isValidCurrency,
  isValidType,
  isValidMonth,
  getMonthRange,
  parseStrictIsoDate,
};
