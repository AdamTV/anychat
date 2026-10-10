#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const sourceRoot = path.join(root, "lib");
const perItemRead =
  /(?:AnyChatUser\.getUserById\s*\(|\.doc\s*\([^)]*\)\s*\.get\s*\()/;

function maskCommentsAndStrings(source) {
  return source
      .replace(/\/\*[\s\S]*?\*\//g, (text) => text.replace(/[^\n]/g, " "))
      .replace(/\/\/[^\n]*/g, (text) => text.replace(/[^\n]/g, " "))
      .replace(/'''[\s\S]*?'''|"""[\s\S]*?"""|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"/g,
          (text) => text.replace(/[^\n]/g, " "));
}

function findLoopBodies(source) {
  const code = maskCommentsAndStrings(source);
  const loops = [];
  const loopHeader = /\b(?:for|while)\s*\([^)]*\)\s*\{/g;
  let match;

  while ((match = loopHeader.exec(code)) !== null) {
    const bodyStart = loopHeader.lastIndex;
    let depth = 1;
    let cursor = bodyStart;
    while (cursor < code.length && depth > 0) {
      if (code[cursor] === "{") depth++;
      if (code[cursor] === "}") depth--;
      cursor++;
    }
    loops.push({
      start: match.index,
      body: code.slice(bodyStart, cursor - 1),
    });
    loopHeader.lastIndex = cursor;
  }
  return loops;
}

function collectDartFiles(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) return collectDartFiles(entryPath);
    return entry.name.endsWith(".dart") ? [entryPath] : [];
  });
}

const violations = [];
for (const file of collectDartFiles(sourceRoot)) {
  const source = fs.readFileSync(file, "utf8");
  const lines = source.split(/\r?\n/);
  for (const loop of findLoopBodies(source)) {
    if (!perItemRead.test(loop.body)) continue;
    const line = source.slice(0, loop.start).split("\n").length;
    violations.push(`${path.relative(root, file)}:${line}: ` +
        `per-document Firestore reads inside a loop; batch IDs with whereIn`);
  }
}

if (violations.length > 0) {
  console.error(violations.join("\n"));
  process.exit(1);
}

console.log("No per-document Firestore reads inside loops.");
