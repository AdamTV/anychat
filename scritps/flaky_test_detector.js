#!/usr/bin/env node
"use strict";

// Detects flaky Flutter tests. Runs the suite once, then re-runs every failed
// test up to FLAKY_MAX_ATTEMPTS times (default 3). A test that failed the
// initial run but passes on a retry is reported as flaky; a test that fails
// every attempt is a stable failure. Tests listed in
// test/flaky_quarantine.txt are never retried and are reported separately.
//
// Writes test-results/flaky-report.json and test-results/flaky-report.md.
// Exit code is 1 when flaky tests or stable failures were found, else 0.

const {spawnSync} = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const resultsDir = path.join(root, "test-results");
const quarantineFile = path.join(root, "test", "flaky_quarantine.txt");
const initialReport = path.join(resultsDir, "flaky-initial-run.json");
const maxAttempts = Number(process.env.FLAKY_MAX_ATTEMPTS || 3);

function readQuarantine() {
  if (!fs.existsSync(quarantineFile)) return new Set();
  return new Set(
      fs.readFileSync(quarantineFile, "utf8")
          .split("\n")
          .map((line) => line.trim())
          .filter((line) => line.length > 0 && !line.startsWith("#")));
}

function runFlutterTest(args) {
  const result = spawnSync("flutter", ["test", ...args], {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
  if (result.error) {
    throw result.error;
  }
  return result;
}

function gitCommit() {
  const result = spawnSync("git", ["rev-parse", "--short", "HEAD"], {
    cwd: root,
    encoding: "utf8",
  });
  return result.status === 0 ? result.stdout.trim() : "unknown";
}

// Parses a `flutter test --file-reporter json:` report. The reporter emits
// testStart events carrying the test name and testDone events carrying only
// a testID, so the two event kinds are joined here. Hidden suite-loading
// pseudo-tests are reported separately as load errors.
// Returns {results: Map(name -> result), loadErrors: string[]}.
function readTestResults(reportFile) {
  const results = new Map();
  const loadErrors = [];
  if (!fs.existsSync(reportFile)) {
    return {results, loadErrors};
  }
  const lines = fs.readFileSync(reportFile, "utf8").split("\n");
  const namesById = new Map();
  for (const line of lines) {
    if (!line.trim()) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue; // Not a JSON line (e.g. partial write); skip it.
    }
    if (event.type === "testStart" && event.test &&
        typeof event.test.name === "string") {
      namesById.set(event.test.id, event.test.name);
    }
  }
  for (const line of lines) {
    if (!line.trim()) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    if (event.type !== "testDone" || event.skipped) continue;
    const name = namesById.get(event.testID);
    if (!name) continue;
    if (event.hidden) {
      if (event.result !== "success") loadErrors.push(name);
      continue;
    }
    results.set(name, event.result);
  }
  return {results, loadErrors};
}

function retryTest(name) {
  const attempts = [];
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const retryReport = path.join(resultsDir, `flaky-retry-${attempt}.json`);
    console.log(`Re-running "${name}" (attempt ${attempt}/${maxAttempts})...`);
    runFlutterTest([
      "--plain-name", name,
      "--concurrency", "1",
      "--file-reporter", `json:${retryReport}`,
    ]);
    const {results} = readTestResults(retryReport);
    const outcome = results.has(name) ? results.get(name) : "not-found";
    attempts.push(outcome);
    if (outcome === "success") {
      return {attempts, passed: true};
    }
  }
  return {attempts, passed: false};
}

function renderMarkdown(report) {
  const lines = [
    "# Flaky test report",
    "",
    `- Generated: ${report.generatedAt}`,
    `- Commit: \`${report.commit}\``,
    `- Initial run: ${report.initialRun.status} ` +
      `(${report.initialRun.failedCount} failed test(s))`,
    `- Retries per failed test: ${report.maxAttempts}`,
    "",
  ];
  const table = (title, entries) => {
    lines.push(`## ${title}`, "");
    if (entries.length === 0) {
      lines.push("None.", "");
      return;
    }
    lines.push("| Test | Retry results |", "| --- | --- |");
    for (const entry of entries) {
      const attempts = entry.attempts.length > 0 ?
        entry.attempts.join(", ") :
        (entry.note || "quarantined (not retried)");
      lines.push(`| \`${entry.name}\` | ${attempts} |`);
    }
    lines.push("");
  };
  table("Flaky tests (failed initially, passed on retry)", report.flaky);
  table("Stable failures (failed every attempt)", report.stableFailures);
  table("Quarantined tests", report.quarantined);
  if (report.passedWhileQuarantined.length > 0) {
    lines.push(
        "## Quarantined tests that passed (candidates for removal)",
        "",
        "These tests are listed in `test/flaky_quarantine.txt` but passed " +
        "on the first run; consider removing them from the quarantine list.",
        "");
    for (const name of report.passedWhileQuarantined) {
      lines.push(`- \`${name}\``);
    }
    lines.push("");
  }
  return lines.join("\n");
}

function main() {
  fs.mkdirSync(resultsDir, {recursive: true});
  const quarantine = readQuarantine();

  console.log("Running the full test suite...");
  const initial = runFlutterTest(["--file-reporter", `json:${initialReport}`]);
  const {results, loadErrors} = readTestResults(initialReport);
  const failed = [...results.entries()]
      .filter(([, result]) => result !== "success")
      .map(([name]) => name);
  const initialStatus = initial.status === 0 ? "pass" : "fail";
  console.log(
      `Initial run ${initialStatus}; ${failed.length} failed test(s) found.`);
  if (initial.status !== 0) {
    const output = `${initial.stdout}\n${initial.stderr}`.trim().split("\n");
    console.log(output.slice(-30).join("\n"));
  }

  const flaky = [];
  const stableFailures = loadErrors.map((name) => ({
    name,
    attempts: [],
    passed: false,
    note: "suite load error (not retried)",
  }));
  const quarantined = [];
  for (const name of failed) {
    if (quarantine.has(name)) {
      quarantined.push({name, attempts: [], passed: false});
      continue;
    }
    const {attempts, passed} = retryTest(name);
    (passed ? flaky : stableFailures).push({name, attempts, passed});
  }

  const passedWhileQuarantined = [...quarantine].filter(
      (name) => results.get(name) === "success");

  const report = {
    generatedAt: new Date().toISOString(),
    commit: process.env.GITHUB_SHA || gitCommit(),
    run: process.env.GITHUB_RUN_ID || "local",
    maxAttempts,
    initialRun: {
      status: initialStatus,
      failedCount: failed.length,
      loadErrors: loadErrors.length,
    },
    flaky,
    stableFailures,
    quarantined,
    passedWhileQuarantined,
  };
  fs.writeFileSync(
      path.join(resultsDir, "flaky-report.json"),
      JSON.stringify(report, null, 2) + "\n");
  fs.writeFileSync(
      path.join(resultsDir, "flaky-report.md"), renderMarkdown(report));

  console.log(
      `Flaky: ${flaky.length}, stable failures: ${stableFailures.length}, ` +
      `quarantined: ${quarantined.length}.`);
  const reportPath = path.join("test-results", "flaky-report.md");
  console.log(`Report written to ${reportPath}`);
  process.exitCode = flaky.length > 0 || stableFailures.length > 0 ? 1 : 0;
}

try {
  main();
} catch (error) {
  console.error(`flaky_test_detector: ${error.message}`);
  process.exit(2);
}
