# Agent Scripts - Agent Notes

## Purpose
This repo is a portable library of skills and slash commands that can be reused
across machines. Treat it as the source of truth for agent workflows.

## Cross-project Coding Patterns

- Add regression tests when discovering bugs through QA
- Avoid polyfills
- Don't reach for `useEffect` by default - many things you think require an effect (calculations, syncing derived state, resetting state on prop change) can often be handled more cleanly in render or via keys.
  - Before adding an effect, ask: "Is this really about synchronizing with something external?"
  - Move shared logic to event handlers, not effects
  - Be careful with effects that fetch / subscribe
  - Those are legitimate use cases, but you must manage cleanup (to avoid stale data or subscriptions) and watch for race conditions. Use React hooks like useSyncExternalStore when available instead of manual subscription logic.
  - Use key or controlled remounting to reset state
  - Abstract complex effect logic into custom hooks
  - Don't use type any
- Use CSS animations/effects instead of custom hooks whenever suitable

## How to add or change things
- Skills go in `skills/<name>/` and must include `SKILL.md`.
- Slash commands go in `slash-commands/<name>.md`.
- Keep names in kebab-case.
- Keep instructions concise and scoped to the skill/command.
- Update `README.md` when you add or remove items.

## Repository expectations
- Prefer small, modular changes over large refactors.
- Avoid unnecessary dependencies; this repo should stay lightweight.
- Preserve existing structure unless there is a clear reason to change it.
