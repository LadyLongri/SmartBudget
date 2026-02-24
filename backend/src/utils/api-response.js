function success(res, data, status = 200) {
  return res.status(status).json({ ok: true, data });
}

function error(res, code, message, status, details) {
  const payload = { error: code, message };
  if (details !== undefined) {
    payload.details = details;
  }
  return res.status(status).json(payload);
}

module.exports = {
  success,
  error,
};
