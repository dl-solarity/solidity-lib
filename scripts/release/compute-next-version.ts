#!/usr/bin/env node

import fs from "fs";

import { bumpBase, parseRc, readJSON, getPkgPath, getChangelogPath } from "./utils";
import { allowedWhenNotRc, allowedWhenRc } from "./constants";

import type { Level } from "./types";

export default function computeNextVersion(): { current: string; level: Level; next: string } {
  const pkgPath = getPkgPath();
  const changelogPath = getChangelogPath();
  const pkg = readJSON<{ version: string }>(pkgPath);
  if (!fs.existsSync(changelogPath)) {
    throw new Error("CHANGELOG.md not found");
  }
  const changelog = fs.readFileSync(changelogPath, "utf8");
  const match = changelog.match(/^##\s*\[(.+?)\]\s*$/m);
  if (!match) {
    throw new Error("Could not find top H2 tag in CHANGELOG.md");
  }
  const level = match[1].trim().toLowerCase() as Level;

  const { base, rc } = parseRc(pkg.version);
  const isRc = rc !== null;

  if ((isRc && !allowedWhenRc.has(level)) || (!isRc && !allowedWhenNotRc.has(level))) {
    throw new Error(`Invalid top H2 tag: ${level} for current version ${pkg.version}`);
  }

  let next: string;
  if (!isRc) {
    switch (level) {
      case "none":
        next = base;
        break;
      case "major":
      case "minor":
      case "patch":
        next = bumpBase(base, level);
        break;
      case "major-rc":
        next = `${bumpBase(base, "major")}-rc.0`;
        break;
      case "minor-rc":
        next = `${bumpBase(base, "minor")}-rc.0`;
        break;
      case "patch-rc":
        next = `${bumpBase(base, "patch")}-rc.0`;
        break;
      case "rc":
      case "release":
        throw new Error(`Tag ${level} is only valid when current version is an RC`);
    }
  } else {
    switch (level) {
      case "rc":
        next = `${base}-rc.${rc + 1}`;
        break;
      case "release":
        next = base;
        break;
      case "none":
        next = `${base}-rc.${rc}`;
        break;
      default:
        throw new Error(`Tag ${level} is not valid while in RC`);
    }
  }
  return { current: pkg.version, level, next };
}
