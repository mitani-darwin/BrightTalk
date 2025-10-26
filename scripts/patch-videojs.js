#!/usr/bin/env node

/**
 * Patch legacy video.js build so that it works when bundled in strict-mode modules.
 * The upstream UMD build relies on `this` being bound to the global object.
 * Vite executes the CommonJS wrapper with strict mode, so `this` is undefined.
 * We rewrite the first occurrence of `var Ba = this;` to provide a safe fallback.
 */

const fs = require("fs");
const path = require("path");

const candidatePaths = [
  path.resolve(__dirname, "..", "node_modules", "video.js", "dist", "video.js"),
  path.resolve(__dirname, "..", "node_modules", "video.js", "dist", "video-js", "video.js")
];
const targetPath = candidatePaths.find((p) => fs.existsSync(p));
const variants = [
  "var Ba=this;",
  "var Ba = this;"
];
const replacement = 'var Ba = typeof window !== "undefined" ? window : (typeof globalThis !== "undefined" ? globalThis : this);';

try {
  if (!targetPath) {
    process.exit(0);
  }

  const original = fs.readFileSync(targetPath, "utf8");

  const match = variants.find((variant) => original.includes(variant));

  if (!match) {
    process.exit(0);
  }

  if (original.includes(replacement)) {
    process.exit(0);
  }

  const patched = original.replace(match, replacement);
  fs.writeFileSync(targetPath, patched, "utf8");
  console.log("[patch-videojs] Applied global context fallback to video.js");
} catch (error) {
  console.error("[patch-videojs] Failed to apply patch:", error);
  process.exit(1);
}
