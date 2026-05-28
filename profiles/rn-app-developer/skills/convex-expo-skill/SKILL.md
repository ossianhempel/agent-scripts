---
name: convex-expo
description: "Convex + Expo (React Native) workflow for setup, env vars, schema/tables, queries/mutations/actions, auth, file uploads, and CI/CD with Convex deploy + EAS. Triggers: add Convex to my Expo app; design a Convex schema; write a Convex query; Convex auth in React Native; set up CI/CD for Convex + Expo."
---

# Convex + Expo (React Native)

## Table of contents

- [Operating principles](#operating-principles)
- [Quick start checklist](#quick-start-checklist)
- [Navigation](#navigation)
- [Default workflow when implementing a feature](#default-workflow-when-implementing-a-feature)
- [Common snippets](#common-snippets)
- [Guardrails](#guardrails)

## Operating principles

- Follow the Convex "dev loop": keep `npx convex dev` running while developing so codegen stays up to date and backend changes are synced.
- In Expo client code, read the deployment URL from `process.env.EXPO_PUBLIC_CONVEX_URL`.
- Never put secrets into `EXPO_PUBLIC_*` variables. Treat them as public.
- Use a schema (`convex/schema.ts`) and indexes early. Query patterns should be index-backed.
- Keep your public API surface area small. Prefer `internalQuery`/`internalMutation`/`internalAction` for sensitive operations.
- Put side effects (fetching external APIs, sending emails, Stripe, etc.) in `action`s, not in `query`/`mutation`.

## Quick start checklist

1. Install Convex and create a project
   - `npm install convex`
   - `npx convex dev`
2. Ensure Expo has `EXPO_PUBLIC_CONVEX_URL` set (usually written into `.env.local` by Convex, otherwise add it yourself).
3. Add `ConvexProvider` at the app root (Expo Router: `app/_layout.tsx`).
4. Define tables + indexes in `convex/schema.ts`.
5. Implement backend functions in `convex/*.ts`.
6. Call them from the app with `useQuery`, `useMutation`, and `usePaginatedQuery`.
7. Commit `convex/_generated/` to git so the app typechecks without requiring `npx convex dev` first.

## Navigation

- Setup (new repo or existing): [references/setup.md](references/setup.md)
- Expo integration patterns: [references/expo-integration.md](references/expo-integration.md)
- Schema and tables (indexes, migrations): [references/schema-and-tables.md](references/schema-and-tables.md)
- Functions (queries, mutations, actions, internal): [references/functions.md](references/functions.md)
- Auth options (Convex Auth, Clerk, Better Auth): [references/auth.md](references/auth.md)
- File uploads and storage: [references/file-storage.md](references/file-storage.md)
- CI/CD (GitHub Actions, Convex deploy, EAS): [references/cicd.md](references/cicd.md)
- Testing + CI (convex-test, convex backend): [references/testing.md](references/testing.md)
- Production (deployments, envs, releases): [references/production.md](references/production.md)
- Troubleshooting: [references/troubleshooting.md](references/troubleshooting.md)

## Default workflow when implementing a feature

1. Clarify the feature and the data lifecycle (create, read, update, delete, permissions).
2. Update schema and indexes first.
3. Implement backend API functions:
   - `query` for reading
   - `mutation` for transactional writes
   - `action` for side effects and external calls
   - `internal*` for sensitive helpers
4. Add authorization checks in every function that returns or modifies user data.
5. Implement the Expo UI:
   - `useQuery` for reactive data
   - `useMutation` for writes
   - optimistic UI where helpful
6. Add tests if the logic is non-trivial.
7. Prepare safe rollout:
   - schema changes must be compatible with existing data
   - function changes must be backwards compatible with old clients

## Common snippets

### Root provider for Expo Router

```ts
import { ConvexProvider, ConvexReactClient } from "convex/react";
import { Stack } from "expo-router";

const convex = new ConvexReactClient(process.env.EXPO_PUBLIC_CONVEX_URL!, {
  // React Native does not need the browser unload warning.
  unsavedChangesWarning: false,
});

export default function RootLayout() {
  return (
    <ConvexProvider client={convex}>
      <Stack />
    </ConvexProvider>
  );
}
```

### Query from the app

```ts
import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

const tasks = useQuery(api.tasks.get);
```

### Mutation from the app

```ts
import { useMutation } from "convex/react";
import { api } from "../convex/_generated/api";

const createTask = useMutation(api.tasks.create);
await createTask({ text: "Buy groceries" });
```

## Guardrails

- If the request involves secrets in the mobile app bundle, move the secret to a Convex environment variable and perform the operation in an `action`.
- If the request could be abused from the client (payments, admin operations, data deletes), do not expose it as a public mutation. Use internal functions plus a checked public entrypoint.
- Prefer IDs over embedding whole documents when passing data between functions.
