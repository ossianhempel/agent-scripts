# Context: Viral thumbnail (YouTube-style)

For YouTube video thumbnails, viral-style hook images, and any case where the deliverable needs to **stop the scroll at thumbnail size**. Different from `tiktok-instagram-vertical` because YouTube is 16:9 horizontal and the platform doesn't overlay UI on top of the thumbnail itself — so the entire frame is yours.

## Hard format constraints

- **Aspect ratio**: 16:9 horizontal
- **Resolution**: 1920×1080 px minimum (request 4K when available)
- **Readability target**: must communicate at 320×180 (the smallest YouTube renders thumbnails)

## The viral thumbnail formula

Every viral thumbnail has three elements working together:

1. **A face with a strong expression** — surprise, shock, awe, disgust. Eyes wide, mouth open.
2. **A bold subject or contrast** — the thing the video is about, presented at maximum visual impact.
3. **Massive overlay text** — 2–5 words, pop-style, with thick outline so it survives compression.

Skip any of those three and the thumbnail loses tension. Use all three and you have the formula.

## Stock prompt template

```
Design a 16:9 viral video thumbnail. [If using a reference image of a person:
"Use the person from Image 1. Keep the person's facial features exactly the
same as Image 1, but change their expression to look [shocked / excited /
horrified / amazed]."] Pose the person on the [left / right] side of the
frame, [pointing / gesturing / reacting] toward the [opposite side].

On the [opposite side], place [SUBJECT — concrete, specific].

Graphics: add a bold [color] arrow or visual element connecting the person's
gesture to the subject. Overlay massive pop-style text in the middle:
"[HEADLINE — 2 to 5 words]". Use heavy sans-serif type, [color] fill,
thick white outline, drop shadow.

Background: blurred [setting] — bright, high contrast. Pump up saturation
and global contrast. The thumbnail must read clearly at 320×180.

Render at 4K, 16:9 horizontal.
```

## Variations

**No-person product hook**: if the topic is a product or thing rather than a reaction, drop the person and lean harder on the contrast:

```
A 16:9 viral thumbnail. Center the [SUBJECT] dramatically, hero-lit and
filling the middle 60% of the frame. Bold [color] background with subtle
radial vignette focusing attention. Overlay massive pop-style text on the
[upper / lower] portion: "[HEADLINE]". Heavy sans-serif type, thick outline,
drop shadow. High saturation, high contrast. Reads clearly at 320×180.
```

**Before / after split**:

```
A 16:9 split-screen viral thumbnail. Left half: [BEFORE STATE] — desaturated,
slightly dim. Right half: [AFTER STATE] — vibrant, well-lit. A bold yellow
arrow with a black outline points from left to right across the seam.
Overlay text at the top: "[HEADLINE]" — heavy sans-serif, white with thick
black outline. 16:9, high contrast, pumped saturation.
```

**Reaction shot only**:

```
A 16:9 viral thumbnail dominated by a single reactive face: [DESCRIBE FACE
or "the person from Image 1"] with [exaggerated expression — eyes wide,
mouth open, hands raised to face]. Tight crop — face fills the middle two
thirds. Bright frontal lighting, slightly overexposed for that "shocked
phone-photo" look. Single strong emoji or graphic element in one corner
pointing back at the face. Massive 2-word headline overlay: "[HEADLINE]".
High saturation, high contrast.
```

## Text overlay tactics

- **2–5 words max**. More than 5 and it's unreadable at 320×180.
- **Use ALL CAPS or Title Case** — mixed case loses visual weight.
- **Number first if there is one** — "3 MISTAKES" reads faster than "MISTAKES YOU MAKE".
- **One color of text** unless using a deliberate two-color contrast (e.g., main word in yellow, kicker word in white).
- **Always quote the headline in the prompt** — `Overlay text: "I QUIT MY JOB"`. Without quotes the model gets creative.

## Color tactics

- **High-saturation backgrounds** beat muted ones for click-through. Reds, yellows, electric blues.
- **Avoid the YouTube red** (#FF0000) — UI competition.
- **Stay within 3 colors total** — face skin tone, background, text. More than 3 looks busy at thumbnail size.

## What to avoid

- **Subtle, sophisticated, "tasteful"** — the format rewards the opposite of all of these.
- **Text that wraps to 3+ lines** — breaks at thumbnail size.
- **Multiple subjects competing for attention** — pick one focal element.
- **Realistic restraint** — viral thumbnails are graphic design, not photography. The expression is exaggerated, the colors are pumped, the arrow is huge. Embrace it.
