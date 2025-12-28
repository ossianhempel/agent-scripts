export type CriterionScope = "repo" | "app";
export type CriterionLevel = 1 | 2 | 3 | 4 | 5;

export interface AppInfo {
  id: string;
  path: string;
  description?: string;
  type?: string;
}

export interface ReportAppInfo {
  path: string;
  description?: string;
  type?: string;
}

export interface RepoContext {
  root: string;
  apps: AppInfo[];
  repoUrl: string | null;
  git: GitMetadata;
}

export interface GitMetadata {
  commitHash: string | null;
  branch: string | null;
  hasLocalChanges: boolean | null;
  hasNonRemoteCommits: boolean | null;
}

export interface CriterionResult {
  id: string;
  title: string;
  level: CriterionLevel;
  pillar: string;
  scope: CriterionScope;
  numerator: number;
  denominator: number;
  rationale: string;
  failingApps?: string[];
}

export interface LevelProgress {
  numerator: number;
  denominator: number;
  completion: number;
}

export interface LevelSummary {
  achievedLevel: number;
  nextLevel: number | null;
  gate: number;
  progress: Record<string, LevelProgress>;
}

export interface ActionItem {
  criterionId: string;
  title: string;
  details: string;
}

export interface ReadinessReport {
  schemaVersion: string;
  toolVersion: string;
  reportId: string;
  createdAt: number;
  repoRoot: string;
  repoUrl: string | null;
  commitHash: string | null;
  branch: string | null;
  hasLocalChanges: boolean | null;
  hasNonRemoteCommits: boolean | null;
  apps: Record<string, ReportAppInfo>;
  report: Record<string, CriterionResult>;
  levels: LevelSummary;
  actionItems?: ActionItem[];
}

export interface CriterionDefinition {
  id: string;
  title: string;
  level: CriterionLevel;
  pillar: string;
  scope: CriterionScope;
  evaluateRepo?: (ctx: RepoContext) => Promise<CriterionCheck> | CriterionCheck;
  evaluateApp?: (ctx: RepoContext, app: AppInfo) => Promise<CriterionCheck> | CriterionCheck;
  recommendation: (ctx: RepoContext, failingApps: string[]) => string;
}

export interface CriterionCheck {
  passed: boolean;
  rationale: string;
}
