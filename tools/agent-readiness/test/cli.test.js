const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { execFileSync } = require("node:child_process");

const cliPath = path.join(__dirname, "..", "dist", "cli.js");

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "agent-readiness-cli-"));
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

test("cli report outputs valid JSON", () => {
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

    const output = execFileSync(process.execPath, [
      cliPath,
      "report",
      "--format",
      "json",
      "--root",
      root,
    ], { encoding: "utf8" });

    const report = JSON.parse(output);
    assert.ok(report.report);
    assert.ok(report.levelSummary);
    assert.ok(report.criteriaMeta);
  } finally {
    cleanup(root);
  }
});
