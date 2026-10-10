#!/usr/bin/env node
"use strict";

const path = require("node:path");

const root = path.resolve(__dirname, "..");
const manifests = ["package.json", "functions/package.json"];
const versionsByPackage = new Map();

for (const relative of manifests) {
  const manifest = require(path.join(root, relative));
  for (const section of ["dependencies", "devDependencies", "optionalDependencies"]) {
    for (const [name, version] of Object.entries(manifest[section] || {})) {
      const declarations = versionsByPackage.get(name) || [];
      declarations.push({manifest: relative, section, version});
      versionsByPackage.set(name, declarations);
    }
  }
}

const conflicts = [];
let sharedDeclarations = 0;
for (const [name, declarations] of versionsByPackage) {
  if (declarations.length < 2) continue;
  sharedDeclarations++;
  const versions = new Set(declarations.map(({version}) => version));
  if (versions.size > 1) {
    conflicts.push(`${name}: ${declarations
        .map(({manifest, version}) => `${manifest}=${version}`)
        .join(", ")}`);
  }
}

if (conflicts.length > 0) {
  console.error("Dependency version drift detected:\n" + conflicts.join("\n"));
  process.exit(1);
}

console.log(
    `Dependency declarations agree across ${manifests.length} npm manifests ` +
    `(${sharedDeclarations} shared package names).`);
