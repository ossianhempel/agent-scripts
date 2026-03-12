# RevenueCat MCP and CLI notes

## Official path: RevenueCat MCP server

RevenueCat officially ships a hosted MCP server at:

- `https://mcp.revenuecat.ai/mcp`

Use this first when it is configured because it exposes resource-oriented tools for project, app, product, entitlement, offering, package, paywall, customer, metrics, and webhook work.

### Claude Code setup
```bash
claude mcp add --transport http revenuecat https://mcp.revenuecat.ai/mcp --header "Authorization: Bearer YOUR_API_V2_SECRET_KEY"
```

### Codex CLI setup
```toml
[mcp_servers.revenuecat]
command = "npx"
args = ["mcp-remote", "https://mcp.revenuecat.ai/mcp", "--header", "Authorization: Bearer ${AUTH_TOKEN}"]
env = { AUTH_TOKEN = "YOUR_API_V2_SECRET_KEY" }
type = "stdio"
startup_timeout_ms = 20_000
```

## RevenueCat MCP behavior

- OAuth is supported for some clients such as VS Code and Cursor.
- API v2 secret keys work across MCP clients.
- RevenueCat recommends dedicated keys and least-privilege permissions.
- Official docs describe 26 MCP tools organized by resource category.

## Optional community CLI: `rc`

If the `rc` command is installed, you can use it as a broad API v2 wrapper.

Typical setup:
```bash
rc configure
# or
export RC_API_KEY="sk_..."
export RC_PROJECT_ID="proj_..."
```

Useful commands:
```bash
rc projects list
rc apps list --project-id "$RC_PROJECT_ID"
rc products list --project-id "$RC_PROJECT_ID"
rc entitlements list --project-id "$RC_PROJECT_ID"
rc offerings list --project-id "$RC_PROJECT_ID"
rc customers get --id "$CUSTOMER_ID" --project-id "$RC_PROJECT_ID"
rc subscriptions get --id "$SUBSCRIPTION_ID" --project-id "$RC_PROJECT_ID"
rc purchases get --id "$PURCHASE_ID" --project-id "$RC_PROJECT_ID"
rc metrics overview --project-id "$RC_PROJECT_ID"
```

Notes:
- `rc` supports JSON, YAML, and table output.
- It documents built-in caching and 429 handling.
- Treat it as a convenience layer over RevenueCat API v2, not as an official RevenueCat product.

## When to prefer which path

- Prefer **MCP** for agent-native workflows and resource-specific tool semantics.
- Prefer **`rc` CLI** when a terminal wrapper is already installed and authenticated.
- Prefer **`scripts/revenuecat_request.py`** when you need a portable fallback with no external dependency beyond Python.
