#!/usr/bin/env python3
"""
Audit skills across repo and global installations.

Subcommands:
  scan   - Report orphans (global skills missing from repo) and duplicates
           (same skill installed in multiple locations with content drift or
           local-repo shadows).
  prune  - Remove global skills that are not in the repo's skills/ folder.
           Dry-run by default; pass --execute to actually delete.

Repo scope (authoritative source):
  <repo>/skills/*

Global scopes (managed — `prune` may delete orphans here):
  ~/.agents/skills/*   ~/.claude/skills/*
  ~/.codex/skills/*    ~/.gemini/skills/*
  ~/.cursor/skills/*

Local/project scopes (read-only — `prune` NEVER touches these):
  ~/Developer/*/.agents/skills/*
  ~/Developer/*/.claude/skills/*
  ~/Developer/*/.cursor/skills/*
"""
from __future__ import annotations

import argparse
import filecmp
import os
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REPO_SKILLS = REPO_ROOT / "skills"

HOME = Path.home()
GLOBAL_SCOPES = [
    HOME / ".agents" / "skills",
    HOME / ".claude" / "skills",
    HOME / ".codex" / "skills",
    HOME / ".gemini" / "skills",
    HOME / ".cursor" / "skills",
]

DEV_ROOT = HOME / "Developer"
LOCAL_SCOPE_SUFFIXES = [
    Path(".agents") / "skills",
    Path(".claude") / "skills",
    Path(".cursor") / "skills",
]


def list_skills(scope: Path) -> list[str]:
    """A skill is a directory containing SKILL.md. Hidden dirs (e.g. Codex's
    `.system/` namespace) and runtime containers (`codex-primary-runtime/`) are
    skipped — they hold nested skills that aren't ours to manage."""
    if not scope.is_dir():
        return []
    return sorted(
        p.name
        for p in scope.iterdir()
        if p.is_dir() and not p.name.startswith(".") and (p / "SKILL.md").is_file()
    )


def dirs_identical(a: Path, b: Path) -> bool:
    """Recursively compare two directories ignoring feedback.log."""
    cmp = filecmp.dircmp(a, b, ignore=["feedback.log", ".DS_Store"])
    if cmp.left_only or cmp.right_only or cmp.diff_files or cmp.funny_files:
        return False
    for sub in cmp.common_dirs:
        if not dirs_identical(a / sub, b / sub):
            return False
    return True


def discover_local_scopes() -> list[Path]:
    if not DEV_ROOT.is_dir():
        return []
    scopes: list[Path] = []
    for repo in sorted(DEV_ROOT.iterdir()):
        if not repo.is_dir() or not (repo / ".git").exists():
            continue
        if repo.resolve() == REPO_ROOT.resolve():
            continue
        for suffix in LOCAL_SCOPE_SUFFIXES:
            candidate = repo / suffix
            if candidate.is_dir():
                scopes.append(candidate)
    return scopes


def cmd_scan(args: argparse.Namespace) -> int:
    repo_skills = set(list_skills(REPO_SKILLS))
    print(f"Repo skills ({REPO_SKILLS}): {len(repo_skills)}")

    # 1. Orphans: global skills not in repo
    orphans: dict[str, list[Path]] = {}
    for scope in GLOBAL_SCOPES:
        for name in list_skills(scope):
            if name not in repo_skills:
                orphans.setdefault(name, []).append(scope / name)

    print()
    print("== Orphans (global, not in repo) ==")
    if not orphans:
        print("  none")
    else:
        for name in sorted(orphans):
            print(f"  {name}")
            for path in orphans[name]:
                print(f"    - {path}")

    # 2. Content drift: same skill in multiple global scopes with different content
    print()
    print("== Content drift (global copies differ) ==")
    drift_found = False
    all_global_names = {n for scope in GLOBAL_SCOPES for n in list_skills(scope)}
    for name in sorted(all_global_names):
        paths = [scope / name for scope in GLOBAL_SCOPES if (scope / name).is_dir()]
        if len(paths) < 2:
            continue
        base = paths[0]
        diverged = [p for p in paths[1:] if not dirs_identical(base, p)]
        if diverged:
            drift_found = True
            print(f"  {name}")
            print(f"    base: {base}")
            for p in diverged:
                print(f"    differs: {p}")
    if not drift_found:
        print("  none")

    # 3. Repo-vs-global drift: repo skill content differs from installed global copy
    print()
    print("== Repo/global drift (installed copy differs from repo) ==")
    repo_drift = False
    for name in sorted(repo_skills):
        repo_path = REPO_SKILLS / name
        for scope in GLOBAL_SCOPES:
            installed = scope / name
            if not installed.is_dir():
                continue
            if not dirs_identical(repo_path, installed):
                repo_drift = True
                print(f"  {name}: repo vs {installed}")
    if not repo_drift:
        print("  none")

    # 4. Local repo shadows: a skill lives in a project's .claude/skills AND globally
    print()
    print("== Local shadows (project-scoped skills that also exist globally) ==")
    local_scopes = discover_local_scopes()
    shadows_found = False
    global_names_by_scope = {scope: set(list_skills(scope)) for scope in GLOBAL_SCOPES}
    for local in local_scopes:
        for name in list_skills(local):
            shadowing = [scope for scope, names in global_names_by_scope.items() if name in names]
            if shadowing:
                shadows_found = True
                print(f"  {name}")
                print(f"    local:  {local / name}")
                for scope in shadowing:
                    print(f"    global: {scope / name}")
    if not shadows_found:
        print("  none")

    # Exit code: 0 if clean, 1 if anything worth attention
    dirty = bool(orphans) or drift_found or repo_drift or shadows_found
    return 1 if (dirty and args.strict) else 0


def cmd_prune(args: argparse.Namespace) -> int:
    repo_skills = set(list_skills(REPO_SKILLS))
    if not repo_skills:
        print(f"Refusing to prune: repo skills dir {REPO_SKILLS} is empty or missing.", file=sys.stderr)
        return 2

    targets: list[Path] = []
    for scope in GLOBAL_SCOPES:
        for name in list_skills(scope):
            if name not in repo_skills:
                targets.append(scope / name)

    if not targets:
        print("No orphans to prune.")
        return 0

    verb = "Would remove" if not args.execute else "Removing"
    print(f"{verb} {len(targets)} orphan skill director{'y' if len(targets) == 1 else 'ies'}:")
    for path in targets:
        print(f"  - {path}")

    if not args.execute:
        print()
        print("Dry run. Re-run with --execute to delete.")
        return 0

    for path in targets:
        # Hard safety: never touch anything outside the known global scope roots.
        resolved = path.resolve()
        if not any(resolved.is_relative_to(scope.resolve()) for scope in GLOBAL_SCOPES if scope.exists()):
            print(f"Skipping {path}: not inside a known global scope", file=sys.stderr)
            continue
        shutil.rmtree(path)
        print(f"  removed {path}")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_scan = sub.add_parser("scan", help="Report orphans, duplicates, and drift")
    p_scan.add_argument("--strict", action="store_true", help="Exit 1 if any issue is found")
    p_scan.set_defaults(func=cmd_scan)

    p_prune = sub.add_parser("prune", help="Remove global skills not in repo skills/")
    p_prune.add_argument("--execute", action="store_true", help="Actually delete (default is dry-run)")
    p_prune.set_defaults(func=cmd_prune)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
