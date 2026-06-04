---
summary: Operational checklist for the local OpenClaw/Clawdbot service, especially Telegram not responding.
read_when:
  - OpenClaw, Clawdbot, Telegram, Discord, or WhatsApp bot messages stop responding.
  - Checking or restarting the local ai.openclaw.gateway launch agent.
  - Investigating queued OpenClaw channel messages or stale gateway logs.
---

# OpenClaw Operations

OpenClaw is the local personal assistant service. Keep upstream source code
vanilla; recover the local service through launchd, config, logs, and state.

## Current macOS service

- Launch agent: `ai.openclaw.gateway`
- Plist: `~/Library/LaunchAgents/ai.openclaw.gateway.plist`
- State: `~/.openclaw`
- Legacy alias: `~/.clawdbot` may be a symlink to `~/.openclaw`
- Live stdout log: `~/Library/Logs/openclaw/gateway.log`
- Detailed dated log: `/tmp/openclaw/openclaw-YYYY-MM-DD.log`

The older `scripts/update-clawdbot.sh` helper is not part of this repo. Do not
assume it exists.

## Telegram Not Responding

First confirm whether Telegram delivered the message to the local service:

```bash
find ~/.openclaw/telegram/ingress-spool-default -maxdepth 1 -type f -print
```

If new files are present there, Telegram delivery worked. The problem is local
OpenClaw processing: the gateway or Telegram channel did not drain the ingress
spool and produce a reply.

Check the launch agent:

```bash
launchctl print gui/$(id -u)/ai.openclaw.gateway
```

Useful fields:

- `state = running` means launchd has a process.
- `runs = ...` shows restart churn.
- `last exit code` or `last terminating signal` helps distinguish clean restarts
  from crashes or manual termination.
- The `stdout path` should point to `~/Library/Logs/openclaw/gateway.log`.

Check the live gateway log:

```bash
tail -n 160 ~/Library/Logs/openclaw/gateway.log
```

Healthy startup includes `gateway ready`, followed by channel provider starts.
Telegram may start tens of seconds after `gateway ready` while plugins and auth
state warm up. If the log says the health monitor is repeatedly restarting
`telegram:default`, or the spool files stay in place after startup, Telegram is
not being processed even if the gateway itself is running.

Restart the gateway:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

Then verify:

```bash
tail -n 120 ~/Library/Logs/openclaw/gateway.log
find ~/.openclaw/telegram/ingress-spool-default -maxdepth 1 -type f -print
```

If Telegram responds after this, the issue was a stuck local channel/gateway
state, not a Telegram outage or allowlist problem.

## Related Symptoms

- `~/.openclaw/logs/gateway.log` can be stale. Prefer
  `~/Library/Logs/openclaw/gateway.log` for the launch-agent service.
- iMessage errors about `~/Library/Messages/chat.db` permissions are separate
  from Telegram unless they coincide with gateway-wide restart churn.
- WhatsApp `401 Unauthorized` means the WhatsApp session is logged out; it is
  separate from Telegram delivery.

## Do Not

- Do not edit OpenClaw source code for local recovery.
- Do not move or delete queued spool files unless explicitly choosing to discard
  messages.
- Do not put bot tokens or secrets into docs, tickets, or final reports.
