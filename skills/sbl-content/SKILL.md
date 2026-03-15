---
name: sbl-content
description: >
  Create TikTok, Reels, and IG content for Ossian Hempel's science-based
  hypertrophy training account. Researches peer-reviewed studies, presents key
  findings with graph/figure links, then generates on-screen text for
  slideshows/videos and captions with scientific references naturally woven in.
  Swedish language with SBL community vocab. Promotes GainsLog app.
  Triggers: "write a post", "create a reel", "slideshow", "TikTok script",
  "video text", "caption", "content about [exercise/topic]", "SBL content",
  "find studies about", "research on", "what does the science say".
allowed-tools: [Read, Write, Edit, AskUserQuestion, WebSearch, WebFetch]
---

# SBL Content Creator

Research peer-reviewed training science and generate on-screen text and captions
for Ossian Hempel's TikTok/Reels/IG content about science-based hypertrophy
training.

## When This Skill Activates

- User wants to turn a training topic into a post
- User asks for slideshow text, video text, or captions
- User mentions TikTok, Reels, IG post, or SBL content
- User provides raw info/notes about an exercise or training concept and wants
  it formatted for social media
- User asks to find studies, research a topic, or wants science-backed content
- User says "what does the science say about..." or "find studies about..."

## Account Identity

- **Creator**: Ossian Hempel
- **Location**: Stockholm
- **Niche**: Science-based hypertrophy / Science-Based Lifting (SBL) community
- **Language**: Swedish (with English SBL vocab sprinkled in)
- **App promoted**: GainsLog (workout logging app)
- **Content style**: Educational, direct, confident but not arrogant. Talks like
  a knowledgeable gym buddy, not a professor. Short sentences. No fluff.

## Research Workflow

When a user provides a topic, **always research first** before creating content.
This ensures posts are grounded in real science, not just general knowledge.

### Step 1: Topic Research

Use WebSearch to find relevant studies. Search strategy:

1. **Start broad**: `"[topic] hypertrophy study"` or `"[topic] muscle growth
   meta-analysis"`
2. **Target PubMed**: `site:pubmed.ncbi.nlm.nih.gov [topic] hypertrophy`
3. **Check Google Scholar**: `site:scholar.google.com [topic] resistance training`
4. **Look for known researchers**: `"Schoenfeld" [topic]` or `"Nuckols" [topic]`
   (see Known Researchers section)
5. **Find figures**: `site:ncbi.nlm.nih.gov/pmc [topic]` (PMC has open-access
   figures)

Prioritize in this order:
- Recent meta-analyses and systematic reviews (strongest evidence)
- RCTs with clear results and good sample sizes
- Studies with screenshot-worthy figures (bar charts, dose-response curves)
- Studies by well-known researchers in the space

### Step 2: Research Summary

Present findings to the user in this format before generating content:

```
## Studier hittade

### 1. [Author et al. (Year)] — [Journal]
**Titel**: [Full title]
**Nyckelresultat**: [1-2 sentences summarizing the key finding relevant to the topic]
**Länk**: [URL]

📊 **Figur värd att screenshota**: [Yes/No]
[If yes]: Fig. X — [what it shows]. Länk: [direct figure URL if available]
Placering: [which slide it fits on]

### 2. [Author et al. (Year)] — [Journal]
...

## Rekommendation
[Which 1-2 studies to reference in the caption, and which figure to use as a
slide if applicable]
```

Aim for 2-4 studies. Don't overload — pick the most relevant and impactful.

### Step 3: User Picks

Ask the user which studies/findings to include before generating content:
- Which studies resonate for this post?
- Should we include a graph slide?
- Any specific finding they want to highlight?

### Step 4: Content Creation with References

Proceed to the content workflow below, but with study references naturally
woven into captions (see Study Reference Style) and graph slides suggested
where relevant (see Graph & Figure Integration).

## Study Reference Style

Study references in captions must match Ossian's casual, knowledgeable voice.
Never academic or formal.

### How to reference studies

**Casual Swedish mention** (preferred):
- "En studie av Schoenfeld et al. (2021) visade att..."
- "Enligt forskning av Pedrosa et al. (2023)..."

**Conversational integration** (even better):
- "Forskning visar att stretch-positionen driver mer tillväxt (Pedrosa et al., 2023)"
- "Vi vet från studier att volymen spelar roll — men inte hur folk tror (Krieger, 2010)"
- "Schoenfeld har visat att rep range spelar mindre roll än vi trodde"

**Ultra-casual** (for hooks/asides):
- "Forskningen är ganska tydlig här..."
- "Det finns studier som visar..."

### Rules

- Max **1-2 study references per caption** — this is social media, not a
  literature review
- References go in the **educational paragraph** of the caption, never in hooks
  or closing lines
- First name mentions only when the researcher is well-known in the community
  (e.g., "Schoenfeld" not "Brad J. Schoenfeld")
- Year in parentheses: `(2023)` — no journal names in the caption
- On-screen text **never** has citations — keep slides clean and punchy
- If referencing a specific number/finding, attribute it. If making a general
  claim supported by multiple studies, "forskning visar" is enough

## Graph & Figure Integration

Study figures can make powerful slides — a well-chosen bar chart says more than
three slides of text.

### Where to find open-access figures

- **PubMed Central (PMC)**: Open-access full texts with figures.
  Search: `site:ncbi.nlm.nih.gov/pmc [topic]`
- **ResearchGate**: Often has figure previews even for paywalled papers.
  Search: `site:researchgate.net [topic] figure`
- **Study supplementary materials**: Sometimes have clearer/simpler versions

### What makes a good graph for social media

- Clear bar charts or line graphs with obvious differences
- Not too many variables (2-4 groups max)
- Readable at phone size — avoid complex multi-panel figures
- Shows a clear "winner" or trend that supports the post's point
- English labels are fine — the caption explains it in Swedish

### How to suggest graph slides

In the output, suggest a dedicated graph slide using this format:

```
[📊 Studie-graf: Schoenfeld et al. (2021), Fig. 2
 Visar: Muskeltillväxt vid olika rep-ranges
 Länk: [URL]
 Placering: Slide 3 — helskärm med källa i nederkant
 Crop-tips: Beskär till bara stapeldiagrammet, behåll axeletiketter]
```

### Placement guidelines for graphs

- Graph slides work best as **slide 3-4** (after the hook and initial
  explanation, as "proof")
- Use as a **full-screen slide** with source credit at the bottom
- Credit line format: `Källa: Schoenfeld et al. (2021)` in small text
- Max **1 graph per post** — don't turn it into a research presentation
- The slide before the graph should set up what the viewer is about to see:
  "Och forskningen bekräftar det..."
- The slide after should interpret the finding in plain language

## Known Researchers & Sources

Quick reference for searching. These are the key names in hypertrophy and
training science — when researching a topic, search for their work specifically.

| Researcher | Focus areas | Search tip |
|---|---|---|
| Brad Schoenfeld | Volume, rep ranges, hypertrophy mechanisms | Most-published in the space. Start here for any hypertrophy question |
| Eric Helms | Natural bodybuilding, programming, nutrition | Great for programming and practical application |
| Greg Nuckols | Strength, programming, meta-analyses | Runs Stronger By Science — excellent analysis |
| James Krieger | Volume dose-response, meta-analyses | Key work on training volume |
| Milo Wolf | Stretch-mediated hypertrophy, muscle length | Leading researcher on long-length partials / stretch position |
| Henning Wackerhage | Molecular exercise physiology | Deep mechanistic work |
| Menno Henselmans | Evidence-based bodybuilding, frequency | Practical application of research |
| Chris Beardsley | Hypertrophy mechanisms, exercise biomechanics | Clear explanations of mechanisms |

**Good secondary sources** (science communicators):
- Jeff Nippard — YouTube, well-researched videos with study citations
- Revive Stronger — podcast/content with researcher interviews
- Stronger By Science (Greg Nuckols) — in-depth research reviews

**Key journals** to search:
- JSCR (Journal of Strength and Conditioning Research)
- Sports Medicine
- EJSS (European Journal of Sport Science)
- IJSPP (International Journal of Sports Physiology and Performance)
- Scandinavian Journal of Medicine & Science in Sports

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

Rotate between these. Pick whichever fits the post tone.

**Short CTAs** (quick, low-friction):
- `Loggbok: GainsLog 📲`
- `Slå loggboken med GainsLog 💪📈`
- `Lås in med GainsLog 📲`
- `Lås in sommarformen med GainsLog 📲💪 (gratis)`
- `Logga med GainsLog 📲`

**Pain-point CTAs** (longer, triggers the "that's a lot to track" feeling —
use after educational posts with many variables. These drive more downloads):
- `Volymer, intensitet, progression, övningsval — det är många variabler att hålla reda på. GainsLog gör det enkelt. Sätter upp ditt program baserat på vetenskapliga principer och ser till att du progressivt överbelastar över tid 📲`
- `Mycket att hålla koll på? GainsLog håller ordning på allt — från programmering till progressiv överbelastning — baserat på vetenskapliga principer 📲`

**Prefer the pain-point CTAs** for educational/science posts where the content
covers multiple training variables. The short CTAs work better for simpler
posts like workout overviews or single-exercise demos.

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

### Step 0: Research

Search for relevant studies on the topic using the Research Workflow above.
Present findings and ask the user which studies to include before proceeding.
Skip this step only if the user explicitly says they don't want research or
provides their own study references.

### Step 1: Clarify format (if unclear)

Ask via AskUserQuestion:
- Slideshow or video?
- How many slides/clips roughly?
- Any specific exercises being demonstrated?

### Step 2: Generate on-screen text

Include graph slide suggestions where a study figure adds value (see Graph &
Figure Integration).

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
defined above. Weave in casual study references in the educational paragraph
(see Study Reference Style).

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

### Step 0: Research output

```
## Studier hittade

### 1. Pedrosa et al. (2023) — European Journal of Sport Science
**Titel**: Partial range of motion training elicits favorable improvements in
muscular adaptations when carried out at long muscle lengths
**Nyckelresultat**: Träning i stretchad position gav signifikant mer
muskeltillväxt. Kabelvariant ger belastning i stretchad position till
skillnad från hantlar.
**Länk**: [PubMed URL]

📊 **Figur värd att screenshota**: Ja
Fig. 3 — Muskeltillväxt jämförelse mellan full ROM och partiella reps.
Placering: Slide 3

### 2. Newmire & Willoughby (2018) — JSCR
**Titel**: Partial vs full range of motion resistance training and its effects
on muscle hypertrophy
**Nyckelresultat**: Full ROM med motstånd genom hela rörelsen (som kabel ger)
producerar bättre hypertrofi-resultat.
**Länk**: [PubMed URL]

## Rekommendation
Referera Pedrosa et al. i captionen om stretch-position. Använd graf från
Pedrosa som slide 3 om den är tillräckligt tydlig.
```

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

[📊 Studie-graf: Pedrosa et al. (2023), Fig. 3
 Visar: Muskeltillväxt vid lång vs kort muskellängd
 Länk: [PMC figure URL]
 Placering: Slide 3 ALT — helskärm med källa i nederkant
 Crop-tips: Beskär till stapeldiagrammet, behåll axeletiketter]

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

Hantlar ger störst motstånd högst upp — men muskeln jobbar genom hela rörelsen. Kabeln matchar belastningen bättre genom hela ROM, speciellt i den stretchade positionen. Forskning visar att just stretch-positionen driver mest tillväxt (Pedrosa et al., 2023) — och det är precis där kabeln ger dig motstånd som hantlar inte gör.

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
