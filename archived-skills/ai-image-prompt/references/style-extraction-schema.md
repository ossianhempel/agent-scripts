# Style fingerprint schema

When extracting a style from an existing image, emit JSON in this exact shape. Save it to `references/fingerprints/<slug>.json`.

The goal is a fingerprint detailed enough that a different person could reproduce the look without seeing the original image — but stripped of subject specifics so it transfers to new subjects.

## Schema

```json
{
  "name": "moody-editorial-food",
  "source_images": ["/path/to/source.jpg"],
  "extracted_at": "2026-04-27",
  "summary": "One-sentence description of the overall feel.",

  "colors": {
    "palette": ["#1a1a1a", "#d4a574", "#8b3a2f"],
    "dominant": "#1a1a1a",
    "accents": ["#d4a574"],
    "background": "deep charcoal black with subtle warm undertone",
    "saturation": "muted",
    "contrast": "high"
  },

  "typography": {
    "has_text": true,
    "style": "serif editorial display",
    "weight": "thin",
    "case": "mixed",
    "alignment": "center",
    "overlay_zones": ["top 20%"],
    "treatment": "white type with subtle drop shadow",
    "notes": null
  },

  "composition": {
    "aspect_ratio": "1:1",
    "subject_position": "centered, slightly low",
    "framing": "tight close-up",
    "depth_of_field": "shallow, background blurred",
    "negative_space_zones": ["top quarter", "bottom edge"],
    "rule_of_thirds": false,
    "symmetry": "near-symmetric"
  },

  "lighting": {
    "source": "single hard light from upper-left",
    "quality": "directional, hard shadows",
    "color_temperature": "warm 3200K tungsten",
    "shadows": "deep, sharply defined, falling to lower-right",
    "highlights": "specular on glossy surfaces",
    "time_of_day": null
  },

  "mood": ["intimate", "moody", "premium", "appetite-evoking"],

  "camera": {
    "lens_mm": 85,
    "angle": "slight 3/4 from above",
    "perspective": "natural, no fisheye",
    "style_raw": false,
    "shot_on": null
  },

  "effects": {
    "grain": "fine, barely visible",
    "vignette": "subtle dark vignette on edges",
    "post_processing": "warm split-tone, lifted blacks, slight orange-teal grade",
    "halation": false,
    "lens_flare": false
  },

  "subject_in_source": "plated meal on dark ceramic — left as reference, NOT part of style",

  "reusable_prompt": "A moody editorial photograph of [SUBJECT], shot tight and centered with a slight 3/4 angle from above. Single hard tungsten light from upper-left at warm 3200K, casting deep sharply-defined shadows to the lower-right. Deep charcoal-black background with a subtle warm undertone, muted high-contrast palette with rich amber and burnt-sienna accents. 85mm lens, shallow depth of field, background pleasingly blurred. Subtle dark vignette and a warm split-tone grade with lifted blacks. Fine grain. Premium, intimate, appetite-evoking feel. Render at 4K."
}
```

## Field guidance

**`name`** — short slug, kebab-case. The user picks; if they don't, propose one based on the dominant feel.

**`source_images`** — absolute paths to the reference image(s) used. Lets future-you trace fingerprints back to their origin.

**`summary`** — one sentence in plain English. The line you'd read out to remind yourself what this style is.

**`colors.palette`** — 3–6 hex codes. Eyeball them from the image; don't over-engineer. The dominant + 1–2 accents matter most.

**`colors.saturation`** — one of `desaturated`, `muted`, `natural`, `vibrant`, `oversaturated`.

**`colors.contrast`** — one of `low`, `medium`, `high`, `extreme`.

**`typography.has_text`** — `false` if the source has no overlay text, in which case the rest of the typography object can be `null`.

**`composition.aspect_ratio`** — string like `"9:16"`, `"1:1"`, `"4:5"`. Measure from the source.

**`composition.depth_of_field`** — `"deep, everything in focus"` / `"medium"` / `"shallow, background blurred"` / `"extreme bokeh"`.

**`lighting.source`** — describe direction and number ("single source from upper-left" / "two sources, key from front-right and fill from left" / "diffuse overcast, no clear source").

**`lighting.color_temperature`** — Kelvin value or named ("warm 3200K tungsten", "cool 6500K daylight", "mixed warm-cool").

**`mood`** — 2–4 adjectives. Concrete, not generic. "Intimate, moody, premium" beats "nice, cool, professional".

**`camera.style_raw`** — boolean. True if the image looks like the iPhone "Style: Raw" setting (low contrast, neutral grade, slightly washed). False otherwise.

**`camera.shot_on`** — set to a specific phrasing if relevant ("Shot on iPhone 14, style raw"). Most images leave this null.

**`subject_in_source`** — what the source image's subject was, **flagged as not-part-of-the-style**. This prevents the fingerprint from accidentally encoding the subject.

**`reusable_prompt`** — the most important field. A single prose paragraph that:

- Uses the literal placeholder `[SUBJECT]` for whatever the user wants to render.
- Bakes in everything from the structured fields above as full sentences (per the principles file — no comma soup).
- Includes the resolution request.
- Reads naturally end-to-end and can be pasted directly into a generator.

## Validation

Before saving, sanity-check the `reusable_prompt`:

1. Substitute `[SUBJECT]` mentally with three different things ("a portrait of a woman", "a vintage typewriter", "a plate of pasta"). Does it still produce the source's look in each case? If not, the fingerprint is leaking subject specifics.
2. Read it out loud. If it reads as a comma-separated tag list, rewrite as prose.
3. Confirm every concrete claim is in the source — don't invent. If you can't tell whether the lens was 50mm or 85mm, write `null` or describe the framing instead.
