"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildAssessmentRequest,
  evaluateAssessment,
  createAssessment,
} = require("../assessment");

test("buildAssessmentRequest nests the token and site key under the event",
    () => {
      const request = buildAssessmentRequest(
          "projects/anychat-c414a", "key-1", "token-1");

      assert.deepEqual(request, {
        assessment: {event: {token: "token-1", siteKey: "key-1"}},
        parent: "projects/anychat-c414a",
      });
    });

test("evaluateAssessment rejects invalid tokens", () => {
  const result = evaluateAssessment(
      {tokenProperties: {valid: false, invalidReason: "EXPIRED"}},
      "login");

  assert.equal(result.valid, false);
  assert.equal(result.score, null);
  assert.match(result.reason, /EXPIRED/);
});

test("evaluateAssessment rejects action mismatches", () => {
  const result = evaluateAssessment(
      {tokenProperties: {valid: true, action: "register"}},
      "login");

  assert.equal(result.valid, false);
  assert.equal(result.score, null);
  assert.match(result.reason, /does not match/);
});

test("evaluateAssessment returns the risk score for a matching action", () => {
  const result = evaluateAssessment(
      {
        tokenProperties: {valid: true, action: "login"},
        riskAnalysis: {score: 0.7, reasons: ["LOW_RISK"]},
      },
      "login");

  assert.equal(result.valid, true);
  assert.equal(result.score, 0.7);
  assert.deepEqual(result.reasons, ["LOW_RISK"]);
});

test("evaluateAssessment tolerates a missing risk analysis", () => {
  const result = evaluateAssessment(
      {tokenProperties: {valid: true, action: "login"}},
      "login");

  assert.equal(result.valid, true);
  assert.equal(result.score, null);
  assert.deepEqual(result.reasons, []);
});

test("evaluateAssessment tolerates a missing response", () => {
  const result = evaluateAssessment(undefined, "login");

  assert.equal(result.valid, false);
  assert.equal(result.score, null);
});

test("createAssessment returns the score with an injected client", async () => {
  const fakeClient = {
    projectPath: (projectID) => `projects/${projectID}`,
    createAssessment: async (request) => {
      assert.equal(request.parent, "projects/anychat-c414a");
      assert.equal(request.assessment.event.token, "token-1");
      assert.equal(request.assessment.event.siteKey, "key-1");
      return [{
        tokenProperties: {valid: true, action: "login"},
        riskAnalysis: {score: 0.9, reasons: []},
      }];
    },
  };

  const score = await createAssessment(
      {recaptchaKey: "key-1", token: "token-1", recaptchaAction: "login"},
      fakeClient);

  assert.equal(score, 0.9);
});

test("createAssessment returns null when the token is invalid", async () => {
  const fakeClient = {
    projectPath: () => "projects/anychat-c414a",
    createAssessment: async () => [{
      tokenProperties: {valid: false, invalidReason: "INVALID"},
    }],
  };

  const score = await createAssessment({}, fakeClient);

  assert.equal(score, null);
});
