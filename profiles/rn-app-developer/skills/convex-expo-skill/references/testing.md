# Testing + CI (Convex)

## When to use which

- `convex-test`: fast, in-process tests for queries/mutations/actions. Best for logic, validation, and pure data flow.
- Convex backend tests: hit a real deployment. Best for auth, permissions, data shape, and integration behavior.

## `convex-test` (unit-style)

- No network or deploy needed.
- Great for PR checks and quick feedback loops.
- Use when you can mock external dependencies.

Docs: https://docs.convex.dev/testing/convex-test

## Convex backend tests (integration-style)

- Runs against a real Convex deployment.
- Use for auth checks (`ctx.auth`), permissions, or HTTP actions.
- Slower; needs deployment config in CI.

Docs: https://docs.convex.dev/testing/convex-backend

## CI basics

- Run `npm run test` on PRs.
- Keep `convex/_generated/` committed so typechecks pass without `npx convex dev`.
- If backend tests require a deployment, set required env vars/secrets in CI.

### Minimal GitHub Actions example

```yaml
name: Tests

on: [pull_request, push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm test
```

Docs: https://docs.convex.dev/testing/ci
