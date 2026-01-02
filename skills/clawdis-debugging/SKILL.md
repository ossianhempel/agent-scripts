---
name: clawdis-debugging
description: Debug and fix Clawdis app, gateway, or agent issues in ../clawdis or container /app. Use when troubleshooting updates from git, config setup or migration (onboard/configure/doctor), heartbeats or cron not firing, gateway restarts, or skills/config changes not being picked up.
---

# Clawdis Debugging

## Overview

Use this skill to diagnose and fix Clawdis runtime, gateway, config, heartbeat, cron, and skill-refresh issues.

## Workflow

1. Identify environment and repo location (local ../clawdis vs container /app).
2. Update from git and rebuild when code may be stale; run `pnpm clawdis doctor` after pulling latest to migrate config.
3. Use `pnpm clawdis onboard` for first-time setup, or `pnpm clawdis configure` to change providers/models/integrations/heartbeat settings; avoid hand-editing JSON unless the user asks.
4. If heartbeats or cron are not firing, confirm the gateway is running continuously, then check config and logs and list cron status.
5. If running node gateway, restart it after rebuild if updates are not picked up.
6. If skills/config changes are not reflected, use `/reset` to refresh the skills snapshot; no gateway restart needed.

## FAQ highlights

- Data lives in `~/.clawdis/` (config, credentials, sessions); workspace path is separate via `agent.workspace`.
- “Unauthorized” health check errors usually mean no config; run `pnpm clawdis onboard`.
- `pnpm clawdis doctor` checks config/skills/gateway and can restart the gateway.
- If the gateway won’t start, inspect `/tmp/clawdis/clawdis-YYYY-MM-DD.log` and check port conflicts, API keys, or JSON5 syntax.
- Start fresh: back up `~/.clawdis`, remove state, then rerun `pnpm clawdis onboard` and `pnpm clawdis login`.
- Build errors on `main`: pull latest, `pnpm install`, run doctor, then check issues or temporarily pin an older commit.
- If WhatsApp logs out, re-auth with `pnpm clawdis login`.
- For auto-restart, run the gateway under a supervisor (pm2 or launchd); see references.
- Port 18789 can be owned by the macOS app relay; don’t run the app relay and a dev gateway at the same time.

## References

- Read `references/clawdis-troubleshooting.md` for exact commands, logs, and known behaviors.
- Upstream FAQ: `https://github.com/steipete/clawdis/blob/main/docs/faq.md`
