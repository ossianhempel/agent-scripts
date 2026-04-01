# Skimmify

You are given the following context:
$ARGUMENTS

## Instructions

Make the added code on the current branch beautiful by applying the rules below.

Steps:
- Run `git diff main...HEAD` (or the appropriate base branch) to identify all added/changed code.
- Review every change against the rules below.
- Rewrite code that violates any rule. Remove changes that aren't strictly required.
- Do not touch code outside the branch diff.

## Rules

1. **Skimmable code** — write extremely simple code that you can understand at a glance.
2. **Minimize states** — reduce number of arguments, remove or narrow any state.
3. **Discriminated unions** — use them to reduce the number of states code can be in.
4. **Exhaustive type handling** — exhaustively handle objects with multiple types, fail on unknown type.
5. **No defensive code** — assume values are what their types say they are.
6. **Asserts over optionals** — use asserts when loading data. Be highly opinionated about parameters; don't let things be optional if not strictly required.
7. **Remove unnecessary changes** — strip anything not strictly required for the feature/fix.
8. **Fewer lines** — bias for fewer lines of code.
9. **No clever code** — no complex or clever constructs.
10. **Fewer functions** — don't break out into too many functions; that's hard to read.
11. **Early returns** — use early returns liberally.
12. **Asserts over try/catch** — use asserts instead of try-catches or default values when you expect something to exist.
13. **Minimal arguments** — never pass overrides except when strictly necessary; keep argument count low.
14. **No false optionals** — don't make arguments optional if they are actually required.
