import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";

export default defineConfig(
  // Global ignores (could also use globalIgnores from eslint/config)
  {
    ignores: ["dist/**", "node_modules/**", "generated-types/**", "artifacts/**"],
  },

  // Base JS recommendations
  js.configs.recommended,

  // TypeScript configs (typed + untyped bundles are available)
  // Using the combined recommended config set from typescript-eslint v8
  ...tseslint.configs.recommended,

  // Project-specific settings for TS files
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        // Point to your tsconfig if you want type-aware rules
        project: "./tsconfig.json",
        tsconfigRootDir: process.cwd(),
      },
      globals: {
        ...globals.node,
        ...globals.browser,
      },
    },
    plugins: {
      "@typescript-eslint": tseslint.plugin,
    },
    rules: {
      "@typescript-eslint/ban-ts-comment": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-unused-expressions": "off",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": [
        "error",
        { checksVoidReturn: { attributes: false } }
      ],
    },
  }
);
