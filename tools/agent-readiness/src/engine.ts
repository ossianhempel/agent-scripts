import crypto from "crypto";
import path from "path";
import { CRITERIA } from "./criteria";
import { discoverApps } from "./discovery";
import { getGitMetadata, getRepoUrl } from "./git";
import {
  ActionItem,
  CriterionDefinition,
  CriterionResult,
  LevelProgress,
  LevelSummary,
  ReadinessReport,
  RepoContext,
} from "./types";

const SCHEMA_VERSION = "0.1.0";
const GATE = 0.8;

export async function buildReport(root: string, toolVersion: string): Promise<ReadinessReport> {
  const apps = discoverApps(root);
  const repoUrl = getRepoUrl(root);
  const git = getGitMetadata(root);

  const ctx: RepoContext = {
    root,
    apps,
    repoUrl,
    git,
  };

  const results = await evaluateCriteria(ctx, CRITERIA);
  const levels = scoreLevels(results);
  const actionItems = getActionItems(ctx, results, levels);

  const appsMap = Object.fromEntries(
    apps.map((app) => [
      app.id,
      {
        path: app.path,
        ...(app.description ? { description: app.description } : {}),
        ...(app.type ? { type: app.type } : {}),
      },
    ])
  );

  return {
    schemaVersion: SCHEMA_VERSION,
    toolVersion,
    reportId: crypto.randomUUID(),
    createdAt: Date.now(),
    repoRoot: root,
    repoUrl,
    commitHash: git.commitHash,
    branch: git.branch,
    hasLocalChanges: git.hasLocalChanges,
    hasNonRemoteCommits: git.hasNonRemoteCommits,
    apps: appsMap,
    report: results,
    levels,
    actionItems,
  };
}

async function evaluateCriteria(
  ctx: RepoContext,
  criteria: CriterionDefinition[]
): Promise<Record<string, CriterionResult>> {
  const results: Record<string, CriterionResult> = {};

  for (const criterion of criteria) {
    if (criterion.scope === "repo") {
      const check = criterion.evaluateRepo
        ? await criterion.evaluateRepo(ctx)
        : { passed: false, rationale: "No evaluator provided." };
      results[criterion.id] = {
        id: criterion.id,
        title: criterion.title,
        level: criterion.level,
        pillar: criterion.pillar,
        scope: criterion.scope,
        numerator: check.passed ? 1 : 0,
        denominator: 1,
        rationale: check.rationale,
      };
      continue;
    }

    const failingApps: string[] = [];
    let numerator = 0;
    for (const app of ctx.apps) {
      const check = criterion.evaluateApp
        ? await criterion.evaluateApp(ctx, app)
        : { passed: false, rationale: "No evaluator provided." };
      if (check.passed) {
        numerator += 1;
      } else {
        failingApps.push(app.path);
      }
    }

    const denominator = Math.max(ctx.apps.length, 1);
    let rationale = "";
    if (failingApps.length === 0) {
      rationale = "All apps satisfied this criterion.";
    } else if (failingApps.length === ctx.apps.length) {
      rationale = "No apps satisfied this criterion.";
    } else {
      rationale = `Missing for: ${failingApps.join(", ")}.`;
    }

    results[criterion.id] = {
      id: criterion.id,
      title: criterion.title,
      level: criterion.level,
      pillar: criterion.pillar,
      scope: criterion.scope,
      numerator,
      denominator,
      rationale,
      failingApps: failingApps.length ? failingApps : undefined,
    };
  }

  return results;
}

function scoreLevels(results: Record<string, CriterionResult>): LevelSummary {
  const progress: Record<string, LevelProgress> = {};
  let achievedLevel = 0;

  for (let level = 1; level <= 5; level += 1) {
    const levelResults = Object.values(results).filter(
      (item): item is CriterionResult => Boolean(item) && item.level === level
    );
    const numerator = levelResults.reduce((sum, item) => sum + item.numerator, 0);
    const denominator = levelResults.reduce((sum, item) => sum + item.denominator, 0);
    const completion = denominator > 0 ? numerator / denominator : 1;
    progress[String(level)] = { numerator, denominator, completion };
  }

  for (let level = 1; level <= 5; level += 1) {
    const completion = progress[String(level)]?.completion ?? 0;
    if (completion >= GATE) {
      achievedLevel = level;
    } else {
      break;
    }
  }

  const nextLevel = achievedLevel >= 5 ? null : achievedLevel + 1;

  return {
    achievedLevel,
    nextLevel,
    gate: GATE,
    progress,
  };
}

function getActionItems(
  ctx: RepoContext,
  results: Record<string, CriterionResult>,
  levels: LevelSummary
): ActionItem[] {
  if (!levels.nextLevel) return [];

  const targetLevel = levels.nextLevel;
  const targetCriteria = CRITERIA.filter((criterion) => criterion.level === targetLevel);

  type MissingEntry = {
    criterion: CriterionDefinition;
    missingCount: number;
    result: CriterionResult;
  };

  const missing = targetCriteria
    .map((criterion): MissingEntry | null => {
      const result = results[criterion.id];
      if (!result) return null;
      const missingCount = result.denominator - result.numerator;
      return {
        criterion,
        missingCount,
        result,
      };
    })
    .filter((entry): entry is MissingEntry => {
      if (!entry) return false;
      return entry.missingCount > 0;
    })
    .sort((a, b) => b.missingCount - a.missingCount);

  return missing.slice(0, 3).map((entry) => {
    const failingApps = entry.result.failingApps ?? [];
    return {
      criterionId: entry.criterion.id,
      title: entry.criterion.title,
      details: entry.criterion.recommendation(ctx, failingApps),
    };
  });
}

export function resolveRoot(rootFlag?: string): string {
  if (!rootFlag) return path.resolve(process.cwd());
  return path.resolve(process.cwd(), rootFlag);
}
