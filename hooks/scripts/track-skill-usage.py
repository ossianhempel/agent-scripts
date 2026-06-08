#!/usr/bin/env python3
"""PostToolUse / Stop hook: log skill usage to a local JSONL file.

Wired into both Claude Code and Codex:
  - Claude: PostToolUse on the `Skill` tool.
  - Codex: PostToolUse on `Bash` when simple shell hooks fire, plus a `Stop`
    hook that scans the session transcript. The transcript path is required
    because Codex's `unified_exec` / `exec_command` shell path does not trigger
    PostToolUse yet (see Codex hooks docs).

Reads the hook payload from stdin, decides whether the tool call touched a
skill, and appends one event per skill to
~/.local/share/agent-skill-usage/events.jsonl.

Skill detection is agent-aware because the two runtimes expose skills very
differently:
  - Claude Code invokes skills through a dedicated `Skill` tool whose input is
    {"skill": "<name>"}. That is an exact, unambiguous invocation signal.
  - Codex has no skill tool; it loads a skill by reading the file at
    .../skills/<name>/SKILL.md via shell. For live capture we scan session
    transcripts for those reads.

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
from datetime import datetime, timedelta, timezone
from glob import glob

SCHEMA = 1

# Matches the canonical skill file path used by every runtime's skill root,
# e.g. /Users/x/.claude/skills/copywriter/SKILL.md -> "copywriter".
SKILL_PATH_RE = re.compile(r"/skills/([^/\"]+)/SKILL\.md")

CODEX_SHELL_TOOLS = frozenset({"exec_command", "shell_command", "Bash", "bash"})


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


def skill_names_from_text(text: str) -> list[str]:
    names: list[str] = []
    for match in SKILL_PATH_RE.findall(text):
        if match not in names:
            names.append(match)
    return names


def source_for_skill_count(count: int) -> str:
    if count == 0:
        return ""
    if count == 1:
        return "skill_md"
    return "skill_scan"


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

    # Codex PostToolUse (Bash only today): command lives in tool_input.command.
    # Also scan the raw payload for skill paths as a fallback.
    names = skill_names_from_text(raw)
    if not names and tool in CODEX_SHELL_TOOLS:
        tool_input = payload.get("tool_input") or payload.get("input") or {}
        if isinstance(tool_input, dict):
            cmd = tool_input.get("command") or tool_input.get("cmd")
            if isinstance(cmd, str) and cmd:
                names = skill_names_from_text(cmd)
    if not names:
        return [], ""
    return names, source_for_skill_count(len(names))


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


def load_existing_keys(path: str) -> set[tuple[str, str, str]]:
    """Return dedupe keys already logged: (session_id, call_id, skill)."""
    keys: set[tuple[str, str, str]] = set()
    if not os.path.exists(path):
        return keys
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except Exception:
                    continue
                if not isinstance(event, dict):
                    continue
                session_id = event.get("session_id") or ""
                call_id = event.get("call_id") or ""
                skill = event.get("skill") or ""
                if session_id and call_id and skill:
                    keys.add((session_id, call_id, skill))
    except Exception:
        return keys
    return keys


def append_events(events: list[dict]) -> int:
    if not events:
        return 0
    path = data_file()
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "a", encoding="utf-8") as fh:
            for event in events:
                fh.write(json.dumps(event, ensure_ascii=False) + "\n")
        return len(events)
    except Exception:
        return 0


def build_event(
    *,
    agent: str,
    skill: str,
    source: str,
    cwd: str,
    session_id: str,
    tool: str,
    call_id: str = "",
    ts: str | None = None,
) -> dict:
    repo, repo_path = git_repo(cwd)
    if ts is None:
        ts = (
            datetime.now(timezone.utc)
            .isoformat(timespec="seconds")
            .replace("+00:00", "Z")
        )
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
    if call_id:
        event["call_id"] = call_id
    return event


def parse_codex_arguments(arguments: str) -> tuple[str, str]:
    """Return (cmd, workdir) from a Codex exec_command arguments JSON string."""
    cmd = ""
    workdir = ""
    try:
        data = json.loads(arguments)
        if isinstance(data, dict):
            raw_cmd = data.get("cmd") or data.get("command")
            if isinstance(raw_cmd, str):
                cmd = raw_cmd
            raw_workdir = data.get("workdir") or data.get("cwd")
            if isinstance(raw_workdir, str):
                workdir = raw_workdir
    except Exception:
        pass
    return cmd, workdir


def session_meta_from_transcript(transcript_path: str) -> tuple[str, str]:
    """Return (session_id, default_cwd) from the first session_meta line."""
    session_id = ""
    cwd = ""
    try:
        with open(transcript_path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                if row.get("type") != "session_meta":
                    continue
                payload = row.get("payload") or {}
                if isinstance(payload, dict):
                    session_id = str(payload.get("id") or "")
                    cwd = str(payload.get("cwd") or "")
                break
    except Exception:
        return "", ""
    return session_id, cwd


def events_from_codex_transcript(
    transcript_path: str,
    *,
    session_id: str = "",
    default_cwd: str = "",
    existing_keys: set[tuple[str, str, str]] | None = None,
) -> list[dict]:
    """Scan a Codex rollout JSONL for shell reads of SKILL.md files."""
    if not transcript_path or not os.path.isfile(transcript_path):
        return []

    if existing_keys is None:
        existing_keys = load_existing_keys(data_file())

    if not session_id or not default_cwd:
        meta_id, meta_cwd = session_meta_from_transcript(transcript_path)
        session_id = session_id or meta_id
        default_cwd = default_cwd or meta_cwd

    events: list[dict] = []
    try:
        with open(transcript_path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                if row.get("type") != "response_item":
                    continue
                payload = row.get("payload") or {}
                if not isinstance(payload, dict):
                    continue
                if payload.get("type") != "function_call":
                    continue
                tool = str(payload.get("name") or "")
                if tool not in CODEX_SHELL_TOOLS:
                    continue
                arguments = payload.get("arguments")
                if not isinstance(arguments, str):
                    continue
                cmd, workdir = parse_codex_arguments(arguments)
                skills = skill_names_from_text(cmd) or skill_names_from_text(arguments)
                if not skills:
                    continue
                source = source_for_skill_count(len(skills))
                call_id = str(payload.get("call_id") or "")
                cwd = workdir or default_cwd
                ts = str(row.get("timestamp") or "")
                if ts and not ts.endswith("Z"):
                    ts = ts.replace("+00:00", "Z")
                for skill in skills:
                    key = (session_id, call_id, skill)
                    if session_id and call_id and key in existing_keys:
                        continue
                    events.append(
                        build_event(
                            agent="codex",
                            skill=skill,
                            source=source,
                            cwd=cwd,
                            session_id=session_id,
                            tool=tool,
                            call_id=call_id,
                            ts=ts or None,
                        )
                    )
                    if session_id and call_id:
                        existing_keys.add(key)
    except Exception:
        return events
    return events


def codex_transcript_mode() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}

    transcript_path = first_str(payload, "transcript_path")
    session_id = first_str(payload, "session_id", "sessionId")
    cwd = first_str(payload, "cwd", "workdir", "working_directory")
    events = events_from_codex_transcript(
        transcript_path,
        session_id=session_id,
        default_cwd=cwd,
    )
    append_events(events)
    return 0


def codex_backfill_mode(since_days: int) -> int:
    codex_home = os.environ.get("CODEX_HOME") or os.path.join(
        os.path.expanduser("~"), ".codex"
    )
    patterns = [
        os.path.join(codex_home, "sessions", "**", "*.jsonl"),
        os.path.join(codex_home, "archived_sessions", "*.jsonl"),
    ]
    cutoff = None
    if since_days > 0:
        cutoff = datetime.now(timezone.utc) - timedelta(days=since_days)

    existing_keys = load_existing_keys(data_file())
    all_events: list[dict] = []
    seen_paths: set[str] = set()

    for pattern in patterns:
        for transcript_path in glob(pattern, recursive=True):
            if transcript_path in seen_paths:
                continue
            seen_paths.add(transcript_path)
            if cutoff is not None:
                try:
                    mtime = datetime.fromtimestamp(
                        os.path.getmtime(transcript_path), tz=timezone.utc
                    )
                except Exception:
                    continue
                if mtime < cutoff:
                    continue
            all_events.extend(
                events_from_codex_transcript(
                    transcript_path,
                    existing_keys=existing_keys,
                )
            )

    append_events(all_events)
    if "--json" in sys.argv:
        print(json.dumps({"added": len(all_events), "file": data_file()}))
    return 0


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "unknown"

    if mode == "codex-transcript":
        return codex_transcript_mode()
    if mode == "codex-backfill":
        since_days = 30
        if len(sys.argv) > 2:
            raw_since = sys.argv[2]
            if raw_since.endswith("d") and raw_since[:-1].isdigit():
                since_days = int(raw_since[:-1])
            elif raw_since.isdigit():
                since_days = int(raw_since)
        return codex_backfill_mode(since_days)

    agent = mode
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}

    skills, source = detect_skills(payload, raw)
    if not skills:
        return 0

    cwd = first_str(payload, "cwd", "workdir", "working_directory") or os.getcwd()
    session_id = first_str(payload, "session_id", "sessionId", "conversation_id")
    tool = first_str(payload, "tool_name", "tool", "name")
    call_id = first_str(payload, "tool_use_id", "toolUseId", "call_id")
    events = [
        build_event(
            agent=agent,
            skill=skill,
            source=source,
            cwd=cwd,
            session_id=session_id,
            tool=tool,
            call_id=call_id,
        )
        for skill in skills
    ]
    append_events(events)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
