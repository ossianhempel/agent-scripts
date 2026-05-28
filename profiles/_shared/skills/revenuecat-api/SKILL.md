---
name: revenuecat-api
description: Manage RevenueCat API v2 resources and the official RevenueCat MCP workflow for Claude Code and Codex. Use when inspecting or changing RevenueCat projects, apps, products, entitlements, offerings, packages, customers, subscriptions, purchases, webhooks, paywalls, invoices, or metrics.
compatibility: Designed for Claude Code and OpenAI Codex. Best with the RevenueCat MCP server configured; otherwise requires internet access plus RC_API_KEY and usually RC_PROJECT_ID. Python 3 is required for the bundled API helper script.
metadata:
  author: openai
  version: "1.0.0"
  protocol: agentskills.io
  researched: "2026-03-11"
---

# RevenueCat API skill

Use this skill for RevenueCat operational work in code agents.

## Prefer these execution paths in order

1. **RevenueCat MCP server**  
   Use the official RevenueCat MCP server first when it is configured. It gives purpose-built tools for project, app, product, entitlement, offering, package, paywall, customer, metrics, and webhook operations.

2. **`rc` CLI**  
   If MCP is not available but the community `rc` command is installed and authenticated, you may use it for broad RevenueCat API v2 coverage.

3. **Bundled API helper**  
   Fall back to `scripts/revenuecat_request.py` for direct RevenueCat API v2 calls.

## Authentication and environment

- For MCP, rely on the user's configured RevenueCat MCP server.
- For direct API calls, set:
  - `RC_API_KEY` to a RevenueCat **API v2 secret key**
  - `RC_PROJECT_ID` when the path needs `{project_id}`
  - optional `RC_BASE_URL` to override `https://api.revenuecat.com/v2`
- Use `Authorization: Bearer <key>` for API v2.
- For write operations, prefer least-privilege keys and avoid echoing secrets back to the user.

## Safety rules

- **Read before write.** Inspect the current object graph before creating, updating, deleting, refunding, canceling, revoking, or transferring.
- **Never guess IDs.** Resolve `project_id`, `app_id`, `product_id`, `entitlement_id`, `offering_id`, `package_id`, `customer_id`, `purchase_id`, `subscription_id`, and webhook IDs by listing or fetching first.
- **Mutate only on explicit intent.** If the user asked for analysis, inventory, or debugging, stay read-only.
- **Be precise with destructive actions.** For delete, refund, cancel, revoke, or transfer operations, report the exact targets you acted on.
- **Do not downgrade to API v1 automatically.** Only suggest v1 when a requested feature is missing in v2 and say why.

## Default workflow

1. Identify the project and resource IDs.
2. Fetch the current state.
3. Summarize the intended change in concrete terms.
4. Execute the smallest possible set of actions.
5. Re-read the affected resources to verify the result.
6. Return the final state, affected IDs, and any follow-up checks.

## Common workflows

### 1. Inventory a RevenueCat setup
- Get the project.
- List apps, products, entitlements, offerings, packages, paywalls, webhook integrations, and overview metrics.
- When relationships matter, also fetch:
  - products attached to entitlements
  - products attached to packages
  - packages inside offerings

### 2. Create a standard subscription configuration
For a new subscription setup, do this in order:
1. Create or locate the app.
2. Create the product.
3. Create the entitlement.
4. Attach the product to the entitlement.
5. Create the offering.
6. Create a package in the offering.
7. Attach the product to the package.
8. Optionally create a paywall for the offering.

Use payload templates from `assets/payloads/` when helpful.

### 3. Customer operations
Supported patterns include:
- get or list customers
- list subscriptions, purchases, active entitlements, aliases, attributes, invoices, and virtual currency balances
- set customer attributes
- assign or clear offering overrides
- grant or revoke promotional entitlements
- transfer purchases and subscriptions between customers

### 4. Billing operations
Supported patterns include:
- search subscriptions by `store_subscription_identifier`
- search purchases by `store_purchase_identifier`
- cancel or refund eligible subscriptions
- refund eligible purchases
- fetch an authenticated subscription management URL when the endpoint applies

## Execution recipes

### MCP
If the RevenueCat MCP server is available, prefer it for both reads and writes. Use resource-specific tools instead of raw HTTP whenever they cover the request.

### `rc` CLI
Detect it with:
```bash
command -v rc
```

Examples:
```bash
rc projects list
rc apps list --project-id "$RC_PROJECT_ID"
rc products list --project-id "$RC_PROJECT_ID"
rc customers get --id "$CUSTOMER_ID" --project-id "$RC_PROJECT_ID"
```

### Bundled API helper
Read example:
```bash
python "${CLAUDE_SKILL_DIR:-.}/scripts/revenuecat_request.py" GET "/projects/{project_id}/products" --all-pages
```

Write example:
```bash
python "${CLAUDE_SKILL_DIR:-.}/scripts/revenuecat_request.py" POST "/projects/{project_id}/entitlements" --json @assets/payloads/create-entitlement.json
```

Search example:
```bash
python "${CLAUDE_SKILL_DIR:-.}/scripts/revenuecat_request.py" GET "/projects/{project_id}/subscriptions" --query store_subscription_identifier=STORE_SUBSCRIPTION_ID
```

## Notes that matter

- RevenueCat API v2 uses relative `next_page` URLs for pagination. Follow them until `next_page` is null or missing.
- The API supports `expand` query parameters on expandable fields. Use expansions when the user needs related objects in one round-trip.
- URL-encode path values such as customer IDs when needed.
- Some operations are Web Billing specific, especially refund and cancel actions on subscriptions and purchases. Check the endpoint before acting.

## Supporting files

- `references/agent-skills-notes.md` explains the open Agent Skills structure and the Claude Code/Codex-specific files used here.
- `references/revenuecat-api-v2.md` summarizes the v2 API surface and common payloads.
- `references/revenuecat-mcp-and-cli.md` explains official RevenueCat MCP setup plus optional CLI usage.
- `scripts/revenuecat_request.py` is the direct API fallback helper.
- `assets/payloads/` contains starter JSON bodies for common write operations.
