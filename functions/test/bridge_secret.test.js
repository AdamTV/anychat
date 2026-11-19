"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {resolveBridgeSecret} = require("../bridge_secret");

test("resolves the canonical TANDIVOX_BRIDGE_SECRET when it is set", () => {
  const env = {TANDIVOX_BRIDGE_SECRET: "new-secret"};

  assert.equal(resolveBridgeSecret(env), "new-secret");
});

test("falls back to legacy ANYCHAT_BRIDGE_SECRET when the new name is unset",
    () => {
      const env = {ANYCHAT_BRIDGE_SECRET: "legacy-secret"};

      assert.equal(resolveBridgeSecret(env), "legacy-secret");
    });

test("accepts both variables set to the same non-empty value", () => {
  const env = {TANDIVOX_BRIDGE_SECRET: "same", ANYCHAT_BRIDGE_SECRET: "same"};

  assert.equal(resolveBridgeSecret(env), "same");
});

test("returns an empty string when neither variable is set", () => {
  assert.equal(resolveBridgeSecret({}), "");
});

test("treats blank values as unset and falls back to the other name", () => {
  const env = {TANDIVOX_BRIDGE_SECRET: "", ANYCHAT_BRIDGE_SECRET: "legacy"};

  assert.equal(resolveBridgeSecret(env), "legacy");
});

test("throws on conflicting non-empty values without leaking either secret",
    () => {
      const env = {
        TANDIVOX_BRIDGE_SECRET: "new-secret-value",
        ANYCHAT_BRIDGE_SECRET: "legacy-secret-value",
      };

      assert.throws(
          () => resolveBridgeSecret(env),
          (/** @type {Error} */ error) => {
            assert.match(error.message, /TANDIVOX_BRIDGE_SECRET/);
            assert.match(error.message, /ANYCHAT_BRIDGE_SECRET/);
            // The error must name the variables, not their values.
            assert.doesNotMatch(error.message, /new-secret-value/);
            assert.doesNotMatch(error.message, /legacy-secret-value/);
            return true;
          });
    });
