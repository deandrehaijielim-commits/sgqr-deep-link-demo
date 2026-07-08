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
    paid: false,
    paidBy: null,
  };
  payloads.set(token, payload);
  return payload;
}

function getPayload(token) {
  return payloads.get(token) || null;
}

// Marks a payload as paid so no other bank app can pay it again — SGQR-style
// QR codes are single-use once a payment against them is completed.
// Returns null if the token doesn't exist, or { alreadyPaid: true } if some
// other bank already paid it first.
function markPaid(token, bankId) {
  const payload = payloads.get(token);
  if (!payload) return null;
  if (payload.paid) return { alreadyPaid: true, payload };
  payload.paid = true;
  payload.paidBy = bankId || null;
  payload.paidAt = new Date().toISOString();
  return { alreadyPaid: false, payload };
}

module.exports = { createPayload, getPayload, markPaid };
