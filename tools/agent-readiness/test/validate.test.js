const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const { buildReport } = require("../dist/engine.js");
const { validateReport } = require("../dist/validate.js");

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "agent-readiness-"));
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

function writeFile(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
}

function cleanup(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

test("validateReport passes for a valid report", async () => {
  const root = makeTempDir();
  try {
    writeFile(
      path.join(root, "README.md"),
      "# Sample\n\nRun: npm run start\nTest: npm test\nBuild: npm run build\n"
    );
    writeFile(path.join(root, "AGENTS.md"), "# Agent Instructions\n");
    writeJson(path.join(root, "package.json"), { name: "root-app" });

    const report = await buildReport(root, "0.1.0-test");
    const schemaPath = path.join(
      __dirname,
      "..",
      "schemas",
      "readiness-report.schema.json"
    );

    const result = validateReport(report, schemaPath);
    assert.equal(result.valid, true);
    assert.equal(result.errors.length, 0);
  } finally {
    cleanup(root);
  }
});

test("validateReport fails on invalid report", () => {
  const schemaPath = path.join(__dirname, "..", "schemas", "readiness-report.schema.json");
  const result = validateReport({ reportId: "bad" }, schemaPath);
  assert.equal(result.valid, false);
  assert.ok(result.errors.length > 0);
});
