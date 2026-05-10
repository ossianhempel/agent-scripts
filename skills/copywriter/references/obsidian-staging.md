# Obsidian Staging — Where Finished Copy Lives

Once you've drafted slideshow, video, or single-image copy for one of
Ossian's apps, write it into the app's **`Posts - Staging.md`** file in the
Obsidian vault. That's the single source of truth Ossian opens on his
phone or laptop to copy-paste into TikTok, Instagram, etc. Don't dump
finished copy only in chat — it gets lost.

This applies whenever the medium is a slideshow, carousel, short-form
video, or single-image post for one of the apps below. Drafts and
explorations can stay in chat; **ready-to-post** copy goes into staging.

## Vault Location

Vault root: `/Users/ossianhempel/ossians-second-brain-sync/`

Each app has its own top-level folder with a consistent layout:

```
PlateSnap/
  Posts - Staging.md       ← finished, copy-paste-ready posts (write here)
  PlateSnap Hooks.md       ← reusable hook bank (read for inspiration)
  PlateSnap Search Terms.md
  Top Formats.md
GainsLog/
  Posts - Staging.md
  GainsLog Hooks.md
  GainsLog Search Terms.md
  GainsLog Prompts.md
  Top Formats.md
Walkmon/
  Top Formats.md
```

Use the `obsidian` skill (or read the file path directly with `Read`) to
open these. Prefer the skill when available so reads/edits go through
the vault's normal flow.

```bash
obsidian read path="PlateSnap/Posts - Staging.md"
obsidian read path="GainsLog/Posts - Staging.md"
```

## Language by App

- **PlateSnap** → Swedish-first. Hooks, overlays, captions, hashtags all
  in Swedish unless Ossian explicitly asks for English.
- **GainsLog** → English-first.
- **Walkmon** → ask if unclear; default English.

## Entry Format (locked — match it exactly)

Every new entry in `Posts - Staging.md` follows this shape so Ossian can
scan, tap, and copy without thinking:

````markdown
### [ ] <short title — usually the hook or a paraphrase>

**Hook overlay:**
```
<the hook text — slide 1 / video opener title card>
```

**Per-point overlays:**
```
1. <point 1>
2. <point 2>
3. <point 3>
4. <point 4>
5. <point 5>
```

**Closing overlay (last 3s):**
```
läs caption 👇        ← PlateSnap (Swedish)
read the caption 👇   ← GainsLog (English)
```

**Caption:**
```
<full caption body, blank line between paragraphs>

<numbered points expanded if needed>

-
<one-line product line + CTA, e.g. "PlateSnap. Länk i bio.">
-

#hashtag1 #hashtag2 #hashtag3 #hashtag4
```
````

For **single-image posts**, replace the hook + per-point + closing trio
with one block:

````markdown
**Image text:**
```
<full text layout for the single image>
```
````

The caption block stays the same.

## Format Rules

- **Checkbox prefix `[ ]`** in the heading. Ossian flips it to `[x]` or
  deletes the entry once posted.
- **Code blocks (```) around every overlay and the caption.** This is
  the whole point: tap the copy-button on each block, paste, done. No
  cleanup, no markdown leaking into the post.
- **Section headings (`## Pain / warning`, `## On-track signals`, etc.)
  to group entries by theme.** Add a new H2 if a new theme shows up;
  otherwise file under an existing one.
- **Newest entries near the top** under their section.
- **Hashtags inside the caption code block**, on their own line at the
  bottom, separated from the body by a blank line.
- **Em-dashes are still banned** (this is the same rule as everywhere
  else in the copywriter skill — staging is no exception, and the
  tiktok-slides config-loader will reject them anyway).
- **Don't add commentary outside the code blocks.** No "this one's
  punchier" notes, no rationale, no variant labels. If you have
  alternates, put them in chat — staging is the chosen version only.
- **Hook should match the hook overlay verbatim** (or near-verbatim) at
  the top of the caption, so the reader who tapped through gets the
  same opener they stopped scrolling for.

## Workflow

1. **Draft in chat** — show Ossian the hook, overlays, and caption
   inline. Iterate until he greenlights it.
2. **Read the existing `Posts - Staging.md`** for that app to (a) avoid
   duplicating a hook and (b) match the existing section structure.
3. **Append the new entry** under the right H2 section, using the
   format above. If no section fits, add a new H2.
4. **Confirm with Ossian** before writing if the post is large or if
   you're unsure which app folder it belongs to. For small additions
   to an established pattern, just write and tell him where it landed.

## Hook Bank — Read Before Drafting

`<App>/<App> Hooks.md` is the running library of hooks Ossian has
already used or saved. Always read it before drafting a new hook so you
can:

- Avoid repeating a hook that's already been posted.
- Reuse a structural pattern that's already worked, with a new angle.
- Append a new hook + variations back to this file when you generate
  them, so the bank compounds.

Pair this file with [slideshow-carousel.md](./slideshow-carousel.md)'s
mining workflow — the hook bank is where mining output gets persisted.

## Don't

- Don't write finished copy only in chat. Chat scrolls away. Staging
  is the durable surface.
- Don't reformat the entry shape. The code-block layout is what makes
  the file copy-paste-friendly on mobile; freeform prose breaks that.
- Don't delete other entries. Ossian deletes them as they ship.
- Don't add a new app folder without asking. Stick to PlateSnap,
  GainsLog, Walkmon unless told otherwise.
