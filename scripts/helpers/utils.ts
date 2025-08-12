import fs from "fs";
import path from "path";

import { allowedWhenNotRc, allowedWhenRc } from "./constants";

import type { Level, TopSection } from "./types";

export function readJSON<T = any>(filePath: string): T {
  return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
}

export function writeJSON(filePath: string, obj: unknown): void {
  fs.writeFileSync(filePath, `${JSON.stringify(obj, null, 2)}\n`);
}

export function getPkgPath(): string {
  return path.resolve(process.cwd(), "package.json");
}

export function getChangelogPath(): string {
  const changelogPath = path.resolve(process.cwd(), "CHANGELOG.md");
  if (!fs.existsSync(changelogPath)) throw new Error("CHANGELOG.md not found");
  return changelogPath;
}

export function parseRc(version: string): { base: string; rc: number | null } {
  const match = version.match(/^(\d+)\.(\d+)\.(\d+)(?:-rc\.(\d+))?$/);
  if (!match) throw new Error(`Invalid semver in package.json: ${version}`);
  const base = `${match[1]}.${match[2]}.${match[3]}`;
  const rc = match[4] ? parseInt(match[4], 10) : null;
  return { base, rc };
}

export function bumpBase(version: string, level: Extract<Level, "major" | "minor" | "patch" | "none">): string {
  const [majorStr, minorStr, patchStr] = version.split(".");
  const major = parseInt(majorStr, 10);
  const minor = parseInt(minorStr, 10);
  const patch = parseInt(patchStr, 10);
  if (Number.isNaN(major) || Number.isNaN(minor) || Number.isNaN(patch)) {
    throw new Error(`Invalid semver in package.json: ${version}`);
  }
  switch (level) {
    case "major":
      return `${major + 1}.0.0`;
    case "minor":
      return `${major}.${minor + 1}.0`;
    case "patch":
      return `${major}.${minor}.${patch + 1}`;
    case "none":
      return version;
  }
}

export function getTopSection(changelogContent: string): TopSection {
  const h2Regex = /^##\s*\[(.+?)\]\s*$/m;
  const allLines = changelogContent.split(/\r?\n/);
  let topIdx = -1;
  for (let i = 0; i < allLines.length; i += 1) {
    if (h2Regex.test(allLines[i])) {
      topIdx = i;
      break;
    }
  }
  if (topIdx === -1) return { level: null, body: "", start: -1, end: -1 };

  const level = allLines[topIdx]
    .replace(/^##\s*\[/, "")
    .replace(/\]\s*$/, "")
    .trim()
    .toLowerCase();
  let endIdx = allLines.length;
  for (let i = topIdx + 1; i < allLines.length; i += 1) {
    if (/^##\s*\[.+?\]\s*$/.test(allLines[i])) {
      endIdx = i;
      break;
    }
  }
  const body = allLines
    .slice(topIdx + 1, endIdx)
    .join("\n")
    .trim();
  return { level, body, start: topIdx, end: endIdx };
}

export function validateReleaseTopSection({
  level,
  body,
  pkgIsRc,
}: {
  level: string | null;
  body: string;
  pkgIsRc: boolean;
}): void {
  if (!level) throw new Error("Top H2 tag not found");
  const normalized = String(level).toLowerCase() as Level;
  if (!(pkgIsRc ? allowedWhenRc.has(normalized) : allowedWhenNotRc.has(normalized))) {
    if (pkgIsRc) {
      throw new Error("Top H2 tag must be one of rc|nonce|release when current version is an RC");
    } else {
      throw new Error("Top H2 tag must be one of patch|minor|major|none|patch-rc|minor-rc|major-rc when not in RC");
    }
  }
  if (body.trim().length === 0) throw new Error("Release notes section is empty");
}
