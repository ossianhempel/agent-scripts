# Context: Product shot / brand asset

For ecommerce hero images, brand asset libraries, fashion-editorial spreads, and any image where the deliverable is "the product, made to look great." Two flavors live here: clean studio (catalog) and lifestyle editorial (campaign).

## Sub-style pick

- **Clean studio** — single product, neutral backdrop, even light, hero treatment. Used for primary catalog images and white-background ecommerce.
- **Lifestyle editorial** — product in context, narrative scene, fashion-magazine feel. Used for campaign launches and brand campaigns.

If both could fit, ask: "Clean studio or lifestyle editorial?"

## Stock prompt — clean studio

```
A premium studio product photograph of [PRODUCT]. Clean [color] seamless
backdrop. Subject centered, occupying the middle 60% of the frame. Lighting:
soft key light from camera-front-right with subtle fill from the left,
producing gentle gradient shadows that ground the product. Materials clearly
visible — describe textures: [matte / glossy / brushed / soft]. Camera: 100mm
macro lens, eye-level, slight downward tilt. Razor-sharp focus on the product,
slight rolloff at the edges. Color-accurate, neutral grade — no creative
filtering. Render at 4K, square 1:1 aspect ratio.
```

## Stock prompt — lifestyle editorial

```
A high-end lifestyle editorial photograph of [PRODUCT] in [SCENE — concrete
setting]. The product is the focal point but lives naturally in the
environment. [Subject(s) interacting with the product, if relevant — describe
the interaction, posture, expression]. Natural light from [direction] —
[time of day], soft and golden / cool and overcast / harsh and directional.
Color palette: [palette descriptor — e.g., "warm earth tones with deep
cobalt accents"]. Shallow depth of field, product crisp, surroundings
gently softened. Camera: 50mm prime, eye-level, [shot type — e.g.,
"3/4 angle, slight crop"]. Mood: [adjectives — e.g., "quiet, considered,
expensive"]. Render at 4K.
```

## Brand asset set (9-shot range)

When the user wants a coherent set of multiple shots from one product reference, use the Nano Banana Pro identity-locking approach:

```
Using Image 1 as the brand style reference, create 9 stunning fashion shots
as if from an award-winning fashion editorial. Add nuance and variety — vary
poses, angles, light direction, and supporting elements — but maintain a
consistent brand aesthetic across all 9. Generate nine images, one at a time.
The product silhouette, color palette, and overall mood must remain identical
to the reference. The variety should come from the surrounding scene, not
the product itself.
```

Pass the brand reference as the image input, then iterate on each frame individually if any drift. The "one at a time" instruction matters — batched generation often loses identity consistency.

## Material vocabulary

A surprisingly large fraction of product-shot quality comes from describing materials concretely. Pull from this when the user just gives you "a watch" or "a bag":

- **Metals**: brushed steel, polished chrome, matte titanium, antiqued brass, gold-plated, anodized aluminum
- **Leathers**: full-grain pebbled leather, smooth aniline calfskin, suede, patent leather, embossed crocodile
- **Plastics**: matte soft-touch, glossy injection-molded, frosted translucent
- **Fabrics**: heavy canvas, brushed merino, raw denim, technical ripstop, silk twill
- **Glass**: optical glass with crisp edges, sandblasted frosted, thick crystal
- **Wood**: oiled walnut, raw white oak, glossy lacquered maple, weathered driftwood

A specific material word does more than three generic adjectives.

## Lighting recipes

- **Apple keynote / hero**: soft top-front fill with a faint kicker from behind to separate from background
- **Ecommerce flat**: large softbox above and slightly forward, white bounce on the opposite side, no hard shadows
- **Editorial moody**: single hard light at 45° from one side, no fill, deep shadows accepted
- **Golden hour outdoor**: low warm sun behind subject (rim light), soft fill from front, sky-blue ambient

## What to avoid

- **"Professional" and "high-quality"** as modifiers — meaningless; the model already tries to be those things.
- **Naming a competitor brand** — outputs become legally awkward and stylistically muddled. Describe the look instead.
- **Listing every feature in the prompt** — the model gets distracted from the image. One product, one frame, one mood.
