const { nanoid } = require("nanoid");

// In-memory payload store — good enough for a simulation, no persistence needed.
const payloads = new Map();

function createPayload({ merchant, amount, currency, reference }) {
  const token = nanoid(12);
  const payload = {
    token,
    merchant,
    amount,
    currency: currency || "SGD",
    reference: reference || `REF-${token.toUpperCase()}`,
    createdAt: new Date().toISOString(),
  };
  payloads.set(token, payload);
  return payload;
}

function getPayload(token) {
  return payloads.get(token) || null;
}

module.exports = { createPayload, getPayload };
