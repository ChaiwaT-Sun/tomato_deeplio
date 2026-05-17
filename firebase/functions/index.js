/**
 * firebase/functions/index.js
 *
 * Optional serverless strategy for flutter_smart_links.
 *
 * Endpoints:
 *   POST /api/deferred   — store a deferred link token
 *   GET  /api/deferred   — retrieve a deferred link by token
 *   POST /api/analytics  — receive analytics events from the web redirect page
 */

const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ── POST /api/deferred ────────────────────────────────────────────────────────
exports.smartLinksApi = onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");

  const path = req.path;

  // ── Store deferred link ──────────────────────────────────────────────────
  if (path === "/deferred" && req.method === "POST") {
    const { url, token, timestamp, referrer } = req.body;
    if (!url || !token) {
      return res.status(400).json({ error: "url and token are required" });
    }
    await db.collection("deferred_links").doc(token).set({
      url,
      token,
      timestamp: timestamp || new Date().toISOString(),
      referrer: referrer || null,
      consumed: false,
      createdAt: FieldValue.serverTimestamp(),
    });
    return res.status(201).json({ success: true, token });
  }

  // ── Retrieve deferred link ───────────────────────────────────────────────
  if (path === "/deferred" && req.method === "GET") {
    const token = req.query.token;
    if (!token) return res.status(400).json({ error: "token is required" });

    const doc = await db.collection("deferred_links").doc(token).get();
    if (!doc.exists) return res.status(404).json({ error: "not found" });

    const data = doc.data();
    if (data.consumed) return res.status(410).json({ error: "already consumed" });

    // Mark as consumed
    await doc.ref.update({ consumed: true, consumedAt: FieldValue.serverTimestamp() });
    return res.status(200).json(data);
  }

  // ── Analytics event ──────────────────────────────────────────────────────
  if (path === "/analytics" && req.method === "POST") {
    const event = req.body;
    if (!event || !event.type) {
      return res.status(400).json({ error: "event.type is required" });
    }
    await db.collection("link_events").add({
      ...event,
      serverTimestamp: FieldValue.serverTimestamp(),
    });
    return res.status(201).json({ success: true });
  }

  return res.status(404).json({ error: "not found" });
});
