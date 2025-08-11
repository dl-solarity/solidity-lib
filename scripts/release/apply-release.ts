#!/usr/bin/env node

import fs from "fs";
import path from "path";

import computeNextVersion from "./compute-next-version";

import { allowedWhenNotRc, allowedWhenRc } from "./constants";
import { getTopSection, readJSON, writeJSON } from "./utils";

import type { Core, Level } from "./types";

export default async function applyRelease(core: Core): Promise<void> {
  const root = process.cwd();
  const pkgPath = path.join(root, "package.json");
  const changelogPath = path.join(root, "CHANGELOG.md");

  if (!fs.existsSync(changelogPath)) throw new Error("CHANGELOG.md not found");

  const pkg = readJSON<{ version: string }>(pkgPath);
  const changelog = fs.readFileSync(changelogPath, "utf8");

  const { level, body, start } = getTopSection(changelog);
  if (!level) throw new Error("Top H2 tag not found");

  const pkgIsRc = /-rc\.\d+$/.test(pkg.version);
  const normalized = String(level).toLowerCase() as Level;

  if (!(pkgIsRc ? allowedWhenRc.has(normalized) : allowedWhenNotRc.has(normalized))) {
    if (pkgIsRc) {
      throw new Error("Top H2 tag must be one of rc|release when current version is an RC");
    } else {
      throw new Error("Top H2 tag must be one of patch|minor|major|none|patch-rc|minor-rc|major-rc when not in RC");
    }
  }
  if (body.trim().length === 0) throw new Error("Release notes section is empty");

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
