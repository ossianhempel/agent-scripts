# Clawdis Debugging Reference

## Update from git (cloned repo)

```bash
cd /app
git pull origin main
pnpm install
pnpm build
```

Then restart the gateway (or container).

### Optional: auto-update on container restart

```bash
#!/bin/bash
cd /app
git pull origin main
pnpm install
pnpm build
pnpm clawdis gateway
```

## Config migration after pulling latest

If you `git pull` latest, run:

```bash
pnpm clawdis doctor
```

This migrates old config to the new format.

## Upstream FAQ

FAQ: https://github.com/steipete/clawdis/blob/main/docs/faq.md

## FAQ highlights (abridged)

- Data lives in `~/.clawdis/` (config, credentials, sessions).
- Workspace path is separate via `agent.workspace`.
- “Unauthorized” health check errors usually mean no config; run `pnpm clawdis onboard`.
- `pnpm clawdis doctor` validates config/skills and can restart the gateway.
- Start fresh: back up, then move `~/.clawdis` to Trash; rerun onboarding + login.
- Build errors on `main`: pull latest, `pnpm install`, run doctor; check issues or temporarily pin an older commit if needed.
- If the gateway won’t start, check `/tmp/clawdis/clawdis-YYYY-MM-DD.log` for port conflicts, missing API keys, or JSON5 syntax issues.
- If a process keeps restarting after you stop it, look for a supervisor (systemd/pm2) and disable that service.
- If WhatsApp logs out, re-auth with `pnpm clawdis login`.

### Start fresh (explicit steps)

1. Back up `~/.clawdis`.
2. Remove state (prefer `trash ~/.clawdis`).
3. Re-run setup:
   ```bash
   pnpm clawdis onboard
   pnpm clawdis login
   ```

### Build errors on main

1. Pull latest + install:
   ```bash
   git pull origin main
   pnpm install
   ```
2. Run:
   ```bash
   pnpm clawdis doctor
   ```
3. If still failing, check GitHub issues; optionally roll back to a known-good commit.

## First-time setup vs reconfigure

- First-time guided setup:
  ```bash
  pnpm clawdis onboard
  ```
- Already set up, need to change settings:
  ```bash
  pnpm clawdis configure
  ```

`configure` is best for:
- Adding providers (MiniMax, OpenRouter, etc.)
- Changing models
- Setting up Discord/Telegram/WhatsApp
- Tweaking heartbeat settings

No need to hand-edit JSON unless you want to.

## Heartbeats

- Gateway sends a `HEARTBEAT` message to the agent at the configured interval (example: every 15m).
- Agent wakes up, checks if anything needs attention.
- If nothing: replies `HEARTBEAT_OK` (silent; you do not see it).
- If something: sends a user-visible message (email arrived, calendar reminder, etc.).
- Logs should show heartbeat activity every interval.

### If heartbeats are not firing

1. Confirm gateway is running continuously (heartbeats require the gateway to stay up).
2. Check config:
   ```bash
   cat ~/.clawdis/clawdis.json | grep -A5 heartbeat
   ```
3. Check logs:
   ```bash
   cat /tmp/clawdis/clawdis-$(date +%Y-%m-%d).log | grep -i heartbeat
   ```

## Cron jobs

- Scheduled tasks run at specific times.
- Managed by the gateway, which triggers the agent with your message.

Check status:

```bash
pnpm clawdis cron list
```

### If cron jobs are not firing

1. Confirm gateway is running continuously.
2. Check config:
   ```bash
   cat ~/.clawdis/clawdis.json | grep -A5 cron
   ```
3. Check logs:
   ```bash
   cat /tmp/clawdis/clawdis-$(date +%Y-%m-%d).log | grep -i cron
   ```

## Skills snapshot refresh (no gateway restart)

`/reset` sets `isFirstTurnInSession = true`, which calls `buildWorkspaceSkillsSnapshot()` fresh from disk. No gateway restart needed.
