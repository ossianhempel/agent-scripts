#!/usr/bin/env python3
"""PostToolUse hook: log skill usage to a local JSONL file.

Wired into both Claude Code and Codex as a PostToolUse hook. Reads the hook
payload from stdin, decides whether the tool call touched a skill, and appends
one event per skill to ~/.local/share/agent-skill-usage/events.jsonl.

Skill detection is agent-aware because the two runtimes expose skills very
differently:
  - Claude Code invokes skills through a dedicated `Skill` tool whose input is
    {"skill": "<name>"}. That is an exact, unambiguous invocation signal.
  - Codex has no skill tool; it loads a skill by reading the file at
    .../skills/<name>/SKILL.md via exec_command. So we scan the raw payload for
    that path pattern.

A single tool call that touches MANY SKILL.md files is a catalog scan (the agent
listing what's available), not real usage of each one — those are tagged
`skill_scan` so the report can exclude them by default.

Design rules: never raise, never block the agent, always exit 0. Parsing or git
failures degrade to a partial event or a silent skip, never a crash.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

SCHEMA = 1

# Matches the canonical skill file path used by every runtime's skill root,
# e.g. /Users/x/.claude/skills/copywriter/SKILL.md -> "copywriter".
SKILL_PATH_RE = re.compile(r"/skills/([^/\"]+)/SKILL\.md")


def data_file() -> str:
    override = os.environ.get("AGENT_SKILL_USAGE_FILE")
    if override:
        return override
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "share"
    )
    return os.path.join(base, "agent-skill-usage", "events.jsonl")


def first_str(payload: dict, *keys: str) -> str:
    """Return the first key present in payload whose value is a string."""
    for k in keys:
        v = payload.get(k)
        if isinstance(v, str) and v:
            return v
    return ""


def detect_skills(payload: dict, raw: str) -> tuple[list[str], str]:
    """Return (skill_names, source). Empty list means 'not a skill event'."""
    tool = first_str(payload, "tool_name", "tool", "name")

    # Claude: explicit Skill tool. tool_input may be nested under a few keys.
    if tool == "Skill":
        tool_input = payload.get("tool_input") or payload.get("input") or {}
        if isinstance(tool_input, dict):
            name = tool_input.get("skill")
            if isinstance(name, str) and name:
                return [name], "skill_tool"

    # Codex (and Claude SKILL.md reads): scan the raw payload for skill paths.
    names = []
    for m in SKILL_PATH_RE.findall(raw):
        if m not in names:
            names.append(m)
    if not names:
        return [], ""
    # One skill touched = a real load; many at once = a catalog scan.
    source = "skill_md" if len(names) == 1 else "skill_scan"
    return names, source


def git_repo(cwd: str) -> tuple[str, str]:
    """Return (repo_basename, repo_path) for cwd, or ('','') on failure."""
    if not cwd or not os.path.isdir(cwd):
        return "", ""
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception:
        return "", ""
    if out.returncode != 0:
        return "", ""
    path = out.stdout.strip()
    return (os.path.basename(path), path) if path else ("", "")


def main() -> int:
    agent = sys.argv[1] if len(sys.argv) > 1 else "unknown"

    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}

    skills, source = detect_skills(payload, raw)
    if not skills:
        return 0  # skills-only: drop everything else

    cwd = first_str(payload, "cwd", "workdir", "working_directory") or os.getcwd()
    repo, repo_path = git_repo(cwd)
    session_id = first_str(payload, "session_id", "sessionId", "conversation_id")
    tool = first_str(payload, "tool_name", "tool", "name")
    ts = datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00", "Z"
    )

    path = data_file()
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "a", encoding="utf-8") as fh:
            for skill in skills:
                event = {
                    "ts": ts,
                    "schema": SCHEMA,
                    "agent": agent,
                    "skill": skill,
                    "source": source,
                    "repo": repo,
                    "repo_path": repo_path,
                    "cwd": cwd,
                    "session_id": session_id,
                    "tool": tool,
                }
                fh.write(json.dumps(event, ensure_ascii=False) + "\n")
    except Exception:
        return 0  # never let logging failures surface to the agent

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
