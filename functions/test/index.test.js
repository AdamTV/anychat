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
