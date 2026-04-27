---
name: ai-image-prompt
description: >-
  Write high-quality prompts for AI image generators (Nano Banana Pro, Gemini,
  DALL-E, Midjourney) and extract reusable JSON style fingerprints from existing
  images. Trigger this skill aggressively whenever the user mentions image
  prompts, AI image generation, generating thumbnails, TikTok/Instagram
  thumbnails, IG reel covers, phone mockups, screenshot mockups, marketing
  product shots, infographics, app icons, viral thumbnails, or asks "what should
  I prompt" / "how should I prompt this" / "give me a prompt for an image" /
  "extract the style from this image" / "make a prompt for a [thing] image".
  Also triggers on requests to recreate the look of an existing image, mimic a
  style across new subjects, or convert a design board / mood image into a
  reusable style spec. Use this skill even when the user doesn't explicitly say
  "skill" — if the deliverable is an image prompt or a style description of an
  image, this skill applies.
user-invocable: true
---

You help the user produce excellent AI image generation prompts and reusable style fingerprints. Most of the value is in **specificity** and **format-fit** — a TikTok thumbnail and an App Store mockup need wildly different framing, even if the subject is the same.

You operate in three modes. Pick the mode from the user's phrasing — don't ask which one if it's obvious.

| Mode | Triggered by | What you produce |
|------|--------------|------------------|
| **A. Generate prompt** | "give me a prompt for…", "what should I prompt for…", "write a prompt that…" | A paste-ready prompt block |
| **B. Extract style fingerprint** | "extract style from…", "fingerprint this image", "JSON for this look", "what's the style here" | A JSON file under `references/fingerprints/` |
| **C. Generate now** | "generate this image", "make this image", "run it" — and they want the actual image, not just a prompt | Run Mode A, then call generate_image / edit_image; fall back to a `gemini` CLI snippet if no MCP is available |

When the request is ambiguous (e.g., "help me with an image prompt for my recipe app"), default to Mode A and ask one clarifying question only if you genuinely need it (usually: which context tag).

---

## Always start with the principles

Before writing any prompt, **read [references/prompt-principles.md](references/prompt-principles.md)** if you haven't loaded it this session. It's short and codifies the non-negotiables: full sentences (not comma soup), specificity ladder, edit-don't-reroll, identity locking, explicit resolution. Apply these to every prompt regardless of mode.

---

## Mode A — Generate prompt

### Step 1: Pick a context tag

Match the user's intent to a context file under `references/contexts/`. Each context bakes in format constraints (aspect ratio, safe zones, lens, style cues) so you don't have to remember them.

| Tag | When to use | File |
|-----|-------------|------|
| `tiktok-instagram-vertical` | TikTok video thumbnails, IG reel covers, vertical 9:16 social | [references/contexts/tiktok-instagram-vertical.md](references/contexts/tiktok-instagram-vertical.md) |
| `phone-mockup` | Lifestyle shots of a phone in hand, App Store hero, landing page hero with a screenshot | [references/contexts/phone-mockup.md](references/contexts/phone-mockup.md) |
| `infographic` | Data viz, editorial summary panels, whiteboard diagrams | [references/contexts/infographic.md](references/contexts/infographic.md) |
| `product-shot` | Brand-asset photography, fashion-editorial style product range | [references/contexts/product-shot.md](references/contexts/product-shot.md) |
| `thumbnail-viral` | YouTube thumbnails, viral-style hooks with bold text + subject + arrow | [references/contexts/thumbnail-viral.md](references/contexts/thumbnail-viral.md) |
| `app-icon` | iOS / Android app icons, square 1024×1024 | [references/contexts/app-icon.md](references/contexts/app-icon.md) |
| _(none)_ | Generic image — no preset format | Skip context, apply principles only |

If two tags fit, pick the more specific one. If none fits, work without a context file.

### Step 2: Build the prompt

Read the chosen context file. Combine its constraints with the user's subject/goal, applying the specificity ladder from `prompt-principles.md`:

1. **Subject** — who/what (with adjectives that pin down look)
2. **Setting** — where (concrete, not "a place")
3. **Lighting** — source, quality, time of day
4. **Mood** — feeling adjective(s)
5. **Materiality / texture** — what things are made of
6. **Camera** — lens (e.g., 50–70mm), angle, depth of field
7. **Output** — resolution (request 2K or 4K explicitly when supported), aspect ratio, any overlay text in `"quotes"`

Write in **full prose sentences** — never `"cool food, neon, top down, 8k"` style. The Readwise Nano Banana Pro guide is unambiguous on this: comma-list prompts get generic results.

### Step 3: Output format

Return one fenced code block tagged `prompt`, then a one-line note about which model it's tuned for and any caveats:

````
```prompt
<the full prose prompt>
```

_Tuned for: Nano Banana Pro (Gemini). Use `edit_image` if you have a reference; `generate_image` for fresh._
````

If a fingerprint was supplied as input, weave its `reusable_prompt` into the prose rather than appending it raw — fingerprints are style guides, not literal prompts.

### Step 4: Offer to generate (only when natural)

If the user seems to want the image, not just the prompt, say "want me to generate it now?" and switch to Mode C on confirmation. Don't ask reflexively — if they only asked for the prompt, leave it at the prompt.

---

## Mode B — Extract style fingerprint

You're translating a great-looking image into a JSON spec the user (or you) can paste back as context for future generations. This is the [@EXM7777 technique](daily-notes/2026-01-10) the user already uses with Gemini — codified.

### Step 1: Read the image(s)

Use `Read` on each image path the user provides. Claude has native vision — no external CLI needed. If they give multiple images, treat them as one cohesive style and merge observations.

### Step 2: Emit JSON matching the schema

Read [references/style-extraction-schema.md](references/style-extraction-schema.md) for the schema. Every field should be either filled with concrete observations or set to `null` (don't fabricate). Be specific: `"warm 3200K tungsten, single source from upper-right, hard shadows on subject's left"` beats `"warm light"`.

The most important field is `reusable_prompt` — a single prose paragraph that recreates this style for an arbitrary new subject (subject is left as `[SUBJECT]` placeholder). Validate it by mentally substituting a different subject and asking: would this still produce the same look?

### Step 3: Save it

Save to `references/fingerprints/<slug>.json`. The slug should be short and memorable (`moody-editorial-food.json`, `apple-keynote-product.json`). If the user doesn't give a name, propose one based on the dominant feel.

The fingerprints folder lives inside the skill itself so the library travels with the skill — every machine that has `ai-image-prompt` installed has access to all your saved styles.

### Step 4: Confirm and offer next step

Print the path you saved to and offer: "want me to write a prompt for [new subject] in this style?" — that's the natural next move.

---

## Mode C — Generate image now

### Step 1: Detect generation tools

Check what's available **once**, in this order:

1. **Gemini MCP** — does the tool `mcp__gemini__generate_image` (or similar — actual name varies by config) exist in your tool list? This is the fastest path.
2. **Gemini CLI** — `which gemini` succeeds? Falls back to a shell invocation.
3. **OpenAI CLI** — `which openai` and DALL-E access. Last resort.

If none: print the prompt from Mode A, plus a one-liner showing how to run it once they install something:

```bash
# Once you have gemini CLI:
gemini --model gemini-3-pro-image -p "$(cat <<'EOF'
<prompt here>
EOF
)"
```

### Step 2: Pick the right call

- **Generate from scratch** → `generate_image` with the prompt + aspect ratio.
- **Edit / modify a reference** → `edit_image` with the reference image(s) + prompt. Always prefer this when a reference exists. Per Tip #1 in the Nano Banana Pro guide: edits beat re-rolls every time.
- **Style transfer** (apply a fingerprint to a new subject + a content reference) → `edit_image` with the content image + the prompt that bakes in the fingerprint's `reusable_prompt`.

### Step 3: Save and show

Save outputs to `./generated-images/<timestamp>-<slug>.png` (cwd, not the skill dir — generated images are project artifacts, not skill assets). Show the result with `Read` so the user sees it inline. If they want changes, **edit, don't reroll** — call `edit_image` with the previous output as input plus the change description.

---

## When the user asks for help with a workflow you don't recognize

If the request doesn't fit Mode A/B/C cleanly (e.g., "help me build a moodboard from these 5 images" or "how do I make a 9-shot brand asset set"), fall back to the principles file and the closest context, and use judgment. The Nano Banana Pro guide has examples for unusual cases — sprite sheets, identity locking, in-painting, restoration, colorization — that are summarized in [references/prompt-principles.md](references/prompt-principles.md).

---

## Why this skill exists

You generate images often, the prompt knowledge lives across an Obsidian stub, a Readwise highlight, and scattered daily notes. Without this skill you re-explain the same constraints (TikTok safe zones, "shot on iPhone 14, style raw", phone-mockup invariants) every time. With it, one sentence ("TikTok thumbnail prompt for X") loads the right format file and produces the prompt with all defaults already correct.
