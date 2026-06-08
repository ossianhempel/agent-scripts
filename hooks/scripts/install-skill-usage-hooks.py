#!/usr/bin/env python3
"""Install skill-usage hooks into Claude Code and Codex config layers."""
from __future__ import annotations

import json
import os
import sys
from copy import deepcopy

HERE = os.path.dirname(os.path.abspath(__file__))
TRACK_SCRIPT = os.path.join(HERE, "track-skill-usage.py")
AUTO_PULL = os.path.join(HERE, "git-auto-pull-current-branch.sh")


def load_json(path: str) -> dict:
    if not os.path.exists(path):
        return {}
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except json.JSONDecodeError:
        return {}


def save_json(path: str, data: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


def command_hook(command: str, *, timeout: int, status: str | None = None) -> dict:
    hook = {"type": "command", "command": command, "timeout": timeout}
    if status:
        hook["statusMessage"] = status
    return hook


def replace_hooks_by_command(hooks: list, command: str) -> list:
    kept = []
    for item in hooks:
        if not isinstance(item, dict):
            continue
        nested = item.get("hooks")
        if not isinstance(nested, list):
            kept.append(item)
            continue
        filtered = [
            h
            for h in nested
            if not (isinstance(h, dict) and h.get("command") == command)
        ]
        if filtered:
            updated = deepcopy(item)
            updated["hooks"] = filtered
            kept.append(updated)
    return kept


def upsert_matcher_group(
    groups: list,
    *,
    matcher: str | None,
    hook: dict,
) -> None:
    for item in groups:
        if not isinstance(item, dict):
            continue
        if matcher is None:
            if "matcher" not in item:
                nested = item.setdefault("hooks", [])
                if isinstance(nested, list) and hook not in nested:
                    nested.append(hook)
                return
        elif item.get("matcher") == matcher:
            nested = item.setdefault("hooks", [])
            if isinstance(nested, list) and hook not in nested:
                nested.append(hook)
            return
    entry: dict = {"hooks": [hook]}
    if matcher is not None:
        entry["matcher"] = matcher
    groups.append(entry)


def install_codex_hooks(codex_home: str) -> None:
    hooks_path = os.path.join(codex_home, "hooks.json")
    data = load_json(hooks_path)
    hooks_root = data.setdefault("hooks", {})
    if not isinstance(hooks_root, dict):
        hooks_root = {}
        data["hooks"] = hooks_root

    track_codex = f"{TRACK_SCRIPT} codex"
    track_transcript = f"{TRACK_SCRIPT} codex-transcript"
    auto_pull = AUTO_PULL

    for event in ("PostToolUse", "Stop", "SessionStart"):
        groups = hooks_root.get(event)
        if not isinstance(groups, list):
            groups = []
            hooks_root[event] = groups
        for command in (track_codex, track_transcript, auto_pull):
            groups[:] = replace_hooks_by_command(groups, command)

    post_tool = hooks_root["PostToolUse"]
    upsert_matcher_group(
        post_tool,
        matcher="Bash",
        hook=command_hook(
            track_codex,
            timeout=10,
            status="Logging skill usage",
        ),
    )

    stop = hooks_root["Stop"]
    upsert_matcher_group(
        stop,
        matcher=None,
        hook=command_hook(
            track_transcript,
            timeout=30,
            status="Logging Codex skill usage",
        ),
    )

    session_start = hooks_root["SessionStart"]
    upsert_matcher_group(
        session_start,
        matcher=None,
        hook=command_hook(
            auto_pull,
            timeout=30,
            status="Pulling latest remote branch when safe",
        ),
    )

    save_json(hooks_path, data)


def install_claude_hooks(claude_home: str) -> None:
    settings_path = os.path.join(claude_home, "settings.json")
    data = load_json(settings_path)
    hooks_root = data.setdefault("hooks", {})
    if not isinstance(hooks_root, dict):
        hooks_root = {}
        data["hooks"] = hooks_root

    track_claude = f"{TRACK_SCRIPT} claude"
    auto_pull = AUTO_PULL

    for event in ("PostToolUse", "SessionStart"):
        groups = hooks_root.get(event)
        if not isinstance(groups, list):
            groups = []
            hooks_root[event] = groups
        for command in (track_claude, auto_pull):
            groups[:] = replace_hooks_by_command(groups, command)

    post_tool = hooks_root["PostToolUse"]
    upsert_matcher_group(
        post_tool,
        matcher="Skill",
        hook=command_hook(track_claude, timeout=10),
    )

    session_start = hooks_root["SessionStart"]
    upsert_matcher_group(
        session_start,
        matcher=None,
        hook=command_hook(auto_pull, timeout=30),
    )

    save_json(settings_path, data)


def main() -> int:
    claude_home = os.environ.get("CLAUDE_HOME") or os.path.expanduser("~/.claude")
    codex_home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
    install_codex_hooks(codex_home)
    install_claude_hooks(claude_home)
    print(f"Installed skill-usage hooks in {codex_home}/hooks.json and {claude_home}/settings.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
