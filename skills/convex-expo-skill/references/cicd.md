# CI/CD for Convex + Expo

## Table of contents

- [Goals](#goals)
- [Convex: recommended approach](#convex-recommended-approach)
- [Minimum CI (tests only)](#minimum-ci-tests-only)
- [Deploying Convex from GitHub Actions](#deploying-convex-from-github-actions)
- [Required secrets](#required-secrets)
- [Production deploy on main](#production-deploy-on-main)
- [Expo (EAS) in CI](#expo-eas-in-ci)
- [A) App Store builds (EAS Build)](#a-app-store-builds-eas-build)
- [B) OTA updates (EAS Update)](#b-ota-updates-eas-update)
- [After deploying Convex](#after-deploying-convex)
- [Environment strategy](#environment-strategy)
- [Recommended default](#recommended-default)
- [Release checklist](#release-checklist)

This guide focuses on practical CI/CD patterns.

## Goals

- On every PR: run lint/typecheck/tests
- On merge to main: deploy Convex backend
- Optionally: trigger EAS build or EAS update for the Expo app

## Convex: recommended approach

- Developers use personal dev deployments with `npx convex dev`.
- CI uses `npx convex deploy` with a Deploy Key stored in the CI secret store.
- Treat schema changes and function changes as backwards compatible for older clients.

## Minimum CI (tests only)

Convex docs show a simple GitHub Actions workflow that runs `npm run test`:

```yaml
name: Run Tests

on: [pull_request, push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run test
```

Extend this with `npm run lint` and `npm run typecheck` if you have them.

## Deploying Convex from GitHub Actions

### Required secrets

Add these in your GitHub repo secrets:

- `CONVEX_DEPLOY_KEY`: a Convex deploy key for the target deployment (production, or a staging project)

### Production deploy on main

```yaml
name: Deploy Convex (prod)

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm test
      - name: Deploy Convex
        run: npx convex deploy
        env:
          CONVEX_DEPLOY_KEY: ${{ secrets.CONVEX_DEPLOY_KEY }}
```

Notes:
- `npx convex deploy` typechecks functions, regenerates code, bundles, and pushes functions/schema/indexes.
- For preview deployments, Convex can create a new deployment per branch when using a Preview Deploy Key.

## Expo (EAS) in CI

There are two common deployment styles:

### A) App Store builds (EAS Build)

- Use this for new binary releases.
- Configure `EXPO_PUBLIC_CONVEX_URL` in your EAS environment variables (preview vs production).

High-level workflow:
1. Deploy Convex
2. Run EAS Build for iOS/Android

You will need an Expo token in CI (for example `EXPO_TOKEN`).

### B) OTA updates (EAS Update)

- Use this for JS updates without shipping a new binary.
- Make sure the update uses the right EAS environment (preview vs production) so `EXPO_PUBLIC_CONVEX_URL` matches.

Example (pseudo):

```bash
# After deploying Convex
npx eas update --branch production --environment production --message "Deploy" 
```

Adjust branch/environment to match your release process.

## Environment strategy

### Recommended default

- Convex production deployment: used by store builds and production OTA updates.
- Convex staging project (separate project): used by preview builds, internal testers, and PR validation.

This is often easier than trying to make ephemeral Convex preview deployments work with mobile preview builds.

## Release checklist

- Backend schema changes are compatible with current production data.
- Backend functions remain compatible with older clients.
- `EXPO_PUBLIC_CONVEX_URL` points to the intended deployment.
- Convex deploy completed successfully.
- Mobile build/update completed and smoke tested.
