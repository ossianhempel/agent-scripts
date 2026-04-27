# Context: Phone mockup (lifestyle product shot)

For App Store hero images, landing-page heroes, marketing emails, and any case where the deliverable is "photo of a phone in a hand displaying my screenshot." The skill's job is to produce a mockup that looks like real product photography while preserving the screenshot pixel-perfect.

## The non-negotiable

The user **uploads a raw simulator/device screenshot** as the reference image. Do **not** ask them to upload a pre-framed mockup. The model's job is to embed the raw screenshot into a photorealistic phone — if you start from a mockup, the model treats the mockup chrome as content and re-renders it (poorly).

## Stock prompt template

This is the verbatim template the user has been refining in their daily notes — use it as the base. Customize the brand-aesthetic line per the user's brand. Always send it as `edit_image` with the raw screenshot as the reference.

```
Use the provided image strictly as the phone screen content. Do not modify,
redraw, restyle, enhance, or alter the UI in any way. Preserve all text, colors,
layout, spacing, and pixels exactly as provided.

Create a photorealistic lifestyle product shot of a modern smartphone held
naturally in a human hand.

The phone should appear realistic and premium, with accurate proportions,
rounded corners, thin bezels, and subtle reflections on the glass. The provided
screenshot must be mapped perfectly onto the phone screen with no cropping,
stretching, perspective distortion, color shift, or UI changes.

Scene style:
- Clean studio background (soft white or very light neutral)
- Natural skin tones, realistic fingers and nails
- Soft diffused lighting, commercial photography quality
- Shallow depth of field, subtle shadow under the hand
- [BRAND AESTHETIC LINE — see options below]

Camera:
- Eye-level or slight 3/4 angle
- 50–70mm lens look
- High realism, no illustration, no stylization

Critical constraints:
- Do NOT edit or enhance the app UI
- Do NOT change fonts, icons, colors, or spacing
- Do NOT add overlays, glare over content, or UI effects
- The phone screen must look exactly like the provided image, only embedded into the device

Output: ultra-realistic product photography, suitable for App Store, landing page, or ads. Render at 4K.
```

## Brand aesthetic line — pick one

Add one of these as the final scene-style bullet, matching the user's brand vibe:

- **Apple-style** → `Minimal Apple keynote product photography style.`
- **Mental health / wellness / calm app** → `Calm, trustworthy, soft wellness aesthetic.`
- **Startup marketing / SaaS** → `Modern SaaS hero image, clean and premium.`
- **Fitness / energetic** → `High-energy, vibrant, athletic feel with subtle motion blur on the hand.`
- **Productivity / pro** → `Modern professional aesthetic, neutral palette, slightly desaturated.`

If none of these fits, ask the user one short question: "Which vibe — Apple-keynote, calm/wellness, SaaS, energetic, or pro?"

## Variations

**Two-hand portrait**: change `held naturally in a human hand` → `held with both hands as the person looks at the screen, phone fills lower half of frame, person's torso slightly soft-focused in the upper half`.

**Top-down on a desk**: change camera section → `Top-down 90° angle. Phone resting on a [neutral linen / light wood / matte concrete] surface, with [a coffee cup / open notebook / pair of AirPods] placed elegantly to one side, all softly out of focus.`

**In the wild**: replace clean studio background with a contextual scene: `On a busy café table with a flat white in the background softly out of focus.` / `Outdoors at golden hour with a warm bokeh background.` Keep the screenshot fidelity constraint untouched.

## Common drift to push back on

If the model returns a result where the UI looks "improved" — sharper text, recolored buttons, a different status bar — reroll with a **stronger constraint clause** and a regenerated prompt that names what drifted:

```
Your last output changed [specific drift, e.g., the status bar icons].
Re-render with the screen contents as a perfect 1:1 reproduction of the
provided image. The phone is just a frame; the screen is the source image,
unmodified.
```

The Nano Banana Pro guide's "edit don't reroll" principle especially applies here — almost always faster to nudge a near-correct mockup than to start over.
