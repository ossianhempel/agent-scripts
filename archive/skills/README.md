# Archived skills

These workflow skills were retired on 2026-06-09 in favor of Every's
[compound-engineering plugin](https://github.com/EveryInc/compound-engineering-plugin),
whose `ce-` namespaced loop (`ce-brainstorm` / `ce-plan` / `ce-compound` /
`ce-doc-review`) covers the same ground.

| Archived skill   | Replaced by      |
|------------------|------------------|
| `plan`           | `ce-plan`        |
| `compound`       | `ce-compound`    |
| `brainstorm`     | `ce-brainstorm`  |
| `review-agent-md`| `ce-doc-review`  |

Kept active because CE has no equivalent: `grill-me`, `grill-with-docs`,
`plan-inbox`.

These are moved out of `skills/` so `scripts/sync-agent-scripts.sh` no longer
links them into `~/.claude`, `~/.agents`, or `~/.gemini/antigravity-cli`. To
restore one, `git mv` it back into `skills/` and re-run the sync.
