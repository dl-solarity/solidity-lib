import path from "path";
import { execSync } from "node:child_process";

import extractReleaseNotes from "./extract-release-notes";

import { readJSON } from "./utils";

import type { Core } from "./types";

export default async function computeReleaseState(core: Core) {
  const pkgPath = path.join(process.cwd(), "package.json");

  const isReleaseCommit = /^chore\(release\):/m.test(execSync("git log -1 --pretty=%B", { encoding: "utf8" }));

  const pkg = readJSON<{ version: string }>(pkgPath);
  const notes = extractReleaseNotes({ version: pkg.version }) || "";

  core.setOutput("is_release_commit", String(isReleaseCommit));
  core.setOutput("local_version", pkg.version);
  core.setOutput("notes", notes);
}
