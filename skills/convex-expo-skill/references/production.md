# Production (Convex)

## Deployments and environments

- Keep a stable production deployment for released apps.
- Use separate staging (or preview) deployments for internal testing.
- Treat schema and function changes as backwards compatible for older clients.

## Staging vs preview deployments

Two common patterns:

1) Separate staging project (recommended for Expo)
   - Stable staging deployment for QA, internal builds, and PR validation.
   - Easier for mobile preview builds and OTA updates.
   - Fewer surprises with environment variables.

2) Preview deployments per branch
   - One deployment per branch for web-style previews.
   - Great for short-lived experiments, but mobile previews are harder to wire.

Pick the simplest option that matches your release process and client platforms.

## Release sanity checks

- `EXPO_PUBLIC_CONVEX_URL` points at the intended deployment.
- Convex deploy succeeded before shipping builds or OTA updates.
- Smoke test key flows against production data.

Docs: https://docs.convex.dev/production
