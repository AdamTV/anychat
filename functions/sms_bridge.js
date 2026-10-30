"use strict";

const {timingSafeEqual} = require("node:crypto");

/**
 * Channel marker the anychat client writes on outbound SMS message docs.
 * Only docs carrying this marker are relayed to the telephony backend, so
 * normal anychat-to-anychat chat never leaves Firestore.
 *
 * @type {string}
 */
const SMS_OUTBOUND_CHANNEL = "sms";

/**
 * Channel marker this bridge writes on inbound SMS message docs. Distinct
 * from the outbound marker so the relay never re-sends an inbound message.
 *
 * @type {string}
 */
const SMS_INBOUND_CHANNEL = "sms-inbound";

/**
 * Longest outbound SMS body the relay will send (Twilio's message limit).
 * Firestore rules enforce the same bound on client writes.
 *
 * @type {number}
 */
const SMS_MAX_TEXT_LENGTH = 1600;

/**
 * Fetch-like POST to the alpha-text backend.
 *
 * @typedef {(url: *, init: *) => Promise<{ok: boolean}>} FetchFn
 */

/**
 * Reads one conversation doc as plain data by id.
 *
 * @typedef {(conversationId: string) => Promise<*>} GetConversationFn
 */

/**
 * Applies a status update to one message doc.
 *
 * @typedef {(conversationId: string, messageId: string,
 *   fields: *) => Promise<void>} UpdateMessageFn
 */

/**
 * A Firestore onCreate snapshot, trimmed to what the relay reads.
 *
 * @typedef {Object} MessageSnapshot
 * @property {() => *} data Returns the doc data.
 */

/**
 * A Firestore trigger context, trimmed to what the relay reads.
 *
 * @typedef {Object} TriggerContext
 * @property {{conversationId: string, messageId: string}} params
 *   Path params of the written doc.
 */

/**
 * Dependencies injected into createSmsRelay.
 *
 * @typedef {Object} SmsRelayOptions
 * @property {FetchFn} fetchFn Fetch-like POST.
 * @property {{alphaTextUrl: string, alphaTextApiKey: string}} config
 *   Backend base URL and bearer key.
 * @property {GetConversationFn} getConversation Conversation reader.
 * @property {UpdateMessageFn} updateMessage Message updater.
 */

/**
 * An Express-ish request, trimmed to what the inbound handler reads.
 *
 * @typedef {Object} BridgeRequest
 * @property {(name: string) => (string|undefined)} get Reads a header.
 * @property {*} body The parsed request body.
 */

/**
 * An Express-ish response, trimmed to what the inbound handler uses.
 *
 * @typedef {Object} BridgeResponse
 * @property {(code: number) => *} status Sets the status code.
 * @property {(payload: Object) => *} json Sends a JSON body.
 */

/**
 * Dependencies injected into createInboundSmsHandler.
 *
 * @typedef {Object} InboundHandlerOptions
 * @property {{bridgeSecret: string}} config Shared bridge secret.
 * @property {(row: *) => Promise<void>} resolveConversation
 *   Creates or merges the conversation + per-user conversation info docs.
 * @property {(row: *) => Promise<void>} writeMessage
 *   Writes the message doc (idempotent on the provider row id).
 */

/**
 * Digits of a phone contact. Inputs are E.164 strings ("+15550100"), but
 * this stays defensive so odd provider formats still produce a stable id.
 *
 * @param {string} contact Phone number in any textual format.
 * @return {string} The digits only.
 */
function smsDigits(contact) {
  return String(contact).replace(/[^0-9]/g, "");
}

/**
 * Deterministic conversation id for (uid, phone contact). The anychat client
 * uses the same function when it starts an SMS thread, so an inbound reply
 * lands in the thread the user already has open — no Firestore query needed.
 *
 * @param {string} uid The anychat user's Firebase uid.
 * @param {string} contact The phone contact, E.164 preferred.
 * @return {string} Conversation document id.
 */
function smsConversationId(uid, contact) {
  return `sms-${uid}-${smsDigits(contact)}`;
}

/**
 * Synthetic participant id representing a phone contact inside anychat. It
 * never resolves to a real users/{id} doc, which the chat UI already
 * tolerates by rendering a placeholder sender.
 *
 * @param {string} contact The phone contact, E.164 preferred.
 * @return {string} Participant id, e.g. "sms:+15550100".
 */
function smsContactParticipantId(contact) {
  return `sms:+${smsDigits(contact)}`;
}

/**
 * Canonical E.164 form of a phone contact: formatting characters (spaces,
 * dots, dashes, parentheses) are dropped and the result must be "+" followed
 * by 7-15 digits with no leading zero. Firestore rules require this exact
 * form for smsContact, so the client, bridge, and relay agree on one id per
 * contact.
 *
 * @param {*} contact Phone number in any textual format.
 * @return {?string} The canonical contact, or null when it is not E.164.
 */
function canonicalSmsContact(contact) {
  if (typeof contact !== "string") {
    return null;
  }
  const compact = contact.replace(/[\s().-]/g, "");
  return /^\+[1-9][0-9]{6,14}$/.test(compact) ? compact : null;
}

/**
 * A string field read defensively from an untrusted payload.
 *
 * @param {*} value Any value from the request body.
 * @return {string} The value when it is a string, else "".
 */
function optionalString(value) {
  return typeof value === "string" ? value : "";
}

/**
 * Validates and normalizes the alpha-text inbound payload (its MessageRow
 * JSON: {id, uid, sid, direction, from, to, body, status, createdAt}).
 *
 * @param {Object|null|undefined} body The parsed request body.
 * @return {?{uid: string, contact: string, text: string, messageId: string,
 *   providerId: ?string, receivedAt: ?number}} Normalized row, or null when
 *   the payload is unusable.
 */
function normalizeInboundRow(body) {
  if (!body || typeof body !== "object") {
    return null;
  }
  const raw = /** @type {*} */ (body);
  const uid = optionalString(raw.uid);
  const contact = canonicalSmsContact(raw.from);
  if (!isDocumentIdPart(uid) || !contact || !isDocumentIdPart(raw.id)) {
    return null;
  }
  const sid = optionalString(raw.sid);
  return {
    uid,
    contact,
    text: optionalString(raw.body),
    messageId: String(raw.id),
    providerId: sid || null,
    receivedAt: typeof raw.createdAt === "number" ? raw.createdAt : null,
  };
}

/**
 * True for a non-empty string or number usable inside a Firestore document
 * id (no "/" path separator).
 *
 * @param {*} value Any value from the request body.
 * @return {boolean} Whether the value is a safe id part.
 */
function isDocumentIdPart(value) {
  if (typeof value === "number") {
    return Number.isFinite(value);
  }
  return typeof value === "string" && value.length > 0 &&
      value.length <= 128 && !value.includes("/");
}

/**
 * Why an outbound message doc must not be relayed, judged on the message
 * fields alone.
 *
 * @param {*} data The message doc data.
 * @return {?string} A failure code, or null when the message is relayable.
 */
function outboundMessageError(data) {
  if (data.smsStatus !== "pending") {
    return "invalid-status";
  }
  if (typeof data.senderId !== "string" || !data.senderId) {
    return "invalid-sender";
  }
  if (typeof data.text !== "string" || !data.text ||
      data.text.length > SMS_MAX_TEXT_LENGTH) {
    return "invalid-text";
  }
  return null;
}

/**
 * Why a conversation must not carry an outbound SMS from senderId. The
 * conversation has to be the sender's own deterministic SMS thread: owned
 * by the sender, bound to one canonical contact, with exactly the owner and
 * that contact as participants. This is defense in depth behind the
 * Firestore rules, so malformed or forged data cannot spend money.
 *
 * @param {string} conversationId The conversation document id.
 * @param {*} conversation The conversation doc data, or null.
 * @param {string} senderId The message's senderId.
 * @return {?string} A failure code, or null when the thread is valid.
 */
function smsConversationError(conversationId, conversation, senderId) {
  if (!conversation) {
    return "missing-conversation";
  }
  const contact = canonicalSmsContact(conversation.smsContact);
  if (!contact || contact !== conversation.smsContact) {
    return "invalid-contact";
  }
  if (conversation.smsOwner !== senderId) {
    return "not-owner";
  }
  if (conversationId !== smsConversationId(senderId, contact)) {
    return "id-mismatch";
  }
  const participants = conversation.participants;
  const expected = [senderId, smsContactParticipantId(contact)];
  if (!Array.isArray(participants) || participants.length !== 2 ||
      participants.some((id, i) => id !== expected[i])) {
    return "invalid-participants";
  }
  return null;
}

/**
 * Timing-safe check of the "Authorization: Bearer <secret>" header.
 *
 * @param {string|undefined} header The Authorization header value.
 * @param {string} secret The shared bridge secret.
 * @return {boolean} True when the header matches the secret.
 */
function isAuthorized(header, secret) {
  if (!header || !secret) {
    return false;
  }
  const presented = Buffer.from(String(header));
  const expected = Buffer.from(`Bearer ${secret}`);
  return presented.length === expected.length &&
      timingSafeEqual(presented, expected);
}

/**
 * Creates the outbound relay: a Firestore onCreate trigger handler that
 * POSTs message docs marked channel "sms" to the alpha-text backend
 * (POST {ALPHA_TEXT_URL}/api/messages with X-User-Uid: senderId), then marks
 * the doc smsStatus "sent" or "failed". Everything else is left untouched.
 * Messages that fail validation (see outboundMessageError and
 * smsConversationError) are never sent and get smsStatus "failed" plus an
 * smsError code.
 *
 * @param {SmsRelayOptions} options Injected dependencies.
 * @return {*} The trigger handler: (snap, context) => Promise<void>. The
 *   inline annotations below carry the full signature for TypeScript.
 */
function createSmsRelay({fetchFn, config, getConversation, updateMessage}) {
  return async (/** @type {MessageSnapshot} */ snap,
      /** @type {TriggerContext} */ context) => {
    const data = snap.data() || {};
    if (data.channel !== SMS_OUTBOUND_CHANNEL) {
      return;
    }
    const {conversationId, messageId} = context.params;
    let error = outboundMessageError(data);
    if (!error && !conversationId.startsWith("sms-")) {
      error = "not-sms-conversation";
    }
    const conversation = error ? null : await getConversation(conversationId);
    error = error ||
        smsConversationError(conversationId, conversation, data.senderId);
    if (error) {
      await updateMessage(conversationId, messageId,
          {smsStatus: "failed", smsError: error});
      return;
    }
    // TODO(TD-005): claim the message before sending; trigger redelivery
    // currently sends the same SMS twice.
    let ok = false;
    try {
      const response = await fetchFn(
          `${config.alphaTextUrl.replace(/\/+$/, "")}/api/messages`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${config.alphaTextApiKey}`,
              "Content-Type": "application/json",
              "X-User-Uid": data.senderId,
            },
            body: JSON.stringify({to: conversation.smsContact,
              body: data.text}),
          });
      ok = response.ok;
    } catch (/** @type {*} */ err) {
      ok = false;
    }
    await updateMessage(conversationId, messageId,
        {smsStatus: ok ? "sent" : "failed"});
  };
}

/**
 * Creates the inbound HTTPS handler: alpha-text POSTs an attributed SMS
 * (MessageRow JSON, Bearer bridge secret) and the bridge writes it into the
 * deterministic SMS conversation, so the existing chat UI, realtime
 * listeners, and translation pipeline pick it up with no client changes.
 *
 * @param {InboundHandlerOptions} options Injected dependencies.
 * @return {*} The request handler: (req, res) => Promise<void>. The inline
 *   annotations below carry the full signature for TypeScript.
 */
function createInboundSmsHandler({config, resolveConversation, writeMessage}) {
  return async (/** @type {BridgeRequest} */ req,
      /** @type {BridgeResponse} */ res) => {
    if (!isAuthorized(req.get("authorization"), config.bridgeSecret)) {
      res.status(401).json({ok: false, error: "invalid bridge secret"});
      return;
    }
    const row = normalizeInboundRow(req.body);
    if (!row) {
      res.status(400).json({ok: false, error: "invalid inbound payload"});
      return;
    }
    try {
      await resolveConversation(row);
      await writeMessage(row);
      res.status(200).json({ok: true});
    } catch (/** @type {*} */ err) {
      res.status(500).json({ok: false, error: String(err)});
    }
  };
}

/**
 * Upserts the deterministic SMS conversation inside a Firestore transaction:
 * merges the conversation doc and creates the per-user conversation info doc
 * only when it is missing. Language settings the user already chose are
 * never overwritten by later inbound messages. All reads happen before any
 * write, as Firestore transactions require.
 *
 * @param {*} tx Firestore transaction (get/set).
 * @param {{conversation: *, info: *, user: *}} refs Document references.
 * @param {{uid: string, contact: string}} row Normalized inbound row.
 * @param {*} timestamp Value stored as the conversation timestamp.
 * @return {Promise<void>} Resolves once the writes are queued.
 */
async function upsertSmsConversation(tx, refs, row, timestamp) {
  const infoSnap = await tx.get(refs.info);
  const userSnap = infoSnap.exists ? null : await tx.get(refs.user);
  tx.set(refs.conversation, {
    participants: [row.uid, smsContactParticipantId(row.contact)],
    smsOwner: row.uid,
    smsContact: row.contact,
    timestamp,
  }, {merge: true});
  if (userSnap) {
    const user = userSnap.exists ? userSnap.data() : null;
    const language = (user && user.language) || "en";
    tx.set(refs.info, {incomingLanguage: language, outgoingLanguage: language});
  }
}

module.exports = {
  SMS_OUTBOUND_CHANNEL,
  SMS_INBOUND_CHANNEL,
  SMS_MAX_TEXT_LENGTH,
  smsDigits,
  canonicalSmsContact,
  outboundMessageError,
  smsConversationError,
  smsConversationId,
  smsContactParticipantId,
  normalizeInboundRow,
  isAuthorized,
  createSmsRelay,
  createInboundSmsHandler,
  upsertSmsConversation,
};
