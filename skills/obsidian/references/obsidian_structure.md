# Obsidian Structure and Concepts

## Overview

Obsidian is a knowledge management system built on local Markdown files. It emphasizes linking and interconnected notes, creating a "second brain" or personal knowledge graph.

## Core Concepts

### Vaults

A vault is a folder on your computer containing all your Obsidian notes and configuration:

```
vault/
├── .obsidian/           # Configuration and plugins (hidden)
│   ├── app.json         # App settings
│   ├── workspace.json   # Layout and open files
│   └── plugins/         # Installed plugins
├── note1.md
├── note2.md
├── folder/
│   └── note3.md
└── attachments/
    └── image.png
```

### Markdown Files

Notes are plain Markdown files with optional YAML frontmatter for metadata.

## YAML Frontmatter (Properties)

Frontmatter appears at the top of files between `---` delimiters:

```markdown
---
created: 2024-01-15
tags:
  - project
  - important
status: active
related-to:
  - "[[Other Note]]"
  - "[[Another Note]]"
aliases:
  - "Alt Name"
---

# Note Content

Regular markdown content starts here.
```

### Common Properties

- `tags` - List of tags (can also use `#tag` in content)
- `aliases` - Alternative names for the note
- `created` / `modified` - Timestamps
- `related-to` - Links to related notes
- Custom properties - Any key-value pairs you define

### Accessing Properties

- In Bases: `status == "active"` or `note.status == "active"`
- In Dataview: `WHERE status = "active"`

## Wiki-Style Links

Obsidian uses `[[Note Name]]` syntax for linking between notes:

### Basic Links

```markdown
[[Note Name]]           # Link to a note
[[Note Name|Display]]   # Link with custom display text
[[Note Name#Heading]]   # Link to a specific heading
[[Note Name#^block]]    # Link to a specific block
```

### Embedding

Use `!` prefix to embed content instead of linking:

```markdown
![[Note Name]]          # Embed entire note
![[image.png]]          # Embed image
![[Note#Heading]]       # Embed specific section
![[file.pdf#page=3]]    # Embed PDF page
```

### Link Types

1. **Internal links**: `[[Note Name]]` - Links between vault notes
2. **External links**: `[Text](https://url.com)` - Standard Markdown links
3. **Backlinks**: Automatically tracked - all notes linking to current note

## Tags

Two ways to add tags:

1. **In frontmatter** (recommended):
   ```yaml
   tags:
     - project
     - work
   ```

2. **Inline in content**:
   ```markdown
   This is a note about #project and #work topics.
   ```

### Nested Tags

Tags can be hierarchical using `/`:

```markdown
#project/active
#project/archived
#work/client/acme
```

### Tag Usage

- Filter in Bases: `file.hasTag("project")`
- Search in Obsidian: `tag:#project`

## Folders and Organization

### Directory Structure

```
vault/
├── daily-notes/          # Daily journal entries
├── pages/                # Main content notes
├── templates/            # Note templates
├── attachments/          # Images, PDFs, etc.
├── moc/                  # Maps of Content (hub notes)
└── readwise/             # External integrations
```

### Best Practices

1. **Flat is better than deep** - Obsidian relies on links, not folders
2. **Links over folders** - Use tags and links for organization
3. **Attachments folder** - Configure in Settings → Files & Links

## Dataview Queries

Dataview is a plugin for querying notes like a database:

```dataview
LIST
FROM #project
WHERE status = "active"
SORT file.mtime DESC
```

Common Dataview query types:
- `LIST` - Simple list of matching notes
- `TABLE` - Tabular view with columns
- `TASK` - List of tasks from notes
- `CALENDAR` - Calendar view of notes

## Templates

Templates are markdown files used to create new notes with pre-filled content.

### Template Example

```markdown
---
created: {{date}}
tags:
  - {{tag}}
---

# {{title}}

## Overview

## Notes

## Related
-
```

### Template Variables

Common variables (depends on template plugin):
- `{{date}}` - Current date
- `{{time}}` - Current time
- `{{title}}` - Note title
- Custom variables defined in template settings

## File Naming Conventions

### Common Patterns

1. **Title Case**: `My Note Title.md`
2. **Kebab Case**: `my-note-title.md`
3. **Date Prefix**: `2024-01-15 Daily Note.md`
4. **Category Prefix**: `Project - Feature Name.md`

### Recommended Practices

- Use descriptive names
- Avoid special characters: `/ \ : * ? " < > |`
- Be consistent across your vault

## Note Maturity Systems

Many users implement note lifecycle systems:

### Zettelkasten-Style

- **Seedling** (`#seedling`) - New, undeveloped ideas
- **Budding** (`#budding`) - Ideas being developed
- **Evergreen** (`#evergreen`) - Fully developed notes

### Status-Based

```yaml
status: draft | review | published
```

## Common Plugins

### Core Plugins

- **Templates** - Insert template content
- **Daily Notes** - Quick access to daily journal
- **Backlinks** - Show notes linking to current note
- **Graph View** - Visualize note connections

### Community Plugins

- **Dataview** - Query notes like a database
- **Templater** - Advanced template system
- **Readwise Official** - Sync highlights from reading apps
- **Natural Language Dates** - Parse dates in natural language

## Finding Content

### Search Operators

```
tag:#project              # Files with tag
file:readme              # Files with name containing "readme"
path:folder/             # Files in folder
content:"exact phrase"   # Files containing exact text
[link]                   # Files with links
```

### Combining Searches

```
tag:#project status:active        # AND logic
tag:#project OR tag:#work         # OR logic
tag:#project -tag:#archived       # NOT logic
```

## Backlinks and Forward Links

### Backlinks

Notes automatically track which other notes link to them. Access via:
- Backlinks pane in sidebar
- Bases filter: `file.hasLink("Current Note")`

### Forward Links

Links from current note to others:
- Visible in note content as `[[Note]]`
- Listed in Outgoing Links pane

### Unlinked Mentions

Obsidian finds text matching note names even without explicit links.

## Best Practices

1. **Link liberally** - Create connections between related ideas
2. **Use properties** - Structured metadata for querying
3. **One idea per note** - Atomic notes are more flexible
4. **Review and refine** - Regularly update and improve notes
5. **Templates for consistency** - Standardize note structure
6. **Tags for categories** - Use tags for broad classifications
7. **MOCs for navigation** - Create hub notes linking related topics
