#!/usr/bin/env node

const { existsSync, readdirSync, readFileSync, statSync } = require("node:fs");
const { homedir } = require("node:os");
const { basename, join, relative, resolve } = require("node:path");

const PLAN_CLOSED = new Set(["completed", "superseded", "abandoned"]);
const BRAINSTORM_CLOSED = new Set(["planned", "superseded", "dropped"]);

function parseArgs(argv) {
  const args = {
    brainstorms: false,
    global: false,
    json: false,
    project: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--brainstorms") {
      args.brainstorms = true;
    } else if (arg === "--global") {
      args.global = true;
    } else if (arg === "--json") {
      args.json = true;
    } else if (arg === "--project") {
      index += 1;
      if (!argv[index]) usage("--project requires a path");
      args.project = resolve(argv[index]);
    } else if (arg === "--help" || arg === "-h") {
      usage();
    } else {
      usage(`Unknown argument: ${arg}`);
    }
  }

  if (args.global && args.project) {
    usage("Use either --global or --project, not both");
  }

  return args;
}

function usage(error) {
  if (error) console.error(error);
  console.error(`Usage: plan-inbox [--project PATH | --global] [--brainstorms] [--json]

Find active docs/plans entries, optionally with unresolved docs/brainstorms entries.`);
  process.exit(error ? 2 : 0);
}

function projectRoots(args) {
  if (args.project) return [args.project];
  if (!args.global) return [process.cwd()];

  const roots = [join(homedir(), "Developer"), join(homedir(), "repos")];
  const projects = [];

  for (const root of roots) {
    if (!existsSync(root)) continue;
    for (const entry of readdirSync(root)) {
      const project = join(root, entry);
      if (!isDirectory(project)) continue;
      if (existsSync(join(project, ".git")) || existsSync(join(project, "docs"))) {
        projects.push(project);
      }
    }
  }

  return projects.sort();
}

function isDirectory(path) {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

function markdownFiles(dir) {
  if (!isDirectory(dir)) return [];
  return readdirSync(dir)
    .filter((entry) => entry.endsWith(".md"))
    .map((entry) => join(dir, entry))
    .sort();
}

function parseArtifact(project, file, kind) {
  const text = readFileSync(file, "utf8");
  const relPath = relative(project, file);
  const title =
    text
      .split(/\r?\n/)
      .find((line) => line.startsWith("# "))
      ?.replace(/^#\s+/, "")
      .trim() || basename(file);
  const status = parseStatus(text) || "Unknown";
  const filename = basename(file);
  const meta = parsePlanFilename(filename);

  return {
    kind,
    project: basename(project),
    projectPath: project,
    path: relPath,
    title,
    status,
    date: meta.date,
    type: meta.type,
    closed: kind === "plan" ? isClosed(status, PLAN_CLOSED) : isClosed(status, BRAINSTORM_CLOSED),
    planRefs: parsePlanRefs(text),
  };
}

function parseStatus(text) {
  const match = text.match(/^\s*>?\s*\*\*Status:\*\*\s*([^·\n\r]+)/im);
  if (!match) return null;
  return match[1].trim();
}

function parsePlanRefs(text) {
  const refs = [];
  const regex = /docs\/plans\/[^\s)`]+\.md/g;
  let match;
  while ((match = regex.exec(text)) !== null) {
    refs.push(match[0]);
  }
  return [...new Set(refs)];
}

function parsePlanFilename(filename) {
  const match = filename.match(/^(\d{4}-\d{2}-\d{2})-\d{3}-([a-z]+)-.+-plan\.md$/);
  return {
    date: match?.[1] || "",
    type: match?.[2] || "",
  };
}

function isClosed(status, closedStatuses) {
  return closedStatuses.has(status.trim().toLowerCase());
}

function scanProject(project) {
  const plans = markdownFiles(join(project, "docs", "plans")).map((file) =>
    parseArtifact(project, file, "plan")
  );
  const brainstorms = markdownFiles(join(project, "docs", "brainstorms")).map((file) =>
    parseArtifact(project, file, "brainstorm")
  );

  const planPaths = new Set(plans.map((plan) => plan.path));
  const planTexts = plans.map((plan) => readFileSync(join(project, plan.path), "utf8"));

  for (const brainstorm of brainstorms) {
    const referencedInPlan = planTexts.some((text) => text.includes(brainstorm.path));
    const referencesExistingPlan = brainstorm.planRefs.some((ref) => planPaths.has(ref));
    brainstorm.linkedToPlan = referencedInPlan || referencesExistingPlan;
  }

  return { project, plans, brainstorms };
}

function activeBrainstorms(brainstorms) {
  return brainstorms.filter((brainstorm) => !brainstorm.closed && !brainstorm.linkedToPlan);
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const scanned = projectRoots(args).map(scanProject);

  const result = {
    plans: scanned.flatMap((project) => project.plans.filter((plan) => !plan.closed)),
    brainstorms: args.brainstorms
      ? scanned.flatMap((project) => activeBrainstorms(project.brainstorms))
      : [],
  };

  if (args.json) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  printText(result, args);
}

function printText(result, args) {
  console.log("Plan Inbox");
  console.log("");

  if (result.plans.length === 0) {
    console.log("Open plans: none");
  } else {
    console.log(`Open plans: ${result.plans.length}`);
    for (const plan of result.plans) {
      const details = [plan.status, plan.date, plan.type].filter(Boolean).join(" | ");
      console.log(`- ${plan.project}: ${plan.title}`);
      console.log(`  ${details}`);
      console.log(`  ${plan.path}`);
    }
  }

  if (!args.brainstorms) return;

  console.log("");
  if (result.brainstorms.length === 0) {
    console.log("Unplanned brainstorms: none");
  } else {
    console.log(`Unplanned brainstorms: ${result.brainstorms.length}`);
    for (const brainstorm of result.brainstorms) {
      console.log(`- ${brainstorm.project}: ${brainstorm.title}`);
      console.log(`  ${brainstorm.status}`);
      console.log(`  ${brainstorm.path}`);
    }
  }
}

main();
