# Context: Infographic / data visualization

For editorial summary panels, data viz, whiteboard explainers, and any image where the goal is "compress information into a single visual." Nano Banana Pro is unusually strong at this — it renders legible stylized text and synthesizes structured layouts in one pass.

## Pick a sub-style up front

Infographics live on a spectrum from polished editorial to hand-drawn whiteboard. The first decision is which end of the spectrum the user wants:

- **Polished editorial** — clean modern layouts, sans-serif type, charts and pull-quotes, brand-y colors. Reads like a slide from a top-tier consulting deck or magazine spread.
- **Technical diagram** — schematic, labeled, mostly lines and boxes. Reads like a textbook figure.
- **Hand-drawn whiteboard** — informal, visible marker strokes, lecture-feel. Reads like a professor's explanation.

If unclear, ask: "Polished editorial, technical diagram, or hand-drawn whiteboard?"

## Stock prompt — polished editorial

```
A clean modern infographic summarizing [TOPIC]. Layout: [describe sections —
e.g., "a hero stat card at the top, two charts side-by-side in the middle, a
stylized pull-quote box at the bottom"]. Use a [color palette — e.g., "deep
navy and warm coral on off-white"]. Sans-serif typography throughout, with
headlines in heavy weight and body labels in regular. Charts: [type — bar,
line, donut] with clean axis labels and value annotations. Quote text in
large quotation marks: "[QUOTE]". Background: subtle off-white, no glow or
gradient. Render at 4K, suitable for a presentation slide or social share.
```

## Stock prompt — hand-drawn whiteboard

```
A hand-drawn whiteboard diagram explaining [CONCEPT], suitable for a
university lecture. Use different colored markers for different parts:
[part A] in blue, [part B] in red, [part C] in green. Include legible
hand-lettered labels for [key terms — name them explicitly]. Arrows and
connecting lines drawn in black marker, slightly imperfect with natural
hand wobble. Background: clean white whiteboard with subtle reflections.
Marker strokes show texture and pressure variation. Render at 4K.
```

## Stock prompt — technical diagram

```
A clean technical diagram of [SYSTEM]. Schematic style: boxes for components,
labeled arrows for flows. Monochrome (black on white) with one accent color
([color]) for [highlight — e.g., "the critical path"]. Sans-serif labels
throughout, all text legible. Layout: [describe — e.g., "left-to-right data
flow"]. Include a small legend in the bottom-right. No background gradients
or decorative elements. Render at 4K.
```

## Powerful patterns

**Compress a document into a visual** (per the Nano Banana Pro guide):

> Generate a clean modern infographic summarizing the key financial highlights from this earnings report. Include charts for "Revenue Growth" and "Net Income", and highlight the CEO's key quote in a stylized pull-quote box.

Pass the source PDF or document as a reference image and let the model extract + visualize.

**Decomposed object infographic** (when the topic is a thing, not data):

> Hyper-realistic infographic of [OBJECT], deconstructed to show the texture of [layer 1], the [property] of [layer 2], and the [property] of [layer 3]. Label each layer with its [meaningful attribute].

Use this for product anatomy, food breakdowns, mechanical parts.

## Composition principles

- **Aspect ratio**: pick one and state it. 16:9 for slide decks, 1:1 for social, 4:5 for IG feed, 3:4 for print.
- **Hierarchy**: one focal element (the headline or the hero number), supporting elements arranged around it.
- **One accent color** beyond the base palette. More than one creates visual chaos at thumbnail size.
- **Quote any specific text** in the prompt — chart titles, axis labels, the headline, the CEO quote.
- **No fake data** — if the user gives you a topic without numbers, write the prompt with placeholders and ask them to fill in real values rather than letting the model invent.

## Common drift

If the output has unreadable squiggle-text instead of letters, that's a sign the model picked the wrong style mode. Re-prompt with a stronger style anchor — "polished editorial like a consulting deck" or "the typography style of a New York Times graphic" — and the model usually locks back in.
