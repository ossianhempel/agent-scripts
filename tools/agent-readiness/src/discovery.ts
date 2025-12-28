import path from "path";
import { AppInfo } from "./types";
import {
  isDirectory,
  listSubdirectories,
  pathExists,
  readFileIfExists,
  readJsonFile,
  toPosixPath,
  walkDirectories,
} from "./utils";

const MANIFEST_FILES = [
  "package.json",
  "pyproject.toml",
  "requirements.txt",
  "setup.py",
  "go.mod",
  "Cargo.toml",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
];

const DEFAULT_APP_DIRS = ["apps", "packages", "services", "libs"];

interface WorkspaceConfig {
  patterns: string[];
  source: string;
}

export function discoverApps(root: string): AppInfo[] {
  const apps = new Map<string, AppInfo>();
  const workspace = readWorkspaceConfig(root);

  if (workspace) {
    for (const pattern of workspace.patterns) {
      for (const appPath of expandWorkspacePattern(root, pattern)) {
        const info = buildAppInfo(root, appPath);
        if (info) apps.set(info.path, info);
      }
    }
  }

  if (apps.size === 0) {
    for (const dirName of DEFAULT_APP_DIRS) {
      const dirPath = path.join(root, dirName);
      if (!isDirectory(dirPath)) continue;
      for (const child of listSubdirectories(dirPath)) {
        const childPath = path.join(dirPath, child);
        const info = buildAppInfo(root, childPath);
        if (info) apps.set(info.path, info);
      }
    }
  }

  if (apps.size === 0) {
    const rootInfo = buildAppInfo(root, root, true);
    if (rootInfo) apps.set(rootInfo.path, rootInfo);
  }

  if (apps.size === 0) {
    const fallback: AppInfo = {
      id: ".",
      path: ".",
      description: "Repository root",
    };
    apps.set(fallback.path, fallback);
  }

  return Array.from(apps.values());
}

function buildAppInfo(root: string, appPath: string, allowNoManifest = false): AppInfo | null {
  const hasManifest = MANIFEST_FILES.some((file) => pathExists(path.join(appPath, file)));
  if (!hasManifest && !allowNoManifest) return null;
  const relativePath = toPosixPath(path.relative(root, appPath) || ".");
  return {
    id: relativePath,
    path: relativePath,
    description: relativePath === "." ? "Repository root" : undefined,
  };
}

function readWorkspaceConfig(root: string): WorkspaceConfig | null {
  const pkg = readJsonFile<{ workspaces?: string[] | { packages?: string[] } }>(
    path.join(root, "package.json")
  );
  if (pkg?.workspaces) {
    const patterns = Array.isArray(pkg.workspaces)
      ? pkg.workspaces
      : pkg.workspaces.packages || [];
    if (patterns.length) {
      return { patterns, source: "package.json" };
    }
  }

  const pnpmWorkspacePath = path.join(root, "pnpm-workspace.yaml");
  const pnpmRaw = readFileIfExists(pnpmWorkspacePath);
  if (pnpmRaw) {
    const patterns = parsePnpmWorkspace(pnpmRaw);
    if (patterns.length) {
      return { patterns, source: "pnpm-workspace.yaml" };
    }
  }

  return null;
}

function parsePnpmWorkspace(raw: string): string[] {
  const lines = raw.split(/\r?\n/);
  const patterns: string[] = [];
  let inPackages = false;
  for (const line of lines) {
    if (/^\s*packages\s*:\s*$/.test(line)) {
      inPackages = true;
      continue;
    }
    if (inPackages) {
      const match = line.match(/^\s*-\s*(.+)\s*$/);
      if (match) {
        patterns.push(match[1].trim().replace(/^['"]|['"]$/g, ""));
        continue;
      }
      if (/^\S/.test(line)) {
        inPackages = false;
      }
    }
  }
  return patterns;
}

function expandWorkspacePattern(root: string, pattern: string): string[] {
  const normalized = pattern.replace(/\\/g, "/");
  if (!normalized.includes("*")) {
    const resolved = path.join(root, normalized);
    return isDirectory(resolved) ? [resolved] : [];
  }

  if (normalized.includes("**")) {
    const base = normalized.split("**")[0].replace(/\/$/, "");
    const baseDir = path.join(root, base);
    if (!isDirectory(baseDir)) return [];
    return walkDirectories(baseDir, ["node_modules", ".git", "dist", "build"]).filter(
      (dir) => MANIFEST_FILES.some((file) => pathExists(path.join(dir, file)))
    );
  }

  const base = normalized.split("*")[0].replace(/\/$/, "");
  const baseDir = path.join(root, base);
  if (!isDirectory(baseDir)) return [];
  return listSubdirectories(baseDir)
    .map((name) => path.join(baseDir, name))
    .filter((dir) => MANIFEST_FILES.some((file) => pathExists(path.join(dir, file))));
}
