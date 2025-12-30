# Obsidian Template Patterns

## Overview

Templates in Obsidian provide consistent structure for new notes. This guide covers common template patterns and the Templater plugin syntax.

## Basic Template Structure

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - template-tag
---

# {{title}}

## Content sections

Your content here
```

## Templater Syntax

Templater is the most popular templating plugin. It uses `<% %>` syntax for logic and `{{}}` for simple variables.

### Date and Time

```markdown
Created: {{date:YYYY-MM-DD}}
Time: {{time:HH:mm}}
Yesterday: {{date-1d:YYYY-MM-DD}}
Next week: {{date+7d:YYYY-MM-DD}}
```

Date format codes:
- `YYYY` - 4-digit year (2024)
- `MM` - 2-digit month (01-12)
- `DD` - 2-digit day (01-31)
- `HH` - 2-digit hour (00-23)
- `mm` - 2-digit minute (00-59)
- `ddd` - Day of week (Mon, Tue)
- `MMMM` - Full month name (January)

### File Name and Path

```markdown
File name: {{title}}
File path: {{folder}}
```

### Prompts and User Input

```markdown
---
project: <% tp.system.prompt("Project name?") %>
priority: <% tp.system.suggester(["High", "Medium", "Low"], [1, 2, 3]) %>
---
```

### Conditional Logic

```markdown
<% if (tp.file.folder.includes("projects")) { %>
## Project Details
Status: In Progress
<% } else { %>
## General Note
<% } %>
```

## Common Template Patterns

### Daily Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - daily-note
---

# {{date:YYYY-MM-DD ddd}}

## Tasks
- [ ]

## Notes

## Meetings

## Journal

---
**Previous:** [[{{date-1d:YYYY-MM-DD}}]]
**Next:** [[{{date+1d:YYYY-MM-DD}}]]
```

### Project Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - project
status: planning
priority: medium
related-to: []
---

# {{title}}

## Overview

Brief description of the project.

## Goals

- [ ] Goal 1
- [ ] Goal 2

## Tasks

- [ ] Task 1
- [ ] Task 2

## Resources

-

## Notes

## Timeline

Start Date:
Target Completion:

## Related Projects

-
```

### Meeting Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - meeting
meeting-date: {{date:YYYY-MM-DD}}
attendees: []
---

# {{title}}

**Date:** {{date:YYYY-MM-DD}}
**Time:** {{time:HH:mm}}
**Attendees:**
-

## Agenda

1.
2.

## Discussion

## Action Items

- [ ]

## Next Meeting

Date:
Topics:
```

### Book/Article Notes Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - reading
  - book
author:
title:
year:
status: reading
rating:
---

# {{title}}

**Author:** {{author}}
**Year:** {{year}}

## Summary

## Key Takeaways

1.
2.
3.

## Highlights

>

## Personal Thoughts

## Related

-
```

### Person Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - people
role:
organization:
contact:
---

# {{title}}

## Role

## Contact Information

- Email:
- Phone:
- LinkedIn:

## Interactions

### {{date:YYYY-MM-DD}}

## Notes

## Related Projects

-
```

### Zettelkasten Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - seedling
aliases: []
related-to: []
---

# {{title}}

## Main Idea

Core concept in one or two sentences.

## Details

Expanded explanation and examples.

## Connections

This connects to:
- [[Related Note 1]]
- [[Related Note 2]]

## Sources

-

## Further Questions

-
```

### MOC (Map of Content) Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - moc
---

# {{title}} - Map of Content

## Overview

Brief description of this topic area.

## Core Concepts

- [[Concept 1]]
- [[Concept 2]]
- [[Concept 3]]

## Subtopics

### Subtopic A
- [[Note 1]]
- [[Note 2]]

### Subtopic B
- [[Note 3]]
- [[Note 4]]

## Related MOCs

- [[Other MOC]]

## Resources

-
```

### Research Note Template

```markdown
---
created: {{date:YYYY-MM-DD}}
tags:
  - research
research-question:
status: in-progress
---

# {{title}}

## Research Question

## Hypotheses

1.

## Methodology

## Findings

### Finding 1

Evidence:
-

### Finding 2

Evidence:
-

## Conclusions

## Future Research

-

## References

-
```

## Advanced Templater Features

### Dynamic File Creation

Create linked files automatically:

```markdown
<% tp.file.create_new("New Note", "New Note Title", false, "folder/path") %>
```

### Run Commands

```markdown
<% tp.obsidian.command("Command Name") %>
```

### JavaScript Functions

```markdown
<%*
function calculateDaysSince(date) {
  const start = new Date(date);
  const now = new Date();
  const diff = now - start;
  return Math.floor(diff / (1000 * 60 * 60 * 24));
}

const projectStart = "2024-01-01";
const days = calculateDaysSince(projectStart);
%>

Project running for <%= days %> days.
```

### System Clipboard

```markdown
Clipboard content: <% tp.system.clipboard() %>
```

## Template Organization

### Recommended Structure

```
templates/
├── daily/
│   └── daily-note.md
├── projects/
│   ├── project.md
│   └── meeting.md
├── reading/
│   ├── book.md
│   └── article.md
└── zettelkasten/
    ├── seedling.md
    └── moc.md
```

## Template Best Practices

1. **Consistent frontmatter** - Use same property names across templates
2. **Meaningful tags** - Include relevant tags in template
3. **Linked structure** - Include related note sections
4. **Prompts sparingly** - Too many prompts slow note creation
5. **Version control** - Keep templates in version control
6. **Test templates** - Create test notes to verify template behavior

## Using Templates

### Via Templater

1. Create new note
2. Run command: "Templater: Insert Template"
3. Select template from list

### Via Hotkey

Configure hotkeys for frequently used templates:
1. Settings → Hotkeys
2. Search for "Templater: Insert Template"
3. Assign keyboard shortcut

### Folder Templates

Automatically apply templates to new notes in specific folders:
1. Templater Settings → Folder Templates
2. Map folder → template

## Template Variables Reference

### Templater Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{date}}` | Current date | `2024-01-15` |
| `{{time}}` | Current time | `14:30` |
| `{{title}}` | Note title | `My Note` |
| `{{folder}}` | Current folder | `notes/projects` |
| `tp.file.creation_date()` | File creation date | Function call |
| `tp.file.cursor()` | Place cursor here | Cursor position |
| `tp.file.selection()` | Selected text | Selected content |

### Common Patterns

**Place cursor at specific location:**
```markdown
# {{title}}

<% tp.file.cursor(1) %>

## Notes

<% tp.file.cursor(2) %>
```

**Insert selected text:**
```markdown
# Quote

> <% tp.file.selection() %>
```

**Create backlink to previous note:**
```markdown
**Previous:** [[<% tp.date.yesterday() %>]]
```
