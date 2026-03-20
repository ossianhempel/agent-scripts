---
name: agent-food-admin
description: Use the PlateSnap agent food admin HTTP API to search, inspect, create, and update food items safely. Trigger this whenever the user wants an agent to add or edit livsmedel, canonical food items, nutrition data, or food metadata programmatically, through automation, via API, or without clicking around in the admin UI. Prefer this skill over browser-driving the admin portal whenever the API is available.
---

# Agent Food Admin

## Feedback Log (DO THIS FIRST)

**At the start of every session, before doing anything else**, read the file
`feedback.log` in this skill's folder. It contains accumulated preferences and
corrections from previous sessions. Apply everything in it as if it were part of
this SKILL.md.

**During a session**, whenever the user gives a correction, states a preference,
or says something like "don't do X" / "I prefer Y" / "always do Z":

1. Decide: is this a **general preference** that applies to future sessions, or
   is it **specific to the current task only** (e.g., "use this exact brand name
   for this food")?
2. If it's general, **immediately append it to `feedback.log`** using the Edit
   or Write tool. Don't wait until the end of the session.
3. Use your judgment on length. A simple preference like "always confirm
   deployment target" is one line. Something nuanced like a nutrition data
   sourcing correction needs a sentence or two of context so it's useful when
   re-read later.
4. Format each entry as: `[YYYY-MM-DD] <the preference or correction>`
5. Skip anything that only matters for the current task and wouldn't apply again.

## Purpose
Use the machine-facing food admin API for sidecar admin work. This skill exists so agents can manage foods programmatically without driving the admin web UI.

The API is for:
- searching foods before edits
- reading the current admin detail for a food
- creating a new food
- updating an existing food

The API is not for:
- driving the Clerk-based admin portal
- using a human Clerk session for automation
- making hidden extra edits beyond the user's request

## Required configuration
Expect these env vars to be available before using the API:
- `PLATESNAP_AGENT_ADMIN_BASE_URL`
  Example: Convex deployment origin or proxy base URL, such as `https://<deployment>.convex.cloud`
- `PLATESNAP_AGENT_ADMIN_TOKEN`
  Example: bearer token for `Authorization: Bearer ...`

If either value is missing, stop and tell the user exactly which env var is missing. Do not fall back to browser automation unless the user explicitly asks for that.

## Deployment targeting

`npx convex run` defaults to the dev deployment (reads `.env.local`).

- **Production**: `npx convex run --prod <function> '<args>'`
- When using the HTTP API, verify `PLATESNAP_AGENT_ADMIN_BASE_URL` points to the correct deployment (dev vs prod).
- Never run mutations without confirming the target deployment with the user.

## Endpoint summary
- `POST /agent-admin/v1/foods/search`
- `GET /agent-admin/v1/foods/:foodItemId`
- `POST /agent-admin/v1/foods`
- `PATCH /agent-admin/v1/foods/:foodItemId`

Always send:

```http
Authorization: Bearer <PLATESNAP_AGENT_ADMIN_TOKEN>
Content-Type: application/json
```

## Default workflow

### Create flow
1. Search first using the name, brand, and barcode if available.
2. Review the results for obvious duplicates or near-matches.
3. If an exact or likely duplicate exists, stop and surface that to the user instead of creating a new food blindly.
4. If no suitable existing food exists, create the food.
5. Report the created food ID and the fields that were set.

### Update flow
1. Require an exact `foodItemId` or search for the intended food first.
2. Fetch the current food with `GET /foods/:foodItemId` before patching.
3. Only change the fields the user asked to change.
4. Preserve unrelated fields and existing intent.
5. Report the changed fields and the final food ID.

## Safety rules
- Search before create unless the user already gave an exact `foodItemId` and explicitly wants a create skipped.
- Get before patch. Never patch a food blind.
- Do not drive the admin UI if the HTTP API is available.
- Do not use a human Clerk token or session cookie for automation.
- Do not invent nutrient values, brands, or serving data that the user did not supply.
- Do not silently overwrite unrelated fields.
- Treat duplicate, validation, and conflict errors as a reason to stop and ask the user, not to guess.
- If the API returns a conflict or duplicate response, present the candidate existing food clearly.

## Search guidance
Use search whenever:
- the user names a food but does not provide `foodItemId`
- the user is unsure whether the food already exists
- the user wants to "add" a food that may already be in the database

Prefer sending the strongest identifiers available:
- `barcode` if known
- `query` using Swedish food name and optional brand
- `status` only when the user explicitly cares about verified/unverified/rejected state

## Serving options reference

Label format: exactly `"<integer> <unit>"` — e.g., `"1 st"`, `"2 dl"`.

**Supported canonical units**: `g`, `kg`, `ml`, `cl`, `dl`, `l`, `tsk`, `msk`, `kopp`, `glas`, `skopa`, `st`, `portion`

Common aliases are accepted (e.g., `piece` → `st`, `cup` → `kopp`, `scoop` → `skopa`, `serving` → `portion`).

Rules:
- Amount must be a positive integer (no decimals, fractions, or zero)
- Weight goes in `gramsPerUnit`, NOT in the label
  - Correct: `{"label": "1 st", "gramsPerUnit": 121}`
  - Wrong: `{"label": "1 st (121 g)", "gramsPerUnit": 121}` — silently dropped
- `g_1` and `g_100` are always auto-included (do not add them manually)
- Invalid labels are silently dropped by `upsertMany`, rejected by the HTTP API
- If `defaultServingOptionId` references a dropped/missing option, falls back to `g_100`

## Source field

Agent-created foods must always use `source: "agent"`.

- `sourceName` — human-readable data origin (e.g., `"mcdonalds.com/se API"`, `"Livsmedelsverket"`)
- `sourceId` — stable unique ID for idempotent upserts (e.g., `"mcd_se_200002"`)
- The HTTP admin API sets `source: "agent"` automatically
- When using `upsertMany` directly via `npx convex run`, set `"source": "agent"` explicitly

Do NOT use source values like `"mcdonalds_se"` or other brand-specific strings — always `"agent"`.

## Data integrity

- NEVER fabricate or estimate nutrition values
- Always source from official product pages, APIs, or databases
- Include data source attribution in `sourceName`
- If a value is uncertain or unavailable, omit it rather than guess

## Bulk operations via upsertMany

Alternative to the HTTP API for batch inserts/updates:

```bash
npx convex run --prod foods:upsertMany '{
  "items": [
    {
      "name": "Cheeseburgare",
      "brand": "McDonald's",
      "source": "agent",
      "sourceId": "mcd_se_200002",
      "sourceName": "mcdonalds.com/se API",
      "nutrientsPer100": {
        "calories": 253,
        "proteinG": 14.0,
        "carbsG": 27.0,
        "fatG": 10.0
      },
      "servingOptions": [
        { "id": "1_st", "label": "1 st", "gramsPerUnit": 121 }
      ],
      "defaultServingOptionId": "1_st"
    }
  ]
}'
```

Key differences from the HTTP API:
- `upsertMany` matches on `(source, sourceId)` for idempotent upserts — updates if found, inserts if not
- Invalid serving labels are silently **dropped** (not rejected)
- No audit logging (unlike the HTTP API)
- No auth token required (uses Convex CLI auth directly)

## Request patterns

### Search

```bash
curl -sS \
  -H "Authorization: Bearer $PLATESNAP_AGENT_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$PLATESNAP_AGENT_ADMIN_BASE_URL/agent-admin/v1/foods/search" \
  -d '{
    "query": "kvarg vanilj lindahls",
    "limit": 10
  }'
```

### Get current food

```bash
curl -sS \
  -H "Authorization: Bearer $PLATESNAP_AGENT_ADMIN_TOKEN" \
  "$PLATESNAP_AGENT_ADMIN_BASE_URL/agent-admin/v1/foods/food_123"
```

### Create food

```bash
curl -sS \
  -H "Authorization: Bearer $PLATESNAP_AGENT_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$PLATESNAP_AGENT_ADMIN_BASE_URL/agent-admin/v1/foods" \
  -d '{
    "name": "Kvarg vanilj",
    "brand": "Lindahls",
    "sourceName": "lindahls.se",
    "nutrientsPer100": {
      "calories": 92,
      "proteinG": 10.0,
      "carbsG": 6.5,
      "fatG": 0.2
    },
    "servingOptions": [
      { "id": "1_portion", "label": "1 portion", "gramsPerUnit": 150 }
    ],
    "defaultServingOptionId": "1_portion"
  }'
```

### Update food

```bash
curl -sS \
  -H "Authorization: Bearer $PLATESNAP_AGENT_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -X PATCH "$PLATESNAP_AGENT_ADMIN_BASE_URL/agent-admin/v1/foods/food_123" \
  -d '{
    "name": "Kvarg vanilj",
    "brand": "Lindahls",
    "nutrientsPer100": {
      "calories": 92,
      "proteinG": 10.0,
      "carbsG": 6.5,
      "fatG": 0.2,
      "sugarG": 6.5
    }
  }'
```

## Response handling
- On success, report:
  - action taken
  - food name
  - `foodItemId`
  - fields changed or created
- On validation failure, report the API error verbatim if short, otherwise summarize it precisely.
- On duplicate/conflict, show the returned existing food candidate and explain that no new record should be created until the user confirms.

## Output format
When performing a food admin action, keep the final report compact and explicit:

```markdown
Action: <searched|created|updated|stopped>
Food: <name> (<brand or —>)
Food ID: <foodItemId or not created>
Result: <one-sentence outcome>
Changed fields: <comma-separated list or none>
```

If you stopped because of duplicate/conflict uncertainty, replace `Changed fields` with:

```markdown
Conflict: <short reason>
Candidate existing food: <name + foodItemId>
```

## Examples

**Example 1: Create a new food**

User intent:
`Add a new livsmedel for Lindahls vaniljkvarg with these macros per 100 g...`

Agent behavior:
1. Search for `Lindahls vaniljkvarg`
2. If no exact match, create the food
3. Return the new `foodItemId`

**Example 2: Update an existing food**

User intent:
`Update food_123 so sugar is 4.8 g per 100 g`

Agent behavior:
1. Fetch `food_123`
2. Preserve all existing fields except the requested nutrient adjustment
3. Patch the food
4. Report the changed nutrient fields only

**Example 3: Duplicate detected**

User intent:
`Add Arla standardmjölk`

Agent behavior:
1. Search first
2. If a likely exact match already exists, stop
3. Report the existing candidate instead of creating a duplicate
