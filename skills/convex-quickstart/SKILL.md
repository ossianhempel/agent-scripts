---
name: convex-quickstart
description: Initialize a new Convex backend from scratch with schema, auth, and basic CRUD operations. Use when starting a new project or adding Convex to an existing app.
homepage: https://github.com/get-convex/convex-agent-plugins
license: MIT
---

# Convex Quickstart

Get a production-ready Convex backend set up in minutes. This skill guides you through initializing Convex, creating your schema, setting up auth, and building your first CRUD operations.

## When to Use

- Starting a brand new project with Convex
- Adding Convex to an existing React/Next.js app
- Prototyping a new feature with real-time data
- Converting from another backend to Convex
- Teaching someone Convex for the first time

## Prerequisites Check

Before starting, verify:
```bash
node --version  # v18 or higher
npm --version   # v8 or higher
```

## Quick Start Flow

### Step 1: Install and Initialize

```bash
# Install Convex
npm install convex

# Initialize (creates convex/ directory)
npx convex dev
```

This command:
- Creates `convex/` directory
- Sets up authentication
- Starts development server
- Generates TypeScript types

### Step 2: Create Schema

Create `convex/schema.ts`:

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    tokenIdentifier: v.string(),
    name: v.string(),
    email: v.string(),
  }).index("by_token", ["tokenIdentifier"]),

  // Add your tables here
  tasks: defineTable({
    userId: v.id("users"),
    title: v.string(),
    completed: v.boolean(),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_and_completed", ["userId", "completed"]),
});
```

### Step 3: Set Up Authentication

> For detailed auth patterns (access control, team-based auth, admin roles), see `convex-auth-setup`.

We'll use WorkOS AuthKit, which provides a complete auth solution with minimal setup.

```bash
npm install @workos-inc/authkit-react
```

#### For React/Vite Apps:

```typescript
// src/main.tsx
import { AuthKitProvider, useAuth } from "@workos-inc/authkit-react";
import { ConvexReactClient } from "convex/react";
import { ConvexProvider } from "convex/react";

const convex = new ConvexReactClient(import.meta.env.VITE_CONVEX_URL);

convex.setAuth(useAuth);

function App() {
  return (
    <AuthKitProvider clientId={import.meta.env.VITE_WORKOS_CLIENT_ID}>
      <ConvexProvider client={convex}>
        <YourApp />
      </ConvexProvider>
    </AuthKitProvider>
  );
}
```

#### For Next.js Apps:

```bash
npm install @workos-inc/authkit-nextjs
```

```typescript
// app/layout.tsx
import { AuthKitProvider } from "@workos-inc/authkit-nextjs";
import { ConvexClientProvider } from "./ConvexClientProvider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <AuthKitProvider>
          <ConvexClientProvider>
            {children}
          </ConvexClientProvider>
        </AuthKitProvider>
      </body>
    </html>
  );
}
```

```typescript
// app/ConvexClientProvider.tsx
"use client";

import { ConvexReactClient } from "convex/react";
import { ConvexProvider } from "convex/react";
import { useAuth } from "@workos-inc/authkit-nextjs";

const convex = new ConvexReactClient(process.env.NEXT_PUBLIC_CONVEX_URL!);

export function ConvexClientProvider({ children }: { children: React.ReactNode }) {
  const { getToken } = useAuth();

  convex.setAuth(async () => {
    return await getToken();
  });

  return <ConvexProvider client={convex}>{children}</ConvexProvider>;
}
```

#### Environment Variables:

```bash
# .env.local
VITE_CONVEX_URL=https://your-deployment.convex.cloud
VITE_WORKOS_CLIENT_ID=your_workos_client_id

# For Next.js:
NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
NEXT_PUBLIC_WORKOS_CLIENT_ID=your_workos_client_id
WORKOS_API_KEY=your_workos_api_key
WORKOS_COOKIE_PASSWORD=generate_a_random_32_character_string
```

**Alternative auth providers:** If you need a different provider (Clerk, Auth0, custom JWT), see the [Convex auth documentation](https://docs.convex.dev/auth).

### Step 4: Create Auth Helpers

Create `convex/lib/auth.ts`:

```typescript
import { QueryCtx, MutationCtx } from "../_generated/server";
import { Doc } from "../_generated/dataModel";

export async function getCurrentUser(
  ctx: QueryCtx | MutationCtx
): Promise<Doc<"users">> {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    throw new Error("Not authenticated");
  }

  const user = await ctx.db
    .query("users")
    .withIndex("by_token", q =>
      q.eq("tokenIdentifier", identity.tokenIdentifier)
    )
    .unique();

  if (!user) {
    throw new Error("User not found");
  }

  return user;
}
```

Create `convex/users.ts`:

```typescript
import { mutation } from "./_generated/server";

export const store = mutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    const existing = await ctx.db
      .query("users")
      .withIndex("by_token", q =>
        q.eq("tokenIdentifier", identity.tokenIdentifier)
      )
      .unique();

    if (existing) return existing._id;

    return await ctx.db.insert("users", {
      tokenIdentifier: identity.tokenIdentifier,
      name: identity.name ?? "Anonymous",
      email: identity.email ?? "",
    });
  },
});
```

### Step 5: Create Your First CRUD Operations

Create `convex/tasks.ts`:

```typescript
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";
import { getCurrentUser } from "./lib/auth";

// List all tasks for current user
export const list = query({
  args: {},
  handler: async (ctx) => {
    const user = await getCurrentUser(ctx);
    return await ctx.db
      .query("tasks")
      .withIndex("by_user", q => q.eq("userId", user._id))
      .order("desc")
      .collect();
  },
});

// Get a single task
export const get = query({
  args: { taskId: v.id("tasks") },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    const task = await ctx.db.get(args.taskId);

    if (!task) throw new Error("Task not found");
    if (task.userId !== user._id) throw new Error("Unauthorized");

    return task;
  },
});

// Create a task
export const create = mutation({
  args: { title: v.string() },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    return await ctx.db.insert("tasks", {
      userId: user._id,
      title: args.title,
      completed: false,
      createdAt: Date.now(),
    });
  },
});

// Update a task
export const update = mutation({
  args: {
    taskId: v.id("tasks"),
    title: v.optional(v.string()),
    completed: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    const task = await ctx.db.get(args.taskId);

    if (!task) throw new Error("Task not found");
    if (task.userId !== user._id) throw new Error("Unauthorized");

    await ctx.db.patch(args.taskId, {
      ...(args.title !== undefined && { title: args.title }),
      ...(args.completed !== undefined && { completed: args.completed }),
    });
  },
});

// Delete a task
export const remove = mutation({
  args: { taskId: v.id("tasks") },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    const task = await ctx.db.get(args.taskId);

    if (!task) throw new Error("Task not found");
    if (task.userId !== user._id) throw new Error("Unauthorized");

    await ctx.db.delete(args.taskId);
  },
});
```

### Step 6: Use in Your React App

```typescript
"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "../../convex/_generated/api";

export default function TasksPage() {
  const tasks = useQuery(api.tasks.list);
  const create = useMutation(api.tasks.create);
  const update = useMutation(api.tasks.update);
  const remove = useMutation(api.tasks.remove);

  if (!tasks) return <div>Loading...</div>;

  return (
    <div>
      <h1>Tasks</h1>

      <form onSubmit={(e) => {
        e.preventDefault();
        const formData = new FormData(e.target as HTMLFormElement);
        create({ title: formData.get("title") as string });
        (e.target as HTMLFormElement).reset();
      }}>
        <input name="title" placeholder="New task" required />
        <button type="submit">Add</button>
      </form>

      {tasks.map(task => (
        <div key={task._id}>
          <input
            type="checkbox"
            checked={task.completed}
            onChange={(e) => update({
              taskId: task._id,
              completed: e.target.checked
            })}
          />
          <span>{task.title}</span>
          <button onClick={() => remove({ taskId: task._id })}>
            Delete
          </button>
        </div>
      ))}
    </div>
  );
}
```

### Step 7: Development vs Production

```bash
# Development (use this!)
npx convex dev

# Production (only when deploying!)
npx convex deploy
```

**Important:** Always use `npx convex dev` during development. Only use `npx convex deploy` when you're ready to ship to production.

## Common Patterns

### Paginated Queries

```typescript
export const listPaginated = query({
  args: {
    cursor: v.optional(v.string()),
    limit: v.number(),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    const results = await ctx.db
      .query("tasks")
      .withIndex("by_user", q => q.eq("userId", user._id))
      .order("desc")
      .paginate({ cursor: args.cursor, limit: args.limit });

    return results;
  },
});
```

### Scheduled Jobs

```typescript
// convex/crons.ts
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";

const crons = cronJobs();

crons.daily(
  "cleanup-old-tasks",
  { hourUTC: 0, minuteUTC: 0 },
  internal.tasks.cleanupOld
);

export default crons;
```

## Project Templates

```bash
# React + Vite + Convex
npm create vite@latest my-app -- --template react-ts
cd my-app && npm install convex @workos-inc/authkit-react && npx convex dev

# Next.js + Convex
npx create-next-app@latest my-app
cd my-app && npm install convex @workos-inc/authkit-nextjs && npx convex dev

# Expo (React Native) + Convex
npx create-expo-app my-app
cd my-app && npm install convex && npx convex dev
```

## Checklist

- [ ] `npm install convex` completed
- [ ] `npx convex dev` running
- [ ] Schema created with proper indexes
- [ ] Auth provider configured
- [ ] `getCurrentUser` helper implemented
- [ ] User storage mutation created
- [ ] CRUD operations with auth checks
- [ ] Frontend integrated with hooks
- [ ] When ready for production, use `npx convex deploy`

## Learn More

- [Convex Docs](https://docs.convex.dev)
- [React Quickstart](https://docs.convex.dev/quickstart/react)
- [Next.js Quickstart](https://docs.convex.dev/quickstart/nextjs)
- [Example Apps](https://github.com/get-convex/convex-demos)
