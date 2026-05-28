#!/usr/bin/env python3
"""Generic RevenueCat API v2 request helper for agent skills.

Features:
- Reads RC_API_KEY and optional RC_PROJECT_ID / RC_BASE_URL from the environment
- Replaces {project_id} placeholders in paths
- Accepts repeated --query key=value pairs
- Accepts JSON from inline text, @file, or stdin
- Follows list pagination when --all-pages is enabled
- Pretty-prints JSON responses
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


DEFAULT_BASE_URL = "https://api.revenuecat.com/v2"


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def parse_kv(values: list[str]) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for item in values:
        if "=" not in item:
            raise SystemExit(f"Expected KEY=VALUE, got: {item}")
        key, value = item.split("=", 1)
        parsed[key] = value
    return parsed


def load_json_arg(value: str | None) -> Any:
    if value is None:
        return None
    if value == "-":
        return json.load(sys.stdin)
    if value.startswith("@"):
        with open(value[1:], "r", encoding="utf-8") as handle:
            return json.load(handle)
    return json.loads(value)


def resolve_url(base_url: str, path: str, project_id: str | None) -> str:
    path = path.strip()
    if "{project_id}" in path:
        if not project_id:
            raise SystemExit("Path contains {project_id} but RC_PROJECT_ID/--project-id was not provided.")
        path = path.replace("{project_id}", urllib.parse.quote(project_id, safe=""))
    if path.startswith("http://") or path.startswith("https://"):
        return path
    if not path.startswith("/"):
        path = "/" + path
    return base_url.rstrip("/") + path


def json_headers(api_key: str, extra: dict[str, str]) -> dict[str, str]:
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
    }
    headers.update(extra)
    return headers


def fetch_once(
    method: str,
    url: str,
    headers: dict[str, str],
    body: Any,
    timeout: int,
) -> tuple[int, Any, dict[str, str]]:
    data: bytes | None = None
    request_headers = dict(headers)

    if body is not None:
        data = json.dumps(body).encode("utf-8")
        request_headers.setdefault("Content-Type", "application/json")

    request = urllib.request.Request(url=url, method=method.upper(), data=data, headers=request_headers)

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read()
            content_type = response.headers.get("Content-Type", "")
            if raw and "application/json" in content_type:
                payload = json.loads(raw.decode("utf-8"))
            elif raw:
                payload = raw.decode("utf-8", errors="replace")
            else:
                payload = None
            return response.status, payload, dict(response.headers.items())
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        content_type = exc.headers.get("Content-Type", "")
        if raw and "application/json" in content_type:
            payload = json.loads(raw.decode("utf-8"))
            eprint(json.dumps(payload, indent=2, sort_keys=True))
        elif raw:
            eprint(raw.decode("utf-8", errors="replace"))
        else:
            eprint(f"HTTP {exc.code} with no response body")
        raise SystemExit(exc.code or 1) from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"Network error: {exc}") from exc


def maybe_paginate(
    method: str,
    first_url: str,
    headers: dict[str, str],
    body: Any,
    timeout: int,
    all_pages: bool,
) -> Any:
    status, payload, _ = fetch_once(method, first_url, headers, body, timeout)
    if status < 200 or status >= 300:
        raise SystemExit(status)

    if not all_pages or not isinstance(payload, dict) or payload.get("object") != "list":
        return payload

    items = list(payload.get("items", []))
    next_page = payload.get("next_page")
    page_count = 1

    parsed = urllib.parse.urlparse(first_url)
    origin = f"{parsed.scheme}://{parsed.netloc}"

    while next_page:
        next_url = urllib.parse.urljoin(origin, next_page)
        _, next_payload, _ = fetch_once("GET", next_url, headers, None, timeout)
        if not isinstance(next_payload, dict) or next_payload.get("object") != "list":
            break
        items.extend(next_payload.get("items", []))
        next_page = next_payload.get("next_page")
        page_count += 1
        if page_count > 100:
            raise SystemExit("Refusing to fetch more than 100 pages. Narrow your query.")

    payload["items"] = items
    payload["next_page"] = next_page
    payload["_pages_fetched"] = page_count
    return payload


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="RevenueCat API v2 helper")
    parser.add_argument("method", help="HTTP method, e.g. GET, POST, DELETE")
    parser.add_argument("path", help="API path like /projects/{project_id}/products or a full URL")
    parser.add_argument("--project-id", default=os.environ.get("RC_PROJECT_ID"))
    parser.add_argument("--api-key", default=os.environ.get("RC_API_KEY"))
    parser.add_argument("--base-url", default=os.environ.get("RC_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument("--query", action="append", default=[], help="Query parameter in key=value form")
    parser.add_argument("--header", action="append", default=[], help="Extra HTTP header in Key=Value form")
    parser.add_argument("--json", dest="json_input", help="Inline JSON, @file.json, or - for stdin")
    parser.add_argument("--all-pages", action="store_true", help="Follow list pagination")
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--compact", action="store_true", help="Emit compact JSON")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not args.api_key:
        raise SystemExit("Missing RC_API_KEY or --api-key")

    url = resolve_url(args.base_url, args.path, args.project_id)
    query = parse_kv(args.query)
    if query:
        split = urllib.parse.urlsplit(url)
        existing = urllib.parse.parse_qsl(split.query, keep_blank_values=True)
        merged = dict(existing)
        merged.update(query)
        url = urllib.parse.urlunsplit(
            (split.scheme, split.netloc, split.path, urllib.parse.urlencode(merged, doseq=True), split.fragment)
        )

    headers = json_headers(args.api_key, parse_kv(args.header))
    body = load_json_arg(args.json_input)

    payload = maybe_paginate(args.method, url, headers, body, args.timeout, args.all_pages)

    if isinstance(payload, (dict, list)):
        if args.compact:
            print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
        else:
            print(json.dumps(payload, indent=2, sort_keys=True))
    elif payload is None:
        print("null")
    else:
        print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
