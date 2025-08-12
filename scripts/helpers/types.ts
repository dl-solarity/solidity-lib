export type Level = "major" | "minor" | "patch" | "none" | "major-rc" | "minor-rc" | "patch-rc" | "rc" | "release";

export type Core = { setOutput: (key: string, value: string) => void };

export type TopSection = {
  level: string | null;
  body: string;
  start: number;
  end: number;
};
