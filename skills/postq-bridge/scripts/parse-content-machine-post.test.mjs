import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { parseContentMachinePost } from "./parse-content-machine-post.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const skillRoot = resolve(__dirname, "..");
const parserPath = join(__dirname, "parse-content-machine-post.mjs");
const examplePath = join(skillRoot, "examples", "walkmon-post.md");

test("parses the Walkmon post example", () => {
  const parsed = parseContentMachinePost(readFileSync(examplePath, "utf8"));

  assert.deepEqual(parsed, {
    title: "walk-first-pet-reveal",
    caption:
      "Turn walks into progress you can actually see. Walkmon is coming soon.\n\n#walkmon #walking #gamifiedfitness",
    onVideoText: [
      { label: "Text 01 (video clip)", text: "this walk counted for something" },
      { label: "Text 02 (still image)", text: "then my pet evolved" },
    ],
  });
});

test("emits JSON from the CLI", () => {
  const raw = execFileSync("node", [parserPath, examplePath], { encoding: "utf8" });
  const parsed = JSON.parse(raw);

  assert.equal(parsed.title, "walk-first-pet-reveal");
  assert.equal(parsed.onVideoText.length, 2);
});

test("preserves shell-sensitive caption text", () => {
  const parsed = parseContentMachinePost(`# money-test

## Caption

\`\`\`
Line one with $literal text

#walkmon
\`\`\`

## On-video text

### Text 01 (video clip)

\`\`\`
walk text
\`\`\`
`);

  assert.equal(parsed.caption, "Line one with $literal text\n\n#walkmon");
});

test("fails when the caption block is missing", () => {
  assert.throws(
    () => parseContentMachinePost("# missing-caption\n\n## On-video text\n"),
    /missing a caption fenced block/
  );
});

test("CLI writes a clear error when the caption block is missing", () => {
  const dir = mkdtempSync(join(tmpdir(), "postq-bridge-"));
  const missingCaption = join(dir, "post.md");
  writeFileSync(missingCaption, "# missing-caption\n\n## On-video text\n", "utf8");

  const result = spawnSync("node", [parserPath, missingCaption], { encoding: "utf8" });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /missing a caption fenced block/);
  assert.equal(result.stdout, "");
});
