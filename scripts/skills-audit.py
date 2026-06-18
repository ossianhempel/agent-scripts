#!/usr/bin/env python3
"""
Audit skills across repo and global installations.

Subcommands:
  scan   - Report orphans (global skills missing from repo) and duplicates
           (same skill installed in multiple locations with content drift or
           local-repo shadows). Also reports profile assignments, profile
           drift, and profile orphans for project-scoped profile installs.
  prune  - Remove global skills that are not in the repo's skills/ folder.
           Dry-run by default; pass --execute to actually delete. Pass
           --profiles to additionally prune profile orphans from assigned
           project scopes (skills installed in a project that are not in its
           assigned profile(s)).

Repo scopes (authoritative source):
  <repo>/skills/*                  - synced to all global installs
  <repo>/local-skills/*            - kept in this repo only, never synced
  <repo>/profiles/<name>/          - project MCP bundles (mcp.json); no skills

Global scopes (managed — `prune` may delete orphans here):
  ~/.agents/skills/*   ~/.claude/skills/*
  ~/.codex/skills/*    ~/.gemini/skills/*
  ~/.cursor/skills/*   ~/.gemini/antigravity-cli/skills/*

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
LOCAL_REPO_SKILLS = REPO_ROOT / "local-skills"
PROFILES_ROOT = REPO_ROOT / "profiles"
PROFILES_MANIFEST = REPO_ROOT / "profile-assignments.json"

# Project scopes a profile installs into, relative to the project root.
PROFILE_PROJECT_SUFFIXES = [
    Path(".agents") / "skills",
    Path(".claude") / "skills",
]

HOME = Path.home()
GLOBAL_SCOPES = [
    HOME / ".agents" / "skills",
    HOME / ".claude" / "skills",
    HOME / ".codex" / "skills",
    HOME / ".gemini" / "skills",
    HOME / ".cursor" / "skills",
    HOME / ".gemini" / "antigravity-cli" / "skills",
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
    """Recursively compare two directories."""
    cmp = filecmp.dircmp(a, b, ignore=[".DS_Store"])
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


def list_profiles() -> list[str]:
    """Profile names: directories under profiles/ that carry MCP or plugin config."""
    if not PROFILES_ROOT.is_dir():
        return []
    return sorted(
        p.name
        for p in PROFILES_ROOT.iterdir()
        if p.is_dir()
        and not p.name.startswith(".")
        and (
            (p / "mcp.json").is_file()
            or (p / "plugins.json").is_file()
            or (p / "skills").is_dir()
        )
    )


def profile_skills(profile: str) -> list[str]:
    """Legacy: profile skill dirs are retired; skills live in skills/ globally."""
    skills_dir = PROFILES_ROOT / profile / "skills"
    if not skills_dir.is_dir():
        return []
    return list_skills(skills_dir)


def profile_union_skills(profiles: list[str]) -> set[str]:
    names: set[str] = set()
    for profile in profiles:
        names.update(profile_skills(profile))
    return names


MANAGED_MANIFEST = ".agent-scripts-managed"


def managed_names_in(scope: Path) -> set[str]:
    """Skill names the profile sync installed into this project scope, read from
    the scope's `.agent-scripts-managed` manifest. This is the authoritative
    record of what the sync owns: only names in here are eligible for prune;
    anything on disk but NOT listed is project-authored content the profile
    tooling must never touch. (Profile skills install as real-directory copies,
    not symlinks — the manifest is how we tell ours apart from the project's.)"""
    manifest = scope / MANAGED_MANIFEST
    if not manifest.is_file():
        return set()
    try:
        return {
            line.strip()
            for line in manifest.read_text(encoding="utf-8").splitlines()
            if line.strip()
        }
    except OSError:
        return set()


def load_assignments() -> list[tuple[Path, list[str]]]:
    """Parse profile-assignments.json into (resolved project path, [profiles]).
    Project keys support a leading ~."""
    if not PROFILES_MANIFEST.is_file():
        return []
    import json

    try:
        data = json.loads(PROFILES_MANIFEST.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"Failed to parse {PROFILES_MANIFEST}: {exc}", file=sys.stderr)
        return []

    assignments = data.get("assignments", data)
    if not isinstance(assignments, dict):
        return []

    result: list[tuple[Path, list[str]]] = []
    for project, profiles in assignments.items():
        if not isinstance(project, str) or project.startswith("_"):
            continue
        if isinstance(profiles, str):
            profiles = [profiles]
        if not isinstance(profiles, list):
            continue
        names = [p for p in profiles if isinstance(p, str) and p]
        if names:
            result.append((Path(project).expanduser(), names))
    return result


def cmd_scan(args: argparse.Namespace) -> int:
    repo_skills = set(list_skills(REPO_SKILLS))
    local_only = set(list_skills(LOCAL_REPO_SKILLS))
    known_repo = repo_skills | local_only
    print(f"Repo skills ({REPO_SKILLS}): {len(repo_skills)}")
    print(f"Local-only skills ({LOCAL_REPO_SKILLS}): {len(local_only)}")

    # Surface local-only skills that leaked into global installs — they should
    # never be synced. Always informational; not counted as drift.
    leaked: dict[str, list[Path]] = {}
    for scope in GLOBAL_SCOPES:
        for name in list_skills(scope):
            if name in local_only:
                leaked.setdefault(name, []).append(scope / name)
    if leaked:
        print()
        print("== Local-only skills present in global installs (should be removed) ==")
        for name in sorted(leaked):
            print(f"  {name}")
            for path in leaked[name]:
                print(f"    - {path}")

    # 1. Orphans: global skills not in repo
    orphans: dict[str, list[Path]] = {}
    for scope in GLOBAL_SCOPES:
        for name in list_skills(scope):
            if name not in known_repo:
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

    profile_issues = scan_profiles()

    # Exit code: 0 if clean, 1 if anything worth attention
    dirty = bool(orphans) or drift_found or repo_drift or shadows_found or profile_issues
    return 1 if (dirty and args.strict) else 0


def scan_profiles() -> bool:
    """Report profile inventory, assignments, name collisions, drift, and
    project-scoped orphans. Returns True if anything needs attention."""
    profiles = list_profiles()
    print()
    print("== Profiles ==")
    if not profiles:
        print("  none")
        return False
    for profile in profiles:
        has_mcp = (PROFILES_ROOT / profile / "mcp.json").is_file()
        skill_count = len(profile_skills(profile))
        suffix = "mcp" if has_mcp else "legacy skills"
        print(f"  {profile} ({suffix}{f', {skill_count} skills' if skill_count else ''})")

    # Name collisions: legacy profile skills that share a name with a global skill.
    global_skills = set(list_skills(REPO_SKILLS))
    print()
    print("== Profile/global name collisions ==")
    collision = False
    for profile in profiles:
        clashes = sorted(set(profile_skills(profile)) & global_skills)
        for name in clashes:
            collision = True
            print(f"  {name}: in profile '{profile}' AND global skills/")
    if not collision:
        print("  none")

    assignments = load_assignments()
    print()
    print("== Profile assignments ==")
    if not assignments:
        print("  none")
    else:
        for project, names in assignments:
            exists = "" if project.is_dir() else "  (project not found)"
            print(f"  {project} -> {', '.join(names)}{exists}")

    # Drift: legacy profile skill copies in projects vs repo skills/.
    print()
    print("== Profile drift (installed project copy differs from repo source) ==")
    drift = False
    for project, names in assignments:
        if not project.is_dir():
            continue
        sources = {
            name: (REPO_SKILLS / name)
            for profile in names
            for name in profile_skills(profile)
            if (REPO_SKILLS / name).is_dir()
        }
        installed_root = project / ".agents" / "skills"
        for name, source in sources.items():
            installed = installed_root / name
            if not installed.is_dir():
                continue
            if not dirs_identical(source.resolve(), installed):
                drift = True
                print(f"  {name}: {source} vs {installed}")
    if not drift:
        print("  none")

    orphan_lines: list[str] = []
    native_lines: list[str] = []
    for project, names in assignments:
        expected = profile_union_skills(names)
        for suffix in PROFILE_PROJECT_SUFFIXES:
            scope = project / suffix
            if not scope.is_dir():
                continue
            owned = managed_names_in(scope)
            for installed in list_skills(scope):
                if installed in expected:
                    continue
                path = scope / installed
                # The .agent-scripts-managed manifest is the source of truth for
                # what the sync installed here. A skill listed there but no longer
                # in the assigned profiles is a prunable orphan; anything NOT in
                # the manifest is project-authored content — never prune it, even
                # if the name happens to collide with a repo skill.
                if installed in owned:
                    orphan_lines.append(f"  {installed}: {path} (not in {', '.join(names)})")
                else:
                    native_lines.append(f"  {installed}: {path}")
            # Broken symlinks left by the old symlink-install model are never
            # legitimate content; flag them for cleanup.
            for entry in scope.iterdir():
                if entry.is_symlink() and not entry.exists():
                    orphan_lines.append(f"  {entry.name}: {entry} (dangling symlink)")

    print()
    print("== Profile orphans (managed by another profile — prunable with prune --profiles) ==")
    print("\n".join(orphan_lines) if orphan_lines else "  none")

    print()
    print("== Project-local skills not in any repo profile (left untouched) ==")
    print("\n".join(native_lines) if native_lines else "  none")

    return collision or drift or bool(orphan_lines)


def cmd_prune(args: argparse.Namespace) -> int:
    repo_skills = set(list_skills(REPO_SKILLS))
    if not repo_skills:
        print(f"Refusing to prune: repo skills dir {REPO_SKILLS} is empty or missing.", file=sys.stderr)
        return 2

    rc = prune_global(args)
    if getattr(args, "profiles", False):
        print()
        prune_profiles(args)
    return rc


def prune_global(args: argparse.Namespace) -> int:
    repo_skills = set(list_skills(REPO_SKILLS))
    local_only = set(list_skills(LOCAL_REPO_SKILLS))
    known_repo = repo_skills | local_only

    targets: list[Path] = []
    for scope in GLOBAL_SCOPES:
        for name in list_skills(scope):
            if name not in known_repo:
                targets.append(scope / name)
        # Also pick up dangling symlinks — left over when a prune removed the
        # target dir in one scope but not the symlink that pointed at it from
        # another scope.
        if scope.is_dir():
            for entry in scope.iterdir():
                if entry.is_symlink() and not entry.exists():
                    targets.append(entry)

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
        # Compare parents, not the path itself — a dangling symlink's resolve()
        # would point outside the scope and trip the guard.
        parent_resolved = path.parent.resolve()
        if not any(parent_resolved.is_relative_to(scope.resolve()) for scope in GLOBAL_SCOPES if scope.exists()):
            print(f"Skipping {path}: not inside a known global scope", file=sys.stderr)
            continue
        try:
            if path.is_symlink():
                path.unlink()
            else:
                shutil.rmtree(path)
            print(f"  removed {path}")
        except FileNotFoundError:
            # Likely a dangling symlink whose target we already removed earlier
            # in this run. Unlink the symlink itself.
            if path.is_symlink():
                path.unlink()
                print(f"  removed dangling symlink {path}")
            else:
                print(f"  already gone {path}")

    return 0


def prune_profiles(args: argparse.Namespace) -> int:
    """Remove profile orphans from assigned project scopes: skills installed in a
    project's .agents/skills or .claude/skills that are not in the project's
    assigned profile(s), plus dangling .claude symlinks. Only ever deletes inside
    an assigned project's own profile scopes."""
    assignments = load_assignments()
    if not assignments:
        print("No profile assignments — nothing to prune.")
        return 0

    # Allowed deletion roots: only the profile scopes of assigned projects.
    allowed_roots = [
        (project / suffix).resolve()
        for project, _ in assignments
        for suffix in PROFILE_PROJECT_SUFFIXES
        if (project / suffix).is_dir()
    ]

    targets: list[Path] = []
    for project, names in assignments:
        expected = profile_union_skills(names)
        for suffix in PROFILE_PROJECT_SUFFIXES:
            scope = project / suffix
            if not scope.is_dir():
                continue
            owned = managed_names_in(scope)
            for installed in list_skills(scope):
                # Only prune skills this scope's .agent-scripts-managed manifest
                # records as ours. A skill not in the manifest is project-authored
                # content — never touch it, even on a name collision. This is the
                # safety guarantee documented in the module docstring and AGENTS.md.
                if installed not in expected and installed in owned:
                    targets.append(scope / installed)
            # Broken symlinks (old-model leftovers) are never legitimate content.
            for entry in scope.iterdir():
                if entry.is_symlink() and not entry.exists():
                    targets.append(entry)

    if not targets:
        print("No profile orphans to prune.")
        return 0

    verb = "Would remove" if not args.execute else "Removing"
    print(f"{verb} {len(targets)} profile orphan(s):")
    for path in targets:
        print(f"  - {path}")

    if not args.execute:
        print()
        print("Dry run. Re-run with --execute to delete.")
        return 0

    for path in targets:
        # Hard safety: only inside an assigned project's profile scope.
        parent_resolved = path.parent.resolve()
        if not any(parent_resolved == root for root in allowed_roots):
            print(f"Skipping {path}: not inside an assigned profile scope", file=sys.stderr)
            continue
        try:
            if path.is_symlink():
                path.unlink()
            else:
                shutil.rmtree(path)
            print(f"  removed {path}")
        except FileNotFoundError:
            if path.is_symlink():
                path.unlink()
                print(f"  removed dangling symlink {path}")
            else:
                print(f"  already gone {path}")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_scan = sub.add_parser("scan", help="Report orphans, duplicates, and drift")
    p_scan.add_argument("--strict", action="store_true", help="Exit 1 if any issue is found")
    p_scan.set_defaults(func=cmd_scan)

    p_prune = sub.add_parser("prune", help="Remove global skills not in repo skills/")
    p_prune.add_argument("--execute", action="store_true", help="Actually delete (default is dry-run)")
    p_prune.add_argument(
        "--profiles",
        action="store_true",
        help="Also prune profile orphans from assigned project scopes",
    )
    p_prune.set_defaults(func=cmd_prune)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
