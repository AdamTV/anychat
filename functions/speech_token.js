"use strict";

const functions = require("firebase-functions");

/**
 * OAuth scopes carried by the tokens minted for the Speech-to-Text API.
 *
 * @type {Array<string>}
 */
const SPEECH_TOKEN_SCOPES = ["https://www.googleapis.com/auth/cloud-platform"];

/**
 * Token minted by the getAccessToken strategy.
 *
 * @typedef {Object} AccessTokenResponse
 * @property {string} token The access token value.
 * @property {string} expirationTime ISO-8601 UTC expiry timestamp.
 */

/**
 * Firebase Auth identity of a signed-in caller.
 *
 * @typedef {Object} AuthIdentity
 * @property {string=} uid The caller's user ID.
 */

/**
 * Firebase Auth context of a callable invocation, trimmed to what this
 * module checks.
 *
 * @typedef {Object} CallableContext
 * @property {AuthIdentity=} auth The caller's identity, when signed in.
 */

/**
 * Payload returned to the app by the getSpeechAccessToken callable.
 *
 * @typedef {Object} SpeechTokenPayload
 * @property {string} accessToken The access token value.
 * @property {string} tokenType Always "Bearer".
 * @property {string} expirationTime ISO-8601 UTC expiry timestamp.
 */

/**
 * Options accepted by createGetSpeechAccessToken.
 *
 * @typedef {Object} SpeechTokenOptions
 * @property {(scopes: Array<string>) => Promise<AccessTokenResponse>}
 *   getAccessToken Mints a token carrying the requested scopes.
 */

/**
 * Creates the getSpeechAccessToken callable: it hands short-lived Google
 * access tokens to signed-in users so the app can stream Speech-to-Text
 * without bundling a service-account private key.
 *
 * @param {SpeechTokenOptions} options Token minting strategy, typically
 *   backed by Application Default Credentials.
 * @return {function} The callable handler: rejects unauthenticated callers
 *   and resolves with a SpeechTokenPayload. Wrap it with
 *   functions.https.onCall before exporting it.
 */
function createGetSpeechAccessToken({getAccessToken}) {
  return async (/** @type {Object} */ data,
      /** @type {CallableContext} */ context) => {
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError("unauthenticated",
          "Sign in to request a Speech-to-Text access token.");
    }
    let tokenResponse;
    try {
      tokenResponse = await getAccessToken(SPEECH_TOKEN_SCOPES);
    } catch (err) {
      throw new functions.https.HttpsError("internal",
          "Failed to mint a Speech-to-Text access token.",
          err instanceof Error ? err.message : String(err));
    }
    return {
      accessToken: tokenResponse.token,
      tokenType: "Bearer",
      expirationTime: tokenResponse.expirationTime,
    };
  };
}

module.exports = {createGetSpeechAccessToken, SPEECH_TOKEN_SCOPES};
