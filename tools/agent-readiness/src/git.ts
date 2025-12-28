import { execSync } from "child_process";
import path from "path";
import { GitMetadata } from "./types";

function runGit(cwd: string, args: string): string | null {
  try {
    const output = execSync(`git ${args}`, {
      cwd,
      stdio: ["ignore", "pipe", "ignore"],
    });
    return output.toString("utf8").trim();
  } catch {
    return null;
  }
}

export function detectRepoRoot(start: string): string {
  const root = runGit(start, "rev-parse --show-toplevel");
  return root ? path.resolve(root) : path.resolve(start);
}

export function getGitMetadata(root: string): GitMetadata {
  const isRepo = runGit(root, "rev-parse --is-inside-work-tree") === "true";
  if (!isRepo) {
    return {
      commitHash: null,
      branch: null,
      hasLocalChanges: null,
      hasNonRemoteCommits: null,
    };
  }

  const commitHash = runGit(root, "rev-parse HEAD");
  const branch = runGit(root, "rev-parse --abbrev-ref HEAD");
  const status = runGit(root, "status --porcelain");
  const hasLocalChanges = status ? status.length > 0 : false;

  let hasNonRemoteCommits: boolean | null = null;
  const upstream = runGit(root, "rev-parse --abbrev-ref --symbolic-full-name @{u}");
  if (upstream) {
    const ahead = runGit(root, "rev-list --count @{u}..HEAD");
    hasNonRemoteCommits = ahead ? Number(ahead) > 0 : false;
  } else {
    hasNonRemoteCommits = null;
  }

  return {
    commitHash: commitHash ?? null,
    branch: branch ?? null,
    hasLocalChanges,
    hasNonRemoteCommits,
  };
}

export function getRepoUrl(root: string): string | null {
  const url = runGit(root, "config --get remote.origin.url");
  return url ?? null;
}
