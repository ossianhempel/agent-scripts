import { spawnSync } from "child_process";
import fs from "fs";
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

const INTEGRATION_SCRIPT_NAMES = [
  "test:integration",
  "integration",
  "test:e2e",
  "e2e",
  "playwright",
  "cypress",
];

const IGNORE_DIRS = [
  ".git",
  "node_modules",
  "dist",
  "build",
  "out",
  "coverage",
  ".next",
  ".turbo",
  ".venv",
  "venv",
  "vendor",
  "tmp",
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
        ? `Add lint config or lint script for: ${formatAppList(failingApps)}.`
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
        ? `Add strict type checking configs for: ${formatAppList(failingApps)}.`
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
        ? `Add unit test configuration or command for: ${formatAppList(failingApps)}.`
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
  {
    id: "integration_tests_configured",
    title: "Integration tests configured per app",
    level: 3,
    pillar: "Testing",
    scope: "app",
    evaluateApp: (ctx, app) => checkIntegrationTestsConfigured(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add integration test scripts/configs for: ${formatAppList(failingApps)}.`
        : "Add integration test scripts/configs for each app.",
  },
  {
    id: "integration_tests_runnable",
    title: "Integration tests runnable locally",
    level: 3,
    pillar: "Testing",
    scope: "app",
    evaluateApp: (ctx, app) => checkIntegrationTestsRunnable(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Ensure integration test commands run locally for: ${formatAppList(failingApps)}.`
        : "Ensure integration test commands run locally for each app.",
  },
  {
    id: "test_env_provisioned",
    title: "Test environment provisioned",
    level: 3,
    pillar: "Dev Environment",
    scope: "repo",
    evaluateRepo: (ctx) => checkTestEnvironment(ctx.root),
    recommendation: () => "Add docker-compose or dev services for integration test dependencies.",
  },
  {
    id: "secret_scanning_enabled",
    title: "Secret scanning enabled",
    level: 3,
    pillar: "Security",
    scope: "repo",
    evaluateRepo: (ctx) => checkSecretScanning(ctx.root),
    recommendation: () => "Add secret scanning (gitleaks/trufflehog) to CI or pre-commit.",
  },
  {
    id: "precommit_secret_scanning",
    title: "Pre-commit secret scanning configured",
    level: 3,
    pillar: "Security",
    scope: "repo",
    evaluateRepo: (ctx) => checkPrecommitSecretScanning(ctx.root),
    recommendation: () => "Add a pre-commit secret scanning hook (gitleaks/trufflehog/detect-secrets).",
  },
  {
    id: "distributed_tracing_instrumented",
    title: "Distributed tracing instrumented per app",
    level: 3,
    pillar: "Observability",
    scope: "app",
    evaluateApp: (ctx, app) => checkTracing(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add OpenTelemetry tracing instrumentation for: ${formatAppList(failingApps)}.`
        : "Add OpenTelemetry tracing instrumentation for each app.",
  },
  {
    id: "metrics_instrumented",
    title: "Metrics instrumented per app",
    level: 3,
    pillar: "Observability",
    scope: "app",
    evaluateApp: (ctx, app) => checkMetrics(ctx, app),
    recommendation: (_, failingApps) =>
      failingApps.length
        ? `Add metrics instrumentation and /metrics exposure for: ${formatAppList(failingApps)}.`
        : "Add metrics instrumentation and /metrics exposure for each app.",
  },
  {
    id: "ci_workflows_present",
    title: "CI workflows present",
    level: 3,
    pillar: "Automation",
    scope: "repo",
    evaluateRepo: (ctx) => checkCiWorkflows(ctx.root),
    recommendation: () => "Add CI workflows for tests, linting, and validation.",
  },
  {
    id: "ci_fast_feedback",
    title: "Fast CI feedback",
    level: 4,
    pillar: "Automation",
    scope: "repo",
    evaluateRepo: (ctx) => checkCiFastFeedback(ctx),
    recommendation: () => "Add CI caching, parallelism, or split jobs to reduce feedback time.",
  },
  {
    id: "regular_deploy_frequency",
    title: "Regular deployment frequency",
    level: 4,
    pillar: "Delivery",
    scope: "repo",
    evaluateRepo: (ctx) => checkDeployFrequency(ctx),
    recommendation: () => "Automate deployments or releases on a steady cadence.",
  },
  {
    id: "flaky_test_detection",
    title: "Flaky test detection",
    level: 4,
    pillar: "Testing",
    scope: "repo",
    evaluateRepo: (ctx) => checkFlakyTests(ctx),
    recommendation: () => "Add flake detection (retries + reporting) to CI.",
  },
  {
    id: "agent_orchestration_present",
    title: "Agent orchestration present",
    level: 5,
    pillar: "Autonomy",
    scope: "repo",
    evaluateRepo: (ctx) => checkAgentOrchestration(ctx.root),
    recommendation: () => "Add an agent runner workflow or orchestration entrypoint.",
  },
  {
    id: "autonomous_changes_are_reviewed",
    title: "Autonomous changes are reviewed",
    level: 5,
    pillar: "Governance",
    scope: "repo",
    evaluateRepo: (ctx) => checkReviewGuardrails(ctx.root),
    recommendation: () => "Add CODEOWNERS and enforce PR reviews for autonomous changes.",
  },
  {
    id: "rollback_or_revert_playbook",
    title: "Rollback or revert playbook",
    level: 5,
    pillar: "Reliability",
    scope: "repo",
    evaluateRepo: (ctx) => checkRollbackPlaybook(ctx.root),
    recommendation: () => "Document rollback/revert steps in a runbook.",
  },
  {
    id: "incident_to_fix_pipeline",
    title: "Incident-to-fix pipeline",
    level: 5,
    pillar: "Operations",
    scope: "repo",
    evaluateRepo: (ctx) => checkIncidentPipeline(ctx.root),
    recommendation: () => "Add issue templates and automation linking incidents to fixes.",
  },
  {
    id: "feedback_loop_instrumentation",
    title: "Feedback loop instrumentation",
    level: 5,
    pillar: "Product",
    scope: "repo",
    evaluateRepo: (ctx) => checkFeedbackLoop(ctx.root),
    recommendation: () => "Add monitoring/analytics configs that feed into automated follow-ups.",
  },
];

function formatAppList(apps: string[]): string {
  return apps.map((app) => (app === "." ? "(root)" : app)).join(", ");
}

function pass(rationale: string): CriterionCheck {
  return { status: "pass", rationale };
}

function fail(rationale: string): CriterionCheck {
  return { status: "fail", rationale };
}

function notEvaluated(rationale: string): CriterionCheck {
  return { status: "not_evaluated", rationale };
}

function checkReadme(root: string): CriterionCheck {
  const readmePath = path.join(root, "README.md");
  if (!pathExists(readmePath)) {
    return fail("README.md not found.");
  }
  const content = readFileIfExists(readmePath) || "";
  const lower = content.toLowerCase();
  const hasTest = /\b(test|tests|pytest|go test|cargo test)\b/.test(lower);
  const hasBuild = /\b(build|compile)\b/.test(lower);
  const hasRun = /\b(run|start|serve)\b/.test(lower);

  if (hasTest && (hasBuild || hasRun)) {
    return pass("README.md includes run/build/test guidance.");
  }

  return fail("README.md found but missing clear run/build/test guidance.");
}

function checkAgentsMd(root: string): CriterionCheck {
  const agentsPath = path.join(root, "AGENTS.md");
  if (!pathExists(agentsPath)) {
    return fail("AGENTS.md not found.");
  }
  return pass("AGENTS.md present at repo root.");
}

function checkDevcontainer(root: string): CriterionCheck {
  const devcontainer = path.join(root, ".devcontainer", "devcontainer.json");
  const single = path.join(root, ".devcontainer.json");
  if (pathExists(devcontainer) || pathExists(single)) {
    return pass("Dev container configuration found.");
  }
  return fail("No devcontainer configuration found.");
}

function checkPrecommit(root: string): CriterionCheck {
  const precommit = path.join(root, ".pre-commit-config.yaml");
  const precommitYml = path.join(root, ".pre-commit-config.yml");
  const husky = path.join(root, ".husky");
  const lintStaged = readPackageJsonScript(root, "lint-staged");
  if (pathExists(precommit) || pathExists(precommitYml) || pathExists(husky) || lintStaged) {
    return pass("Pre-commit tooling detected.");
  }
  return fail("No pre-commit tooling detected.");
}

function checkLintConfig(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);
  const hasConfig = LINT_FILES.some((file) => pathExists(path.join(appRoot, file)));
  const hasScript = !!readPackageJsonScript(appRoot, "lint");

  if (hasConfig || hasScript) {
    return pass("Lint configuration or script detected.");
  }

  return fail("No lint config or lint script found in app.");
}

function checkTypeCheck(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);

  if (pathExists(path.join(appRoot, "go.mod")) || pathExists(path.join(appRoot, "Cargo.toml"))) {
    return pass("Typed language module detected (Go/Rust).");
  }

  const tsConfigPath = path.join(appRoot, "tsconfig.json");
  if (pathExists(tsConfigPath)) {
    const config = readJsonFile<{ compilerOptions?: Record<string, unknown> }>(tsConfigPath);
    const options = config?.compilerOptions || {};
    const strict = Boolean(options.strict || options.strictNullChecks || options.noImplicitAny);
    if (strict) {
      return pass("tsconfig.json with strict options detected.");
    }
    return fail("tsconfig.json found but strict options missing.");
  }

  for (const file of TYPECHECK_FILES) {
    if (pathExists(path.join(appRoot, file))) {
      return pass(`Type check config found (${file}).`);
    }
  }

  const pyproject = readFileIfExists(path.join(appRoot, "pyproject.toml"));
  if (pyproject && /\[tool\.mypy\]|\[tool\.pyright\]/.test(pyproject)) {
    return pass("pyproject.toml includes type checking tool config.");
  }

  return fail("No type checking configuration found.");
}

function checkUnitTests(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);
  const hasTestScript = !!readPackageJsonScript(appRoot, "test");
  const hasConfig = TEST_CONFIG_FILES.some((file) => pathExists(path.join(appRoot, file)));
  const hasTestDir = pathExists(path.join(appRoot, "tests")) ||
    pathExists(path.join(appRoot, "__tests__"));

  if (hasTestScript || hasConfig || hasTestDir) {
    return pass("Unit test command or config detected.");
  }

  const pyproject = readFileIfExists(path.join(appRoot, "pyproject.toml"));
  if (pyproject && /\[tool\.pytest\.ini_options\]/.test(pyproject)) {
    return pass("pyproject.toml includes pytest config.");
  }

  return fail("No unit test command/config detected.");
}

function checkIntegrationTestsConfigured(ctx: RepoContext, app: AppInfo): CriterionCheck {
  const appRoot = path.join(ctx.root, app.path);
  const hasScript = INTEGRATION_SCRIPT_NAMES.some(
    (name) => readPackageJsonScript(appRoot, name) !== null
  );
  const hasConfig = [
    "playwright.config.ts",
    "playwright.config.js",
    "playwright.config.mjs",
    "cypress.config.ts",
    "cypress.config.js",
    "cypress.config.mjs",
  ].some((file) => pathExists(path.join(appRoot, file)));
  const hasDirs = [
    path.join(appRoot, "tests", "integration"),
    path.join(appRoot, "tests", "e2e"),
    path.join(appRoot, "__tests__", "integration"),
    path.join(appRoot, "__tests__", "e2e"),
    path.join(appRoot, "e2e"),
  ].some((dir) => pathExists(dir));
  const hasGoFiles = findFilesByPattern(appRoot, /_integration_test\.go$/).length > 0;

  if (hasScript || hasConfig || hasDirs || hasGoFiles) {
    return pass("Integration test scripts/config detected.");
  }

  const pyproject = readFileIfExists(path.join(appRoot, "pyproject.toml"));
  if (pyproject && /integration/.test(pyproject)) {
    return pass("Pyproject contains integration test markers/config.");
  }

  return fail("No integration test scripts/config detected.");
}

function checkIntegrationTestsRunnable(ctx: RepoContext, app: AppInfo): CriterionCheck {
  if (!ctx.options.runIntegration) {
    return notEvaluated("Enable --run-integration to execute integration tests.");
  }

  const appRoot = path.join(ctx.root, app.path);
  const command = resolveIntegrationCommand(appRoot);
  if (!command) {
    return fail("No integration test command resolved.");
  }

  try {
    const result = runCommand(command, appRoot, 90_000);
    if (result.ok) {
      return pass("Integration tests ran successfully.");
    }
    return fail(`Integration tests failed (exit ${result.code}).`);
  } catch (error) {
    return fail(`Integration tests failed to run: ${String(error)}.`);
  }
}

function checkTestEnvironment(root: string): CriterionCheck {
  const composeFiles = [
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
    "docker-compose.test.yml",
    "docker-compose.test.yaml",
  ];
  if (composeFiles.some((file) => pathExists(path.join(root, file)))) {
    return pass("Docker compose configuration detected for test services.");
  }
  if (pathExists(path.join(root, ".devcontainer", "devcontainer.json"))) {
    return pass("Dev container config can provision test services.");
  }
  return fail("No test environment provisioning config detected.");
}

function checkSecretScanning(root: string): CriterionCheck & { evidence?: string[] } {
  const configHit = [
    "gitleaks.toml",
    ".gitleaks.toml",
    ".trufflehog",
    ".trufflehogignore",
  ].find((file) => pathExists(path.join(root, file)));
  if (configHit) {
    return { ...pass(`Secret scanning config detected (${configHit}).`), evidence: [configHit] };
  }

  const workflows = readWorkflowFiles(root);
  for (const file of workflows) {
    if (
      fileContainsAny(file, [
        /gitleaks/i,
        /trufflehog/i,
        /detect[-_ ]secrets/i,
        /secret[-_ ]scan/i,
      ])
    ) {
      return {
        ...pass(`Secret scanning workflow detected (${path.basename(file)}).`),
        evidence: [path.relative(root, file)],
      };
    }
  }

  return fail("No secret scanning workflow/config detected.");
}

function checkPrecommitSecretScanning(root: string): CriterionCheck & { evidence?: string[] } {
  const precommit = readFileIfExists(path.join(root, ".pre-commit-config.yaml"));
  const precommitYml = readFileIfExists(path.join(root, ".pre-commit-config.yml"));
  const content = `${precommit || ""}\n${precommitYml || ""}`;
  if (/gitleaks|trufflehog|detect-secrets/i.test(content)) {
    return {
      ...pass("Pre-commit secret scanning hook detected (.pre-commit-config.*)."),
      evidence: [".pre-commit-config.yaml", ".pre-commit-config.yml"].filter((file) =>
        pathExists(path.join(root, file))
      ),
    };
  }
  return fail("No pre-commit secret scanning hook detected.");
}

function checkTracing(ctx: RepoContext, app: AppInfo): CriterionCheck & { evidence?: string[] } {
  const appRoot = path.join(ctx.root, app.path);
  const hasDep = hasTracingDependency(appRoot);
  const hasEntrypoint = hasTelemetryEntrypoint(appRoot, [
    "instrumentation.ts",
    "instrumentation.js",
    "tracing.ts",
    "tracing.js",
    "telemetry.ts",
    "telemetry.js",
    "otel.ts",
    "otel.js",
  ]);
  const signatureHit = ctx.options.telemetryScan
    ? scanFilesForPatterns(appRoot, [
        /opentelemetry/i,
        /getTracer\(/,
        /startSpan\(/,
        /trace\.getTracer/i,
      ])
    : null;

  if (hasDep && (hasEntrypoint || signatureHit)) {
    if (hasEntrypoint) {
      return {
        ...pass("Tracing dependencies and instrumentation detected (entrypoint file)."),
        evidence: listTelemetryEntrypoints(appRoot, [
          "instrumentation.ts",
          "instrumentation.js",
          "tracing.ts",
          "tracing.js",
          "telemetry.ts",
          "telemetry.js",
          "otel.ts",
          "otel.js",
        ]).map((filePath: string) => path.relative(ctx.root, filePath)),
      };
    }
    if (signatureHit) {
      return {
        ...pass(`Tracing dependencies and instrumentation detected (${signatureHit}).`),
        evidence: [path.relative(ctx.root, path.join(appRoot, signatureHit))],
      };
    }
    return pass("Tracing dependencies and instrumentation detected.");
  }
  if (hasDep) {
    return fail("Tracing dependency present but no instrumentation entrypoint found.");
  }
  return fail("No tracing dependency or instrumentation detected.");
}

function checkMetrics(ctx: RepoContext, app: AppInfo): CriterionCheck & { evidence?: string[] } {
  const appRoot = path.join(ctx.root, app.path);
  const hasDep = hasMetricsDependency(appRoot);
  const hasEntrypoint = hasTelemetryEntrypoint(appRoot, [
    "metrics.ts",
    "metrics.js",
    "telemetry.ts",
    "telemetry.js",
  ]);
  const signatureHit = ctx.options.telemetryScan
    ? scanFilesForPatterns(appRoot, [/prom-client/i, /prometheus/i, /metrics/i])
    : null;

  if (hasDep && (hasEntrypoint || signatureHit)) {
    if (hasEntrypoint) {
      return {
        ...pass("Metrics dependencies and instrumentation detected (entrypoint file)."),
        evidence: listTelemetryEntrypoints(appRoot, [
          "metrics.ts",
          "metrics.js",
          "telemetry.ts",
          "telemetry.js",
        ]).map((filePath: string) => path.relative(ctx.root, filePath)),
      };
    }
    if (signatureHit) {
      return {
        ...pass(`Metrics dependencies and instrumentation detected (${signatureHit}).`),
        evidence: [path.relative(ctx.root, path.join(appRoot, signatureHit))],
      };
    }
    return pass("Metrics dependencies and instrumentation detected.");
  }
  if (hasDep) {
    return fail("Metrics dependency present but no instrumentation entrypoint found.");
  }
  return fail("No metrics dependency or instrumentation detected.");
}

function checkCiWorkflows(root: string): CriterionCheck & { evidence?: string[] } {
  const workflows = readWorkflowFiles(root);
  if (workflows.length > 0) {
    return {
      ...pass(`CI workflow files detected (${workflows.length}).`),
      evidence: workflows.map((file) => path.relative(root, file)),
    };
  }
  return fail("No CI workflows detected.");
}

function checkCiFastFeedback(ctx: RepoContext): CriterionCheck & { evidence?: string[] } {
  if (ctx.options.signals !== "github" && ctx.options.ciProvider !== "github") {
    return notEvaluated(
      "Enable GitHub signals in the CLI (e.g. `agent-readiness report --signals github`) to evaluate CI feedback."
    );
  }
  const workflows = readWorkflowFiles(ctx.root);
  if (workflows.length === 0) {
    return fail("No CI workflows available to assess feedback speed.");
  }
  const cachingHit = findFirstWorkflowMatch(workflows, [
    /actions\/cache/i,
    /cache:\s*/i,
    /restore-keys/i,
  ]);
  const matrixHit = findFirstWorkflowMatch(workflows, [/strategy:\s*\n\s*matrix/i]);
  if (cachingHit || matrixHit) {
    if (cachingHit) {
      return {
        ...pass(`CI caching detected (${path.basename(cachingHit)}).`),
        evidence: [path.relative(ctx.root, cachingHit)],
      };
    }
    if (matrixHit) {
      return {
        ...pass(`CI matrix parallelism detected (${path.basename(matrixHit)}).`),
        evidence: [path.relative(ctx.root, matrixHit)],
      };
    }
    return pass("CI caching or matrix parallelism detected.");
  }
  return fail("No CI caching or matrix parallelism detected.");
}

function checkDeployFrequency(ctx: RepoContext): CriterionCheck & { evidence?: string[] } {
  if (ctx.options.signals !== "github" && ctx.options.ciProvider !== "github") {
    return notEvaluated(
      "Enable GitHub signals in the CLI (e.g. `agent-readiness report --signals github`) to evaluate deployment frequency."
    );
  }
  const workflows = readWorkflowFiles(ctx.root);
  const deployHit = findFirstWorkflowMatch(workflows, [
    /deploy/i,
    /release/i,
    /publish/i,
    /environment/i,
  ]);
  if (deployHit) {
    return {
      ...pass(`Deployment/release workflows detected (${path.basename(deployHit)}).`),
      evidence: [path.relative(ctx.root, deployHit)],
    };
  }
  return fail("No deployment/release workflows detected.");
}

function checkFlakyTests(ctx: RepoContext): CriterionCheck & { evidence?: string[] } {
  if (ctx.options.signals !== "github" && ctx.options.ciProvider !== "github") {
    return notEvaluated(
      "Enable GitHub signals in the CLI (e.g. `agent-readiness report --signals github`) to evaluate flaky test detection."
    );
  }
  const root = ctx.root;
  const workflows = readWorkflowFiles(root);
  const workflowHit = findFirstWorkflowMatch(workflows, [/retry/i, /flake/i, /rerun/i]);
  const configHit = hasFlakyTestConfig(ctx);
  if (workflowHit || configHit) {
    if (workflowHit) {
      return {
        ...pass(`Flaky test workflow detected (${path.basename(workflowHit)}).`),
        evidence: [path.relative(ctx.root, workflowHit)],
      };
    }
    if (configHit) {
      return {
        ...pass(`Flaky test config detected (${configHit}).`),
        evidence: [configHit],
      };
    }
    return pass("Flaky test retries or detection configuration detected.");
  }
  return fail("No flaky test detection configuration detected.");
}

function checkAgentOrchestration(root: string): CriterionCheck & { evidence?: string[] } {
  const workflows = readWorkflowFiles(root);
  const workflowHit = findFirstWorkflowMatch(workflows, [
    /\bagent\b/i,
    /autonomous/i,
    /codex/i,
    /copilot/i,
  ]);
  const scriptHit = findFilesByPattern(root, /agent[-_].*\.(js|ts|py|sh)$/)[0];
  if (workflowHit || scriptHit) {
    if (workflowHit) {
      return {
        ...pass(`Agent orchestration workflow detected (${path.basename(workflowHit)}).`),
        evidence: [path.relative(root, workflowHit)],
      };
    }
    if (scriptHit) {
      return {
        ...pass(`Agent orchestration script detected (${path.basename(scriptHit)}).`),
        evidence: [path.relative(root, scriptHit)],
      };
    }
    return pass("Agent orchestration workflow or scripts detected.");
  }
  return fail("No agent orchestration workflow or scripts detected.");
}

function checkReviewGuardrails(root: string): CriterionCheck {
  const hasCodeowners = [
    path.join(root, "CODEOWNERS"),
    path.join(root, ".github", "CODEOWNERS"),
  ].some((file) => pathExists(file));
  if (hasCodeowners) {
    return pass("CODEOWNERS detected for review guardrails.");
  }
  return fail("CODEOWNERS not found for review guardrails.");
}

function checkRollbackPlaybook(root: string): CriterionCheck & { evidence?: string[] } {
  const candidates = findFilesByPattern(root, /(runbook|rollback|revert)\.md$/i);
  if (candidates.length > 0) {
    return {
      ...pass(`Rollback/runbook documentation detected (${path.basename(candidates[0])}).`),
      evidence: [path.relative(root, candidates[0])],
    };
  }
  return fail("No rollback/runbook documentation detected.");
}

function checkIncidentPipeline(root: string): CriterionCheck & { evidence?: string[] } {
  const issueTemplates = path.join(root, ".github", "ISSUE_TEMPLATE");
  const hasTemplates = pathExists(issueTemplates) ||
    pathExists(path.join(root, ".github", "issue_template.yml"));
  const workflows = readWorkflowFiles(root);
  const incidentHit = findFirstWorkflowMatch(workflows, [
    /issues?/i,
    /incident/i,
    /pagerduty/i,
    /ops/i,
  ]);
  if (hasTemplates && incidentHit) {
    return pass(
      `Incident templates and automation detected (${incidentHit ? path.basename(incidentHit) : "workflow"}).`
    );
  }
  if (hasTemplates) {
    return fail("Issue templates found but no incident automation detected.");
  }
  return fail("No incident templates or automation detected.");
}

function checkFeedbackLoop(root: string): CriterionCheck & { evidence?: string[] } {
  const candidates = findFilesByPattern(root, /(sentry|datadog|newrelic|grafana|prometheus|alerts?)\.(yml|yaml|json|toml|properties)$/i);
  if (candidates.length > 0) {
    return {
      ...pass(`Monitoring/analytics config detected (${path.basename(candidates[0])}).`),
      evidence: [path.relative(root, candidates[0])],
    };
  }
  const dependencyHit = scanFilesForPatterns(root, [
    /sentry/i,
    /datadog/i,
    /newrelic/i,
    /grafana/i,
  ]);
  if (dependencyHit) {
    return {
      ...pass(`Monitoring/analytics dependencies detected (${dependencyHit}).`),
      evidence: [dependencyHit],
    };
  }
  return fail("No feedback loop instrumentation detected.");
}

function resolveIntegrationCommand(appRoot: string): string | null {
  const pkg = readJsonFile<{ scripts?: Record<string, string> }>(
    path.join(appRoot, "package.json")
  );
  if (pkg?.scripts) {
    for (const name of INTEGRATION_SCRIPT_NAMES) {
      if (pkg.scripts[name]) {
        return `npm run ${name}`;
      }
    }
  }

  if (pathExists(path.join(appRoot, "pytest.ini")) ||
    pathExists(path.join(appRoot, "tests", "integration"))) {
    return "pytest tests/integration";
  }

  if (pathExists(path.join(appRoot, "go.mod")) &&
    findFilesByPattern(appRoot, /_integration_test\.go$/).length > 0) {
    return "go test -tags=integration ./...";
  }

  return null;
}

function readPackageJsonScript(root: string, scriptName: string): string | null {
  const pkg = readJsonFile<{ scripts?: Record<string, string> }>(path.join(root, "package.json"));
  if (!pkg?.scripts) return null;
  return pkg.scripts[scriptName] ?? null;
}

function hasTracingDependency(root: string): boolean {
  return hasDependency(root, [
    "@opentelemetry/api",
    "@opentelemetry/sdk-node",
    "@opentelemetry/sdk-trace",
    "opentelemetry-api",
  ]) ||
    hasPythonDependency(root, ["opentelemetry", "opentelemetry-sdk", "opentelemetry-api"]) ||
    hasGoDependency(root, ["go.opentelemetry.io/otel"]);
}

function hasMetricsDependency(root: string): boolean {
  return hasDependency(root, ["prom-client", "@opentelemetry/sdk-metrics", "opentelemetry-metrics"]) ||
    hasPythonDependency(root, ["prometheus_client", "opentelemetry", "opentelemetry-sdk"]) ||
    hasGoDependency(root, ["github.com/prometheus/client_golang", "go.opentelemetry.io/otel"]);
}

function hasDependency(root: string, names: string[]): boolean {
  const pkg = readJsonFile<{
    dependencies?: Record<string, string>;
    devDependencies?: Record<string, string>;
    peerDependencies?: Record<string, string>;
  }>(path.join(root, "package.json"));
  const deps = {
    ...(pkg?.dependencies || {}),
    ...(pkg?.devDependencies || {}),
    ...(pkg?.peerDependencies || {}),
  };
  return names.some((name) => Object.prototype.hasOwnProperty.call(deps, name));
}

function hasPythonDependency(root: string, names: string[]): boolean {
  const files = [
    "requirements.txt",
    "requirements-dev.txt",
    "pyproject.toml",
    "Pipfile",
    "poetry.lock",
  ];
  for (const file of files) {
    const content = readFileIfExists(path.join(root, file));
    if (!content) continue;
    if (names.some((name) => new RegExp(name, "i").test(content))) {
      return true;
    }
  }
  return false;
}

function hasGoDependency(root: string, names: string[]): boolean {
  const content = readFileIfExists(path.join(root, "go.mod"));
  if (!content) return false;
  return names.some((name) => content.includes(name));
}

function hasTelemetryEntrypoint(root: string, names: string[]): boolean {
  return names.some((name) => pathExists(path.join(root, name)));
}

function listTelemetryEntrypoints(root: string, names: string[]): string[] {
  return names.map((name) => path.join(root, name)).filter((file) => pathExists(file));
}

function readWorkflowFiles(root: string): string[] {
  const workflowsDir = path.join(root, ".github", "workflows");
  if (!pathExists(workflowsDir)) return [];
  try {
    return fs
      .readdirSync(workflowsDir)
      .filter((file) => file.endsWith(".yml") || file.endsWith(".yaml"))
      .map((file) => path.join(workflowsDir, file));
  } catch {
    return [];
  }
}

function fileContainsAny(filePath: string, patterns: RegExp[]): boolean {
  const content = readFileIfExists(filePath);
  if (!content) return false;
  return patterns.some((pattern) => pattern.test(content));
}

function findFilesByPattern(root: string, pattern: RegExp, maxFiles = 600): string[] {
  const results: string[] = [];
  const stack = [root];

  while (stack.length && results.length < maxFiles) {
    const current = stack.pop();
    if (!current) break;
    let entries: fs.Dirent[] = [];
    try {
      entries = fs.readdirSync(current, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (entry.isDirectory()) {
        if (IGNORE_DIRS.includes(entry.name)) continue;
        stack.push(path.join(current, entry.name));
      } else if (entry.isFile()) {
        if (pattern.test(entry.name)) {
          results.push(path.join(current, entry.name));
          if (results.length >= maxFiles) break;
        }
      }
    }
  }

  return results;
}

function scanFilesForPatterns(
  root: string,
  patterns: RegExp[],
  extensions: string[] = [".ts", ".js", ".tsx", ".jsx", ".py", ".go", ".rb", ".java"],
  maxFiles = 600,
  maxSize = 1_000_000
): string | null {
  const stack = [root];
  let scanned = 0;

  while (stack.length && scanned < maxFiles) {
    const current = stack.pop();
    if (!current) break;
    let entries: fs.Dirent[] = [];
    try {
      entries = fs.readdirSync(current, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (entry.isDirectory()) {
        if (IGNORE_DIRS.includes(entry.name)) continue;
        stack.push(path.join(current, entry.name));
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name);
        if (!extensions.includes(ext)) continue;
        const filePath = path.join(current, entry.name);
        try {
          const stats = fs.statSync(filePath);
          if (stats.size > maxSize) continue;
        } catch {
          continue;
        }
        scanned += 1;
        const content = readFileIfExists(filePath);
        if (!content) continue;
        if (patterns.some((pattern) => pattern.test(content))) {
          return path.relative(root, filePath);
        }
      }
    }
  }

  return null;
}

function hasFlakyTestConfig(ctx: RepoContext): string | null {
  const retryPatterns = [
    /retries\s*:/i,
    /retryTimes\(/i,
    /pytest-rerunfailures/i,
    /rerunfailures/i,
    /testRetry/i,
  ];
  const configNames = [
    "playwright.config.ts",
    "playwright.config.js",
    "playwright.config.mjs",
    "cypress.config.ts",
    "cypress.config.js",
    "cypress.config.mjs",
    "jest.config.js",
    "jest.config.cjs",
    "jest.config.mjs",
    "vitest.config.ts",
    "vitest.config.js",
    "pytest.ini",
    "tox.ini",
    "pyproject.toml",
    "package.json",
  ];

  const roots = [ctx.root, ...ctx.apps.map((app) => path.join(ctx.root, app.path))];
  for (const root of roots) {
    for (const name of configNames) {
      const filePath = path.join(root, name);
      if (!pathExists(filePath)) continue;
      if (fileContainsAny(filePath, retryPatterns)) {
        return path.relative(ctx.root, filePath);
      }
    }
  }

  return null;
}

function findFirstWorkflowMatch(files: string[], patterns: RegExp[]): string | null {
  for (const file of files) {
    if (fileContainsAny(file, patterns)) {
      return file;
    }
  }
  return null;
}

function runCommand(command: string, cwd: string, timeoutMs: number): { ok: boolean; code: number } {
  const result = spawnSync(command, {
    cwd,
    shell: true,
    stdio: "ignore",
    timeout: timeoutMs,
  });
  const ok = result.status === 0;
  return { ok, code: result.status ?? 1 };
}
