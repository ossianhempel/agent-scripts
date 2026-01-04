---
name: gh-cli
description: >
  Use when asked to work with GitHub via the gh CLI: issues, PRs, reviews,
  CI runs, releases, or repo metadata. Prefer gh over web for GitHub tasks.
---

# GitHub CLI (gh)

Use `gh` for GitHub interactions. Avoid web UI. No URLs in responses.

## Quick start

- Auth check: `gh auth status`
- Repo context: run in repo root, or pass `-R owner/repo`.

## Accounts

- We have multiple GitHub accounts; default assumption: ossianhempel (personal repos).
- Other accounts: Rebtech, H&M. If repo access fails, check auth and switch.

## Pull requests

- View: `gh pr view <number> --comments --files`
- List: `gh pr list` (add filters as needed)
- Diff: `gh pr diff <number>`
- Checks: `gh pr checks <number>`
- Review: `gh pr review <number> --approve|--comment` (ask before approve)
- Merge: `gh pr merge <number>` (explicit user go-ahead)

## Issues

- View: `gh issue view <number> --comments`
- List: `gh issue list`
- Create: `gh issue create` (only when requested)

## CI / Actions

- Runs: `gh run list`
- Logs: `gh run view <id> --log`
- Rerun: `gh run rerun <id>` (ask before rerun unless requested)

## Releases

- List: `gh release list`
- View: `gh release view <tag>`
- Create: `gh release create <tag> ...` (explicit user go-ahead)

## Output handling

- Prefer `--json` + `--jq` when parsing structured data.
- Quote exact error output lines in responses.
