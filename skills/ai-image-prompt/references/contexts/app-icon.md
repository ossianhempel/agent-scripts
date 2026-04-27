# Context: App icon (iOS / Android)

For iOS, iPadOS, macOS, watchOS, and Android app icons. The hardest format on this list to get right because the icon will be rendered at 60×60px (or smaller) on a busy home screen — so it must communicate instantly.

## Hard format constraints

- **Canvas size**: 1024×1024 px (square)
- **Aspect ratio**: 1:1
- **Safe inset**: ~10% margin on all edges. iOS applies a rounded-corner mask (the squircle) — anything in the corners gets clipped. Android applies platform-specific masks (round, rounded-square, teardrop) which are even more aggressive.
- **No text**. Almost never works. The icon's name appears below the icon on the home screen — repeating the name inside the icon wastes pixels and looks amateur. Acceptable exceptions: a single letter or short monogram (1–2 characters), and only when it IS the brand mark.

## The 60×60 test

Before finalizing any prompt, mentally render the result at 60×60 — actual size on a phone home screen. Can you tell what it is? If not, simplify the concept.

The signature of a well-designed icon: **one focal element, one or two colors, readable as a silhouette at the smallest size.**

## Stock prompt template

```
Design a square app icon at 1024×1024 resolution for [APP TYPE].

Concept: [SINGLE-WORD CONCEPT — e.g., "a stylized leaf", "a minimalist
dumbbell", "a folded paper airplane"]. The concept must be instantly
readable at 60×60px on a home screen.

Style: [flat / subtle gradient / soft 3D]. [Brief style descriptor — e.g.,
"clean modern flat design with subtle inner shadow", "soft 3D with gentle
gradient and a single highlight", "duotone flat illustration"].

Color palette: [BACKGROUND COLOR] background filling the entire canvas,
with the [CONCEPT] in [FOREGROUND COLOR]. Maximum 2-3 colors total.

Composition: [CONCEPT] centered, scaled to fill roughly 70% of the canvas
with a 10% margin on all four edges (the iOS rounded-corner mask will clip
the corners — keep critical elements well inside the safe area). No text.

Output: clean, crisp, no JPEG artifacts, no watermarks. Pure flat
[or "subtly dimensional"] design.
```

## Style sub-modes

**Flat / minimalist (most common)**:
> Clean modern flat design. Solid color shapes, minimal detail, no gradients (or a single subtle gradient on the background). The shape is the design.

**Subtle 3D / dimensional**:
> Soft 3D rendering with gentle volumetric lighting from above. One subtle highlight, one soft shadow. Material: [matte plastic / soft clay / brushed metal]. Modern, premium feel.

**Duotone illustrated**:
> Duotone flat illustration in [color A] and [color B]. Subject rendered in clean shapes with minimal detail. Vintage-modern editorial feel.

**Skeuomorphic / textural** (use sparingly — feels dated unless executed perfectly):
> Skeuomorphic icon with realistic [material] texture, ambient occlusion, soft cast shadow. The object appears to sit slightly raised off the canvas.

## Color tactics

- **One bold background color** — it's what catches the eye in the home screen grid. Saturated, distinctive, not in the same family as iOS system colors (avoid pure system blue, system green, system red unless that's strategic).
- **One or two foreground colors** that contrast clearly with the background. White-on-color or color-on-white are reliable defaults.
- **Avoid white backgrounds** unless the brand demands it — they disappear against light home-screen wallpapers.
- **Avoid black backgrounds** unless the brand is dark-mode native — they fight against home-screen wallpapers and look dim.

## Concept patterns that work

- **Abstract symbol that hints at the function** (paper plane for messaging, mountain for outdoor app, flame for fitness streaks)
- **The brand monogram** — single letter or 2-letter mark, treated as a logotype
- **A literal but stylized object** (a magnifying glass for search, a calendar grid for a calendar app)

## Concept patterns that fail

- **Complex scenes** (a person at a desk, a city skyline) — unreadable at 60×60.
- **Realistic photographs** — collapse to noise at small size.
- **Multiple objects** — divides attention, none of them reads.
- **Text-heavy** — even short text becomes mush.

## When to ship multiple variants

Always generate 3 variants when the user asks for an icon, varying:
- The background color (keep concept identical)
- Or the concept (keep colors identical)

Side-by-side at 60×60 it becomes obvious which one wins. Use `edit_image` for variants once you have a base you like — same icon, different color.
