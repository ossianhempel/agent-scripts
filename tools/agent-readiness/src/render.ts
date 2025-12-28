import { CriterionResult, CriterionStatus, ReadinessReport } from "./types";

export function renderMarkdown(report: ReadinessReport): string {
  const lines: string[] = [];
  const achieved = report.levelSummary.achievedLevel;
  const nextLevel = report.levelSummary.nextLevel;
  const currentProgress = report.levels[String(achieved)] || {
    passCount: 0,
    evaluatedCount: 0,
    completion: 0,
    unlocked: false,
  };
  const nextProgress = nextLevel ? report.levels[String(nextLevel)] : null;

  lines.push("# Agent Readiness Report");
  lines.push("");
  lines.push(`- Repo root: ${report.repoRoot}`);
  if (report.repoUrl) lines.push(`- Repo URL: ${report.repoUrl}`);
  lines.push(
    `- Level achieved: ${achieved} (${formatPercent(currentProgress.completion)} complete)`
  );
  if (nextLevel && nextProgress) {
    lines.push(
      `- Next gate: Level ${nextLevel} (${formatPercent(
        nextProgress.completion
      )} / ${Math.round(report.levelSummary.gate * 100)}% required)`
    );
  } else {
    lines.push("- Next gate: none (all levels achieved)");
  }

  const appList = Object.keys(report.apps);
  lines.push(`- Apps discovered: ${appList.length ? appList.join(", ") : "none"}`);

  lines.push("");
  lines.push("## Criteria");

  const grouped = groupByLevel(report.report);
  const maxVisibleLevel = Math.min(achieved + 1, 5);
  for (const level of Object.keys(grouped).sort((a, b) => Number(a) - Number(b))) {
    if (Number(level) > maxVisibleLevel) continue;
    const results = grouped[level];
    const progress = report.levels[level];
    const progressLabel =
      progress.evaluatedCount === 0
        ? "not evaluated"
        : `${progress.passCount}/${progress.evaluatedCount} = ${formatPercent(
            progress.completion
          )}`;
    lines.push("");
    lines.push(`### Level ${level} (${progressLabel})`);
    for (const result of results) {
      const meta = report.criteriaMeta[result.id];
      const status = formatStatus(meta?.status);
      const evidence =
        result.evidence && result.evidence.length ? ` [${result.evidence.join(", ")}]` : "";
      lines.push(
        `- [${status}] ${result.id} (${result.numerator}/${result.denominator}): ${result.rationale}${evidence}`
      );
    }
  }

  if (report.actionItems && report.actionItems.length) {
    lines.push("");
    lines.push("## Top action items");
    for (const item of report.actionItems) {
      lines.push(`- ${item.title}: ${item.details}`);
    }
  }

  return lines.join("\n");
}

function groupByLevel(report: Record<string, CriterionResult>): Record<string, CriterionResult[]> {
  const grouped: Record<string, CriterionResult[]> = {};
  for (const result of Object.values(report)) {
    const level = String(result.level);
    if (!grouped[level]) grouped[level] = [];
    grouped[level].push(result);
  }
  return grouped;
}

function formatPercent(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function formatStatus(status?: CriterionStatus): string {
  if (!status) return "UNKNOWN";
  switch (status) {
    case "pass":
      return "PASS";
    case "fail":
      return "FAIL";
    case "not_applicable":
      return "N/A";
    case "not_evaluated":
      return "NOT EVALUATED";
    default:
      return "UNKNOWN";
  }
}
