import fs from "fs";
import path from "path";

export function pathExists(filePath: string): boolean {
  try {
    fs.accessSync(filePath, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

export function readFileIfExists(filePath: string): string | null {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch {
    return null;
  }
}

export function readJsonFile<T = unknown>(filePath: string): T | null {
  const raw = readFileIfExists(filePath);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function ensureDir(dirPath: string): void {
  fs.mkdirSync(dirPath, { recursive: true });
}

export function listSubdirectories(dirPath: string): string[] {
  try {
    return fs
      .readdirSync(dirPath, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name);
  } catch {
    return [];
  }
}

export function toPosixPath(filePath: string): string {
  return filePath.split(path.sep).join("/");
}

export function isDirectory(filePath: string): boolean {
  try {
    return fs.statSync(filePath).isDirectory();
  } catch {
    return false;
  }
}

export function walkDirectories(root: string, ignore: string[] = []): string[] {
  const results: string[] = [];
  const stack = [root];

  while (stack.length) {
    const current = stack.pop();
    if (!current) break;
    results.push(current);
    for (const dirName of listSubdirectories(current)) {
      if (ignore.includes(dirName)) continue;
      stack.push(path.join(current, dirName));
    }
  }

  return results;
}
