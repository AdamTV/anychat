#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const normalLimit = 800;
const approvedLimits = new Map([
  // Vendored Awesome Notifications utility module; prevent further growth.
  ["lib/services/notifications/notifications_util.dart", 2200],
]);
const skippedDirectories = new Set(["node_modules", "coverage", "build", ".dart_tool"]);
const violations = [];

function inspect(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    if (entry.isDirectory() && skippedDirectories.has(entry.name)) continue;
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      inspect(file);
      continue;
    }
    if (!/\.(?:dart|js)$/.test(entry.name)) continue;

    const relative = path.relative(root, file).split(path.sep).join("/");
    const lineCount = fs.readFileSync(file, "utf8").split(/\r?\n/).length;
    const limit = approvedLimits.get(relative) ?? normalLimit;
    if (lineCount > limit) {
      violations.push(`${relative}: ${lineCount} lines exceeds limit ${limit}`);
    }
  }
}

for (const directory of ["lib", "functions"]) {
  inspect(path.join(root, directory));
}

if (violations.length > 0) {
  console.error(violations.join("\n"));
  process.exit(1);
}

console.log(`Source file limits passed (default ${normalLimit} lines).`);
