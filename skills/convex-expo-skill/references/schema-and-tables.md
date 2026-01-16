# Schema and tables

## Table of contents

- [Core concepts](#core-concepts)
- [Why define a schema?](#why-define-a-schema)
- [Example schema (users + tasks)](#example-schema-users--tasks)
- [Validators you will use constantly](#validators-you-will-use-constantly)
- [Index design](#index-design)
- [Declare indexes](#declare-indexes)
- [Query using an index](#query-using-an-index)
- [Modeling relationships](#modeling-relationships)
- [One-to-many](#one-to-many)
- [Many-to-many](#many-to-many)
- [Safe schema evolution (production)](#safe-schema-evolution-production)
- [Migration workflow (data backfill)](#migration-workflow-data-backfill)
- [Example: making a new field required](#example-making-a-new-field-required)
- [Imports, seed data, and local testing](#imports-seed-data-and-local-testing)

Convex stores JSON-like documents in tables. Define tables, fields, and indexes in `convex/schema.ts`.

## Core concepts

- A table is a collection of documents.
- Every document has:
  - `_id` (typed as `Id<"table">`)
  - `_creationTime` (milliseconds since epoch)
- Reference other documents by storing IDs (for example `userId: v.id("users")`).

## Why define a schema?

- Enforces that data matches expected shape when schema enforcement is on.
- Enables end-to-end types for IDs, docs, and function args/returns.
- Lets you define indexes that power efficient queries.

## Example schema (users + tasks)

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    // Example: map an auth identity to an app user
    tokenIdentifier: v.string(),
    name: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
  }).index("by_tokenIdentifier", ["tokenIdentifier"]),

  tasks: defineTable({
    text: v.string(),
    isCompleted: v.boolean(),
    // Optional until you add auth
    userId: v.optional(v.id("users")),
  })
    .index("by_user", ["userId"])
    .index("by_user_creationTime", ["userId", "_creationTime"]),
});
```

## Validators you will use constantly

From `convex/values`:

- Scalars: `v.string()`, `v.number()`, `v.boolean()`, `v.null()`
- IDs: `v.id("tableName")`
- Optional: `v.optional(<validator>)`
- Objects: `v.object({ ... })`
- Arrays: `v.array(<validator>)`
- Unions: `v.union(v.literal("a"), v.literal("b"), ...)`

Rule of thumb: validate every public function argument.

## Index design

Convex queries are fastest when they use an index that matches the access pattern.

### Declare indexes

In the schema, add `.index("by_something", ["fieldA", "fieldB"])`.

- Put equality fields first.
- Use `_creationTime` as a sortable suffix when you want recent-first queries.

### Query using an index

```ts
// convex/tasks.ts
import { query } from "./_generated/server";
import { v } from "convex/values";

export const listByUser = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .withIndex("by_user_creationTime", (q) => q.eq("userId", args.userId))
      .order("desc")
      .take(50);
  },
});
```

When you do not have an index, you can still use `.filter(...)`, but index-backed queries are the default for scalable apps.

## Modeling relationships

### One-to-many

- Store the parent ID on the child.
- Index by the parent ID.

Example: `tasks` has `userId`.

### Many-to-many

Use a join table.

Example: `projectMembers` table:

```ts
projectMembers: defineTable({
  projectId: v.id("projects"),
  userId: v.id("users"),
  role: v.union(v.literal("owner"), v.literal("member")),
})
  .index("by_project", ["projectId"])
  .index("by_user", ["userId"])
  .index("by_project_user", ["projectId", "userId"]),
```

## Safe schema evolution (production)

Schema changes must be compatible with existing data.

Common safe patterns:

1. Add a new table.
2. Add a new optional field, backfill it, then make it required.
3. Make a required field optional, remove it from all docs, then remove it from schema.
4. Widen a field type with a union, migrate values, then narrow the type.

## Migration workflow (data backfill)

Use this when you need to transform existing documents.

1. Add new fields as optional.
2. Ship the new schema and code.
3. Backfill data using a migration mutation/action:
   - run in batches
   - make it idempotent
   - track progress in a cursor or job table
4. Flip the field to required (or narrow types).

References:
- https://stack.convex.dev/intro-to-migrations
- https://stack.convex.dev/migrating-data-with-mutations

### Example: making a new field required

1. Add the new field as `v.optional(...)`.
2. Deploy.
3. Backfill existing docs using a migration mutation/action.
4. Change to a required validator.
5. Deploy again.

## Imports, seed data, and local testing

- Import JSONL: `npx convex import --table <name> <file.jsonl>`
- Export: `npx convex export --path <dir>`

Use imports to seed dev deployments with synthetic data, or copy prod data into a dev deployment when debugging.
