#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const libRoot = path.join(root, "lib");
const violations = [];
const rules = [
  {
    source: /^lib\/database\//,
    target: /^package:anychat\/(?:screens|widgets)\//,
    message: "database modules cannot depend on screens or widgets",
  },
  {
    source: /^lib\/components\//,
    target: /^package:anychat\/screens\//,
    message: "shared components cannot depend on route-level screens",
  },
  {
    source: /^lib\/widgets\//,
    target: /^package:anychat\/screens\//,
    message: "reusable widgets cannot depend on route-level screens",
  },
];

function collectFiles(directory, extension) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) return collectFiles(entryPath, extension);
    return entry.name.endsWith(extension) ? [entryPath] : [];
  });
}

for (const file of collectFiles(libRoot, ".dart")) {
  const relative = path.relative(root, file);
  const source = fs.readFileSync(file, "utf8");
  const imports = source.matchAll(
      /^\s*(?:import|export)\s+['"]([^'"]+)['"]/gm);
  for (const [, target] of imports) {
    for (const rule of rules) {
      if (rule.source.test(relative) && rule.target.test(target)) {
        violations.push(`${relative}: ${rule.message} (${target})`);
      }
    }
  }
}

const functionsRoot = path.join(root, "functions");
for (const file of ["index.js", "assessment.js"]) {
  const source = fs.readFileSync(path.join(functionsRoot, file), "utf8");
  const imports = source.matchAll(
      /(?:require\s*\(\s*|from\s+|import\s*\(\s*)['"]([^'"]+)['"]/g);
  for (const [, target] of imports) {
    if (target.startsWith("./test/") || target.startsWith("../test/")) {
      violations.push(`functions/${file}: production code cannot depend on tests (${target})`);
    }
    if (file === "assessment.js" && target === "./index") {
      violations.push("functions/assessment.js: domain code cannot depend on the Functions entrypoint");
    }
  }
}

if (violations.length > 0) {
  console.error(violations.join("\n"));
  process.exit(1);
}

console.log("Module boundaries validated.");
