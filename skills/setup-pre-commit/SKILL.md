---
name: setup-pre-commit
description: Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. Use when user wants to add pre-commit hooks, set up Husky, configure lint-staged, or add commit-time formatting/typechecking/testing.
---

# Setup Pre-Commit Hooks

## What This Sets Up

- **Husky** pre-commit hook
- **lint-staged** running Prettier on all staged files
- **Prettier** config (if missing)
- **500 LOC per-file lint** for staged source files only
- **typecheck** and **test** scripts in the pre-commit hook

## Steps

### 1. Detect package manager

Check for `package-lock.json` (npm), `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn), `bun.lockb` (bun). Use whichever is present. Default to npm if unclear.

### 2. Install dependencies

Install as devDependencies:

```
husky lint-staged prettier
```

### 3. Create `scripts/check-staged-file-loc.js`

Create this script and make it executable. It checks only files that are staged
as added, copied, modified, or renamed, so oversized untouched files already in
the repo do not block commits.

```js
#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const { existsSync, readFileSync } = require("node:fs");

const MAX_LINES = 500;
const IGNORED_EXTENSIONS = new Set([".md", ".mdx"]);
const IGNORED_DIRECTORIES = new Set(["docs"]);
const SOURCE_EXTENSIONS = new Set([
  ".cjs",
  ".css",
  ".cts",
  ".go",
  ".js",
  ".jsx",
  ".mjs",
  ".mts",
  ".py",
  ".rs",
  ".scss",
  ".sh",
  ".swift",
  ".ts",
  ".tsx",
]);

function stagedFiles() {
  const output = execFileSync(
    "git",
    ["diff", "--cached", "--name-only", "--diff-filter=ACMR"],
    { encoding: "utf8" }
  );

  return output.split(/\r?\n/).filter(Boolean);
}

function extensionOf(path) {
  const match = path.match(/(\.[^.\/]+)$/);
  return match ? match[1].toLowerCase() : "";
}

function shouldCheck(path) {
  const parts = path.split("/");
  if (parts.some((part) => IGNORED_DIRECTORIES.has(part))) return false;

  const extension = extensionOf(path);
  if (IGNORED_EXTENSIONS.has(extension)) return false;

  return SOURCE_EXTENSIONS.has(extension);
}

const oversized = [];

for (const file of stagedFiles()) {
  if (!shouldCheck(file) || !existsSync(file)) continue;

  const text = readFileSync(file, "utf8").replace(/\r?\n$/, "");
  const lines = text.length === 0 ? 0 : text.split(/\r?\n/).length;

  if (lines > MAX_LINES) {
    oversized.push({ file, lines });
  }
}

if (oversized.length > 0) {
  console.error(`Files must be ${MAX_LINES} lines or fewer:`);
  for (const { file, lines } of oversized) {
    console.error(`- ${file}: ${lines} lines`);
  }
  process.exit(1);
}
```

Add this package script:

```json
"lint:max-lines:staged": "node scripts/check-staged-file-loc.js"
```

### 4. Initialize Husky

```bash
npx husky init
```

This creates `.husky/` dir and adds `prepare: "husky"` to package.json.

### 5. Create `.husky/pre-commit`

Write this file (no shebang needed for Husky v9+):

```
npx lint-staged
npm run lint:max-lines:staged
npm run typecheck
npm run test
```

**Adapt**: Replace `npm` with detected package manager. If repo has no `typecheck` or `test` script in package.json, omit those lines and tell the user. Keep `lint:max-lines:staged` unless the repo is not JavaScript-capable.

### 6. Create `.lintstagedrc`

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

### 7. Create `.prettierrc` (if missing)

Only create if no Prettier config exists. Use these defaults:

```json
{
  "useTabs": false,
  "tabWidth": 2,
  "printWidth": 80,
  "singleQuote": false,
  "trailingComma": "es5",
  "semi": true,
  "arrowParens": "always"
}
```

### 8. Verify

- [ ] `.husky/pre-commit` exists and is executable
- [ ] `.lintstagedrc` exists
- [ ] `prepare` script in package.json is `"husky"`
- [ ] `lint:max-lines:staged` script exists
- [ ] `prettier` config exists
- [ ] Run `npm run lint:max-lines:staged` with no oversized staged source file
- [ ] Stage a temporary >500-line source file, confirm `npm run lint:max-lines:staged` fails, then unstage and remove it
- [ ] Confirm an existing >500-line source file that was not staged is ignored
- [ ] Run `npx lint-staged` to verify it works

### 9. Commit

Stage all changed/created files and commit with message: `Add pre-commit hooks (husky + lint-staged + prettier)`

This will run through the new pre-commit hooks — a good smoke test that everything works.

## Notes

- Husky v9+ doesn't need shebangs in hook files
- `prettier --ignore-unknown` skips files Prettier can't parse (images, etc.)
- The LOC lint checks only newly staged source changes, not the whole repo
- The pre-commit runs lint-staged first (fast, staged-only), then staged LOC lint, then full typecheck and tests
