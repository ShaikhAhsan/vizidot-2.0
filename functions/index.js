/**
 * Firebase Cloud Functions for Vizidot.
 * Deploy: firebase deploy --only functions
 *
 * sendPushNotification - HTTP function. Call from your API server with a shared secret.
 */

const { onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const functions = require('firebase-functions');

setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

const FCM_BATCH_SIZE = 500;
const CONCURRENT_BATCHES = 5;

function chunk(arr, n) {
  const out = [];
  for (let i = 0; i < arr.length; i += n) out.push(arr.slice(i, i + n));
  return out;
}

function stringifyData(data) {
  if (!data || typeof data !== 'object') return undefined;
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    out[String(k)] = v === null || v === undefined ? '' : String(v);
  }
  return Object.keys(out).length ? out : undefined;
}

/**
 * POST body: { secret, title, message, fcmTokens, data?, imageUrl? }
 * Set SEND_PUSH_SECRET in Firebase Functions config; your API sends the same value as "secret".
 */
exports.sendPushNotification = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ success: false, error: 'Method not allowed' });
      return;
    }

    const expectedSecret = process.env.SEND_PUSH_SECRET || functions.config().send_push?.secret;
    if (!expectedSecret) {
      console.error('SEND_PUSH_SECRET is not set in Firebase config');
      res.status(500).json({ success: false, error: 'Server configuration error' });
      return;
    }

    let body;
    try {
      body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body || {};
    } catch (_) {
      res.status(400).json({ success: false, error: 'Invalid JSON body' });
      return;
    }

    const { secret, title, message, fcmTokens, data, imageUrl } = body;
    if (secret !== expectedSecret) {
      res.status(401).json({ success: false, error: 'Unauthorized' });
      return;
    }
    if (!title || !message) {
      res.status(400).json({ success: false, error: 'title and message are required' });
      return;
    }

    const tokens = [...new Set((fcmTokens || []).filter((t) => t && String(t).trim()))];
    const dataPayload = stringifyData(data);

    const notification = {
      title: String(title).slice(0, 255),
      body: String(message)
    };
    if (imageUrl && String(imageUrl).trim()) notification.imageUrl = String(imageUrl).trim();

    const baseMessage = {
      notification,
      ...(dataPayload && Object.keys(dataPayload).length > 0 && { data: dataPayload })
    };
    baseMessage.android = { priority: 'high' };
    baseMessage.apns = { payload: { aps: { sound: 'default' } } };
    if (imageUrl && String(imageUrl).trim()) {
      baseMessage.apns.fcmOptions = { imageUrl: String(imageUrl).trim() };
      baseMessage.apns.payload.aps['mutable-content'] = 1;
    }

    if (tokens.length === 0) {
      res.json({ success: true, successCount: 0, failureCount: 0, total: 0 });
      return;
    }

    try {
      const messaging = admin.messaging();
      const batches = chunk(tokens, FCM_BATCH_SIZE);
      const errors = [];
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < batches.length; i += CONCURRENT_BATCHES) {
        const slice = batches.slice(i, i + CONCURRENT_BATCHES);
        const results = await Promise.allSettled(
          slice.map((tokenBatch) =>
            messaging.sendEachForMulticast({
              tokens: tokenBatch,
              ...baseMessage
            })
          )
        );
        results.forEach((r, idx) => {
          const tokenBatch = slice[idx];
          if (r.status === 'fulfilled' && r.value) {
            successCount += r.value.successCount || 0;
            failureCount += r.value.failureCount || 0;
            (r.value.responses || []).forEach((resp, j) => {
              if (!resp.success && resp.error)
                errors.push(`${(tokenBatch && tokenBatch[j])?.slice(0, 20) || '?'}...: ${resp.error.message}`);
            });
          } else {
            failureCount += (tokenBatch && tokenBatch.length) || 0;
            if (r.reason) errors.push(r.reason.message || String(r.reason));
          }
        });
      }

      res.json({
        success: true,
        successCount,
        failureCount,
        total: tokens.length,
        errors: errors.length ? errors.slice(0, 10) : undefined
      });
    } catch (err) {
      console.error('sendPushNotification error:', err);
      res.status(500).json({
        success: false,
        error: err.message || String(err),
        code: err.code || undefined
      });
    }
  }
);
