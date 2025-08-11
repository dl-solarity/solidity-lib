#!/usr/bin/env node

import fs from "fs";

import computeNextVersion from "./compute-next-version";

import { allowedWhenNotRc, allowedWhenRc } from "./constants";
import { getTopSection, readJSON, writeJSON, getPkgPath, getChangelogPath, validateReleaseTopSection } from "./utils";

import type { Core, Level } from "./types";

export default async function applyRelease(core: Core): Promise<void> {
  const pkgPath = getPkgPath();
  const changelogPath = getChangelogPath();

  if (!fs.existsSync(changelogPath)) throw new Error("CHANGELOG.md not found");

  const pkg = readJSON<{ version: string }>(pkgPath);
  const changelog = fs.readFileSync(changelogPath, "utf8");

  const { level, body, start } = getTopSection(changelog);
  const pkgIsRc = /-rc\.\d+$/.test(pkg.version);
  validateReleaseTopSection({ level, body, pkgIsRc });

  if (level === "none") {
    core.setOutput("skip", String(true));
    core.setOutput("version", pkg.version);
    core.setOutput("notes", body);
    return;
  }

  const { next } = computeNextVersion();

  // Update package.json version
  writeJSON(pkgPath, { ...pkg, version: next });

  // Rewrite top section heading to the new version number
  const lines = changelog.split(/\r?\n/);
  if (start >= 0) {
    lines[start] = `## [${next}]`;
  }
  fs.writeFileSync(changelogPath, `${lines.join("\n")}\n`);

  core.setOutput("skip", String(false));
  core.setOutput("version", next);
  core.setOutput("notes", body);

  return;
}
