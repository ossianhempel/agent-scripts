# Expo integration

## Table of contents

- [Environment variables (Expo)](#environment-variables-expo)
- [Provider setup](#provider-setup)
- [Expo Router (recommended)](#expo-router-recommended)
- [No Expo Router](#no-expo-router)
- [Data fetching patterns](#data-fetching-patterns)
- [Basic query](#basic-query)
- [Mutations](#mutations)
- [Pagination](#pagination)
- [Networking notes](#networking-notes)
- [Performance notes](#performance-notes)

## Environment variables (Expo)

Expo CLI automatically loads variables prefixed with `EXPO_PUBLIC_` from `.env` files into your JS bundle when running `npx expo start`.

Recommended variables:

```bash
# .env.local (do not commit)
EXPO_PUBLIC_CONVEX_URL=https://<deployment>.convex.cloud

# Optional: HTTP actions use the .site domain
EXPO_PUBLIC_CONVEX_SITE_URL=https://<deployment>.convex.site
```

Usage in code:

```ts
const convex = new ConvexReactClient(process.env.EXPO_PUBLIC_CONVEX_URL!);
```

Notes:
- Variables can change while Expo is running, but you typically need a full reload in the client to see updates.
- Never store secrets in `EXPO_PUBLIC_*` variables.

## Provider setup

### Expo Router (recommended)

Place the provider in `app/_layout.tsx`.

```ts
import { ConvexProvider, ConvexReactClient } from "convex/react";
import { Stack } from "expo-router";

const convex = new ConvexReactClient(process.env.EXPO_PUBLIC_CONVEX_URL!, {
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

### No Expo Router

Wrap your top-level component (usually `App.tsx`) in `ConvexProvider`.

## Data fetching patterns

### Basic query

```ts
import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

export function TaskList() {
  const tasks = useQuery(api.tasks.get);
  if (tasks === undefined) return null; // still loading
  return (
    <>
      {tasks.map((t) => (
        <Text key={t._id}>{t.text}</Text>
      ))}
    </>
  );
}
```

Tips:
- `useQuery` returns `undefined` while loading.
- Handle `null` or empty arrays depending on your query.

### Mutations

```ts
import { useMutation } from "convex/react";
import { api } from "../convex/_generated/api";

export function AddTaskButton() {
  const createTask = useMutation(api.tasks.create);
  return (
    <Button
      title="Add"
      onPress={() => createTask({ text: "Hello" })}
    />
  );
}
```

### Pagination

Use `usePaginatedQuery` + a paginated server query that calls `.paginate(paginationOpts)`.

## Networking notes

- Mobile devices must be able to reach the Convex deployment URL over the network.
- If you are debugging HTTP actions, use the `.convex.site` URL, not `.convex.cloud`.

## Performance notes

- Prefer index-backed queries.
- Avoid returning extremely large payloads; paginate or split.
