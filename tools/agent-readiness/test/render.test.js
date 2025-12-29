const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const { buildReport } = require("../dist/engine.js");
const { renderMarkdown } = require("../dist/render.js");

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "agent-readiness-"));
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

function cleanup(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

test("renderMarkdown works even when no levels are achieved", async () => {
  const root = makeTempDir();
  try {
    writeJson(path.join(root, "package.json"), { name: "root-app" });
    const report = await buildReport(root, "0.1.0-test");
    const output = renderMarkdown(report);
    assert.ok(output.includes("Agent Readiness Report"));
    assert.ok(output.includes("Level achieved: 0"));
  } finally {
    cleanup(root);
  }
});

test("renderMarkdown displays (root) for fallback app in action items", async () => {
  const root = makeTempDir();
  try {
    // Create a minimal repo with README but no lint config
    fs.writeFileSync(path.join(root, "README.md"), "# Test\nRun: npm start\nTest: npm test\n");
    writeJson(path.join(root, "package.json"), {
      name: "test-app",
      scripts: { test: "echo test" }
    });

    const report = await buildReport(root, "0.1.0-test");
    const output = renderMarkdown(report);

    // Verify that action items use "(root)" not "."
    if (output.includes("Top action items")) {
      assert.ok(!output.includes("for: .."), "Should not have confusing '..' in action items");
      assert.ok(!output.includes("for: ."), "Should not have bare '.' in action items");
      // If there are failing apps, they should be displayed as "(root)"
      if (output.includes("for:")) {
        assert.ok(output.includes("(root)"), "Should display '(root)' for fallback app");
      }
    }
  } finally {
    cleanup(root);
  }
});
