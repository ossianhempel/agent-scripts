const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const { buildReport } = require("../dist/engine.js");

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

test("buildReport scores Level 1 criteria and produces action items", async () => {
  const root = makeTempDir();
  try {
    writeFile(
      path.join(root, "README.md"),
      "# Sample\n\nRun: npm run start\nTest: npm test\nBuild: npm run build\n"
    );
    writeFile(path.join(root, "AGENTS.md"), "# Agent Instructions\n");
    writeJson(path.join(root, "package.json"), {
      name: "root-app",
      scripts: { lint: "eslint .", test: "echo test" },
    });
    writeJson(path.join(root, "tsconfig.json"), {
      compilerOptions: { strict: true },
    });

    const report = await buildReport(root, "0.1.0-test");

    assert.equal(report.levels.achievedLevel, 1);
    assert.equal(report.levels.nextLevel, 2);
    assert.equal(report.report.lint_config.numerator, 1);
    assert.equal(report.report.type_check.numerator, 1);
    assert.equal(report.report.unit_tests.numerator, 1);
    assert.ok(report.actionItems.length > 0);
    const actionIds = report.actionItems.map((item) => item.criterionId);
    assert.ok(actionIds.includes("devcontainer") || actionIds.includes("precommit_hooks"));
  } finally {
    cleanup(root);
  }
});
