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
  const previousSecret = process.env.ANYCHAT_BRIDGE_SECRET;
  process.env.ANYCHAT_BRIDGE_SECRET = "inbound-adapter-test";
  delete require.cache[modulePath];
  t.after(() => {
    delete admin.firestore;
    require.cache[modulePath] = cached;
    if (previousSecret === undefined) {
      delete process.env.ANYCHAT_BRIDGE_SECRET;
    } else {
      process.env.ANYCHAT_BRIDGE_SECRET = previousSecret;
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
