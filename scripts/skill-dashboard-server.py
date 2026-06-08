#!/usr/bin/env python3
"""Local-only skill-usage dashboard.

Serves a single-page dashboard on localhost that reads the skill-usage event log
(written by hooks/scripts/track-skill-usage.py) live on every request. Nothing is
committed or sent anywhere — it binds to 127.0.0.1 and reads ~/.local/share only.

The dashboard's Refresh button (and auto-refresh) just re-hits /api/data, so the
view always reflects the current file with no terminal commands during use.

Run via `bin/skill-dashboard` or by double-clicking "Skill Dashboard.command".
Stdlib only.
"""
import http.server
import json
import os
import socketserver
import subprocess
import sys
import threading
import webbrowser

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
HTML_PATH = os.path.join(REPO, "dashboard", "index.html")
TRACK_SCRIPT = os.path.join(REPO, "hooks", "scripts", "track-skill-usage.py")


def data_file() -> str:
    override = os.environ.get("AGENT_SKILL_USAGE_FILE")
    if override:
        return override
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "share"
    )
    return os.path.join(base, "agent-skill-usage", "events.jsonl")


def backfill_codex_events() -> None:
    """Best-effort Codex transcript backfill before serving the dashboard."""
    if not os.path.isfile(TRACK_SCRIPT):
        return
    try:
        subprocess.run(
            [sys.executable, TRACK_SCRIPT, "codex-backfill", "30d"],
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except Exception:
        return


def load_events() -> list:
    backfill_codex_events()
    path = data_file()
    events = []
    if os.path.exists(path):
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


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):  # quiet
        pass

    def _send(self, code, body: bytes, ctype: str):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/api/data"):
            events = load_events()
            payload = {
                "file": data_file(),
                "count": len(events),
                "events": events,
            }
            self._send(200, json.dumps(payload).encode("utf-8"), "application/json")
            return
        if self.path in ("/", "/index.html"):
            try:
                with open(HTML_PATH, "rb") as fh:
                    body = fh.read()
            except FileNotFoundError:
                self._send(500, b"dashboard/index.html missing", "text/plain")
                return
            self._send(200, body, "text/html; charset=utf-8")
            return
        self._send(404, b"not found", "text/plain")


def open_browser(url: str) -> None:
    if sys.platform == "darwin":
        try:
            subprocess.run(["open", url], check=True)
            return
        except Exception:
            pass
    webbrowser.open(url)


def main() -> int:
    # Bind to a free port on localhost only.
    with socketserver.TCPServer(("127.0.0.1", 0), Handler) as httpd:
        port = httpd.server_address[1]
        url = f"http://127.0.0.1:{port}/"
        print(f"\n  Skill-usage dashboard → {url}", flush=True)
        print(f"  Reading: {data_file()}", flush=True)
        print("  Press Ctrl-C (or close this window) to stop.\n", flush=True)
        # Open the browser shortly after the server starts accepting. On macOS,
        # use the native `open` so the page lands in a normal window/tab of the
        # user's default browser — webbrowser.open can spawn an odd transient
        # Chrome window on some setups.
        if "--no-open" not in sys.argv:
            threading.Timer(0.4, lambda: open_browser(url)).start()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n  Dashboard stopped.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
