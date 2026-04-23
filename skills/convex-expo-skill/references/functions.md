# Functions: queries, mutations, actions

## Table of contents

- [File-based routing](#file-based-routing)
- [Queries (read)](#queries-read)
- [Mutations (transactional write)](#mutations-transactional-write)
- [Actions (side effects, external APIs)](#actions-side-effects-external-apis)
- [Internal functions (reduce public surface area)](#internal-functions-reduce-public-surface-area)
- [Authorization patterns](#authorization-patterns)
- [Pagination](#pagination)
- [HTTP actions (webhooks, public HTTP API)](#http-actions-webhooks-public-http-api)

Convex backend code lives in the `convex/` directory.

## File-based routing

- Exported functions become part of your generated API.
- The function name is derived from the file path + export name.
  - `convex/tasks.ts` + `export const get = ...` becomes `api.tasks.get`.

## Queries (read)

Use queries for reading data. They are reactive and rerun when underlying data changes.

```ts
import { query } from "./_generated/server";
import { v } from "convex/values";

export const getTask = query({
  args: { id: v.id("tasks") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.id);
  },
});
```

Guidelines:
- Validate args
- Prefer index-backed queries (`withIndex`) for anything non-trivial
- Keep queries deterministic and side-effect free

## Mutations (transactional write)

Mutations can read and write in a single transaction.

```ts
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const create = mutation({
  args: { text: v.string() },
  handler: async (ctx, args) => {
    const id = await ctx.db.insert("tasks", {
      text: args.text,
      isCompleted: false,
    });
    return id;
  },
});
```

Guidelines:
- Validate args
- Enforce authorization (do not trust the client)
- Keep mutations relatively small and fast

## Actions (side effects, external APIs)

Actions are for interacting with the outside world, like calling Stripe, sending emails, or talking to other APIs.

Actions cannot directly write with `ctx.db.*`. They write by calling mutations via `ctx.runMutation(...)`.

```ts
import { action } from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/api";

export const fetchAndStore = action({
  args: { url: v.string() },
  handler: async (ctx, args) => {
    const res = await fetch(args.url);
    if (!res.ok) throw new Error("Failed to fetch");
    const text = await res.text();

    await ctx.runMutation(internal.pages.upsert, { url: args.url, text });
  },
});
```

Guidelines:
- Use actions for secrets and external calls
- Keep mutations internal if they should not be callable directly
- Consider idempotency if actions can be retried externally

## Internal functions (reduce public surface area)

By default, exported functions are public and callable by any client that knows the name.

Use:
- `internalQuery`
- `internalMutation`
- `internalAction`

for sensitive helpers.

Example:

```ts
import { internalMutation } from "./_generated/server";
import { v } from "convex/values";

export const deleteAllTasks = internalMutation({
  args: {},
  handler: async (ctx) => {
    const tasks = await ctx.db.query("tasks").collect();
    for (const task of tasks) {
      await ctx.db.delete(task._id);
    }
  },
});
```

Then call it from an action that checks permissions.

## Authorization patterns

In every function that touches user data:
1. Read auth identity (for example `ctx.auth.getUserIdentity()`)
2. If missing, throw (unauthenticated)
3. Map identity to an app user (optional but common)
4. Check ownership/roles before reading or writing

Avoid "security by obscurity". Even if your app UI hides a button, a malicious user can still call your public mutation.

## Pagination

Use cursor pagination for large lists:
- server query calls `.paginate(paginationOpts)`
- app uses `usePaginatedQuery`

## HTTP actions (webhooks, public HTTP API)

HTTP actions:
- receive a Fetch `Request`
- return a Fetch `Response`
- can call queries/mutations/actions

They run in the same environment as queries and mutations, so if you need Node APIs, call an action.
