# Authentication

## Table of contents

- [Mental model](#mental-model)
- [In Convex functions](#in-convex-functions)
- [Expo client: where auth state lives](#expo-client-where-auth-state-lives)
- [Option A: Better Auth (Convex component) for Expo](#option-a-better-auth-convex-component-for-expo)
- [In your Convex deployment env](#in-your-convex-deployment-env)
- [In your Expo .env.local created by npx convex dev](#in-your-expo-envlocal-created-by-npx-convex-dev)
- [Option B: Clerk/Auth0/etc](#option-b-clerkauth0etc)
- [Option C: No auth (prototype)](#option-c-no-auth-prototype)
- [Common pitfalls](#common-pitfalls)

This file focuses on how to think about auth with Convex in an Expo (React Native) app.

Convex supports multiple auth approaches. Your choice usually depends on whether you want:
- a fully managed auth product (Clerk/Auth0/etc)
- Convex-first auth (Convex Auth)
- bring-your-own auth library (for example Better Auth)

## Mental model

- The Expo app obtains an auth token from some identity provider.
- Convex verifies that token and makes the identity available in functions via `ctx.auth.getUserIdentity()`.
- Your functions must enforce authorization. Convex will not magically prevent user A from calling user B's APIs.

## In Convex functions

Typical pattern:

```ts
import { query } from "./_generated/server";

export const me = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");

    // identity.tokenIdentifier is commonly used as the stable key
    return identity;
  },
});
```

If you maintain a `users` table, map `identity.tokenIdentifier` to a user document:
- query users by `tokenIdentifier`
- create a new user doc on first login
- store app-specific profile fields there

## Expo client: where auth state lives

In React Native, store auth state and tokens in a secure place:
- prefer platform secure storage (Keychain/Keystore) instead of AsyncStorage for long-lived secrets
- avoid putting sensitive tokens in `EXPO_PUBLIC_*` env vars

## Option A: Better Auth (Convex component) for Expo

Convex maintains an official integration guide for "Convex + Better Auth" on Expo.

High-level steps from that guide:

1) Install packages

```bash
npm install convex@latest @convex-dev/better-auth
npm install better-auth@1.4.9 @better-auth/expo@1.4.9 --save-exact
```

2) Install Expo dependency for secure cookie storage

```bash
npx expo install expo-secure-store
```

3) Register the component in your Convex project

```ts
// convex/convex.config.ts
import { defineApp } from "convex/server";
import betterAuth from "@convex-dev/better-auth/convex.config";

const app = defineApp();
app.use(betterAuth);

export default app;
```

4) Add Convex auth config

```ts
// convex/auth.config.ts
import { getAuthConfigProvider } from "@convex-dev/better-auth/auth-config";
import type { AuthConfig } from "convex/server";

export default {
  providers: [getAuthConfigProvider()],
} satisfies AuthConfig;
```

5) Environment variables

```bash
# In your Convex deployment env
npx convex env set BETTER_AUTH_SECRET=$(openssl rand -base64 32)

# In your Expo .env.local created by npx convex dev
CONVEX_DEPLOYMENT=dev:adjective-animal-123
EXPO_PUBLIC_CONVEX_URL=https://adjective-animal-123.convex.cloud
EXPO_PUBLIC_CONVEX_SITE_URL=https://adjective-animal-123.convex.site
```

Then continue with the rest of the Better Auth Expo guide to wire up the client and providers.

## Option B: Clerk/Auth0/etc

If you already use a provider with strong React Native support (Clerk, Auth0, etc), you can:
- authenticate in the app
- pass the provider's JWT access token to Convex using the Convex React auth helpers

In this model, Convex uses your provider's JWT verification keys and exposes the identity in `ctx.auth`.

## Option C: No auth (prototype)

For prototypes:
- keep tables public
- do not store sensitive user data
- plan a migration path to auth early (schema indexes, userId fields)

## Common pitfalls

- Forgetting to check auth and ownership in backend functions.
- Assuming client-side UI restrictions are security.
- Putting secrets into `EXPO_PUBLIC_*` vars.
- Not indexing `users` by the auth identity identifier.
