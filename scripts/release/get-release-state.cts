import { execSync } from "node:child_process";

import extractReleaseNotes from "./extract-release-notes.cts";

import { readJSON, getPkgPath } from "./helpers/index.cts";

import type { Core } from "./helpers/index.cts";

export default async function getReleaseState(core: Core) {
  const isReleaseCommit = /^chore\(release\):/m.test(execSync("git log -1 --pretty=%B", { encoding: "utf8" }));

  const pkg = readJSON<{ version: string }>(getPkgPath());
  const notes = extractReleaseNotes({ version: pkg.version }) || "";

  core.setOutput("is_release_commit", String(isReleaseCommit));
  core.setOutput("local_version", pkg.version);
  core.setOutput("notes", notes);
}
