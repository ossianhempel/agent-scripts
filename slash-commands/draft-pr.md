# Draft PR

You are given the following context:
$ARGUMENTS

## Instructions

Create a **draft** GitHub PR using the GitHub CLI.

Requirements:
- Parse `$ARGUMENTS` to determine the **base** and **head** branches.
  - Example: `develop -> main` or `develop main`
  - If unclear, ask a brief clarification before proceeding.
- Also parse any **optional instructions** from `$ARGUMENTS` (e.g. title hints, what to emphasize, testing notes).
- Inspect the diff between the branches to craft a concise, accurate title and body.
- Use `gh pr create --draft --base <base> --head <head> --title "<title>" --body "<body>"`
- Keep the title in Conventional Commit style if reasonable (e.g. `chore(release): develop -> main (YYYY-MM-DD)`).
- The body should include:
  - `## Summary` with 3-6 bullets of the most important changes.
  - `## Testing` with the actual tests run or `not run (draft PR)`.

Guardrails:
- Do not open a browser.
- Do not modify files.
- Ask questions if the branches or intent are ambiguous.
