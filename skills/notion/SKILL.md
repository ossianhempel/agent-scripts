---
name: notion
description: Notion API for reading, querying, creating, and updating Notion pages, databases, data sources, and blocks. Use this whenever the user asks to inspect, migrate, sync, or automate Notion content, especially work items or task databases.
homepage: https://developers.notion.com
---

# notion

Use the Notion REST API for Notion pages, databases, data sources, and blocks.

## Setup

1. Create an integration at https://notion.so/my-integrations.
2. Copy the API key.
3. Store it outside repos:

```bash
mkdir -p ~/.config/notion
echo "ntn_your_key_here" > ~/.config/notion/api_key
chmod 600 ~/.config/notion/api_key
```

4. Share each target page, database, or data source with the integration in Notion.

## API Basics

All REST requests need an authorization header and a `Notion-Version` header. Prefer `2026-03-11` for new integrations unless the user's existing tooling is pinned to an older version.

```bash
NOTION_KEY=$(cat ~/.config/notion/api_key)
curl "https://api.notion.com/v1/search" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11" \
  -H "Content-Type: application/json"
```

## Common Operations

Search for pages and data sources:

```bash
curl -X POST "https://api.notion.com/v1/search" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11" \
  -H "Content-Type: application/json" \
  -d '{"query": "task backlog"}'
```

Query a data source:

```bash
curl -X POST "https://api.notion.com/v1/data_sources/{data_source_id}/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11" \
  -H "Content-Type: application/json" \
  -d '{"page_size": 50}'
```

Get page content:

```bash
curl "https://api.notion.com/v1/blocks/{page_id}/children?page_size=100" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11"
```

Create a page in a database:

```bash
curl -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"database_id": "database-id"},
    "properties": {
      "Name": {"title": [{"text": {"content": "New item"}}]}
    }
  }'
```

Update page properties:

```bash
curl -X PATCH "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2026-03-11" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"Status": {"status": {"name": "Done"}}}}'
```

## Property Formats

- Title: `{"title": [{"text": {"content": "..."}}]}`
- Rich text: `{"rich_text": [{"text": {"content": "..."}}]}`
- Select: `{"select": {"name": "Option"}}`
- Status: `{"status": {"name": "Todo"}}`
- Multi-select: `{"multi_select": [{"name": "A"}, {"name": "B"}]}`
- Date: `{"date": {"start": "2026-06-20"}}`
- Checkbox: `{"checkbox": true}`
- URL: `{"url": "https://..."}`

## Notes

- API versions are date strings and are required on every REST request.
- Since `2025-09-03`, Notion splits databases from data sources; query task rows through `/v1/data_sources/{id}/query`.
- Pagination cursors are opaque. Pass `next_cursor` back as `start_cursor` without parsing it.
- Keep tokens in `~/.config/notion/api_key` or a specific environment variable, never in repo config files.
