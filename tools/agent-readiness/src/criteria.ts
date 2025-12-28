import path from "path";
import { AppInfo, CriterionCheck, CriterionDefinition, RepoContext } from "./types";
import { pathExists, readFileIfExists, readJsonFile } from "./utils";

const ESLINT_FILES = [
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  "eslint.config.js",
  "eslint.config.mjs",
];

const LINT_FILES = [
  ...ESLINT_FILES,
  ".ruff.toml",
  "ruff.toml",
  ".pylintrc",
  "pylintrc",
  "setup.cfg",
  "tox.ini",
  ".golangci.yml",
  ".golangci.yaml",
  "golangci.yml",
  "golangci.yaml",
];

const TEST_CONFIG_FILES = [
  "jest.config.js",
  "jest.config.cjs",
  "jest.config.mjs",
  "vitest.config.ts",
  "vitest.config.js",
  "pytest.ini",
  "tox.ini",
  "phpunit.xml",
];

const TYPECHECK_FILES = [
  "tsconfig.json",
  "pyrightconfig.json",
  "mypy.ini",
];

export const CRITERIA: CriterionDefinition[] = [
  {
    id: "readme",
    title: "README with run/test/build guidance",
    level: 1,
    pillar: "Documentation",
    scope: "repo",
    evaluateRepo: (ctx) => checkReadme(ctx.root),
    recommendation: () => "Add a README.md with clear run/build/test instructions.",
  },
  {
    id: "lint_config",
    title: "Lint configuration per app",
    level: 1,
    pillar: "Style & Validation",
    scope: "app",
    evaluateApp: (ctx, app) => checkLintConfig(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add lint config or lint script for: ${failingApps.join(", ")}.`
        : "Add lint configuration for each app.",
  },
  {
    id: "type_check",
    title: "Type checking configured per app",
    level: 1,
    pillar: "Build System",
    scope: "app",
    evaluateApp: (ctx, app) => checkTypeCheck(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add strict type checking configs for: ${failingApps.join(", ")}.`
        : "Add type checking configuration for each app.",
  },
  {
    id: "unit_tests",
    title: "Unit test command or config per app",
    level: 1,
    pillar: "Testing",
    scope: "app",
    evaluateApp: (ctx, app) => checkUnitTests(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add unit test configuration or command for: ${failingApps.join(", ")}.`
        : "Add unit tests or test command for each app.",
  },
  {
    id: "agents_md",
    title: "AGENTS.md instructions",
    level: 2,
    pillar: "Documentation",
    scope: "repo",
    evaluateRepo: (ctx) => checkAgentsMd(ctx.root),
    recommendation: () => "Add AGENTS.md with repo workflow and guardrails.",
  },
  {
    id: "devcontainer",
    title: "Reproducible dev environment hints",
    level: 2,
    pillar: "Dev Environment",
    scope: "repo",
    evaluateRepo: (ctx) => checkDevcontainer(ctx.root),
    recommendation: () => "Add .devcontainer/devcontainer.json or equivalent setup hints.",
  },
  {
    id: "precommit_hooks",
    title: "Pre-commit hooks configured",
    level: 2,
    pillar: "Style & Validation",
    scope: "repo",
    evaluateRepo: (ctx) => checkPrecommit(ctx.root),
    recommendation: () => "Add pre-commit hooks (pre-commit, husky, or lint-staged).",
  },
];

function checkReadme(root: string): CriterionCheck {
  const readmePath = path.join(root, "README.md");
  if (!pathExists(readmePath)) {
    return { passed: false, rationale: "README.md not found." };
  }
  const content = readFileIfExists(readmePath) || "";
  const lower = content.toLowerCase();
  const hasTest = /\b(test|tests|pytest|go test|cargo test)\b/.test(lower);
  const hasBuild = /\b(build|compile)\b/.test(lower);
  const hasRun = /\b(run|start|serve)\b/.test(lower);

  if (hasTest && (hasBuild || hasRun)) {
    return { passed: true, rationale: "README.md includes run/build/test guidance." };
  }

  return {
    passed: false,
    rationale: "README.md found but missing clear run/build/test guidance.",
  };
}

function checkAgentsMd(root: string): CriterionCheck {
  const agentsPath = path.join(root, "AGENTS.md");
  if (!pathExists(agentsPath)) {
    return { passed: false, rationale: "AGENTS.md not found." };
  }
  return { passed: true, rationale: "AGENTS.md present at repo root." };
}

function checkDevcontainer(root: string): CriterionCheck {
  const devcontainer = path.join(root, ".devcontainer", "devcontainer.json");
  const single = path.join(root, ".devcontainer.json");
  if (pathExists(devcontainer) || pathExists(single)) {
    return { passed: true, rationale: "Dev container configuration found." };
  }
  return { passed: false, rationale: "No devcontainer configuration found." };
}

function checkPrecommit(root: string): CriterionCheck {
  const precommit = path.join(root, ".pre-commit-config.yaml");
  const precommitYml = path.join(root, ".pre-commit-config.yml");
  const husky = path.join(root, ".husky");
  const lintStaged = readPackageJsonScript(root, "lint-staged");
  if (pathExists(precommit) || pathExists(precommitYml) || pathExists(husky) || lintStaged) {
    return { passed: true, rationale: "Pre-commit tooling detected." };
  }
  return { passed: false, rationale: "No pre-commit tooling detected." };
}

function checkLintConfig(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);
  const hasConfig = LINT_FILES.some((file) => pathExists(path.join(appRoot, file)));
  const hasScript = !!readPackageJsonScript(appRoot, "lint");

  if (hasConfig || hasScript) {
    return { passed: true, rationale: "Lint configuration or script detected." };
  }

  return {
    passed: false,
    rationale: "No lint config or lint script found in app.",
  };
}

function checkTypeCheck(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);

  if (pathExists(path.join(appRoot, "go.mod")) || pathExists(path.join(appRoot, "Cargo.toml"))) {
    return { passed: true, rationale: "Typed language module detected (Go/Rust)." };
  }

  const tsConfigPath = path.join(appRoot, "tsconfig.json");
  if (pathExists(tsConfigPath)) {
    const config = readJsonFile<{ compilerOptions?: Record<string, unknown> }>(tsConfigPath);
    const options = config?.compilerOptions || {};
    const strict = Boolean(options.strict || options.strictNullChecks || options.noImplicitAny);
    if (strict) {
      return { passed: true, rationale: "tsconfig.json with strict options detected." };
    }
    return { passed: false, rationale: "tsconfig.json found but strict options missing." };
  }

  for (const file of TYPECHECK_FILES) {
    if (pathExists(path.join(appRoot, file))) {
      return { passed: true, rationale: `Type check config found (${file}).` };
    }
  }

  const pyproject = readFileIfExists(path.join(appRoot, "pyproject.toml"));
  if (pyproject && /\[tool\.mypy\]|\[tool\.pyright\]/.test(pyproject)) {
    return { passed: true, rationale: "pyproject.toml includes type checking tool config." };
  }

  return { passed: false, rationale: "No type checking configuration found." };
}

function checkUnitTests(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);
  const hasTestScript = !!readPackageJsonScript(appRoot, "test");
  const hasConfig = TEST_CONFIG_FILES.some((file) => pathExists(path.join(appRoot, file)));
  const hasTestDir = pathExists(path.join(appRoot, "tests")) ||
    pathExists(path.join(appRoot, "__tests__"));

  if (hasTestScript || hasConfig || hasTestDir) {
    return { passed: true, rationale: "Unit test command or config detected." };
  }

  const pyproject = readFileIfExists(path.join(appRoot, "pyproject.toml"));
  if (pyproject && /\[tool\.pytest\.ini_options\]/.test(pyproject)) {
    return { passed: true, rationale: "pyproject.toml includes pytest config." };
  }

  return { passed: false, rationale: "No unit test command/config detected." };
}

function readPackageJsonScript(root: string, scriptName: string): string | null {
  const pkg = readJsonFile<{ scripts?: Record<string, string> }>(path.join(root, "package.json"));
  if (!pkg?.scripts) return null;
  return pkg.scripts[scriptName] ?? null;
}
