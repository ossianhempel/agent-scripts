---
summary: Use MCP servers as on-demand CLI commands without persistent MCP installs
read_when:
  - Evaluating MCP Porter, MCP-as-CLI, or persistent MCP installs
  - Using RevenueCat or Vercel MCP endpoints from a terminal
  - Avoiding always-on MCP server configuration in agent sessions
---

# MCP as CLI

Use this note when an MCP server is useful, but installing it into every agent
session would add persistent tool surface area or unwanted startup/auth state.

## Recommendation

Prefer this order:

1. Use a real CLI or direct API helper when one exists and covers the task. For
   RevenueCat, the repo already ships `skills/revenuecat-api/scripts/revenuecat_request.py`.
2. Use `bin/mcp-as-cli` for one-off MCP discovery and tool calls. It delegates
   to `mcporter`, but blocks `--persist`, `config`, `daemon`, and `serve` unless
   `MCP_AS_CLI_ALLOW_PERSIST=1` is set.
3. Generate or commit a purpose-built CLI only after repeated successful use and
   review of auth, logging, and command naming.

Do not add a project profile MCP entry just to try a service. Profile MCP config
is still the right fit only when a project should intentionally expose that MCP
server to every compatible agent session.

## Why this works

MCP is transport-independent JSON-RPC. The official architecture docs describe
stdio for local processes, Streamable HTTP for remote servers, and `tools/list`
plus `tools/call` as the normal discovery/execution flow:
https://modelcontextprotocol.io/docs/learn/architecture

The MCP tools spec also says implementations can expose tools through any
interface pattern; the protocol does not require a chat-agent UI:
https://modelcontextprotocol.io/specification/2025-06-18/server/tools

`mcporter` is the current conservative fit for MCP-as-CLI in this repo because
it supports ad-hoc HTTP and stdio targets, one-shot `list` and `call`, OAuth, and
optional generated CLIs:
https://github.com/openclaw/mcporter

The wrapper here intentionally uses the ad-hoc path and refuses persistence by
default. OAuth token caches may still be created by `mcporter auth`; those are
credentials, not installed MCP server definitions.

## Examples

Inspect a public or already-authenticated remote MCP endpoint:

```bash
bin/mcp-as-cli list https://mcp.example.com/mcp --schema --timeout 15000
```

Call a discovered tool:

```bash
bin/mcp-as-cli call 'https://mcp.example.com/mcp.tool_name' key=value
```

Use a local stdio MCP server for one command without adding it to Codex, Claude,
Cursor, or project MCP config:

```bash
bin/mcp-as-cli list --stdio "npx -y some-mcp-server" --name some-service
bin/mcp-as-cli call --stdio "npx -y some-mcp-server" tool_name key=value
```

## RevenueCat

RevenueCat's hosted MCP endpoint is `https://mcp.revenuecat.ai/mcp`. Its docs
support both OAuth and API v2 bearer-token auth:
https://www.revenuecat.com/docs/tools/mcp

For repeatable automation, prefer the repo's direct API helper because it is
deterministic and does not depend on an MCP client implementation:

```bash
python skills/revenuecat-api/scripts/revenuecat_request.py GET "/projects/{project_id}/products" --all-pages
```

For MCP-only tool coverage or parity checks, use an API v2 secret key through an
environment reference rather than writing the token into shell history:

```bash
export RC_API_KEY="..."
bin/mcp-as-cli list \
  --http-url https://mcp.revenuecat.ai/mcp \
  --name revenuecat \
  --header 'Authorization=Bearer $env:RC_API_KEY' \
  --schema
```

RevenueCat filters tools by granted permissions, so a read-only key may not show
write tools:
https://www.revenuecat.com/docs/tools/mcp/best-practices-and-troubleshooting

## Vercel

Vercel's official hosted MCP server is `https://mcp.vercel.com`. Its docs say it
is a remote MCP with OAuth, implements MCP Authorization and Streamable HTTP, and
has public plus authenticated tool categories:
https://vercel.com/docs/agent-resources/vercel-mcp

Try public or cached-auth discovery without installing a persistent server:

```bash
bin/mcp-as-cli list https://mcp.vercel.com --no-oauth --timeout 15000
```

If a live Vercel operation is needed, complete OAuth explicitly:

```bash
bin/mcp-as-cli auth https://mcp.vercel.com
bin/mcp-as-cli list https://mcp.vercel.com --schema
```

Open risk: Vercel's docs say it only supports reviewed/approved AI clients. If
Vercel rejects MCPorter's OAuth client, use the native `vercel` CLI for terminal
work or an officially supported MCP client for an item-specific live proof.

## Security rules

- Do not pass API keys directly as command arguments when an environment
  placeholder can be used.
- Do not use `--persist`, `mcporter config`, `mcporter daemon`, or
  `mcporter serve` unless the owner explicitly chooses persistent MCP state.
- Treat `mcporter auth` token caches as credentials. Do not commit, print, or
  attach them to PRs/issues.
- Use read-only service keys for discovery and write-enabled keys only for
  intentional mutations.
- Prefer service-specific CLIs or direct API helpers for CI and repeatable
  scripts; keep MCP-as-CLI for discovery, parity checks, and tools that do not
  have a normal CLI/API wrapper yet.

## Decision boundary

This PR does not install RevenueCat or Vercel MCP servers. It gives agents a
guarded way to evaluate or call MCP endpoints on demand. The next owner decision
is whether to allow live OAuth/API-key proof for Vercel and RevenueCat, or keep
this as a documented pattern until a concrete project needs it.
