import crypto from "crypto";
import path from "path";
import { CRITERIA } from "./criteria";
import { discoverApps } from "./discovery";
import { getGitMetadata, getRepoUrl } from "./git";
import {
  ActionItem,
  CriterionCheck,
  CriterionDefinition,
  CriterionResult,
  CriteriaMeta,
  LevelDetail,
  LevelSummary,
  ReadinessReport,
  RepoContext,
} from "./types";

const SCHEMA_VERSION = "0.2.0";
const GATE = 0.8;

export async function buildReport(
  root: string,
  toolVersion: string,
  options?: RepoContext["options"]
): Promise<ReadinessReport> {
  const apps = discoverApps(root);
  const repoUrl = getRepoUrl(root);
  const git = getGitMetadata(root);

  const ctx: RepoContext = {
    root,
    apps,
    repoUrl,
    git,
    options: {
      telemetryScan: options?.telemetryScan ?? false,
      runIntegration: options?.runIntegration ?? false,
      ciProvider: options?.ciProvider,
      signals: options?.signals,
    },
  };

  const { results, criteriaMeta } = await evaluateCriteria(ctx, CRITERIA);
  const levelSummary = scoreLevels(results);
  const actionItems = getActionItems(ctx, results, levelSummary);

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

  const signals =
    options?.ciProvider || options?.signals
      ? {
          ...(options?.ciProvider ? { ciProvider: options.ciProvider } : {}),
          ...(options?.signals ? { deploySource: options.signals } : {}),
          notes: "Signals derived from local heuristics; API signals not enabled.",
        }
      : undefined;

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
    criteriaMeta,
    levels: levelSummary.levels,
    levelSummary,
    ...(signals ? { signals } : {}),
    actionItems,
  };
}

async function evaluateCriteria(
  ctx: RepoContext,
  criteria: CriterionDefinition[]
): Promise<{ results: Record<string, CriterionResult>; criteriaMeta: Record<string, CriteriaMeta> }> {
  const results: Record<string, CriterionResult> = {};
  const criteriaMeta: Record<string, CriteriaMeta> = {};

  for (const criterion of criteria) {
    if (criterion.scope === "repo") {
      const check: CriterionCheck = criterion.evaluateRepo
        ? await criterion.evaluateRepo(ctx)
        : { status: "not_evaluated", rationale: "No evaluator provided." };
      const isScored = check.status === "pass" || check.status === "fail";
      results[criterion.id] = {
        id: criterion.id,
        title: criterion.title,
        level: criterion.level,
        pillar: criterion.pillar,
        scope: criterion.scope,
        numerator: check.status === "pass" ? 1 : 0,
        denominator: isScored ? 1 : 0,
        rationale: check.rationale,
        ...(check.evidence ? { evidence: check.evidence } : {}),
      };
      criteriaMeta[criterion.id] = {
        level: criterion.level,
        scope: criterion.scope,
        pillar: criterion.pillar,
        status: check.status,
      };
      continue;
    }

    if (ctx.apps.length === 0) {
      results[criterion.id] = {
        id: criterion.id,
        title: criterion.title,
        level: criterion.level,
        pillar: criterion.pillar,
        scope: criterion.scope,
        numerator: 0,
        denominator: 0,
        rationale: "No apps discovered.",
      };
      criteriaMeta[criterion.id] = {
        level: criterion.level,
        scope: criterion.scope,
        pillar: criterion.pillar,
        status: "not_applicable",
      };
      continue;
    }

    const failingApps: string[] = [];
    let numerator = 0;
    let denominator = 0;
    let sawNotEvaluated = false;
    const evidence: string[] = [];
    for (const app of ctx.apps) {
      const criterionCheck: CriterionCheck = criterion.evaluateApp
        ? await criterion.evaluateApp(ctx, app)
        : { status: "not_evaluated", rationale: "No evaluator provided." };
      if (criterionCheck.status === "pass") {
        numerator += 1;
        denominator += 1;
      } else if (criterionCheck.status === "fail") {
        denominator += 1;
        failingApps.push(app.path);
      } else if (criterionCheck.status === "not_evaluated") {
        sawNotEvaluated = true;
      }
      if (criterionCheck.evidence) {
        evidence.push(...criterionCheck.evidence);
      }
    }

    let rationale = "";
    if (denominator === 0) {
      rationale = sawNotEvaluated
        ? "Not evaluated for apps (missing required signals)."
        : "Not applicable for discovered apps.";
    } else if (failingApps.length === 0) {
      rationale = "All apps satisfied this criterion.";
    } else if (failingApps.length === ctx.apps.length) {
      rationale = "No apps satisfied this criterion.";
    } else {
      rationale = `Missing for: ${failingApps.join(", ")}.`;
    }

    let status: CriteriaMeta["status"];
    if (denominator === 0) {
      status = sawNotEvaluated ? "not_evaluated" : "not_applicable";
    } else {
      status = numerator === denominator ? "pass" : "fail";
    }

    const uniqueEvidence = Array.from(new Set(evidence));
    results[criterion.id] = {
      id: criterion.id,
      title: criterion.title,
      level: criterion.level,
      pillar: criterion.pillar,
      scope: criterion.scope,
      numerator,
      denominator,
      rationale,
      ...(uniqueEvidence.length ? { evidence: uniqueEvidence } : {}),
      failingApps: failingApps.length ? failingApps : undefined,
    };
    criteriaMeta[criterion.id] = {
      level: criterion.level,
      scope: criterion.scope,
      pillar: criterion.pillar,
      status,
    };
  }

  return { results, criteriaMeta };
}

function scoreLevels(results: Record<string, CriterionResult>): LevelSummary {
  const levels: Record<string, LevelDetail> = {};
  let achievedLevel = 0;

  for (let level = 1; level <= 5; level += 1) {
    const levelResults = Object.values(results).filter(
      (item): item is CriterionResult => Boolean(item) && item.level === level
    );
    const passCount = levelResults.reduce((sum, item) => sum + item.numerator, 0);
    const evaluatedCount = levelResults.reduce((sum, item) => sum + item.denominator, 0);
    const completion = evaluatedCount > 0 ? passCount / evaluatedCount : 0;
    const unlocked = evaluatedCount > 0 && completion >= GATE;
    levels[String(level)] = {
      completion,
      evaluatedCount,
      passCount,
      unlocked,
    };
  }

  for (let level = 1; level <= 5; level += 1) {
    const unlocked = levels[String(level)]?.unlocked ?? false;
    if (unlocked) {
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
    levels,
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
      if (result.denominator === 0) return null;
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
