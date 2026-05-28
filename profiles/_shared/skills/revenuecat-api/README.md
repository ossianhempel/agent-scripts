# RevenueCat API skill

Cross-agent skill for Claude Code and OpenAI Codex.

## Install

### Claude Code
Put this directory at one of:
- `~/.claude/skills/revenuecat-api/`
- `.claude/skills/revenuecat-api/` inside a project

### OpenAI Codex
Put this directory at one of:
- `$HOME/.agents/skills/revenuecat-api/`
- `.agents/skills/revenuecat-api/` inside a repo

## Recommended companion setup

RevenueCat officially documents an MCP server for Claude Code and Codex CLI. Configure that first when possible.

Claude Code example:
```bash
claude mcp add --transport http revenuecat https://mcp.revenuecat.ai/mcp --header "Authorization: Bearer YOUR_API_V2_SECRET_KEY"
```

Codex example (`~/.codex/config.toml`):
```toml
[mcp_servers.revenuecat]
command = "npx"
args = ["mcp-remote", "https://mcp.revenuecat.ai/mcp", "--header", "Authorization: Bearer ${AUTH_TOKEN}"]
env = { AUTH_TOKEN = "YOUR_API_V2_SECRET_KEY" }
type = "stdio"
startup_timeout_ms = 20_000
```

## Fallback environment variables

If MCP is unavailable, the bundled helper script uses:

```bash
export RC_API_KEY="sk_your_v2_secret_key"
export RC_PROJECT_ID="proj_..."
```

## Included files

- `SKILL.md` main workflow and behavior
- `agents/openai.yaml` Codex metadata and MCP dependency hint
- `scripts/revenuecat_request.py` generic API v2 helper
- `references/` research-backed notes
- `assets/payloads/` starter request bodies
