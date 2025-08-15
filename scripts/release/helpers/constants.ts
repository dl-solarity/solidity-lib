import type { Level } from "./types";

export const allowedWhenNotRc: Set<Level> = new Set([
  "patch",
  "minor",
  "major",
  "none",
  "patch-rc",
  "minor-rc",
  "major-rc",
]);
export const allowedWhenRc: Set<Level> = new Set(["rc", "release", "none"]);
