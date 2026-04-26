#!/usr/bin/env node
/**
 * Synchronize the version from the root VERSION file to all action package.json files.
 * Usage: node scripts/sync-versions.js [--check]
 *
 * --check: Exit with error if versions are out of sync (for CI)
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const VERSION_FILE = path.join(ROOT, "VERSION");
const ACTION_DIRS = ["actions/setup-bun", "actions/gh-release", "actions/fossa-scan"];

function main() {
  const checkOnly = process.argv.includes("--check");
  const version = fs.readFileSync(VERSION_FILE, "utf-8").trim();

  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    console.error(`Invalid version in VERSION file: "${version}"`);
    process.exit(1);
  }

  console.log(`Monorepo version: ${version}`);

  // Update root package.json
  const rootPkgPath = path.join(ROOT, "package.json");
  updatePackageJson(rootPkgPath, version, checkOnly);

  // Update each action's package.json
  for (const dir of ACTION_DIRS) {
    const pkgPath = path.join(ROOT, dir, "package.json");
    if (fs.existsSync(pkgPath)) {
      updatePackageJson(pkgPath, version, checkOnly);
    }
  }

  if (checkOnly) {
    console.log("All versions are in sync.");
  } else {
    console.log("All versions synchronized.");
  }
}

function updatePackageJson(pkgPath, version, checkOnly) {
  const content = fs.readFileSync(pkgPath, "utf-8");
  const pkg = JSON.parse(content);
  const relativePath = path.relative(ROOT, pkgPath);

  if (pkg.version === version) {
    console.log(`  ${relativePath}: ${version} (ok)`);
    return;
  }

  if (checkOnly) {
    console.error(
      `  ${relativePath}: expected ${version}, got ${pkg.version}`
    );
    process.exit(1);
  }

  pkg.version = version;
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf-8");
  console.log(`  ${relativePath}: updated to ${version}`);
}

main();
