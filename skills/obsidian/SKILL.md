---
name: obsidian
description: Interact with Obsidian vaults using the Obsidian CLI to read, create, search, and manage notes, tasks, properties, and more. Also supports plugin and theme development with commands to reload plugins, run JavaScript, capture errors, take screenshots, and inspect the DOM. Includes knowledge of .base file syntax, templates, vault structure, and Dataview-to-Bases migration. Use when the user asks to interact with their Obsidian vault, manage notes, search vault content, create .base database views, work with templates, or develop and debug Obsidian plugins and themes.
---

# Obsidian

Use the `obsidian` CLI to interact with a running Obsidian instance. Requires Obsidian to be open.

## Command reference

Run `obsidian help` to see all available commands. This is always up to date. Full docs: https://help.obsidian.md/cli

## Syntax

**Parameters** take a value with `=`. Quote values with spaces:

```bash
obsidian create name="My Note" content="Hello world"
```

**Flags** are boolean switches with no value:

```bash
obsidian create name="My Note" silent overwrite
```

For multiline content use `\n` for newline and `\t` for tab.

## File targeting

Many commands accept `file` or `path` to target a file. Without either, the active file is used.

- `file=<name>` — resolves like a wikilink (name only, no path or extension needed)
- `path=<path>` — exact path from vault root, e.g. `folder/note.md`

## Vault targeting

Commands target the most recently focused vault by default. Use `vault=<name>` as the first parameter to target a specific vault:

```bash
obsidian vault="My Vault" search query="test"
```

## Common patterns

```bash
obsidian read file="My Note"
obsidian create name="New Note" content="# Hello" template="Template" silent
obsidian append file="My Note" content="New line"
obsidian search query="search term" limit=10
obsidian daily:read
obsidian daily:append content="- [ ] New task"
obsidian property:set name="status" value="done" file="My Note"
obsidian tasks daily todo
obsidian tags sort=count counts
obsidian backlinks file="My Note"
```

Use `--copy` on any command to copy output to clipboard. Use `silent` to prevent files from opening. Use `total` on list commands to get a count.

## Plugin development

### Develop/test cycle

After making code changes to a plugin or theme, follow this workflow:

1. **Reload** the plugin to pick up changes:
   ```bash
   obsidian plugin:reload id=my-plugin
   ```
2. **Check for errors** — if errors appear, fix and repeat from step 1:
   ```bash
   obsidian dev:errors
   ```
3. **Verify visually** with a screenshot or DOM inspection:
   ```bash
   obsidian dev:screenshot path=screenshot.png
   obsidian dev:dom selector=".workspace-leaf" text
   ```
4. **Check console output** for warnings or unexpected logs:
   ```bash
   obsidian dev:console level=error
   ```

### Additional developer commands

Run JavaScript in the app context:

```bash
obsidian eval code="app.vault.getFiles().length"
```

Inspect CSS values:

```bash
obsidian dev:css selector=".workspace-leaf" prop=background-color
```

Toggle mobile emulation:

```bash
obsidian dev:mobile on
```

Run `obsidian help` to see additional developer commands including CDP and debugger controls.

## Vault knowledge references

For deeper context on vault structure, .base files, and templates, load these references as needed:

- [obsidian_structure.md](references/obsidian_structure.md) — vault organization, YAML frontmatter, wiki-links, tags, backlinks, common plugins
- [base_syntax.md](references/base_syntax.md) — full .base file YAML syntax, filters, formulas, views, Dataview-to-Bases migration
- [templates.md](references/templates.md) — template patterns, Templater syntax, common note templates

### Quick reference — .base files

Bases (.base) are YAML database views that replace Dataview queries. Key distinction: `order` defines **columns**, `sort` defines **row sorting**.

```yaml
views:
  - type: table
    name: "Active Projects"
    filters:
      and:
        - 'file.hasTag("project")'
        - 'status != "archived"'
    order:
      - file.name
      - status
      - file.mtime
    sort:
      - property: file.mtime
        direction: DESC
    limit: 50
```

Read [base_syntax.md](references/base_syntax.md) for filters, formulas, property display, and Dataview conversion table.

### Quick reference — links and properties

```markdown
[[Note Name]]           # Internal link
[[Note Name|Display]]   # Link with custom text
[[Note Name#Heading]]   # Link to heading
![[Note Name]]          # Embed note content
```

```yaml
---
created: 2024-01-15
tags:
  - project
status: active
related-to:
  - "[[Other Note]]"
---
```

## Assets

Example templates in `assets/`:
- [daily-note-template.md](assets/daily-note-template.md)
- [zettelkasten-template.md](assets/zettelkasten-template.md)
