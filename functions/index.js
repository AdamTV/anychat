"use strict";

const functions = require("firebase-functions");

const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);

const {GoogleAuth} = require("google-auth-library");

const {createGetSpeechAccessToken} = require("./speech_token");

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
exports.getSpeechAccessToken = createGetSpeechAccessToken(
    {getAccessToken: mintAccessToken});
