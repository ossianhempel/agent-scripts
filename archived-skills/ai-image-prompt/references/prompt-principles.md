# Prompt principles for AI image generation

Distilled from the Nano Banana Pro 10-tip guide and the user's working notes. These apply to every prompt you write, regardless of the context tag. They are mostly model-agnostic — Gemini / Nano Banana Pro is the primary target, but the same principles produce better results on DALL-E, Midjourney, and Flux.

## 1. Edit, don't re-roll

If an image is 80% there, **don't regenerate from scratch**. Ask for the specific change instead. Conversational edits are what these models are best at, and they preserve continuity (composition, identity, lighting) that a re-roll would scramble.

> "That's great, but change the lighting to sunset and make the text neon blue."

When the user has a previous output and wants tweaks, prefer `edit_image` over `generate_image`. The fingerprint of the original image is anchored — you only describe the delta.

## 2. Talk in full sentences

Treat the model like a human art director, not a search engine. Comma-list prompts produce generic results.

- ❌ Bad: `"Cool car, neon, city, night, 8k."`
- ✅ Good: `"A cinematic wide shot of a futuristic sports car speeding through a rainy Tokyo street at night. The neon signs reflect off the wet pavement and the car's metallic chassis."`

The good version isn't longer for the sake of length — every clause is doing work. Wide shot establishes framing, "rainy Tokyo street at night" pins place + time + weather, "neon reflect off wet pavement" forces a concrete lighting interaction.

## 3. The specificity ladder

When the prompt feels generic, walk down this ladder and add a concrete detail at each rung:

1. **Subject** — not "a woman" but "a sophisticated elderly woman wearing a vintage Chanel-style suit"
2. **Setting** — not "in a park" but "on a wrought-iron bench in Luxembourg Gardens, late autumn, leaves on the path"
3. **Lighting** — source, quality, color temperature ("low golden-hour sun from camera-left, warm 3200K, long shadows")
4. **Mood** — one or two adjectives that lock the feeling ("contemplative, slightly melancholic")
5. **Materiality** — texture words ("matte finish", "brushed steel", "soft velvet", "crumpled paper", "wet sheen")
6. **Camera** — lens length, angle, depth of field ("50mm, eye-level, shallow depth of field with the background pleasantly blurred")
7. **Output** — resolution, aspect ratio, any overlay text in `"quotes"`

Not every prompt needs all seven rungs. But if your prompt is missing 3+ of them, it's almost certainly underspecified.

## 4. Quote any text that should appear in the image

Models render legible stylized text well — but only if you're explicit about what the text says.

> Overlay the text **"3 mins to dinner"** in massive pop-style yellow type with a thick white outline and drop shadow.

Quoting also helps when text appears in non-Latin scripts ("3分钟搞定!"). Without quotes, the model often gets creative and replaces or rewords.

Specify text **style** alongside content: "polished editorial", "technical diagram", "hand-drawn whiteboard with colored markers", "vinyl-cut sticker", "hand-lettered marker on craft paper".

## 5. Reference images = identity locking

Nano Banana Pro accepts up to 14 reference images (6 with high fidelity). Use this for **identity locking** — placing a specific person, character, or product into new scenarios without facial / object distortion.

Phrasings that work:

- `"Keep the person's facial features exactly the same as Image 1."`
- `"Keep the attire and identity consistent for all 3 characters across all 10 frames."`
- `"Use Image 1 as the brand style reference; preserve color palette and silhouette."`

When the model drifts, restate the lock more forcefully and name what's drifting: "The face in your last output is too round — keep the cheekbones and jawline exactly as in Image 1."

## 6. Request high resolution explicitly

Nano Banana Pro generates 1K to 4K natively. If you don't ask, you may get the model's default which is often lower than what you want. Add a clause:

> Render at 4K with high-fidelity surface texture detail.

For close-ups and texture-heavy shots, also describe imperfections: "subtle skin pores and freckles", "fine grain on the leather", "tiny scratches on the brushed metal" — this nudges the model toward photorealism instead of plastic-smooth output.

## 7. Be honest about composition

Aspect ratio and crop matter as much as content. State the format up front:

> Generate as a 9:16 vertical image, 1080×1920px, with the subject centered in the middle third.

For social formats with safe zones (TikTok, IG), describe the safe zones positively rather than negatively. Don't say "leave the top empty" — say "place the subject in the middle 60% with clean negative space in the top 25% for hook text overlay."

## 8. In-painting, colorization, style swap — describe semantically

For complex edits you don't have to mask manually. Describe what to change in plain language and the model handles the masking:

- **Object removal**: `"Remove the tourists from the background and fill the space with cobblestones and storefronts that match the surrounding environment."`
- **Seasonal swap**: `"Turn this scene into winter. Keep the house architecture exactly the same, but add snow to the roof and yard, and change the lighting to a cold overcast afternoon."`
- **Restoration**: `"Restore this damaged 1920s photograph: remove scratches and creases, balance the tones, sharpen the faces, but preserve the original sepia color and grain."`
- **Colorization**: `"Colorize this manga panel with a soft pastel palette — peach skin tones, lavender shadows, pale yellow background. Keep the line art exactly as is."`
- **Style swap**: `"Re-render Image 1 in the style of a hand-painted Studio Ghibli background. Keep all the same composition, characters, and props."`

## 9. Watermark / logo handling

Quick template for asking the model to remove a watermark naturally:

> "Replace the [logo / watermark] in the [corner] with the natural background instead. Don't touch anything else."

Don't ask the model to "remove" — the seam often shows. "Replace with [what should be there]" produces cleaner results.

## 10. Edge cases and unusual outputs

Less-common output types the model handles well — keep these in your back pocket:

- **Sprite sheets**: `"Sprite sheet of a woman doing a backflip on a drone, 3×3 grid, sequence, frame-by-frame animation, square aspect ratio."`
- **Floor plan → 3D interior board**: described as a single composite image with one large hero render plus three smaller views.
- **Decomposed object infographic**: `"Hyper-realistic infographic of a gourmet cheeseburger, deconstructed to show texture of the toasted brioche bun, the seared crust of the patty, and the glistening melt of the cheese. Label each layer with its flavor profile."`
- **Whiteboard summary**: `"Summarize [concept] as a hand-drawn whiteboard diagram suitable for a university lecture. Use different colored markers for [parts], legible labels."`
- **9-shot brand asset set**: `"Create 9 stunning fashion shots as if from an award-winning fashion editorial. Use this reference as the brand style. Generate nine images, one at a time."`

## What to leave out

Don't include things that don't matter. If you're writing a phone mockup prompt, you probably don't need to specify camera lens — the context handles it. If you're writing an infographic prompt, "shallow depth of field" is irrelevant. Brevity inside each section is fine; padding the prompt with generic descriptors ("beautiful, professional, high-quality") actively makes it worse — those words are noise the model has to filter out.
