---
name: obsidian
description: Work with Obsidian vaults - create and manage .base files (Bases database tables), understand Obsidian structure (wiki-links, YAML properties, tags, folders), insert and edit templates, find and navigate content, follow trails of linked notes and backlinks. Use when working with Obsidian markdown files, converting Dataview queries to Bases, creating note templates, or navigating knowledge graphs.
---

# Obsidian

Work with Obsidian vaults including creating database views (.base files), managing templates, and navigating linked notes.

## Core Capabilities

### 1. Understand Obsidian Structure

Read [obsidian_structure.md](references/obsidian_structure.md) for comprehensive documentation on:
- Vault organization and file structure
- YAML frontmatter (properties) syntax and usage
- Wiki-style links: `[[Note Name]]`, `[[Note#Heading]]`, `[[Note|Display]]`
- Tags: frontmatter vs inline, nested tags with `/`
- Folders and file organization best practices
- Backlinks and forward links
- Common plugins (Dataview, Templater, etc.)

**Quick reference - Link syntax:**
```markdown
[[Note Name]]           # Internal link
[[Note Name|Display]]   # Link with custom text
[[Note Name#Heading]]   # Link to heading
![[Note Name]]          # Embed note content
![[image.png]]          # Embed image
```

**Quick reference - YAML frontmatter:**
```yaml
---
created: 2024-01-15
tags:
  - project
  - important
status: active
related-to:
  - "[[Other Note]]"
---
```

### 2. Create and Manage .base Files

Obsidian Bases (.base files) are YAML-based database views that replace Dataview queries. They are faster, support inline editing, and use a clean declarative syntax.

Read [base_syntax.md](references/base_syntax.md) for complete syntax reference including filters, formulas, views, and properties.

**Quick start - Basic .base structure:**
```yaml
views:
  - type: table
    name: Table
    filters:
      and:
        - 'file.hasTag("tag_name")'
        - 'property == "value"'
    order:
      - file.name      # Columns to display
      - file.mtime
    sort:
      - property: file.mtime   # How to sort rows
        direction: DESC
    limit: 50
```

**IMPORTANT:**
- `order` defines which **columns** are displayed
- `sort` defines how **rows** are sorted

**Common filter functions:**
- `file.hasTag("tag")` - Check for tag (without #)
- `file.hasLink("Note Name")` - Check for links
- `file.inFolder("path")` - Check folder location
- Date filters: `file.mtime > now() - "1 week"`

**Converting Dataview to Bases:**

| Dataview Pattern | Base Equivalent |
| ---------------- | --------------- |
| `FROM #tag` | `file.hasTag("tag")` (in filters) |
| `WHERE contains(prop, [[Note]])` | `file.hasLink("Note")` (in filters) |
| `WHERE prop = "value"` | `prop == "value"` (in filters) |
| `TABLE field1, field2` | `order: [field1, field2]` (columns to display) |
| `SORT file.mtime DESC` | `sort: [{property: file.mtime, direction: DESC}]` (row sorting) |
| `LIMIT 10` | `limit: 10` |

**Workflow:**
1. Identify filters needed (tags, properties, dates, etc.)
2. Create .base file with filters in YAML
3. Define view properties (name, order, limit)
4. Add formulas if calculated fields are needed
5. Test by opening in Obsidian

### 3. Work with Templates

Templates provide consistent structure for new notes. Obsidian supports basic templates (core plugin) and advanced templates (Templater plugin).

Read [templates.md](references/templates.md) for comprehensive guide including Templater syntax, common patterns, and best practices.

**Quick reference - Template variables:**
```markdown
{{date:YYYY-MM-DD}}     # Current date
{{time:HH:mm}}          # Current time
{{title}}               # Note title
{{date-7d:YYYY-MM-DD}}  # Date arithmetic
```

**Example templates are in `assets/`:**
- `daily-note-template.md` - Daily journal template
- `zettelkasten-template.md` - Note-taking template

**Creating templates:**
1. Determine note type and required structure
2. Add YAML frontmatter with relevant properties
3. Use template variables for dates, titles, etc.
4. Include structural sections (headings, lists)
5. Add links to related notes or navigation
6. Save in vault's templates folder

**Inserting templates into existing notes:**
1. Read template file from assets/ or vault's templates folder
2. Replace template variables with actual values
3. Insert at cursor position or appropriate location

### 4. Find and Navigate Content

Use file operations and text search to find content across the vault.

**Finding files by pattern:**
```bash
# Use Glob tool
pattern: "**/*.md"
pattern: "**/daily-notes/*.md"
pattern: "**/*project*.md"
```

**Searching content:**
```bash
# Use Grep tool
pattern: "\\[\\[Note Name\\]\\]"  # Find links to specific note
pattern: "status.*active"          # Find notes with status
pattern: "#tag"                    # Find tag usage
```

**Common search patterns:**
- Find backlinks: `grep -r "\[\[Note Name\]\]" vault/`
- Find by tag: `grep -r "#project" vault/`
- Find by property: `grep -r "status: active" vault/`
- Find orphan notes: Notes with no incoming/outgoing links

**Multi-step navigation:**
1. Start with initial note
2. Extract links from content: `[[Link]]` patterns
3. Read linked notes
4. Extract links from those notes
5. Repeat to follow link trail

### 5. Follow Trails of Linked Notes

Navigate knowledge graphs by following chains of linked notes.

**Reading links in a note:**
1. Read note content
2. Find all `[[Note Name]]` patterns (use regex: `\[\[([^\]]+)\]\]`)
3. Parse note names, handling aliases: `[[Note|Alias]]` → `Note.md`
4. Handle heading links: `[[Note#Heading]]` → `Note.md`

**Following backlinks:**
1. Search vault for pattern: `\[\[Target Note\]\]`
2. List all notes containing the pattern
3. Read each note to see context

**Tracing link paths:**
1. Start with note A
2. Extract all outgoing links from A
3. For each link, read target note
4. Extract outgoing links from each target
5. Build connection map or follow specific path

**Example - Find related notes:**
```markdown
Note A links to: [[B]], [[C]]
Note B links to: [[D]], [[E]]
Note C links to: [[E]], [[F]]

Related to A: B, C, D, E, F
```

**Finding MOCs (Maps of Content):**
MOCs are hub notes with many outgoing links. Find by:
1. Count outgoing links per note
2. Notes with >10 links are often MOCs
3. Check for "moc" tag or "MOC" in title

## File Operations

**Reading notes:**
- Always read full file to preserve formatting
- Parse YAML frontmatter separately from content
- Handle both `---` YAML blocks and content

**Writing/editing notes:**
- Preserve existing YAML frontmatter structure
- Maintain link formatting: `[[Note]]` not `[Note](note.md)`
- Keep consistent indentation in YAML (2 spaces)
- Don't break existing wiki-links when editing

**Creating new notes:**
1. Determine appropriate folder based on vault structure
2. Use consistent file naming (Title Case or kebab-case)
3. Include YAML frontmatter with created date and tags
4. Add relevant links to related notes
5. Apply template if appropriate

## Best Practices

1. **Preserve vault conventions** - Check existing notes for naming, tagging, and organization patterns
2. **Use .base over Dataview** - Bases are faster and more maintainable
3. **Link liberally** - Create connections between related ideas
4. **Atomic notes** - One concept per note for flexibility
5. **Consistent properties** - Use same property names across similar notes
6. **Read before writing** - Always read files before editing to preserve structure
7. **Validate links** - Ensure linked notes exist in vault
8. **Test .base files** - Verify syntax by checking if file would load in Obsidian

## References

- [obsidian_structure.md](references/obsidian_structure.md) - Complete Obsidian structure and concepts guide
- [base_syntax.md](references/base_syntax.md) - Full .base file YAML syntax reference
- [templates.md](references/templates.md) - Template patterns and Templater syntax

## Assets

- [daily-note-template.md](assets/daily-note-template.md) - Daily journal template
- [zettelkasten-template.md](assets/zettelkasten-template.md) - Zettelkasten note-taking template
