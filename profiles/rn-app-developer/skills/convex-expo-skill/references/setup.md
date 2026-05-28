# Setup: Convex + Expo

## Table of contents

- [Prerequisites](#prerequisites)
- [Golden path: new project](#golden-path-new-project)
- [1) Create the Expo app](#1-create-the-expo-app)
- [2) Install Convex](#2-install-convex)
- [3) Start the Convex dev loop](#3-start-the-convex-dev-loop)
- [4) Ensure `EXPO_PUBLIC_CONVEX_URL` exists](#4-ensure-expo_public_convex_url-exists)
- [5) If using Expo Router, ensure `app/` exists](#5-if-using-expo-router-ensure-app-exists)
- [6) Connect Convex to the app root](#6-connect-convex-to-the-app-root)
- [7) Add a first table and query](#7-add-a-first-table-and-query)
- [8) Run the app](#8-run-the-app)
- [Add Convex to an existing Expo project](#add-convex-to-an-existing-expo-project)
- [Repo hygiene](#repo-hygiene)

This guide is for both:
- starting a new Expo project and adding Convex
- adding Convex to an existing Expo project

## Prerequisites

- Node.js + npm (or pnpm/yarn/bun)
- Expo tooling (Expo CLI comes via `npx expo`)
- A Git repo (recommended) so you can commit `convex/_generated/`

## Golden path: new project

### 1) Create the Expo app

```bash
npx create-expo-app my-app
cd my-app
```

If you plan to use Expo Router (recommended), keep the default template or add it later.

### 2) Install Convex

```bash
npm install convex
```

### 3) Start the Convex dev loop

```bash
npx convex dev
```

What this does:
- prompts you to log in (or develop locally)
- creates a Convex project and a dev deployment
- creates `convex/` (if missing)
- keeps running to sync backend changes
- updates `convex/_generated/` for end-to-end TypeScript types

Keep this command running in its own terminal while you develop.

### 4) Ensure `EXPO_PUBLIC_CONVEX_URL` exists

Your Expo app must know which Convex deployment to connect to.

Convex typically writes deployment info to `.env.local`. For Expo, you want:

```bash
EXPO_PUBLIC_CONVEX_URL=https://<your-deployment>.convex.cloud
```

If `EXPO_PUBLIC_CONVEX_URL` is missing but you have something like `CONVEX_URL`, either:
- rename it to `EXPO_PUBLIC_CONVEX_URL`, or
- set `EXPO_PUBLIC_CONVEX_URL` and keep `CONVEX_URL` if other tooling needs it

Do not commit `.env.local`. Instead, commit a `.env.example` with placeholders.

### 5) If using Expo Router, ensure `app/` exists

Some Expo templates may not include the `app/` directory.

The Convex React Native quickstart suggests:

```bash
npm run reset-project
```

### 6) Connect Convex to the app root

For Expo Router, add the provider in `app/_layout.tsx`:

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

### 7) Add a first table and query

Create sample data and import it:

```bash
cat > sampleData.jsonl <<'JSONL'
{"text":"Buy groceries","isCompleted":true}
{"text":"Go for a swim","isCompleted":true}
{"text":"Integrate Convex","isCompleted":false}
JSONL

npx convex import --table tasks sampleData.jsonl
```

Create `convex/tasks.ts`:

```ts
import { query } from "./_generated/server";

export const get = query({
  args: {},
  handler: async (ctx) => {
    return await ctx.db.query("tasks").collect();
  },
});
```

Display it in `app/index.tsx`:

```ts
import { api } from "@/convex/_generated/api";
import { useQuery } from "convex/react";
import { Text, View } from "react-native";

export default function Index() {
  const tasks = useQuery(api.tasks.get);
  return (
    <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
      {tasks?.map(({ _id, text }) => (
        <Text key={_id}>{text}</Text>
      ))}
    </View>
  );
}
```

### 8) Run the app

```bash
npm start
```

## Add Convex to an existing Expo project

1. `npm install convex`
2. `npx convex dev`
3. Add `ConvexProvider` at the root (Expo Router `_layout.tsx`, or your `App.tsx`)
4. Make sure your env var is `EXPO_PUBLIC_CONVEX_URL`

## Repo hygiene

- Commit `convex/_generated/`
- Ignore `.env*` local files that contain developer-specific deployment identifiers
- Consider adding scripts:
  - `dev:backend`: `convex dev`
  - `dev:app`: `expo start`
  - `dev`: run both (use `concurrently` or `npm-run-all`)
