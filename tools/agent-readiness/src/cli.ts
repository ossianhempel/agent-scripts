import fs from "fs";
import path from "path";
import { buildReport, resolveRoot } from "./engine";
import { detectRepoRoot } from "./git";
import { renderMarkdown } from "./render";
import { ensureDir } from "./utils";
import { getDefaultSchemaPath, validateReport } from "./validate";

const pkg = JSON.parse(
  fs.readFileSync(path.join(__dirname, "..", "package.json"), "utf8")
) as { version: string };

const args = process.argv.slice(2);
const hasExplicitCommand = Boolean(args[0] && !args[0].startsWith("-"));
const command = hasExplicitCommand ? args[0] : "report";
const options = parseArgs(hasExplicitCommand ? args.slice(1) : args);

if (options.help) {
  printHelp();
  process.exit(0);
}

if (options.version) {
  process.stdout.write(`${pkg.version}\n`);
  process.exit(0);
}

if (command !== "report" && command !== "validate") {
  process.stderr.write(`Unknown command: ${command}\n`);
  printHelp();
  process.exit(1);
}

const runner = command === "report" ? runReport : runValidate;

runner().catch((error) => {
  process.stderr.write(
    `agent-readiness failed: ${error instanceof Error ? error.message : String(error)}\n`
  );
  process.exit(1);
});

async function runReport(): Promise<void> {
  const rootInput = resolveRoot(options.root);
  const repoRoot = detectRepoRoot(rootInput);
  const report = await buildReport(repoRoot, pkg.version, {
    telemetryScan: options.telemetryScan ?? false,
    runIntegration: options.runIntegration ?? false,
    ciProvider: options.ciProvider,
    signals: options.signals,
  });

  if (options.out) {
    const outPath = path.resolve(repoRoot, options.out);
    ensureDir(path.dirname(outPath));
    fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  }

  if (options.format === "json") {
    const json = options.pretty ? JSON.stringify(report, null, 2) : JSON.stringify(report);
    process.stdout.write(`${json}\n`);
  } else {
    process.stdout.write(`${renderMarkdown(report)}\n`);
  }
}

async function runValidate(): Promise<void> {
  const rootInput = resolveRoot(options.root);
  const repoRoot = detectRepoRoot(rootInput);
  const inputPath = options.input || ".agent-readiness/latest.json";
  const resolvedInput = path.resolve(repoRoot, inputPath);
  const raw = fs.readFileSync(resolvedInput, "utf8");
  const report = JSON.parse(raw) as unknown;
  const schemaPath = getDefaultSchemaPath();
  const result = validateReport(report, schemaPath);
  if (result.valid) {
    process.stdout.write("Report is valid.\n");
    return;
  }
  process.stderr.write("Report failed validation:\n");
  for (const error of result.errors) {
    process.stderr.write(`- ${error}\n`);
  }
  process.exit(1);
}

function parseArgs(rest: string[]): {
  format: "json" | "markdown";
  out?: string;
  root?: string;
  input?: string;
  pretty?: boolean;
  help?: boolean;
  version?: boolean;
  telemetryScan?: boolean;
  runIntegration?: boolean;
  ciProvider?: "github";
  signals?: "github";
} {
  const result: {
    format: "json" | "markdown";
    out?: string;
    root?: string;
    input?: string;
    pretty?: boolean;
    help?: boolean;
    version?: boolean;
    telemetryScan?: boolean;
    runIntegration?: boolean;
    ciProvider?: "github";
    signals?: "github";
  } = {
    format: "markdown",
  };

  for (let i = 0; i < rest.length; i += 1) {
    const arg = rest[i];
    if (arg === "--format") {
      const value = rest[i + 1];
      if (value === "json" || value === "markdown") {
        result.format = value;
        i += 1;
      }
      continue;
    }
    if (arg.startsWith("--format=")) {
      const value = arg.split("=")[1];
      if (value === "json" || value === "markdown") {
        result.format = value;
      }
      continue;
    }
    if (arg === "--out") {
      result.out = rest[i + 1];
      i += 1;
      continue;
    }
    if (arg.startsWith("--out=")) {
      result.out = arg.split("=")[1];
      continue;
    }
    if (arg === "--root") {
      result.root = rest[i + 1];
      i += 1;
      continue;
    }
    if (arg.startsWith("--root=")) {
      result.root = arg.split("=")[1];
      continue;
    }
    if (arg === "--in" || arg === "--input") {
      result.input = rest[i + 1];
      i += 1;
      continue;
    }
    if (arg.startsWith("--in=") || arg.startsWith("--input=")) {
      result.input = arg.split("=")[1];
      continue;
    }
    if (arg === "--pretty") {
      result.pretty = true;
      continue;
    }
    if (arg === "--telemetry-scan") {
      result.telemetryScan = true;
      continue;
    }
    if (arg === "--run-integration") {
      result.runIntegration = true;
      continue;
    }
    if (arg === "--ci-provider") {
      const value = rest[i + 1];
      if (value === "github") {
        result.ciProvider = value;
      }
      i += 1;
      continue;
    }
    if (arg.startsWith("--ci-provider=")) {
      const value = arg.split("=")[1];
      if (value === "github") {
        result.ciProvider = value;
      }
      continue;
    }
    if (arg === "--signals") {
      const value = rest[i + 1];
      if (value === "github") {
        result.signals = value;
      }
      i += 1;
      continue;
    }
    if (arg.startsWith("--signals=")) {
      const value = arg.split("=")[1];
      if (value === "github") {
        result.signals = value;
      }
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      result.help = true;
      continue;
    }
    if (arg === "--version" || arg === "-v") {
      result.version = true;
    }
  }

  return result;
}

function printHelp(): void {
  const message = `Agent Readiness Framework\n\nUsage:\n  agent-readiness report [--format json|markdown] [--out path] [--root path] [--pretty]\n  agent-readiness validate [--in path] [--root path]\n\nOptions:\n  --format           Output format (default: markdown)\n  --out              Write JSON report to a file (relative to repo root)\n  --in               Input JSON report path (default: .agent-readiness/latest.json)\n  --root             Start path for repo discovery (default: cwd)\n  --pretty           Pretty-print JSON output\n  --telemetry-scan   Enable deeper tracing/metrics code scanning\n  --run-integration  Execute integration test commands (short timeout)\n  --ci-provider      CI provider for optional checks (github)\n  --signals          Enable signals-based checks (github)\n  --version          Print CLI version\n  --help             Show help\n`;
  process.stdout.write(message);
}
