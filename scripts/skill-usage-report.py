#!/usr/bin/env python3
"""Report on skill usage collected by hooks/scripts/track-skill-usage.py.

Answers "which skills do I actually use, per repo/agent, over time?" from the
local JSONL event log. Stdlib only.

Examples:
  skill-usage-report.py                 # last 7 days, all agents/repos
  skill-usage-report.py --since 30d     # last 30 days
  skill-usage-report.py --agent codex   # one agent
  skill-usage-report.py --repo gainslog # one repo
  skill-usage-report.py --by repo       # group by repo instead of skill
  skill-usage-report.py --include-scans # count catalog scans too
  skill-usage-report.py --include-authoring  # count agent-scripts edits too
  skill-usage-report.py --json          # raw aggregate as JSON
"""
import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

# Skill loads observed while working IN agent-scripts are almost always
# authoring/editing the skills, not using them — excluded unless asked.
AUTHORING_REPO = "agent-scripts"


def data_file() -> str:
    override = os.environ.get("AGENT_SKILL_USAGE_FILE")
    if override:
        return override
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "share"
    )
    return os.path.join(base, "agent-skill-usage", "events.jsonl")


def parse_since(spec: str) -> datetime | None:
    if not spec or spec.lower() in ("all", "0"):
        return None
    m = re.fullmatch(r"(\d+)\s*([dhw])", spec.strip().lower())
    if not m:
        raise SystemExit(f"bad --since '{spec}'; use e.g. 7d, 24h, 2w, or 'all'")
    n, unit = int(m.group(1)), m.group(2)
    delta = {"h": timedelta(hours=n), "d": timedelta(days=n), "w": timedelta(weeks=n)}[unit]
    return datetime.now(timezone.utc) - delta


def load_events(path: str):
    if not os.path.exists(path):
        return []
    events = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except Exception:
                continue
    return events


def event_ts(ev: dict) -> datetime | None:
    raw = ev.get("ts")
    if not isinstance(raw, str):
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Report skill usage from the local event log.")
    ap.add_argument("--since", default="7d", help="window: 7d, 24h, 2w, or 'all' (default 7d)")
    ap.add_argument("--agent", help="filter to one agent (claude, codex)")
    ap.add_argument("--repo", help="filter to one repo (basename)")
    ap.add_argument("--by", choices=["skill", "repo", "agent"], default="skill", help="grouping (default skill)")
    ap.add_argument("--include-scans", action="store_true", help="include catalog scans (source=skill_scan)")
    ap.add_argument("--include-authoring", action="store_true", help=f"include loads in the {AUTHORING_REPO} repo")
    ap.add_argument("--json", action="store_true", help="emit aggregate as JSON")
    ap.add_argument("--file", help="override event log path")
    args = ap.parse_args()

    path = args.file or data_file()
    since = parse_since(args.since)
    events = load_events(path)

    kept = []
    for ev in events:
        if not args.include_scans and ev.get("source") == "skill_scan":
            continue
        if not args.include_authoring and ev.get("repo") == AUTHORING_REPO:
            continue
        if args.agent and ev.get("agent") != args.agent:
            continue
        if args.repo and ev.get("repo") != args.repo:
            continue
        if since is not None:
            ts = event_ts(ev)
            if ts is None or ts < since:
                continue
        kept.append(ev)

    if not kept:
        where = path if os.path.exists(path) else f"{path} (not created yet)"
        print(f"No skill-usage events match. Log: {where}")
        if events:
            print(f"({len(events)} total events on file; widen --since or pass --include-scans/--include-authoring)")
        return 0

    key = args.by
    counts = Counter(ev.get(key) or "?" for ev in kept)
    # Per-group agent breakdown for the default skill view.
    breakdown = defaultdict(Counter)
    for ev in kept:
        breakdown[ev.get(key) or "?"][ev.get("agent") or "?"] += 1

    if args.json:
        out = {
            "since": args.since,
            "total": len(kept),
            "by": key,
            "counts": dict(counts.most_common()),
            "agent_breakdown": {k: dict(v) for k, v in breakdown.items()},
        }
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0

    window = "all time" if since is None else f"last {args.since}"
    print(f"Skill usage — {window} — {len(kept)} invocations, {len(counts)} {key}s")
    print()
    width = max((len(str(k)) for k, _ in counts.most_common()), default=5)
    for name, n in counts.most_common():
        agents = breakdown[name]
        detail = ", ".join(f"{a}:{c}" for a, c in agents.most_common())
        print(f"  {str(name).ljust(width)}  {str(n).rjust(4)}   ({detail})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
