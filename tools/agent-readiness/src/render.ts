import { CriterionResult, ReadinessReport } from "./types";

export function renderMarkdown(report: ReadinessReport): string {
  const lines: string[] = [];
  const achieved = report.levels.achievedLevel;
  const nextLevel = report.levels.nextLevel;
  const currentProgress = report.levels.progress[String(achieved)] || {
    numerator: 0,
    denominator: 0,
    completion: 0,
  };
  const nextProgress = nextLevel
    ? report.levels.progress[String(nextLevel)]
    : null;

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
      )} / ${Math.round(report.levels.gate * 100)}% required)`
    );
  } else {
    lines.push("- Next gate: none (all levels achieved)");
  }

  const appList = Object.keys(report.apps);
  lines.push(`- Apps discovered: ${appList.length ? appList.join(", ") : "none"}`);

  lines.push("");
  lines.push("## Criteria");

  const grouped = groupByLevel(report.report);
  for (const level of Object.keys(grouped).sort((a, b) => Number(a) - Number(b))) {
    const results = grouped[level];
    const progress = report.levels.progress[level];
    lines.push("");
    lines.push(
      `### Level ${level} (${progress.numerator}/${progress.denominator} = ${formatPercent(
        progress.completion
      )})`
    );
    for (const result of results) {
      const status = result.numerator === result.denominator ? "PASS" : "FAIL";
      lines.push(
        `- [${status}] ${result.id} (${result.numerator}/${result.denominator}): ${result.rationale}`
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
