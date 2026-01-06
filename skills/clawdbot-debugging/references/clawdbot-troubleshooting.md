# Clawdbot Debugging Reference

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
pnpm clawdbot gateway
```

## Config migration after pulling latest

If you `git pull` latest, run:

```bash
pnpm clawdbot doctor
```

This migrates old config to the new format.

## Upstream FAQ

FAQ: `https://github.com/clawdbot/clawdbot/blob/main/docs/faq.md`

## FAQ highlights (abridged)

- Data lives in `~/.clawdbot/` (config, credentials, sessions).
- Workspace path is separate via `agent.workspace`.
- “Unauthorized” health check errors usually mean no config; run `pnpm clawdbot onboard`.
- `pnpm clawdbot doctor` validates config/skills and can restart the gateway.
- Start fresh: back up, then move `~/.clawdbot` to Trash; rerun onboarding + login.
- Build errors on `main`: pull latest, `pnpm install`, run doctor; check issues or temporarily pin an older commit if needed.
- If the gateway won’t start, check `/tmp/clawdbot/clawdbot-YYYY-MM-DD.log` for port conflicts, missing API keys, or JSON5 syntax issues.
- If a process keeps restarting after you stop it, look for a supervisor (systemd/pm2) and disable that service.
- If WhatsApp logs out, re-auth with `pnpm clawdbot login`.
- Node gateway may need a restart after rebuilds; stop the running process and rerun `pnpm clawdbot gateway`, or restart your supervisor.
- Port 18789 conflicts often mean the macOS app relay is running; pick one gateway (app relay or dev/pm2) at a time.

## Auto-restart options (macOS)

### pm2 (recommended for simplicity)

```bash
npm i -g pm2
pm2 start /Users/ossianhempel/Library/pnpm/pnpm --name clawdbot-gateway --cwd /Users/ossianhempel/Developer/clawdbot --interpreter bash -- gateway:watch
pm2 save
```

Auto-start on login/reboot (requires sudo):

```bash
sudo env PATH=$PATH:/Users/ossianhempel/.nvm/versions/node/v22.16.0/bin /Users/ossianhempel/.nvm/versions/node/v22.16.0/lib/node_modules/pm2/bin/pm2 startup launchd -u ossianhempel --hp /Users/ossianhempel
```

Useful:

```bash
pm2 status
pm2 logs clawdbot-gateway
pm2 restart clawdbot-gateway
```

### launchd (native)

Create a LaunchAgent that runs `pnpm gateway:watch` in `/Users/ossianhempel/Developer/clawdbot` with:

- `RunAtLoad = true`
- `KeepAlive = true`
- `StandardOutPath` and `StandardErrorPath` to a log file

## App relay vs dev gateway

- **App relay** lives inside `Clawdbot.app/Contents/Resources/Relay/clawdbot` and owns port 18789.
- **Dev gateway** is `pnpm gateway[:watch]` from the repo, often supervised by pm2/launchd.
- If the dev gateway logs “attach failed” or health check errors, the app relay may be holding the port or be stuck.
- Resolution: quit the app relay or stop pm2/launchd, then restart the chosen gateway.

### Start fresh (explicit steps)

1. Back up `~/.clawdbot`.
2. Remove state (prefer `trash ~/.clawdbot`).
3. Re-run setup:
   ```bash
   pnpm clawdbot onboard
   pnpm clawdbot login
   ```

### Build errors on main

1. Pull latest + install:
   ```bash
   git pull origin main
   pnpm install
   ```
2. Run:
   ```bash
   pnpm clawdbot doctor
   ```
3. If still failing, check GitHub issues; optionally roll back to a known-good commit.

## First-time setup vs reconfigure

- First-time guided setup:
  ```bash
  pnpm clawdbot onboard
  ```
- Already set up, need to change settings:
  ```bash
  pnpm clawdbot configure
  ```

`configure` is best for:
- Adding providers (MiniMax, OpenRouter, etc.)
- Changing models
- Setting up Discord/Telegram/WhatsApp
- Tweaking heartbeat settings

No need to hand-edit JSON unless you want to.

## Model switching errors (unknown model / wrong provider)

Symptoms:
- `Unknown model: anthropic/<model>`
- `/model <name>` fails even though the model exists

Root cause:
- Provider omitted → Clawdbot defaults to `anthropic/...`.
- Model not in the catalog (`~/.clawdbot/agent/models.json`) or blocked by
  `agent.allowedModels`.

Fix checklist:
1. List available models from the running gateway:
   ```bash
   clawdbot gateway call models.list
   ```
2. Use the full `provider/model` in `/model`:
   ```text
   /model google-antigravity/<exact-model-id>
   ```
3. Add an alias (and allowlist if set):
   ```json5
   {
     agent: {
       allowedModels: ["google-antigravity/<exact-model-id>"],
       modelAliases: { geminiFlash: "google-antigravity/<exact-model-id>" }
     }
   }
   ```

Notes:
- If you only provide a model name, Clawdbot assumes `anthropic`.
- If you set `agent.allowedModels`, the model must be listed there.

## Gemini "Corrupted thought signature" (Cloud Code Assist / Antigravity)

Symptoms:
- `Cloud Code Assist API error (400): "Corrupted thought signature"`

Likely cause:
- Stale session state or a bad thought/think payload after a model switch.
- Can happen on both Cloud Code Assist and Antigravity Gemini.

Fixes:
1. Reset the session: `/new`.
2. Temporarily disable thinking: `/think off`.
3. If needed, set default thinking off:
   ```json5
   { agent: { thinkingDefault: "off" } }
   ```

## Model swap compatibility tips (general)

Symptoms:
- Weird provider errors right after switching models.
- Tool-call ordering or “thinking”/reasoning errors.

Fixes:
1. Reset the session: `/new`.
2. Disable thinking for the session: `/think off`.
3. If the model still fails, switch to a known-good model, then back.
4. For persistent issues, set `thinkingDefault: "off"` in config and only enable per-session.

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
   cat ~/.clawdbot/clawdbot.json | grep -A5 heartbeat
   ```
3. Check logs:
   ```bash
   cat /tmp/clawdbot/clawdbot-$(date +%Y-%m-%d).log | grep -i heartbeat
   ```

## Cron jobs

- Scheduled tasks run at specific times.
- Managed by the gateway, which triggers the agent with your message.

Check status:

```bash
pnpm clawdbot cron list
```

### If cron jobs are not firing

1. Confirm gateway is running continuously.
2. Check config:
   ```bash
   cat ~/.clawdbot/clawdbot.json | grep -A5 cron
   ```
3. Check logs:
   ```bash
   cat /tmp/clawdbot/clawdbot-$(date +%Y-%m-%d).log | grep -i cron
   ```

## Skills snapshot refresh (no gateway restart)

`/reset` sets `isFirstTurnInSession = true`, which calls `buildWorkspaceSkillsSnapshot()` fresh from disk. No gateway restart needed.
