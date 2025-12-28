const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const { discoverApps } = require("../dist/discovery.js");

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

test("discoverApps falls back to root app when no workspace", () => {
  const root = makeTempDir();
  try {
    writeJson(path.join(root, "package.json"), { name: "root-app" });
    const apps = discoverApps(root);
    assert.equal(apps.length, 1);
    assert.equal(apps[0].path, ".");
  } finally {
    cleanup(root);
  }
});

test("discoverApps uses workspaces when present", () => {
  const root = makeTempDir();
  try {
    writeJson(path.join(root, "package.json"), { workspaces: ["apps/*"] });
    writeJson(path.join(root, "apps/web/package.json"), { name: "web" });
    writeJson(path.join(root, "apps/api/package.json"), { name: "api" });

    const apps = discoverApps(root);
    const paths = apps.map((app) => app.path).sort();
    assert.deepEqual(paths, ["apps/api", "apps/web"]);
  } finally {
    cleanup(root);
  }
});
