"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
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
} = require("../sms_bridge");

test("smsDigits keeps digits only", () => {
  assert.equal(smsDigits("+1 555-0100"), "15550100");
  assert.equal(smsDigits(""), "");
});

test("smsConversationId is deterministic across formats", () => {
  const a = smsConversationId("uid123", "+15550100");
  const b = smsConversationId("uid123", "+1 (555) 0100");
  assert.equal(a, "sms-uid123-15550100");
  assert.equal(a, b);
});

test("canonicalSmsContact accepts only E.164 numbers", () => {
  assert.equal(canonicalSmsContact("+15550100"), "+15550100");
  assert.equal(canonicalSmsContact(" +1 (555) 010-0100 "), "+15550100100");
  assert.equal(canonicalSmsContact("+1.555.0100"), "+15550100");
  assert.equal(canonicalSmsContact("15550100"), null);
  assert.equal(canonicalSmsContact("+05550100"), null);
  assert.equal(canonicalSmsContact("+123456"), null);
  assert.equal(canonicalSmsContact("+1234567890123456"), null);
  assert.equal(canonicalSmsContact("+1555abc0100"), null);
  assert.equal(canonicalSmsContact(15550100), null);
  assert.equal(canonicalSmsContact(undefined), null);
});

test("smsContactParticipantId prefixes the digits", () => {
  assert.equal(smsContactParticipantId("+15550100"), "sms:+15550100");
});

test("normalizeInboundRow rejects unusable payloads", () => {
  assert.equal(normalizeInboundRow(null), null);
  assert.equal(normalizeInboundRow(undefined), null);
  assert.equal(normalizeInboundRow("nope"), null);
  assert.equal(normalizeInboundRow({from: "+15550100"}), null);
  assert.equal(normalizeInboundRow({uid: "uid1", body: "hi"}), null);
  assert.equal(normalizeInboundRow({id: 1, uid: "uid1", from: "12345"}), null);
  assert.equal(normalizeInboundRow({id: 1, uid: "a/b", from: "+15550100"}),
      null);
  assert.equal(normalizeInboundRow({uid: "uid1", from: "+15550100"}), null);
  assert.equal(normalizeInboundRow({id: "x/y", uid: "uid1",
    from: "+15550100"}), null);
});

test("normalizeInboundRow canonicalizes the contact", () => {
  const row = normalizeInboundRow({id: "r1", uid: "uid1",
    from: "+1 555 010 0100", body: "hi"});

  assert.equal(row.contact, "+15550100100");
  assert.equal(row.messageId, "r1");
});

test("normalizeInboundRow normalizes a valid alpha-text row", () => {
  const row = normalizeInboundRow({
    id: 42,
    uid: "uid1",
    sid: "SM1",
    direction: "in",
    from: "+15550100",
    to: "+15550001111",
    body: "hello",
    status: "received",
    createdAt: 1234567890,
  });

  assert.deepEqual(row, {
    uid: "uid1",
    contact: "+15550100",
    text: "hello",
    messageId: "42",
    providerId: "SM1",
    receivedAt: 1234567890,
  });
});

test("normalizeInboundRow tolerates missing sid and createdAt", () => {
  const row = normalizeInboundRow({id: 7, uid: "uid1", from: "+15550100",
    body: ""});

  assert.equal(row.providerId, null);
  assert.equal(row.receivedAt, null);
  assert.equal(row.text, "");
});

test("isAuthorized checks the bearer secret in constant time", () => {
  const secret = "bridge-secret";
  assert.equal(isAuthorized(undefined, secret), false);
  assert.equal(isAuthorized("Bearer nope", secret), false);
  assert.equal(isAuthorized("Bearer bridge-secret", ""), false);
  assert.equal(isAuthorized("Bearer bridge-secret", secret), true);
});

/**
 * Minimal Express-like request double.
 *
 * @param {Object<string, string>} headers Header values by lowercase name.
 * @param {*} body The parsed request body.
 * @return {{get: function(string): string, body: *}} The request stub.
 */
function fakeReq(headers, body) {
  return {get: (name) => headers[name.toLowerCase()], body};
}

/**
 * Minimal Express-like response double.
 *
 * @return {{statusCode: ?number, payload: ?Object,
 *   status: function(number), json: function(Object)}} The response stub.
 */
function fakeRes() {
  return {
    statusCode: null,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.payload = payload;
      return this;
    },
  };
}

const SMS_THREAD = "sms-uid1-15550100";

/**
 * A well-formed SMS conversation owned by uid1.
 *
 * @return {Object} Conversation data.
 */
function validSmsConversation() {
  return {
    participants: ["uid1", "sms:+15550100"],
    smsOwner: "uid1",
    smsContact: "+15550100",
  };
}

/**
 * A well-formed outbound SMS message from uid1.
 *
 * @return {Object} Message data.
 */
function validOutbound() {
  return {channel: SMS_OUTBOUND_CHANNEL, smsStatus: "pending", text: "hi",
    senderId: "uid1"};
}

/**
 * Builds a relay with isolated status recording and overridable dependencies.
 *
 * @param {Object} overrides Relay dependency overrides.
 * @return {{relay: Function, updates: Array<Object>}} The relay and its writes.
 */
function relayTestFixture(overrides = {}) {
  const updates = [];
  const relay = createSmsRelay({
    fetchFn: async () => ({ok: true}),
    config: {alphaTextUrl: "http://backend", alphaTextApiKey: "key"},
    getConversation: async () => validSmsConversation(),
    updateMessage: async (conversationId, messageId, fields) => {
      updates.push({conversationId, messageId, fields});
    },
    ...overrides,
  });
  return {relay, updates};
}

/**
 * Delivers an outbound message to a test document path.
 *
 * @param {Function} relay The relay under test.
 * @param {Object} data Message data, defaulting to a valid outbound SMS.
 * @param {string} conversationId Conversation the message is written to.
 * @return {Promise<void>} Resolves after the relay handles the message.
 */
async function deliverSms(relay, data = validOutbound(),
    conversationId = SMS_THREAD) {
  await relay({data: () => data},
      {params: {conversationId, messageId: "m1"}});
}

/**
 * The single failed-status update a rejected message should produce.
 *
 * @param {string} smsError Expected failure code.
 * @param {string} conversationId Conversation the message was written to.
 * @return {Array<Object>} Expected updates.
 */
function failedWith(smsError, conversationId = SMS_THREAD) {
  return [{
    conversationId,
    messageId: "m1",
    fields: {smsStatus: "failed", smsError},
  }];
}

test("createSmsRelay ignores non-sms channels without touching anything",
    async () => {
      const calls = [];
      const relay = createSmsRelay({
        fetchFn: async () => {
          calls.push("fetch");
          return {ok: true};
        },
        config: {alphaTextUrl: "http://backend", alphaTextApiKey: "key"},
        getConversation: async () => {
          calls.push("getConversation");
          return {smsContact: "+15550100"};
        },
        updateMessage: async () => {
          calls.push("updateMessage");
        },
      });

      await relay(
          {data: () => ({channel: "chat", text: "hi", senderId: "uid1"})},
          {params: {conversationId: "c1", messageId: "m1"}});

      assert.deepEqual(calls, []);
    });

test("createSmsRelay marks docs failed when text is not a string",
    async () => {
      const {relay, updates} = relayTestFixture();

      await deliverSms(relay,
          {channel: SMS_OUTBOUND_CHANNEL, smsStatus: "pending",
            senderId: "uid1"});

      assert.deepEqual(updates, failedWith("invalid-text"));
    });

test("createSmsRelay marks docs failed when the conversation is missing",
    async () => {
      const {relay, updates} = relayTestFixture({
        getConversation: async () => null,
      });

      await deliverSms(relay);

      assert.deepEqual(updates, failedWith("missing-conversation"));
    });

test("outboundMessageError rejects malformed message fields", () => {
  const base = validOutbound();
  assert.equal(outboundMessageError(base), null);
  assert.equal(outboundMessageError({...base, smsStatus: "sent"}),
      "invalid-status");
  assert.equal(outboundMessageError({...base, smsStatus: undefined}),
      "invalid-status");
  assert.equal(outboundMessageError({...base, senderId: ""}),
      "invalid-sender");
  assert.equal(outboundMessageError({...base, senderId: 7}),
      "invalid-sender");
  assert.equal(outboundMessageError({...base, text: ""}), "invalid-text");
  assert.equal(outboundMessageError(
      {...base, text: "x".repeat(SMS_MAX_TEXT_LENGTH + 1)}), "invalid-text");
  assert.equal(outboundMessageError(
      {...base, text: "x".repeat(SMS_MAX_TEXT_LENGTH)}), null);
});

test("smsConversationError requires the sender's own consistent thread",
    () => {
      const valid = validSmsConversation();
      const check = (conversation, id = SMS_THREAD, sender = "uid1") =>
        smsConversationError(id, conversation, sender);

      assert.equal(check(valid), null);
      assert.equal(check(null), "missing-conversation");
      assert.equal(check({...valid, smsContact: undefined}),
          "invalid-contact");
      assert.equal(check({...valid, smsContact: "+1 555 0100"}),
          "invalid-contact");
      assert.equal(check({...valid, smsContact: "5550100"}),
          "invalid-contact");
      assert.equal(check(valid, SMS_THREAD, "uid2"), "not-owner");
      assert.equal(check({...valid, smsOwner: undefined}), "not-owner");
      assert.equal(check(valid, "sms-uid1-15550199"), "id-mismatch");
      assert.equal(check(valid, "sms-uid2-15550100"), "id-mismatch");
      assert.equal(check({...valid, participants: undefined}),
          "invalid-participants");
      assert.equal(check({...valid, participants: ["uid1"]}),
          "invalid-participants");
      assert.equal(check({...valid,
        participants: ["uid1", "sms:+15550199"]}), "invalid-participants");
      assert.equal(check({...valid,
        participants: ["sms:+15550100", "uid1"]}), "invalid-participants");
      assert.equal(check({...valid,
        participants: ["uid1", "sms:+15550100", "uid2"]}),
      "invalid-participants");
    });

test("createSmsRelay never sends for a forged or malformed thread",
    async () => {
      const cases = [
        {conversation: {...validSmsConversation(), smsOwner: "uid2"},
          error: "not-owner"},
        {conversation: {...validSmsConversation(),
          participants: ["uid1", "uid2"]}, error: "invalid-participants"},
        {conversation: {...validSmsConversation(), smsContact: "+15550199"},
          error: "id-mismatch"},
      ];
      for (const {conversation, error} of cases) {
        const fetches = [];
        const {relay, updates} = relayTestFixture({
          fetchFn: async () => {
            fetches.push("fetch");
            return {ok: true};
          },
          getConversation: async () => conversation,
        });

        await deliverSms(relay);

        assert.deepEqual(fetches, []);
        assert.deepEqual(updates, failedWith(error));
      }
    });

test("createSmsRelay rejects sms messages in non-SMS conversations",
    async () => {
      const reads = [];
      const {relay, updates} = relayTestFixture({
        getConversation: async (id) => {
          reads.push(id);
          return validSmsConversation();
        },
      });

      await deliverSms(relay, validOutbound(), "c1");

      assert.deepEqual(reads, []);
      assert.deepEqual(updates, failedWith("not-sms-conversation", "c1"));
    });

test("createSmsRelay rejects messages that are not pending", async () => {
  const {relay, updates} = relayTestFixture();

  await deliverSms(relay, {...validOutbound(), smsStatus: "sent"});

  assert.deepEqual(updates, failedWith("invalid-status"));
});

test("createSmsRelay POSTs to alpha-text and marks the doc sent",
    async () => {
      const fetches = [];
      const updates = [];
      const relay = createSmsRelay({
        fetchFn: async (url, options) => {
          fetches.push({url, options});
          return {ok: true};
        },
        config: {alphaTextUrl: "http://backend/", alphaTextApiKey: "key"},
        getConversation: async () => validSmsConversation(),
        updateMessage: async (conversationId, messageId, fields) => {
          updates.push({conversationId, messageId, fields});
        },
      });

      await deliverSms(relay, {...validOutbound(), text: "hi there"});

      assert.equal(fetches.length, 1);
      assert.equal(fetches[0].url, "http://backend/api/messages");
      assert.equal(fetches[0].options.method, "POST");
      assert.equal(fetches[0].options.headers["X-User-Uid"], "uid1");
      assert.equal(fetches[0].options.headers.Authorization, "Bearer key");
      assert.deepEqual(JSON.parse(fetches[0].options.body),
          {to: "+15550100", body: "hi there"});
      assert.deepEqual(updates, [{
        conversationId: SMS_THREAD,
        messageId: "m1",
        fields: {smsStatus: "sent"},
      }]);
    });

test("createSmsRelay marks the doc failed when alpha-text rejects",
    async () => {
      const {relay, updates} = relayTestFixture({
        fetchFn: async () => ({ok: false}),
      });

      await deliverSms(relay);

      assert.deepEqual(updates, [{
        conversationId: SMS_THREAD,
        messageId: "m1",
        fields: {smsStatus: "failed"},
      }]);
    });

test("createSmsRelay marks the doc failed when fetch throws", async () => {
  const {relay, updates} = relayTestFixture({
    fetchFn: async () => {
      throw new Error("connection refused");
    },
  });

  await deliverSms(relay);

  assert.deepEqual(updates, [{
    conversationId: SMS_THREAD,
    messageId: "m1",
    fields: {smsStatus: "failed"},
  }]);
});

test("createInboundSmsHandler rejects calls without the bridge secret",
    async () => {
      const handler = createInboundSmsHandler({
        config: {bridgeSecret: "bridge-secret"},
        resolveConversation: async () => {},
        writeMessage: async () => {},
      });

      const res = fakeRes();
      await handler(fakeReq({}, {uid: "uid1"}), res);
      assert.equal(res.statusCode, 401);

      const wrong = fakeRes();
      await handler(
          fakeReq({authorization: "Bearer nope"}, {uid: "uid1"}), wrong);
      assert.equal(wrong.statusCode, 401);
    });

test("createInboundSmsHandler rejects invalid payloads", async () => {
  const handler = createInboundSmsHandler({
    config: {bridgeSecret: "bridge-secret"},
    resolveConversation: async () => {},
    writeMessage: async () => {},
  });

  const res = fakeRes();
  await handler(
      fakeReq({authorization: "Bearer bridge-secret"}, {nope: true}), res);
  assert.equal(res.statusCode, 400);
});

test("createInboundSmsHandler writes the conversation and message",
    async () => {
      const conversations = [];
      const messages = [];
      const handler = createInboundSmsHandler({
        config: {bridgeSecret: "bridge-secret"},
        resolveConversation: async (row) => {
          conversations.push(row);
        },
        writeMessage: async (row) => {
          messages.push(row);
        },
      });

      const res = fakeRes();
      await handler(
          fakeReq({authorization: "Bearer bridge-secret"}, {
            id: 42,
            uid: "uid1",
            sid: "SM1",
            direction: "in",
            from: "+15550100",
            to: "+15550001111",
            body: "hello",
            createdAt: 1234567890,
          }),
          res);

      assert.equal(res.statusCode, 200);
      assert.deepEqual(res.payload, {ok: true});
      assert.equal(conversations.length, 1);
      assert.equal(conversations[0].uid, "uid1");
      assert.equal(messages.length, 1);
      assert.equal(messages[0].messageId, "42");
      assert.equal(SMS_INBOUND_CHANNEL, "sms-inbound");
    });

test("createInboundSmsHandler answers 500 when Firestore fails", async () => {
  const handler = createInboundSmsHandler({
    config: {bridgeSecret: "bridge-secret"},
    resolveConversation: async () => {
      throw new Error("firestore down");
    },
    writeMessage: async () => {},
  });

  const res = fakeRes();
  await handler(
      fakeReq({authorization: "Bearer bridge-secret"}, {
        id: 42,
        uid: "uid1",
        from: "+15550100",
        body: "hello",
      }),
      res);

  assert.equal(res.statusCode, 500);
  assert.match(res.payload.error, /firestore down/);
});

/**
 * Runs upsertSmsConversation against an in-memory transaction double.
 *
 * @param {Object<string, *>} docs Existing doc data by ref name.
 * @return {Promise<{gets: Array<string>, sets: Array<Object>}>} Calls made.
 */
async function upsertWith(docs) {
  const gets = [];
  const sets = [];
  const tx = {
    get: async (ref) => {
      gets.push(ref);
      return {exists: ref in docs, data: () => docs[ref]};
    },
    set: (ref, data, options) => {
      sets.push({ref, data, options});
    },
  };
  await upsertSmsConversation(tx,
      {conversation: "conversation", info: "info", user: "user"},
      {uid: "uid1", contact: "+15550100"}, "now");
  return {gets, sets};
}

test("upsertSmsConversation initializes languages for a new thread",
    async () => {
      const {gets, sets} = await upsertWith({user: {language: "fr"}});

      assert.deepEqual(gets, ["info", "user"]);
      assert.deepEqual(sets, [{
        ref: "conversation",
        data: {
          participants: ["uid1", "sms:+15550100"],
          smsOwner: "uid1",
          smsContact: "+15550100",
          timestamp: "now",
        },
        options: {merge: true},
      }, {
        ref: "info",
        data: {incomingLanguage: "fr", outgoingLanguage: "fr"},
        options: undefined,
      }]);
    });

test("upsertSmsConversation defaults to English without a user doc",
    async () => {
      const {sets} = await upsertWith({});

      assert.deepEqual(sets[1].data,
          {incomingLanguage: "en", outgoingLanguage: "en"});
    });

test("upsertSmsConversation preserves existing language settings",
    async () => {
      const {gets, sets} = await upsertWith({
        info: {incomingLanguage: "es", outgoingLanguage: "de"},
        user: {language: "fr"},
      });

      assert.deepEqual(gets, ["info"]);
      assert.deepEqual(sets.map((set) => set.ref), ["conversation"]);
    });
