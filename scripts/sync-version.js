#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

// Read version argument or fallback to git describe / pubspec.yaml
let targetVersion = process.argv[2];

if (!targetVersion) {
  try {
    const { execSync } = await import("node:child_process");
    targetVersion = execSync("git describe --tags --exact-match 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null", { encoding: "utf8" }).trim();
  } catch {}
}

if (!targetVersion) {
  console.error("Usage: node scripts/sync-version.js <version-or-tag>");
  process.exit(1);
}

// Strip leading 'v'
const cleanVersion = targetVersion.replace(/^v/, "").trim();
if (!cleanVersion || !/^\d+\.\d+\.\d+/.test(cleanVersion)) {
  console.error(`Invalid semver version: "${targetVersion}"`);
  process.exit(1);
}

console.log(`Synchronizing app version to: ${cleanVersion}`);

// Calculate build number: major * 1000000 + minor * 1000 + patch
const semverParts = cleanVersion.split("-")[0].split(".").map(Number);
const major = semverParts[0] || 0;
const minor = semverParts[1] || 0;
const patch = semverParts[2] || 0;
const buildNumber = major * 1000000 + minor * 1000 + patch;

// Update pubspec.yaml
const pubspecPath = path.join(rootDir, "pubspec.yaml");
if (fs.existsSync(pubspecPath)) {
  let pubspecContent = fs.readFileSync(pubspecPath, "utf8");
  pubspecContent = pubspecContent.replace(
    /^version:\s*.*$/m,
    `version: ${cleanVersion}+${buildNumber}`
  );
  fs.writeFileSync(pubspecPath, pubspecContent);
  console.log(`✓ pubspec.yaml -> ${cleanVersion}+${buildNumber}`);
}

console.log("App version synchronization complete!");

