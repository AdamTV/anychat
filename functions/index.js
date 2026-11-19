"use strict";

/* global fetch */

const functions = require("firebase-functions");

const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
admin.initializeApp(functions.config().firebase);

const {GoogleAuth} = require("google-auth-library");

const {createGetSpeechAccessToken} = require("./speech_token");

const {resolveBridgeSecret} = require("./bridge_secret");

// The reCAPTCHA Enterprise assessment sample lives in ./assessment.js and is
// covered by unit tests (test/assessment.test.js). Require it here and wire it
// up as an HTTPS callable when the endpoint is needed:
// const {createAssessment} = require("./assessment");

/**
 * Mints a short-lived Google access token with the credentials of the
 * function's own runtime service account (Application Default
 * Credentials), so no private key ships with the app or the repo.
 *
 * @param {Array<string>} scopes OAuth scopes the token must carry.
 * @return {Promise<{token: string, expirationTime: string}>} The token
 *   and its expiry.
 */
async function mintAccessToken(scopes) {
  const client = await new GoogleAuth({scopes}).getClient();
  const {token} = await client.getAccessToken();
  if (!token) {
    throw new Error("Application Default Credentials returned no token");
  }
  // ADC access tokens live for about an hour; advertise a shorter lifetime
  // so the app refreshes its credentials before the real expiry.
  return {
    token,
    expirationTime: new Date(Date.now() + 55 * 60 * 1000).toISOString(),
  };
}

/**
 * Health check endpoint. Always answers 200 so agents and monitors can
 * verify that the functions deployment is up and serving requests.
 */
exports.health = functions.https.onRequest((req, res) => {
  res.status(200).json({status: "ok"});
});

/**
 * Speech-to-Text access tokens for signed-in app users. The app used to
 * bundle a service-account key; it now calls this endpoint instead.
 */
exports.getSpeechAccessToken = functions.https.onCall(
    /** @type {(d: Object, c: Object) => Promise<Object>} */
    (createGetSpeechAccessToken({getAccessToken: mintAccessToken})));

// --- alpha-text SMS bridge ---
//
// anychat talks to real phone numbers through the alpha-text backend: a
// shared pool of Twilio numbers routed per contact (one number may serve
// many users, but only one user per contact, so replies are unambiguous).
//
//   outbound: the client writes a message doc with channel "sms"; the
//             trigger claims it and records sent/failed/unknown.
//   inbound:  alpha-text POSTs here with Bearer TANDIVOX_BRIDGE_SECRET (legacy
//             ANYCHAT_BRIDGE_SECRET still accepted) and
//             the handler writes the message into the same conversation,
//             so the existing chat UI and translation pipeline pick it up.

const {
  SMS_INBOUND_CHANNEL,
  createInboundSmsHandler,
  createSmsRelay,
  claimSmsMessage,
  smsContactParticipantId,
  smsConversationId,
  upsertSmsConversation,
} = require("./sms_bridge");

/**
 * Bridge configuration from the functions environment. ALPHA_TEXT_URL and
 * the two secrets come from functions/.env or Secret Manager. The bridge
 * secret resolves from TANDIVOX_BRIDGE_SECRET, falling back to the legacy
 * ANYCHAT_BRIDGE_SECRET (see resolveBridgeSecret).
 *
 * @return {{alphaTextUrl: string, alphaTextApiKey: string,
 *   bridgeSecret: string}} Bridge configuration.
 */
function smsBridgeConfig() {
  return {
    alphaTextUrl: process.env.ALPHA_TEXT_URL || "",
    alphaTextApiKey: process.env.ALPHA_TEXT_API_KEY || "",
    bridgeSecret: resolveBridgeSecret(process.env),
  };
}

/**
 * Reads one conversation doc as plain data.
 *
 * @param {string} conversationId Conversation document id.
 * @return {Promise<*>} The doc data, or null when missing.
 */
async function getConversationData(conversationId) {
  const snap = await admin.firestore()
      .collection("conversations")
      .doc(conversationId)
      .get();
  if (!snap.exists) {
    return null;
  }
  const data = snap.data();
  return data || null;
}

/**
 * Ensures the deterministic SMS conversation exists: the conversation doc
 * plus the per-user conversation info the chat list and translation
 * pipeline read. Languages default to the user's own language only when
 * the info doc is first created; existing settings are preserved.
 *
 * @param {{uid: string, contact: string}} row Normalized inbound row.
 * @return {Promise<void>} Resolves when the transaction commits.
 */
async function resolveSmsConversation(row) {
  const db = admin.firestore();
  const conversationId = smsConversationId(row.uid, row.contact);
  const user = db.collection("users").doc(row.uid);
  await db.runTransaction((tx) => upsertSmsConversation(tx, {
    conversation: db.collection("conversations").doc(conversationId),
    info: user.collection("conversations").doc(conversationId),
    user,
  }, row, FieldValue.serverTimestamp()));
}

/**
 * Writes one inbound SMS as a message doc. The doc id is derived from the
 * alpha-text row id, so webhook retries are idempotent.
 *
 * @param {{uid: string, contact: string, text: string, messageId: string,
 *   providerId: ?string, receivedAt: ?number}} row Normalized inbound row.
 * @return {Promise<void>} Resolves when the doc is written.
 */
async function writeSmsMessage(row) {
  const conversationId = smsConversationId(row.uid, row.contact);
  await admin.firestore()
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .doc(`sms-${row.messageId}`)
      .set({
        senderId: smsContactParticipantId(row.contact),
        text: row.text,
        timestamp: FieldValue.serverTimestamp(),
        channel: SMS_INBOUND_CHANNEL,
        smsProviderId: row.providerId,
        smsReceivedAt: row.receivedAt,
      }, {merge: true});
}

/**
 * Outbound relay: message docs marked channel "sms" are POSTed to
 * alpha-text with the writer's uid after a transactional pending -> sending
 * claim, then stamped sent/failed/unknown.
 * Non-SMS/nonpending docs are untouched.
 */
exports.relaySmsMessage = functions.firestore
    .document("conversations/{conversationId}/messages/{messageId}")
    .onCreate(
        /** @type {(snapshot: *, context: *) => Promise<void>} */
        (createSmsRelay({
          fetchFn: fetch,
          config: smsBridgeConfig(),
          getConversation: getConversationData,
          claimMessage: async (
              /** @type {string} */ conversationId,
              /** @type {string} */ messageId) => {
            const db = admin.firestore();
            const ref = db.doc(
                `conversations/${conversationId}/messages/${messageId}`);
            return db.runTransaction((tx) =>
              claimSmsMessage(tx, ref, FieldValue.serverTimestamp()));
          },
          updateMessage: async (
              /** @type {string} */ conversationId,
              /** @type {string} */ messageId,
              /** @type {*} */ fields) => {
            await admin.firestore()
                .doc(`conversations/${conversationId}/messages/${messageId}`)
                .update(fields);
          },
        })));

/**
 * Inbound endpoint: POST /inboundSms with Bearer TANDIVOX_BRIDGE_SECRET
 * (legacy ANYCHAT_BRIDGE_SECRET still accepted) carrying alpha-text's
 * MessageRow JSON.
 */
// Public at the IAM layer: alpha-text cannot mint Google identity tokens, so
// the bearer bridge secret is the only gate.
exports.inboundSms = functions.runWith({invoker: "public"}).https.onRequest(
    /** @type {(req: *, res: *) => Promise<void>} */
    (createInboundSmsHandler({
      config: smsBridgeConfig(),
      resolveConversation: resolveSmsConversation,
      writeMessage: writeSmsMessage,
    })));
