"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const functions = require("firebase-functions");

const {
  createGetSpeechAccessToken,
  SPEECH_TOKEN_SCOPES,
} = require("../speech_token.js");

const neverMints = () => async () => {
  throw new Error("getAccessToken must not be called");
};

test("rejects callers without an auth context", async () => {
  const handler = createGetSpeechAccessToken({getAccessToken: neverMints()});

  await assert.rejects(
      handler({}, {}),
      (err) => err instanceof functions.https.HttpsError &&
        err.code === "unauthenticated");
});

test("rejects callers without a uid", async () => {
  const handler = createGetSpeechAccessToken({getAccessToken: neverMints()});

  await assert.rejects(
      handler({}, {auth: {}}),
      (err) => err.code === "unauthenticated");
});

test("returns a Bearer payload for signed-in callers", async () => {
  let seenScopes = null;
  const handler = createGetSpeechAccessToken({
    async getAccessToken(scopes) {
      seenScopes = scopes;
      return {
        token: "token-1",
        expirationTime: "2026-01-01T00:00:00.000Z",
      };
    },
  });

  const payload = await handler({}, {auth: {uid: "user-1"}});

  assert.equal(payload.accessToken, "token-1");
  assert.equal(payload.tokenType, "Bearer");
  assert.equal(payload.expirationTime, "2026-01-01T00:00:00.000Z");
  assert.deepEqual(seenScopes, SPEECH_TOKEN_SCOPES);
});

test("surfaces mint failures as internal errors", async () => {
  const handler = createGetSpeechAccessToken({
    async getAccessToken() {
      throw new Error("metadata unavailable");
    },
  });

  await assert.rejects(
      handler({}, {auth: {uid: "user-1"}}),
      (err) => err instanceof functions.https.HttpsError &&
        err.code === "internal" &&
        err.message.includes("Failed to mint") &&
        err.details === "metadata unavailable");
});
