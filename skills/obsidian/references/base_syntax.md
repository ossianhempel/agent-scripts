# Obsidian Bases (.base) File Syntax

## Overview

`.base` files are YAML documents that define database-like table views in Obsidian. They are part of Obsidian's Bases feature (available in v1.9.0+) and provide a more powerful, editable alternative to Dataview queries.

## Basic Structure

```yaml
views:
  - type: table
    name: "View Name"
    filters:
      and:
        - 'condition1'
        - 'condition2'
    order:
      - file.name       # Columns to display (and their order)
      - property_name
    sort:
      - property: file.mtime   # How to sort rows
        direction: DESC
    limit: 50

formulas:
  calculated_field: 'expression'

properties:
  field_name:
    displayName: "Display Name"
```

## Filters

Filters narrow down which files appear in the view. By default, a base includes every file in the vault.

### Filter Structure

Filters use `and`, `or`, and `not` operators with filter statements (strings) or nested filter objects:

```yaml
filters:
  and:
    - 'file.hasTag("important")'
    - or:
        - 'status == "active"'
        - 'priority > 5'
    - not:
        - 'file.inFolder("Archive")'
```

### Filter Functions

- `file.hasTag("tag_name")` - Check if file has a tag (without #)
- `file.hasLink("Note Name")` - Check if file links to a note
- `file.inFolder("path/to/folder")` - Check if file is in a folder
- `contains(property, value)` - Check if a property contains a value

### Comparison Operators

- `==`, `!=` - Equality/inequality
- `>`, `<`, `>=`, `<=` - Numeric comparisons
- `&&`, `||`, `!` - Boolean logic

### Date Filtering

```yaml
filters:
  - 'file.mtime > now() - "1 week"'
  - 'date + "1M"'  # Add 1 month
```

Duration formats: `y`/`year`, `M`/`month`, `w`/`week`, `d`/`day`, `h`/`hour`, `m`/`minute`, `s`/`second`

## File Properties

Available for all files:

| Property | Type | Description |
| -------- | ---- | ----------- |
| `file.ctime` | Date | Created time |
| `file.mtime` | Date | Modified time |
| `file.name` | String | File name |
| `file.path` | String | Full file path |
| `file.ext` | String | File extension |
| `file.size` | Number | File size in bytes |
| `file.folder` | String | Parent folder path |
| `file.links` | List | Internal links in file |
| `file.embeds` | List | Embeds in file |
| `file.tags` | List | Tags in file |

## Note Properties

Properties from YAML frontmatter can be accessed directly by name or via `note.property_name`:

```yaml
filters:
  - 'status == "done"'
  - 'note.priority > 3'
```

## Formulas

Define calculated properties:

```yaml
formulas:
  days_old: '(now() - file.ctime) / (1000 * 60 * 60 * 24)'
  formatted_price: 'if(price, price.toFixed(2) + " dollars", "N/A")'
```

Reference formulas with `formula.` prefix in views:

```yaml
views:
  - type: table
    order:
      - formula.days_old
```

## Views

Each base can have multiple views with different filters and display options:

```yaml
views:
  - type: table
    name: "Active Tasks"
    filters:
      - 'status == "active"'
    order:
      - priority
      - file.mtime
    limit: 25

  - type: table
    name: "Completed"
    filters:
      - 'status == "completed"'
    order:
      - file.mtime
```

### View Options

- `type` - View type (currently only "table" is common)
- `name` - Display name for the view
- `filters` - View-specific filters (in addition to global filters)
- **`order`** - Array of properties defining **which columns are displayed** and their sequence (left to right)
- **`sort`** - Array of sort rules defining **how rows are sorted** (separate from column display)
- `limit` - Maximum number of rows to display

**CRITICAL: `order` vs `sort`**
- **`order`** controls **COLUMN DISPLAY** - which properties appear as columns and in what sequence
- **`sort`** controls **ROW SORTING** - how the data rows are ordered

Example showing both:
```yaml
views:
  - type: table
    name: "My Table"
    order:
      - file.name      # Column 1: File name
      - file.mtime     # Column 2: Modified time
      - tags           # Column 3: Tags
    sort:
      - property: file.mtime
        direction: DESC  # Sort rows by modification time (newest first)
    limit: 100
```

## Property Display Configuration

Customize how properties display in the table:

```yaml
properties:
  status:
    displayName: "Status"
  file.mtime:
    displayName: "Last Modified"
  formula.days_old:
    displayName: "Age (days)"
```

## Common Patterns

### Filter by Tag and Property

```yaml
filters:
  and:
    - 'file.hasTag("project")'
    - 'status != "archived"'
```

### Recent Files

```yaml
filters:
  - 'file.mtime > now() - "7d"'
order:
  - file.name        # Display file name column
  - file.mtime       # Display modified time column
sort:
  - property: file.mtime
    direction: DESC  # Sort by newest first
```

### Files Linking to Specific Note

```yaml
filters:
  - 'file.hasLink("Project Name")'
```

### Multiple Views for Different Statuses

```yaml
views:
  - type: table
    name: "Todo"
    filters:
      - 'status == "todo"'

  - type: table
    name: "In Progress"
    filters:
      - 'status == "in-progress"'

  - type: table
    name: "Done"
    filters:
      - 'status == "done"'
```

## Converting from Dataview

Common Dataview patterns and their Base equivalents:

| Dataview | Base |
| -------- | ---- |
| `FROM #tag` | `file.hasTag("tag")` (in filters) |
| `WHERE contains(prop, [[Note]])` | `file.hasLink("Note")` (in filters) |
| `WHERE prop = "value"` | `prop == "value"` (in filters) |
| `SORT file.mtime DESC` | `sort: [{property: file.mtime, direction: DESC}]` |
| `TABLE field1, field2` | `order: [field1, field2]` (columns to display) |
| `LIMIT 10` | `limit: 10` |

**Example Dataview to Base conversion:**

Dataview:
```dataview
TABLE file.mtime, tags
FROM #inbox
WHERE status != "done"
SORT file.mtime DESC
LIMIT 50
```

Base equivalent:
```yaml
views:
  - type: table
    name: Inbox
    filters:
      and:
        - 'file.hasTag("inbox")'
        - 'status != "done"'
    order:
      - file.name
      - file.mtime
      - tags
    sort:
      - property: file.mtime
        direction: DESC
    limit: 50
```

## Tips

1. **Quotes in YAML**: Text literals in filter expressions must use quotes. Nested quotes in YAML strings use single quotes inside double quotes or vice versa.

2. **Tag names**: Use tag names without the `#` symbol in `file.hasTag()`

3. **Performance**: Bases are significantly faster than Dataview queries and support inline editing

4. **Testing**: Create the base in Obsidian's UI first, then examine the generated `.base` file to learn the syntax
