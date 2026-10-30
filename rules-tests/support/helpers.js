"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

// Denied writes are expected in these tests; keep the SDK from logging
// every PERMISSION_DENIED stream error.
require("firebase/firestore").setLogLevel("silent");

const RULES_PATH = path.resolve(__dirname, "..", "..", "firestore.rules");

/**
 * Starts a rules test environment against the local Firestore emulator.
 * Each test file uses its own demo project id so files can run in parallel
 * without clearing each other's data. "demo-" project ids never reach a
 * real Firebase project and need no credentials.
 *
 * @param {string} suffix Distinguishes the project id per test file.
 * @return {Promise<*>} The RulesTestEnvironment.
 */
async function startEnv(suffix) {
  const hostPort = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8181";
  const [host, port] = hostPort.split(":");
  return initializeTestEnvironment({
    projectId: `demo-anychat-${suffix}`,
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
      host,
      port: Number(port),
    },
  });
}

/**
 * Writes fixture documents with security rules disabled, the way the Admin
 * SDK (Cloud Functions) would.
 *
 * @param {*} env The RulesTestEnvironment.
 * @param {Object<string, Object>} docs Document data by full path.
 * @return {Promise<void>} Resolves once every document is written.
 */
async function seed(env, docs) {
  const {doc, setDoc} = require("firebase/firestore");
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [docPath, data] of Object.entries(docs)) {
      await setDoc(doc(db, docPath), data);
    }
  });
}

/**
 * Reads one document with security rules disabled.
 *
 * @param {*} env The RulesTestEnvironment.
 * @param {string} docPath Full document path.
 * @return {Promise<?Object>} The document data, or null when missing.
 */
async function readAsAdmin(env, docPath) {
  const {doc, getDoc} = require("firebase/firestore");
  let data = null;
  await env.withSecurityRulesDisabled(async (context) => {
    const snap = await getDoc(doc(context.firestore(), docPath));
    data = snap.exists() ? snap.data() : null;
  });
  return data;
}

/**
 * Firestore client authenticated as a uid, or unauthenticated when uid is
 * null.
 *
 * @param {*} env The RulesTestEnvironment.
 * @param {?string} uid The signed-in uid.
 * @return {*} A modular Firestore instance.
 */
function dbAs(env, uid) {
  const context = uid === null ?
    env.unauthenticatedContext() :
    env.authenticatedContext(uid);
  return context.firestore();
}

/**
 * Profile document the client writes on registration.
 *
 * @param {string} name Display name.
 * @param {string} language Language code.
 * @return {Object} Profile data.
 */
function profile(name, language = "en") {
  return {
    displayName: name,
    email: `${name.toLowerCase()}@example.test`,
    photoUrl: "",
    language,
  };
}

module.exports = {
  assertFails,
  assertSucceeds,
  startEnv,
  seed,
  readAsAdmin,
  dbAs,
  profile,
};
