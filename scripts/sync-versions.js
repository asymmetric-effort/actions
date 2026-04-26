#!/usr/bin/env node
/**
 * Synchronize the version from the root VERSION file to all versioned files.
 * Usage: node scripts/sync-versions.js [--check]
 *
 * --check: Exit with error if versions are out of sync (for CI)
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const VERSION_FILE = path.join(ROOT, "VERSION");

// Files that contain a version field to sync
const VERSIONED_PACKAGE_JSONS = [
  "site/package.json",
];

function main() {
  const checkOnly = process.argv.includes("--check");
  const version = fs.readFileSync(VERSION_FILE, "utf-8").trim();

  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    console.error(`Invalid version in VERSION file: "${version}"`);
    process.exit(1);
  }

  console.log(`Monorepo version: ${version}`);

  let hasError = false;

  // Update each versioned package.json
  for (const relPath of VERSIONED_PACKAGE_JSONS) {
    const pkgPath = path.join(ROOT, relPath);
    if (!fs.existsSync(pkgPath)) {
      console.log(`  ${relPath}: not found (skipping)`);
      continue;
    }

    const content = fs.readFileSync(pkgPath, "utf-8");
    const pkg = JSON.parse(content);

    if (pkg.version === version) {
      console.log(`  ${relPath}: ${version} (ok)`);
      continue;
    }

    if (checkOnly) {
      console.error(`  ${relPath}: expected ${version}, got ${pkg.version}`);
      hasError = true;
      continue;
    }

    pkg.version = version;
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf-8");
    console.log(`  ${relPath}: updated to ${version}`);
  }

  if (hasError) {
    process.exit(1);
  }

  console.log(checkOnly ? "All versions are in sync." : "All versions synchronized.");
}

main();
