#!/usr/bin/env node

import fs from "fs";

import { getChangelogPath, getPkgPath, readJSON, allowedWhenNotRc, allowedWhenRc } from "../helpers";

import type { Level } from "../helpers";

function fail(message: string): never {
  throw new Error(`CHANGELOG validation failed: ${message}`);
}

export default function validateChangelog(): void {
  const content = fs.readFileSync(getChangelogPath(), "utf8");
  const lines = content.split(/\r?\n/);

  // Find first H2 (## [xxx])
  const h2Regex = /^##\s*\[(.+?)\]\s*$/;
  let firstH2Index = -1;
  let firstH2Tag = "";
  for (let i = 0; i < lines.length; i += 1) {
    const m = lines[i].match(h2Regex);
    if (m) {
      firstH2Index = i;
      firstH2Tag = m[1].trim();
      break;
    }
  }

  if (firstH2Index === -1) {
    fail('No H2 heading like "## [patch|minor|major|none]" found');
  }

  const pkg = readJSON<{ version: string }>(getPkgPath());
  const isRc = /-rc\.\d+$/.test(pkg.version);
  const normalized = firstH2Tag.toLowerCase() as Level;

  const isAllowed = isRc ? allowedWhenRc.has(normalized) : allowedWhenNotRc.has(normalized);
  if (!isAllowed) {
    if (isRc) {
      fail(
        `Project is currently in RC (${pkg.version}). Top H2 tag must be one of [rc, none, release], got "${firstH2Tag}"`,
      );
    } else {
      fail(`Top H2 tag must be one of [patch, minor, major, none, patch-rc, minor-rc, major-rc], got "${firstH2Tag}"`);
    }
  }

  // Extract section content until next H2
  let nextH2Index = lines.length;
  for (let i = firstH2Index + 1; i < lines.length; i += 1) {
    if (h2Regex.test(lines[i])) {
      nextH2Index = i;
      break;
    }
  }

  const section = lines
    .slice(firstH2Index + 1, nextH2Index)
    .join("\n")
    .trim();
  if (section.length === 0) {
    fail("Top section content is empty");
  }

  // Basic structure: must have a top-level title `# Changelog` somewhere
  const hasTitle = /^#\s+Changelog\b/i.test(content);
  if (!hasTitle) {
    fail('Missing top-level "# Changelog" title');
  }
}

if (require.main === module) {
  try {
    validateChangelog();
    console.log("CHANGELOG.md validation passed.");
  } catch (err: any) {
    console.error(err?.message ?? String(err));
    process.exit(1);
  }
}
