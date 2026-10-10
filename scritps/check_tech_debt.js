#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const debtRegister = fs.readFileSync(path.join(root, "TECH_DEBT.md"), "utf8");
const markerPattern = /\b(?:TODO|FIXME|HACK|XXX)(?:\((TD-\d{3})\))?/g;
const knownIds = new Set(
    [...debtRegister.matchAll(/^\|\s*(TD-\d{3})\s*\|/gm)]
        .map(([, id]) => id));
const violations = [];
const trackedIds = new Set();

function scan(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    if (entry.isDirectory() && entry.name === "node_modules") continue;
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      scan(file);
      continue;
    }
    if (!/\.(?:dart|js)$/.test(entry.name)) continue;

    const relative = path.relative(root, file).split(path.sep).join("/");
    const source = fs.readFileSync(file, "utf8");
    for (const match of source.matchAll(markerPattern)) {
      const line = source.slice(0, match.index).split("\n").length;
      const id = match[1];
      if (!id) {
        violations.push(`${relative}:${line}: debt marker needs a TD-### ID`);
      } else if (!knownIds.has(id)) {
        violations.push(`${relative}:${line}: ${id} is missing from TECH_DEBT.md`);
      } else {
        trackedIds.add(id);
      }
    }
  }
}

for (const directory of ["lib", "functions"]) {
  scan(path.join(root, directory));
}

for (const id of knownIds) {
  if (!trackedIds.has(id)) {
    violations.push(`${id}: register entry has no source marker`);
  }
}

if (violations.length > 0) {
  console.error(violations.join("\n"));
  process.exit(1);
}

console.log(`All ${trackedIds.size} technical-debt markers are registered.`);
