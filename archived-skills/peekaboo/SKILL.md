---
name: peekaboo
description: Capture, inspect, and automate macOS UI with the Peekaboo CLI. Use this skill whenever the user asks to inspect the screen, take or analyze screenshots, control apps/windows/menus, click/type/scroll in native macOS apps, verify a visual state outside the browser, or explicitly mentions peekaboo.sh/Peekaboo.
homepage: https://peekaboo.boo
metadata:
  openclaw:
    emoji: "👀"
    os:
      - darwin
    requires:
      bins:
        - peekaboo
    install:
      - id: brew
        kind: brew
        formula: steipete/tap/peekaboo
        bins:
          - peekaboo
        label: Install Peekaboo via Homebrew
---

# Peekaboo

Use `peekaboo` for macOS UI capture and automation: screenshots, annotated UI
maps, app/window/menu control, keyboard/mouse input, and visual verification.

Prefer browser automation tools for normal web-app testing. Use Peekaboo when
you need the actual macOS UI, native apps, desktop windows, menus, dialogs, or a
screen-level visual check.

## First step

Verify the CLI exists and permissions are healthy:

```bash
peekaboo --version
peekaboo permissions
```

If it is missing, install it:

```bash
brew install steipete/tap/peekaboo
```

Peekaboo needs macOS Screen Recording permission for capture and Accessibility
permission for input automation.

## Reliable inspect -> act flow

Capture an annotated UI map before interacting:

```bash
peekaboo see --annotate --path /tmp/peekaboo-see.png
```

Then target element IDs or coordinates from the latest snapshot:

```bash
peekaboo click --on B1
peekaboo type "Hello" --return
peekaboo press escape
```

Use `--json` for scripts:

```bash
peekaboo list apps --json
peekaboo list windows --app Safari --json
```

## Common commands

```bash
peekaboo image --mode screen --path /tmp/screen.png
peekaboo image --app Safari --window-title "Dashboard" --analyze "Summarize the visible KPIs"
peekaboo app launch Safari --open https://example.com
peekaboo window focus --app Safari
peekaboo menu click --app Safari --item "New Window"
peekaboo hotkey --keys "cmd,shift,t"
peekaboo scroll --direction down --amount 6 --smooth
```

## Targeting

Most interaction commands support:

- App/window: `--app`, `--pid`, `--window-title`, `--window-id`,
  `--window-index`
- Snapshot targeting: `--snapshot`
- Element/coords: `--on`, `--id`, `--coords x,y`
- Focus control: `--no-auto-focus`, `--space-switch`,
  `--bring-to-current-space`

## Diagnostics

When capture or interaction fails:

```bash
peekaboo bridge status --json
peekaboo permissions status --json
peekaboo image --mode screen --json
```

Do not use destructive UI actions unless the user explicitly asked for them.
