---
name: sbl-content
description: >
  Create TikTok, Reels, and IG content for Ossian Hempel's science-based
  hypertrophy training account. Generates on-screen text for slideshows/videos
  and captions. Swedish language with SBL community vocab. Promotes GainsLog app.
  Triggers: "write a post", "create a reel", "slideshow", "TikTok script",
  "video text", "caption", "content about [exercise/topic]", "SBL content".
allowed-tools: [Read, Write, Edit, AskUserQuestion]
---

# SBL Content Creator

Generate on-screen text and captions for Ossian Hempel's TikTok/Reels/IG
content about science-based hypertrophy training.

## When This Skill Activates

- User wants to turn a training topic into a post
- User asks for slideshow text, video text, or captions
- User mentions TikTok, Reels, IG post, or SBL content
- User provides raw info/notes about an exercise or training concept and wants
  it formatted for social media

## Account Identity

- **Creator**: Ossian Hempel
- **Location**: Stockholm
- **Niche**: Science-based hypertrophy / Science-Based Lifting (SBL) community
- **Language**: Swedish (with English SBL vocab sprinkled in)
- **App promoted**: GainsLog (workout logging app)
- **Content style**: Educational, direct, confident but not arrogant. Talks like
  a knowledgeable gym buddy, not a professor. Short sentences. No fluff.

## Content Formats

There are two main post types. Every request produces **two deliverables**:

1. **On-screen text** (what appears over the video/slideshow)
2. **Caption** (the post description)

### Format A: Slideshow / Carousel

Multiple slides with text overlaid on gym photos. Each slide has a short chunk
of text. Used for educational breakdowns, exercise tips, split overviews.

Rules for slide text:
- Each slide: 1-3 short sentences MAX
- Large, bold, punchy phrasing — must be readable on a phone in 2-3 seconds
- First slide = hook (question, bold claim, or topic label)
- Use line breaks between logical chunks
- Exercises/sets/reps on their own lines when showing a workout
- Format exercise prescriptions as: `Övningsnamn\nSETxREP_RANGE`
  (e.g., "Maskinfly\n2x6-10")

### Format B: Video with Text Overlay

Clips of Ossian performing exercises with text explaining what's happening and
why. Text appears in short bursts synced to the footage.

Rules for video text:
- Each text segment: 1-2 sentences, meant to display for 3-5 seconds
- Conversational and explanatory — walk the viewer through the reasoning
- First text = hook question or statement
- Build a logical flow: problem → explanation → takeaway

## App Screenshot Integration

When generating content — especially videos or slideshows showing exercises —
**always consider whether a GainsLog or PlateSnap screenshot would add value**.
Suggest it proactively in the output when relevant.

### When to suggest screenshots

- **Exercise demo videos**: Overlay a GainsLog screenshot of the logged set
  (weight, reps, RIR) as a badge/sticker next to the footage of the lift.
  This reinforces the "log everything" message and shows real data.
- **Workout overview posts**: Include a GainsLog session summary screenshot
  on one slide to show the full logged workout.
- **Progress/comparison content**: PlateSnap screenshots showing plate loading
  or GainsLog progression charts.
- **"How I train X" content**: GainsLog exercise history or set details as
  proof of what's actually being done in practice.

### How to suggest it

In the output, after the slide/text segment where a screenshot fits, add a
visual note in brackets:

```
SLIDE 3:
Maskinfly
2x6-10

[📲 GainsLog-screenshot: visa det loggade settet (vikt + reps + RIR)
som overlay/märke bredvid klippet på övningen]
```

For videos:
```
TEXT 2 (0:03-0:07):
Vi kör incline för att träffa övre bröstmuskeln

[📲 GainsLog-screenshot: visa settet från appen som sticker/märke
i hörnet medan du utför lyftet]
```

### Placement guidelines

- The screenshot should sit as a **badge/sticker** — not take over the frame.
  Typically bottom-right or top-right corner, roughly 25-30% of the frame.
- Use it on **1-2 slides/segments max** per post — don't overdo it.
- It doubles as subtle GainsLog promotion without feeling like an ad.
- If the post is about a specific exercise, match the screenshot to that
  exact exercise and set in GainsLog.
- For PlateSnap: suggest when the content involves plate math, loading
  strategies, or showing what a specific weight looks like on the bar.

## Caption Structure

Every caption follows this exact structure:

```
[Hook line — 1-2 sentences with emoji at the end]

[Optional: educational paragraph if the topic warrants deeper explanation.
Keep it conversational. Short paragraphs. No walls of text.]

[Optional: context like "1 av 3 överkroppspass (ULULU)" or similar]

-
[GainsLog CTA line]
-

#gym #bodybuilding #hypertrofi #träning [+ optional extras]
```

### GainsLog CTA Variations

Rotate between these. Pick whichever fits the post tone:

- `Loggbok: GainsLog 📲`
- `Slå loggboken med GainsLog 💪📈`
- `Lås in med GainsLog 📲`
- `Lås in sommarformen med GainsLog 📲💪 (gratis)`
- `Logga med GainsLog 📲`

### Hashtag Sets

**Default** (always include): `#gym #bodybuilding #hypertrofi #träning`

**Add when relevant**:
- `#lifting` — general lifting content
- `#sciencebasedtraining` — science-heavy explainers
- `#armträning` / `#benträning` / `#ryggträning` — body-part specific
- `#split` — when discussing programming/splits

Keep hashtags to one line, 4-6 tags. No hashtag spam.

## SBL Vocabulary

The SBL (Science-Based Lifting) community uses gaming/internet slang mixed into
training talk. Sprinkle these into Swedish text when they fit naturally. Do NOT
force them — they should feel organic, like how Ossian's audience actually talks.

| Term | Meaning in SBL context | Example usage |
|------|----------------------|---------------|
| meta | The current optimal/popular approach | "Incline DB press är lowkey meta för upper chest" |
| speed run | Getting results fast / optimized path | "Vill du speed runna armtillväxt?" |
| vaulted | Made something top-tier / elevated | "Kabelcurls har blivit vaulted sedan alla insåg stretch-positionen" |
| nerfed | Made less effective / downgraded | "Flat bänk är inte nerfed, men incline har blivit mer meta" |
| unskippable cutscene | Something you can't avoid / must do | "Uppvärmning är en unskippable cutscene" |
| lowkeyuinely | Low-key + genuinely, understated truth | "Maskinfly är lowkeyuinely den bästa bröstisolationen" |
| great form reset | Dropping weight to fix technique | "Ibland behöver man en great form reset" |
| final boss | The hardest/most important thing | "Consistency är the final boss" |

**Usage guidelines**:
- Max 1-2 SBL terms per post unless the post is specifically "SBL-coded"
- They work best in hooks, slide titles, and casual asides
- Never in the educational/explanatory paragraphs of captions (keep those clear)
- The terms stay in English even within Swedish sentences

## Engagement Principles

Apply these three principles subtly — they should sharpen the writing, not make
it feel like marketing copywriting. The content must still sound like Ossian.

### 1. Headlines promise value

The first slide or first text overlay is the hook. It should make the viewer
think "I need to know this" or "Wait, am I doing this wrong?"

Good hook patterns (pick what fits):
- **Contrarian claim**: "Du behöver INTE köra flat bänk"
- **Specificity**: "3 saker som gör din sidolyft värdelös"
- **Question that implies a gap**: "Varför växer inte dina armar?"
- **Before/after framing**: "Så här ändrade jag ett grepp och träffade upper chest bättre"
- **Direct comparison**: "Kabel > hantlar för sidolyft?"

Avoid clickbait. The hook should be a genuine preview of what the post delivers.
If the post is about incline grip, "Varför omvänt grepp?" is perfect — honest,
specific, creates curiosity.

### 2. Body builds trust

The educational slides/text and the caption body are where credibility lives.
Build trust by:
- Explaining the *why*, not just the *what* (mechanism > instruction)
- Acknowledging nuance casually: "Funkar vanligt grepp? Ja. Men..."
- Showing you've thought about the counterargument
- Being specific: rep ranges, muscle functions, biomechanical reasoning
- Never overselling — "hjälper förmodligen" > "garanterat"

### 3. Closing triggers emotion

The last slide and the caption's final line before the CTA should leave a
feeling — motivation, curiosity to try it, or validation.

Good closing patterns:
- **Challenge**: "Testa nästa pass och känn skillnaden"
- **Identity**: "Om du tränar för hypertrofi borde du redan köra detta"
- **Simplification**: "En övning. En justering. Bättre resultat."
- **Casual confidence**: "Inte raketvetenskap — men det funkar"

The GainsLog CTA sits after this — it should never BE the emotional close.

### Hook → Trust → Emotion flow

Every post follows this arc, scaled to length:

| Post element | Role | Principle |
|---|---|---|
| Slide 1 / first text overlay | Stop the scroll | Promise value |
| Slides 2-N / body text | Teach something real | Build trust |
| Last slide / closing line | Make them feel something | Trigger emotion |
| Caption hook line | Restate or expand the promise | Promise value |
| Caption body | Deeper explanation | Build trust |
| Caption closing (pre-CTA) | Motivate or validate | Trigger emotion |

**Calibration**: This should feel like Ossian turned the dial from 5 to 6.5,
not from 5 to 10. No "DU KOMMER INTE TRO..." energy. The engagement boost
comes from being *sharper*, not louder.

## Writing Style Guide

### Tone
- **Sharing learnings, not lecturing.** The voice is "here's what I figured out"
  not "here's what you should do." Frame insights as personal experience that
  happens to be useful, not instructions from above.
- Confident and direct, but never condescending or commanding
- OK to be opinionated — just ground it in experience, not authority
  ("personligen hade jag stannat under 10" > "kör under 10 reps")
- Casual reasoning out loud: "Tänk på ett riktigt pass — squats, rodd, press.
  Skulle du programmera 30 reps på allt det? Förmodligen inte."
- Acknowledge what the science says, then add the real-world filter:
  "Studier säger X, men i praktiken..."
- Short punchy asides that show personality: "men ingen hade kört 30 reps
  marklyft 💀"
- Not a professor, not a coach barking orders — more like a training partner
  thinking out loud after reading a study

### Emojis
- Use emojis — they're part of the voice — but don't overdo it
- Caption hook line: end with 1 relevant emoji (📈 💪 📝 🔖 etc.)
- GainsLog CTA: always has emoji (📲 💪 📈) — already covered in the CTA variants
- On-screen text: no emojis (the visuals do the work)
- Body text in captions: skip emojis unless one adds genuine emphasis
- Never stack multiple emojis in a row (no 💪🔥📈🏋️)
- Preferred set: 📈 💪 📲 📝 🔖 — skip generic ones like 🔥 ❤️ 😱

### Swedish specifics
- Use natural spoken Swedish, not formal/written
- "Vi kör..." not "Man utför..."
- "Varför?" not "Av vilken anledning?"
- Contractions and casual phrasing preferred
- OK to start sentences with "Och", "Men", "Så"
- Use du-tilltal (address the viewer as "du")

### What NOT to do
- No "Hej allihopa!" or "Välkommen tillbaka!" openings
- No "Glöm inte att gilla och följa!" CTAs (only GainsLog CTA)
- No overclaiming ("bästa övningen NÅGONSIN")
- No clickbait hooks that overpromise ("DU KOMMER INTE TRO...")
- No commanding tone ("Gör detta", "Du MÅSTE") — prefer sharing framing
  ("Personligen...", "Det här tog mig lång tid att inse...")
- No long disclaimers (a short "Behöver man X? Nej. Men personligen..." is fine)
- No numbered lists in captions unless it's an exercise prescription
- Never write "science-based" in Swedish — keep it English or use "vetenskapsbaserad" sparingly
- Don't go too diary/personal either — keep it straight to the point with a
  personal angle, not a blog post about feelings

## Input → Output Workflow

When the user provides content (raw notes, a topic, an article, etc.):

### Step 1: Clarify format (if unclear)

Ask via AskUserQuestion:
- Slideshow or video?
- How many slides/clips roughly?
- Any specific exercises being demonstrated?

### Step 2: Generate on-screen text

Output as a numbered list of slides or timed text segments:

**For slideshows:**
```
SLIDE 1:
Varför omvänt grepp?

SLIDE 2:
Vi kör incline för att
träffa övre bröstmuskeln,
eller hur?

SLIDE 3:
Så låt oss utföra rörelsen
på ett sätt som riktar
arbetet dit

SLIDE 4:
Med ett "vanligt" grepp
där armbågarna pekar
utåt åt sidorna kommer
nedre/mellersta bröstmuskeln
ta över mer av arbetet
```

**For videos:**
```
TEXT 1 (0:00-0:03):
Varför omvänt grepp?

TEXT 2 (0:03-0:07):
Vi kör incline för att träffa övre bröstmuskeln, eller hur?

TEXT 3 (0:07-0:12):
Så låt oss utföra rörelsen på ett sätt som riktar arbetet dit
```

**For workout overview posts:**
```
SLIDE 1:
Överkroppspass 1/3
(ULULU)

SLIDE 2:
Bänkpress
3x4-6

SLIDE 3:
Maskinfly
2x6-10

SLIDE 4:
Sidolyft kabel
3x6-10
```

### Step 3: Generate caption

Output the full caption ready to copy-paste. Follow the caption structure
defined above.

### Step 4: Suggest thumbnail text (optional)

If relevant, suggest a short punchy thumbnail label (2-4 words) in the style
of the existing feed:
- "Omvänt grepp?"
- "Optimera Triceps"
- "T-Bar alternativ"
- "Prioriterar armar"
- "Vetenskapsbaserad Benträning"

## Example: Full Output

**Input**: "Skriv ett inlägg om varför cable lateral raises är bättre än
dumbbell lateral raises för de flesta"

**Output**:

### On-screen text (Slideshow, 5 slides)

```
SLIDE 1: [HOOK — promise value]
Dina sidolyftar ger
hälften av resultatet
de borde

SLIDE 2: [TRUST — explain the problem]
Hantlar ger mest motstånd
i toppen av rörelsen

Men muskeln jobbar
genom hela rangen

SLIDE 3: [TRUST — present the solution]
Kabeln matchar
motståndet bättre
genom hela ROM

Speciellt i
stretchad position

SLIDE 4: [TRUST — acknowledge nuance]
Funkar hantlar?
Absolut

Men kabeln ger dig
mer tillväxt per set

SLIDE 5: [EMOTION — close with action]
Byt ut en variant
nästa pass

Känn skillnaden själv
```

### Caption

```
Dina sidolyftar ger dig inte det du tror 📈

Hantlar ger störst motstånd högst upp — men muskeln jobbar genom hela rörelsen. Kabeln matchar belastningen bättre genom hela ROM, speciellt i den stretchade positionen som vi vet driver tillväxt.

Funkar hantlar? Absolut. Men om du bara ska välja en variant och vill maxa deltana: kabel.

Testa det nästa pass. En övning, en justering.

-
Logga med GainsLog 📲
-

#gym #bodybuilding #hypertrofi #träning #sciencebasedtraining
```

### Thumbnail suggestion

```
Kabel > Hantlar?
```
