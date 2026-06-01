# Context: TikTok / Instagram vertical (9:16)

For TikTok video thumbnails, IG reel covers, and any vertical short-form social. The entire context is built around one fact: most viewers see this on a phone, briefly, with platform UI overlapping the image.

## Hard format constraints

- **Aspect ratio**: 9:16 vertical
- **Resolution**: 1080×1920 px (request 4K when available — generators downsample better than they upsample)
- **Orientation**: portrait

## Safe zones (the most important constraint)

Platform chrome covers significant portions of the image. Anything important — face, food, hook text — must live in the safe zone.

- **Top ~250px** is covered by TikTok UI (creator handle, music)
- **Bottom ~400px** is covered by the caption + buttons (like, comment, share, profile pic)
- **Middle 60% of the frame is the safe zone** — subject MUST live here
- **Top 25% of the canvas**: deliberately clean negative space or blurred background — reserved for hook text overlay added later in editing
- **Bottom 20%**: secondary clean zone for kcal / protein / CTA text overlay

## Subject placement

- **Subject centered in the middle third** of the canvas, vertically and horizontally
- Vertical orientation when subject has a vertical axis (a person, a phone, a tall stack of pancakes)
- For food: tight close-up framing, subject filling roughly 60–70% of the safe zone
- For people: faces in the upper half of the middle third (eyes around the rule-of-thirds line), so the face stays visible above the bottom UI

## Visual treatment

- **High contrast** — phone screens at thumbnail size lose detail; muted images disappear in feed
- **Saturated colors** — readable as a small thumbnail before viewers tap
- **Style raw** — the iPhone camera "Raw" look: lower contrast in-camera, neutral colors, no over-processing. Reads as "actually shot on a phone" rather than AI-rendered
- **Shot on iPhone 14** — phrasing convention that pushes the model toward natural phone-camera optics: slightly compressed depth of field, mild lens distortion at edges, sensor-realistic lighting

## Stock prompt template

When the user gives you a subject, drop it into this template (then refine per the specificity ladder in `prompt-principles.md`):

```
A 9:16 vertical photograph of [SUBJECT], shot on iPhone 14, style raw.
The subject is centered in the middle third of the frame in a tight composition,
with deliberate negative space in the top 25% for a hook text overlay and the
bottom 20% kept clean for kcal/CTA text. [Lighting] from [direction], natural
phone-camera depth of field. [Mood adjectives]. High contrast, saturated colors
that read clearly at thumbnail size on a phone screen. 1080×1920 resolution,
portrait orientation.
```

## Common subjects and overrides

**Food (most common)**:
- Tight overhead 3/4 angle, plate filling middle third
- Warm side-light suggesting natural window light
- Add: "garnish freshly placed, steam visible if hot, gloss on sauces"

**Person reaction shot (viral hook)**:
- Face in upper half of middle third
- Wide-eyed or open-mouth expression
- Mention: "looking slightly off-camera as if reacting to something"
- Bright, evenly lit — avoid shadow on face that disappears at small size

**Before/after split**:
- Vertical split down the middle of the safe zone
- Both halves equally lit, same camera angle
- Add: "clearly contrasting transformation, no labels (text overlay added in editing)"

## What to avoid

- **Wide landscape framing** — your subject ends up in the dead zones
- **Subjects against busy backgrounds** — at thumbnail size it's mush
- **Text baked into the image** — overlays go on after, in the editor; baked text usually conflicts with the platform's caption
- **Centered subjects with no negative space** — leaves nowhere for the hook text
- **Heavy stylization (oil painting, illustration)** — the format is built for "real moment captured on phone"; stylization fights the format
