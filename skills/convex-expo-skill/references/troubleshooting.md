# Troubleshooting

## `process.env.EXPO_PUBLIC_CONVEX_URL` is undefined

Symptoms:
- App crashes at startup because the env var is missing.
- Convex client cannot connect.

Fix:
- Ensure you have `EXPO_PUBLIC_CONVEX_URL=...` in `.env.local` (or `.env`).
- Fully reload the Expo app after adding env vars.
- Verify you are using the `EXPO_PUBLIC_` prefix.

## Convex functions do not typecheck in CI

Fix:
- Ensure `convex/_generated/` is committed.
- Ensure CI runs `npm ci` and TypeScript typecheck.
- If you rely on codegen in CI, run `npx convex codegen` (may require access to a deployment).

## Schema push fails on deploy

Likely cause:
- Existing data in the deployment does not match the new schema.

Fix:
- Use a safe migration sequence:
  - make new fields optional
  - deploy
  - backfill data
  - then make fields required

## HTTP actions 404 or CORS errors

Fix:
- Confirm you are using the `.convex.site` URL for HTTP actions.
- Ensure the file is named exactly `convex/http.ts` (or `convex/http.js`) and exports a router.
- If called from a browser, add proper CORS headers and handle OPTIONS.

## Mobile device cannot connect

Fix:
- Confirm the device has network access.
- Confirm the deployment URL is reachable.
- If you are using a corporate VPN or restrictive network, test on a different connection.

## Uploads fail

Fix:
- Ensure you generate a fresh upload URL shortly before uploading.
- Ensure you POST the blob bytes with a correct Content-Type.
- If using HTTP actions for upload, remember request size limits.
