import extractReleaseNotes from "./extract-release-notes.cts";

import { readJSON, getPkgPath } from "./helpers/index.cts";

import type { Core } from "./helpers/index.cts";

export default async function getReleaseState(core: Core) {
  const pkg = readJSON<{ version: string }>(getPkgPath());
  const notes = extractReleaseNotes({ version: pkg.version }) || "";

  core.setOutput("local_version", pkg.version);
  core.setOutput("notes", notes);
}
