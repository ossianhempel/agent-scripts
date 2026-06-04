#!/usr/bin/env python3
"""
Generate native subagent files for each AI harness from one canonical source.

Canonical source lives in  <repo>/subagents/<name>.md  — a Claude-Code-flavoured
Markdown file (YAML frontmatter + body-as-system-prompt). This is the single
source of truth; every harness gets a *transformed* copy, because the formats
genuinely differ (Codex is TOML; some tools put the prompt in a field, not the
body). See docs/subagents.md for the why.

v1 targets:
  - Claude Code : ~/.claude/agents/<name>.md     (near-verbatim)
  - Codex       : ~/.codex/agents/<name>.toml    (TOML; body -> developer_instructions)

Two axes don't port literally and are abstracted in the canonical frontmatter:
  - access: read-only | edit | full   -> expanded into each tool's permission model
  - model:  inherit | <id>            -> 'inherit' maps to each tool's inherit/omit

Pruning is MANIFEST-BASED: the generator only ever deletes files it previously
wrote (tracked in a .agent-scripts-manifest in each target dir). Hand-authored
agents in those dirs are never touched.

Usage:
  scripts/gen-subagents.py [--claude-agents-dir DIR] [--codex-agents-dir DIR]
                           [--repo DIR] [--dry-run] [--quiet]
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

MANIFEST = ".agent-scripts-manifest"

# access enum -> per-tool permission expansion
ACCESS = {
    "read-only": {
        "claude_tools": ["Read", "Grep", "Glob"],
        "codex_sandbox": "read-only",
    },
    "edit": {
        "claude_tools": None,  # None => omit (inherit all tools)
        "codex_sandbox": "workspace-write",
    },
    "full": {
        "claude_tools": None,
        "codex_sandbox": "danger-full-access",
    },
}
DEFAULT_ACCESS = "edit"


# --- tiny frontmatter parser (restricted YAML; we own the format) -------------

def parse_agent(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise ValueError(f"{path.name}: missing YAML frontmatter")
    _, fm, body = text.split("---", 2)
    meta: dict[str, str] = {}
    for line in fm.strip().splitlines():
        line = line.rstrip()
        if not line or line.lstrip().startswith("#") or ":" not in line:
            continue
        key, _, val = line.partition(":")
        meta[key.strip()] = val.strip()
    name = meta.get("name") or path.stem
    desc = meta.get("description", "").strip()
    access = meta.get("access", DEFAULT_ACCESS).strip()
    if access not in ACCESS:
        raise ValueError(f"{path.name}: unknown access '{access}' (use {', '.join(ACCESS)})")
    return {
        "name": name,
        "description": desc,
        "access": access,
        "model": meta.get("model", "inherit").strip(),
        "body": body.strip() + "\n",
    }


# --- emitters -----------------------------------------------------------------

def emit_claude(a: dict) -> str:
    lines = ["---", f"name: {a['name']}", f"description: {a['description']}"]
    if a["model"] and a["model"] != "":
        lines.append(f"model: {a['model']}")
    tools = ACCESS[a["access"]]["claude_tools"]
    if tools:
        lines.append(f"tools: {', '.join(tools)}")
    lines += ["---", "", a["body"]]
    return "\n".join(lines)


def _toml_basic(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emit_codex(a: dict) -> str:
    lines = [
        f'name = "{_toml_basic(a["name"])}"',
        f'description = "{_toml_basic(a["description"])}"',
        f'sandbox_mode = "{ACCESS[a["access"]]["codex_sandbox"]}"',
    ]
    # 'inherit' => omit model so Codex uses the parent session model.
    if a["model"] and a["model"] != "inherit":
        lines.append(f'model = "{_toml_basic(a["model"])}"')
    # Codex puts the system prompt in a field, not the body. Triple-quote it;
    # escape any stray triple-quote run in the prompt to stay valid TOML.
    body = a["body"].replace('"""', '\\"\\"\\"')
    lines.append(f'developer_instructions = """\n{body}"""')
    return "\n".join(lines) + "\n"


# --- write + manifest-based prune ---------------------------------------------

def sync_target(agents: list[dict], out_dir: Path, suffix: str, emit, label: str,
                dry_run: bool, quiet: bool) -> None:
    def say(msg: str) -> None:
        if not quiet:
            print(f"  {msg}")

    print(f"== Subagents -> {label} ({out_dir}) ==")
    wanted = {f"{a['name']}{suffix}": emit(a) for a in agents}

    manifest_path = out_dir / MANIFEST
    prev = []
    if manifest_path.exists():
        prev = [ln.strip() for ln in manifest_path.read_text().splitlines() if ln.strip()]

    # Prune: files we wrote before that are no longer wanted.
    for stale in sorted(set(prev) - set(wanted)):
        p = out_dir / stale
        if p.exists():
            say(f"prune {stale}")
            if not dry_run:
                p.unlink()

    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    for fname, content in sorted(wanted.items()):
        dest = out_dir / fname
        action = "update" if dest.exists() else "create"
        say(f"{action} {fname}")
        if not dry_run:
            dest.write_text(content, encoding="utf-8")

    if not dry_run:
        manifest_path.write_text("\n".join(sorted(wanted)) + "\n", encoding="utf-8")


def main() -> int:
    repo_default = Path(__file__).resolve().parent.parent
    home = Path(os.path.expanduser("~"))
    ap = argparse.ArgumentParser(description="Generate native subagents from canonical source.")
    ap.add_argument("--repo", type=Path, default=repo_default)
    ap.add_argument("--claude-agents-dir", type=Path, default=home / ".claude" / "agents")
    ap.add_argument("--codex-agents-dir", type=Path, default=home / ".codex" / "agents")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    src = args.repo / "subagents"
    if not src.is_dir():
        print(f"No {src} — nothing to generate.")
        return 0

    agents = []
    for path in sorted(src.glob("*.md")):
        try:
            agents.append(parse_agent(path))
        except ValueError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 1

    if not agents:
        print(f"No *.md subagents in {src}.")
        return 0

    sync_target(agents, args.claude_agents_dir, ".md", emit_claude,
                "Claude Code", args.dry_run, args.quiet)
    sync_target(agents, args.codex_agents_dir, ".toml", emit_codex,
                "Codex", args.dry_run, args.quiet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
