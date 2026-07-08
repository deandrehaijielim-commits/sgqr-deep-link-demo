const path = require("path");
const express = require("express");
const QRCode = require("qrcode");
const { createPayload, getPayload } = require("./store");
const { BANKS } = require("./banks");

const app = express();
const PORT = process.env.PORT || 3000;
// BASE_URL must be a real HTTPS host for phone QR scanning to work (e.g. an ngrok
// tunnel or a deployed instance). RENDER_EXTERNAL_URL is set automatically by
// Render, so deployments there work with no extra config. Defaults to
// localhost for local dev/emulator testing.
const BASE_URL =
  process.env.BASE_URL ||
  process.env.RENDER_EXTERNAL_URL ||
  `http://localhost:${PORT}`;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.get("/api/banks", (req, res) => {
  res.json(BANKS);
});

app.post("/api/payments", (req, res) => {
  const { merchant, amount, currency, reference } = req.body || {};
  if (!merchant || !amount) {
    return res.status(400).json({ error: "merchant and amount are required" });
  }
  const payload = createPayload({ merchant, amount, currency, reference });
  const payUrl = `${BASE_URL}/pay/${payload.token}`;
  res.json({
    ...payload,
    payUrl,
    qrPngUrl: `${BASE_URL}/qr/${payload.token}`,
  });
});

app.get("/api/payload/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).json({ error: "payload not found" });
  res.json(payload);
});

app.get("/qr/:token", async (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("payload not found");
  const payUrl = `${BASE_URL}/pay/${payload.token}`;
  try {
    const png = await QRCode.toBuffer(payUrl, { width: 320, margin: 2 });
    res.type("png").send(png);
  } catch (err) {
    res.status(500).send("failed to generate QR");
  }
});

// This is the universal-link target encoded in the QR. Android apps register an
// unverified intent-filter for this host so the OS always shows its app chooser;
// iOS has no hosted apple-app-site-association, so it always lands here in Safari.
app.get("/pay/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  res.sendFile(path.join(__dirname, "public", "pay.html"));
});

app.listen(PORT, () => {
  console.log(`SGQR deep-link backend running at ${BASE_URL}`);
});
