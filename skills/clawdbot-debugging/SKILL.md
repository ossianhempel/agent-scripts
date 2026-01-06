---
name: clawdbot-debugging
description: Debug and fix Clawdbot app, gateway, or agent issues in ../clawdbot or container /app. Use when troubleshooting updates from git, config setup or migration (onboard/configure/doctor), heartbeats or cron not firing, gateway restarts, or skills/config changes not being picked up.
---

# Clawdbot Debugging

## Overview

Use this skill to diagnose and fix Clawdbot runtime, gateway, config, heartbeat, cron, and skill-refresh issues.

## Workflow

1. Identify environment and repo location (local ../clawdbot vs container /app).
2. Update from git and rebuild when code may be stale; update the global `clawdbot` install if the repo changed; run `pnpm clawdbot doctor` after pulling latest to migrate config.
3. Use `pnpm clawdbot onboard` for first-time setup, or `pnpm clawdbot configure` to change providers/models/integrations/heartbeat settings; avoid hand-editing JSON unless the user asks.
4. If heartbeats or cron are not firing, confirm the gateway is running continuously, then check config and logs and list cron status.
5. If running node gateway, restart it after rebuild if updates are not picked up.
6. If skills/config changes are not reflected, use `/reset` to refresh the skills snapshot; no gateway restart needed.

## FAQ highlights

- Data lives in `~/.clawdbot/` (config, credentials, sessions); workspace path is separate via `agent.workspace`.
- “Unauthorized” health check errors usually mean no config; run `pnpm clawdbot onboard`.
- `pnpm clawdbot doctor` checks config/skills/gateway and can restart the gateway.
- If the gateway won’t start, inspect `/tmp/clawdbot/clawdbot-YYYY-MM-DD.log` and check port conflicts, API keys, or JSON5 syntax.
- Start fresh: back up `~/.clawdbot`, remove state, then rerun `pnpm clawdbot onboard` and `pnpm clawdbot login`.
- Build errors on `main`: pull latest, `pnpm install`, run doctor, then check issues or temporarily pin an older commit.
- If WhatsApp logs out, re-auth with `pnpm clawdbot login`.
- Unknown model errors usually mean missing provider prefix (defaults to `anthropic`) or the model is absent from `models.json` / `allowedModels`.
- Gemini "Corrupted thought signature" (Cloud Code Assist or Antigravity) usually clears with `/new` or `/think off`; see reference for details.
- After model swaps, mismatched thinking/tool semantics can cause odd errors; `/new` and `/think off` are the fastest resets.
- For auto-restart, run the gateway under a supervisor (pm2 or launchd); see references.
- Port 18789 can be owned by the macOS app relay; don’t run the app relay and a dev gateway at the same time.

## References

- Read `references/clawdbot-troubleshooting.md` for exact commands, logs, and known behaviors.
- Upstream FAQ: `https://github.com/clawdbot/clawdbot/blob/main/docs/faq.md`
