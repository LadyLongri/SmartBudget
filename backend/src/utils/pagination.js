function encodePageToken(payload) {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

function decodePageToken(token) {
  try {
    const decoded = Buffer.from(token, "base64url").toString("utf8");
    const parsed = JSON.parse(decoded);
    if (!parsed || typeof parsed !== "object") {
      throw new Error("invalid");
    }
    return parsed;
  } catch (_error) {
    return null;
  }
}

module.exports = {
  encodePageToken,
  decodePageToken,
};
