"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const admin = require("firebase-admin");

test("index.js initializes the default Firebase app and exposes health",
    () => {
      const index = require("../index.js");

      assert.equal(typeof index.health, "function");
      assert.ok(index.health.__trigger, "health must be a Cloud Function");

      const app = admin.app();
      assert.equal(app.name, "[DEFAULT]");
    });

test("health endpoint responds 200 with an ok status", async () => {
  const index = require("../index.js");

  const res = {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };

  await index.health({}, res);

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body, {status: "ok"});
});

test("index.js exposes the speech token callable", () => {
  const index = require("../index.js");

  assert.equal(typeof index.getSpeechAccessToken, "function");
  assert.ok(
      index.getSpeechAccessToken.__trigger,
      "getSpeechAccessToken must be wrapped in functions.https.onCall",
  );
});

test("inbound adapters use explicit Firestore timestamp exports", async (t) => {
  const {FieldValue} = require("firebase-admin/firestore");
  const writes = [];
  const doc = (path) => ({
    path,
    collection: (name) => collection(`${path}/${name}`),
    set: async (data, options) => writes.push({path, data, options}),
  });
  const collection = (path) => ({
    doc: (id) => doc(`${path}/${id}`),
  });
  const db = {
    collection,
    runTransaction: async (callback) => callback({
      get: async () => ({exists: false}),
      set: (ref, data, options) => {
        writes.push({path: ref.path, data, options});
      },
    }),
  };
  // Match runtimes where firestore is callable but has no namespace exports.
  Object.defineProperty(admin, "firestore", {
    configurable: true,
    value: () => db,
  });
  t.mock.method(admin, "initializeApp", () => admin.app());
  const modulePath = require.resolve("../index.js");
  const cached = require.cache[modulePath];
  const previousSecret = process.env.TANDIVOX_BRIDGE_SECRET;
  process.env.TANDIVOX_BRIDGE_SECRET = "inbound-adapter-test";
  delete require.cache[modulePath];
  t.after(() => {
    delete admin.firestore;
    require.cache[modulePath] = cached;
    if (previousSecret === undefined) {
      delete process.env.TANDIVOX_BRIDGE_SECRET;
    } else {
      process.env.TANDIVOX_BRIDGE_SECRET = previousSecret;
    }
  });
  const index = require("../index.js");
  const res = {
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
  await index.inboundSms({
    get: () => "Bearer inbound-adapter-test",
    body: {
      id: 42, uid: "owner", from: "+15551234567", body: "Hello",
      sid: "SM-test", createdAt: 1234,
    },
  }, res);

  assert.equal(res.statusCode, 200, JSON.stringify(res.body));
  assert.deepEqual(res.body, {ok: true});
  assert.deepEqual(writes, [
    {
      path: "conversations/sms-owner-15551234567",
      data: {
        participants: ["owner", "sms:+15551234567"],
        smsOwner: "owner", smsContact: "+15551234567",
        timestamp: FieldValue.serverTimestamp(),
      },
      options: {merge: true},
    },
    {
      path: "users/owner/conversations/sms-owner-15551234567",
      data: {incomingLanguage: "en", outgoingLanguage: "en"},
      options: undefined,
    },
    {
      path: "conversations/sms-owner-15551234567/messages/sms-42",
      data: {
        senderId: "sms:+15551234567", text: "Hello",
        timestamp: FieldValue.serverTimestamp(), channel: "sms-inbound",
        smsProviderId: "SM-test", smsReceivedAt: 1234,
      },
      options: {merge: true},
    },
  ]);
});

test("outbound adapter commits transactional claim before fetch", async (t) => {
  const {FieldValue} = require("firebase-admin/firestore");
  const cid = "sms-owner-15551234567";
  const path = `conversations/${cid}/messages/m1`;
  let message = {channel: "sms", smsStatus: "pending", senderId: "owner",
    text: "persisted body"};
  const events = [];
  let rejectCommit = true;
  const doc = (refPath) => ({
    path: refPath,
    get: async () => ({exists: true, data: () => ({
      smsOwner: "owner", smsContact: "+15551234567",
      participants: ["owner", "sms:+15551234567"],
    })}),
    update: async (fields) => {
      assert.equal(refPath, path);
      events.push("final-write");
      message = {...message, ...fields};
    },
  });
  const db = {
    doc,
    collection: () => ({doc: (id) => doc(`conversations/${id}`)}),
    runTransaction: async (callback) => {
      let queued;
      const result = await callback({
        get: async (ref) => {
          assert.equal(ref.path, path);
          events.push("transaction-read");
          return {exists: true, data: () => message};
        },
        update: (ref, fields) => {
          assert.equal(ref.path, path);
          assert.deepEqual(fields, {smsStatus: "sending",
            smsClaimedAt: FieldValue.serverTimestamp()});
          queued = fields;
        },
      });
      if (rejectCommit) throw new Error("commit unavailable");
      if (queued) message = {...message, ...queued};
      events.push("commit");
      return result;
    },
  };
  Object.defineProperty(admin, "firestore", {
    configurable: true, value: () => db,
  });
  t.mock.method(admin, "initializeApp", () => admin.app());
  t.mock.method(global, "fetch", async (url, init) => {
    assert.equal(message.smsStatus, "sending");
    assert.equal(JSON.parse(init.body).body, "persisted body");
    events.push("fetch");
    return {ok: true, status: 202};
  });
  const modulePath = require.resolve("../index.js");
  const cached = require.cache[modulePath];
  delete require.cache[modulePath];
  t.after(() => {
    delete admin.firestore;
    require.cache[modulePath] = cached;
  });
  const index = require("../index.js");
  const invoke = () => index.relaySmsMessage.run(
      {data: () => ({...message, text: "stale body"})},
      {params: {conversationId: cid, messageId: "m1"}});
  await assert.rejects(invoke(), /commit unavailable/);
  assert.deepEqual(events, ["transaction-read"]);
  assert.equal(message.smsStatus, "pending");
  events.length = 0;
  rejectCommit = false;
  await invoke();
  await invoke();
  assert.deepEqual(events, ["transaction-read", "commit", "fetch",
    "final-write", "transaction-read", "commit"]);
  assert.equal(message.smsStatus, "sent");
});
