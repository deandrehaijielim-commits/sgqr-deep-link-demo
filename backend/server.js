const path = require("path");
const express = require("express");
const QRCode = require("qrcode");
const { createPayload, getPayload, markPaid } = require("./store");
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

// Anti-clickjacking: refuse to render any page from this app inside an
// iframe, so a malicious site can't overlay invisible bank-picker buttons
// on top of its own UI to trick users into tapping "Approve" unknowingly.
app.use((req, res, next) => {
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Content-Security-Policy", "frame-ancestors 'none'");
  next();
});

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

// Called by whichever bank app the user approves the payment in. Once a
// payload is paid, it's single-use — any other bank app trying to pay the
// same token afterwards gets a 409 so it can show "already paid" instead.
app.post("/api/payload/:token/pay", (req, res) => {
  const { bank } = req.body || {};
  const result = markPaid(req.params.token, bank);
  if (!result) return res.status(404).json({ error: "payload not found" });
  if (result.alreadyPaid) {
    return res.status(409).json({ error: "payment already completed", payload: result.payload });
  }
  res.json(result.payload);
});

// ==================== METHOD DEMOS ====================
// Separate, standalone apps illustrating other deep-linking mechanisms
// besides this project's core unregistered-link approach. Each is a
// deliberate contrast case — see SGQR_Complete_Project_Documentation.docx
// for the full comparison.

// Digital Asset Links file for method_applinks (Verified Android App Links).
// Android checks this against the app's real signing certificate at install
// time; if it matches, the app becomes the sole verified owner of
// /methods/applinks/* and opens directly with no chooser.
app.get("/.well-known/assetlinks.json", (req, res) => {
  res.json([
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: "com.sgqrdemo.methodapplinks",
        sha256_cert_fingerprints: [
          "D7:87:13:E6:43:7B:0D:B4:D3:97:00:92:B2:07:CE:8D:58:0F:FA:B5:FF:B7:E3:1C:7C:56:30:A8:9D:04:A3:1E",
        ],
      },
    },
  ]);
});

// Reached only if verification failed or the app isn't installed — a
// genuinely verified App Link never lets the browser see this at all.
app.get("/methods/applinks/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  res.send(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Verified App Links demo</title></head>
  <body style="font-family:-apple-system,Helvetica,Arial,sans-serif;max-width:420px;margin:40px auto;padding:0 16px;">
  <h2>You're seeing this in a browser</h2>
  <p>If the "AppLinks Demo" app were installed and its App Link verification succeeded, Android would have opened it directly — this page would never have been reached.</p>
  <p>Install the app, then tap this same link again to see the difference.</p>
  <p style="color:#888;font-size:0.85rem">token: ${payload.token}</p>
  </body></html>`);
});

// Apple's equivalent of assetlinks.json for method_universallinks (Verified
// iOS Universal Links). iOS fetches this once at install/update time over
// HTTPS and, if the app's Team ID + bundle ID match, treats the app as sole
// verified owner of /methods/universallinks/* — the link then opens the
// app directly with no Safari, no prompt of any kind. Must be served with
// no file extension and content-type application/json (no .json suffix,
// unlike Android's assetlinks.json).
app.get("/.well-known/apple-app-site-association", (req, res) => {
  res.json({
    applinks: {
      details: [
        {
          appID: "HBT73QTC22.com.sgqrdemo.methodUniversallinks",
          paths: ["/methods/universallinks/*"],
        },
      ],
    },
  });
});

// Reached only if verification failed or the app isn't installed — a
// genuinely verified Universal Link never lets Safari see this at all.
app.get("/methods/universallinks/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  res.send(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Verified Universal Links demo</title></head>
  <body style="font-family:-apple-system,Helvetica,Arial,sans-serif;max-width:420px;margin:40px auto;padding:0 16px;">
  <h2>You're seeing this in Safari</h2>
  <p>If the "UniversalLinks Demo" app were installed and its Universal Link verification succeeded, iOS would have opened it directly — this page would never have been reached.</p>
  <p>Install the app, then tap this same link again to see the difference.</p>
  <p style="color:#888;font-size:0.85rem">token: ${payload.token}</p>
  </body></html>`);
});

// iOS Smart App Banner demo (method_smartbanner). The <meta name="apple-itunes-app">
// tag is what triggers Safari's banner — no entitlement, no hosted
// verification file, nothing server-side to prove ownership. Apple instead
// validates the app-id against a REAL App Store listing before ever
// rendering the banner. Since this demo app is sideloaded and unpublished,
// the banner cannot actually appear no matter how correct this tag is —
// documented here and in the app itself.
app.get("/methods/smartbanner/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  const appArgument = `smartbannerdemo://pay?token=${payload.token}`;
  res.send(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="apple-itunes-app" content="app-id=0000000000, app-argument=${appArgument}">
  <title>Smart App Banner demo</title></head>
  <body style="font-family:-apple-system,Helvetica,Arial,sans-serif;max-width:420px;margin:40px auto;padding:0 16px;">
  <h2>Smart App Banner demo page</h2>
  <p>This page carries a real &lt;meta name="apple-itunes-app"&gt; tag. On a genuinely published app, Safari would show a banner up top offering to open (or install) it.</p>
  <p>Because this demo app isn't on the App Store, Safari has nothing to validate the app-id against, so no banner appears here — that's expected, not a bug.</p>
  <p>If you have the app installed, you can still open it directly to see how it reads the same app-argument value a real banner tap would deliver:</p>
  <p><a href="${appArgument}">${appArgument}</a></p>
  <p style="color:#888;font-size:0.85rem">token: ${payload.token}</p>
  </body></html>`);
});

app.get("/methods/smartbanner/qr/:token", async (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("payload not found");
  const url = `${BASE_URL}/methods/smartbanner/${payload.token}`;
  try {
    const png = await QRCode.toBuffer(url, { width: 320, margin: 2 });
    res.type("png").send(png);
  } catch (err) {
    res.status(500).send("failed to generate QR");
  }
});

// Android explicit-package intent demo (method_explicit_intent). No
// autoVerify, no assetlinks.json, no domain proof at all — this page's
// "Open" link is an intent:// URI that names the target package directly
// (package=com.sgqrdemo.method_explicit_intent). Android has nothing left
// to disambiguate when exactly one package is named, so it skips the
// chooser unconditionally, the same no-chooser outcome as method_applinks
// but reached by a completely different mechanism: the sender states the
// answer instead of the OS verifying it. This only makes sense when
// whoever generates the link already knows which app should open it —
// the opposite of this project's core "any of 3 banks" scenario.
app.get("/methods/explicitintent/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  const intentUrl =
    `intent://pay?token=${encodeURIComponent(payload.token)}` +
    `#Intent;scheme=explicitintentdemo;package=com.sgqrdemo.method_explicit_intent;end`;
  res.send(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Explicit Package Intent demo</title></head>
  <body style="font-family:-apple-system,Helvetica,Arial,sans-serif;max-width:420px;margin:40px auto;padding:0 16px;">
  <h2>Explicit package intent demo</h2>
  <p>This link names <code>com.sgqrdemo.method_explicit_intent</code> directly — Android has nothing to disambiguate, so tapping below skips any chooser, even with other bank apps installed.</p>
  <p><a href="${intentUrl}" style="display:inline-block;padding:14px 20px;background:#E07A5F;color:white;border-radius:10px;text-decoration:none;font-weight:600;">Open ExplicitIntent Demo</a></p>
  <p style="color:#888;font-size:0.85rem">token: ${payload.token}</p>
  </body></html>`);
});

app.get("/methods/explicitintent/qr/:token", async (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("payload not found");
  const url = `${BASE_URL}/methods/explicitintent/${payload.token}`;
  try {
    const png = await QRCode.toBuffer(url, { width: 320, margin: 2 });
    res.type("png").send(png);
  } catch (err) {
    res.status(500).send("failed to generate QR");
  }
});

app.get("/methods/universallinks/qr/:token", async (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("payload not found");
  const url = `${BASE_URL}/methods/universallinks/${payload.token}`;
  try {
    const png = await QRCode.toBuffer(url, { width: 320, margin: 2 });
    res.type("png").send(png);
  } catch (err) {
    res.status(500).send("failed to generate QR");
  }
});

app.get("/methods/applinks/qr/:token", async (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("payload not found");
  const url = `${BASE_URL}/methods/applinks/${payload.token}`;
  try {
    const png = await QRCode.toBuffer(url, { width: 320, margin: 2 });
    res.type("png").send(png);
  } catch (err) {
    res.status(500).send("failed to generate QR");
  }
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

// This is the universal-link target encoded in the QR. Android apps register
// an unverified intent-filter for this host — verifying it would let Android
// silently resolve to one app instead of prompting, which defeats the
// chooser; iOS has no hosted apple-app-site-association, so it always lands
// here in Safari.
app.get("/pay/:token", (req, res) => {
  const payload = getPayload(req.params.token);
  if (!payload) return res.status(404).send("Payment not found or expired.");
  res.sendFile(path.join(__dirname, "public", "pay.html"));
});

app.listen(PORT, () => {
  console.log(`SGQR deep-link backend running at ${BASE_URL}`);
});
