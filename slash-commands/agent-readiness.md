# Agent Readiness

You are given the following context:
$ARGUMENTS

## Instructions

Generate an Agent Readiness report for the current repo.

Steps:
- Run `scripts/readiness.sh .`
- Summarize the achieved level and progress toward the next level (80% gate)
- List the top 3 action items from the report
- If output format is specified in `$ARGUMENTS`, pass it via `FORMAT=...`
