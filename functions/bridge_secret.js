"use strict";

/**
 * Environment map used to resolve the shared bridge secret. Only the keys read
 * by this module matter, so a small test fixture object is acceptable.
 *
 * @typedef {Record<string, string|undefined>} EnvLike
 */

/**
 * Resolves the alpha-text SMS bridge secret from the environment.
 *
 * `TANDIVOX_BRIDGE_SECRET` is the canonical name; `ANYCHAT_BRIDGE_SECRET` is
 * kept as a legacy fallback so existing deployments keep working untouched.
 * When only one variable holds a non-empty value that value is used, so an
 * unset (or blank) canonical falls back to the legacy name. When both hold
 * different non-empty values the configuration is ambiguous, so this throws
 * instead of silently picking one. The error names the variables but never
 * their values.
 *
 * @param {EnvLike} env Environment source.
 * @return {string} The bridge secret, or "" when neither variable is set.
 * @throws {Error} When both variables are non-empty and disagree.
 */
function resolveBridgeSecret(env) {
  const canonical = env.TANDIVOX_BRIDGE_SECRET || "";
  const legacy = env.ANYCHAT_BRIDGE_SECRET || "";

  if (canonical !== "" && legacy !== "" && canonical !== legacy) {
    throw new Error(
        "TANDIVOX_BRIDGE_SECRET and ANYCHAT_BRIDGE_SECRET are both set to " +
        "different non-empty values; unset one of them");
  }
  if (canonical !== "") {
    return canonical;
  }
  return legacy;
}

module.exports = {resolveBridgeSecret};
