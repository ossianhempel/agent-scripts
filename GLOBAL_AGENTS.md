# Global Agent Instructions

These are the shared, cross‑repo instructions used by agent runtimes.

## Cross-project Coding Patterns

- Add regression tests when discovering bugs through QA.
- Avoid polyfills unless explicitly required by the target environment.
- Don't reach for `useEffect` by default; many things you think require an effect
  can be handled in render or via keys.
  - Before adding an effect, ask: "Is this really about synchronizing with something external?"
  - Move shared logic to event handlers, not effects.
  - Be careful with effects that fetch / subscribe; manage cleanup and race conditions.
  - Use key or controlled remounting to reset state.
  - Abstract complex effect logic into custom hooks.
  - Don't use `any` in TypeScript.
- Use CSS animations/effects instead of custom hooks whenever suitable.
