#!/usr/bin/env node

import fs from "fs";
import { getChangelogPath, getPkgPath, readJSON } from "./utils";

export default function extractReleaseNotes({ version }: { version?: string } = {}): string {
  const changelogPath = getChangelogPath();
  if (!fs.existsSync(changelogPath)) {
    return "";
  }
  const changelog = fs.readFileSync(changelogPath, "utf8");

  const pkgVersion = version || readJSON<{ version: string }>(getPkgPath()).version;
  const escapedVersion = pkgVersion.replace(/\./g, "\\.");
  const header = new RegExp(`^##\\s*\\[${escapedVersion}\\]\\s*$`, "m");

  const lines = changelog.split(/\r?\n/);
  let start = -1;
  for (let i = 0; i < lines.length; i += 1) {
    if (header.test(lines[i])) {
      start = i;
      break;
    }
  }
  if (start === -1) {
    return "";
  }
  let end = lines.length;
  const h2 = /^##\s*\[.+?\]\s*$/;
  for (let i = start + 1; i < lines.length; i += 1) {
    if (h2.test(lines[i])) {
      end = i;
      break;
    }
  }

  return lines
    .slice(start + 1, end)
    .join("\n")
    .trim();
}
