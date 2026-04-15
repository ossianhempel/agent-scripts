---
name: article-outline
description: >
  Plan and outline long-form blog posts and articles. Mines Ossian's Obsidian
  vault for existing thinking, finds relevant studies and research, then
  produces a structured working outline that reads like a real writer's notes.
  Trained to avoid AI writing patterns. Supports Swedish and English.
  Triggers: "outline a blog post", "article about [topic]", "help me outline",
  "I want to write about", "blog post about", "plan an article",
  "write about [topic]", "article outline", "post outline".
allowed-tools: [Bash, Read, Glob, Grep, WebSearch, WebFetch, Write, Edit, AskUserQuestion]
---

# Article Outline

Research a topic by **starting in Ossian's Obsidian vault**, then filling gaps
with external sources. The vault is the anchor - it contains Ossian's existing
thinking, highlights, and positions. External research supports and challenges
vault findings, it doesn't replace them. If the vault has nothing on a topic,
that's a signal worth flagging (maybe the topic isn't ripe yet, or the angle
needs rethinking).

The output is a working outline that feels like a smart person's notes -
opinionated, specific, and structurally driven by the content itself.

## Feedback Log (DO THIS FIRST)

**At the start of every session, before doing anything else**, read the file
`feedback.log` in this skill's folder. It contains accumulated preferences and
corrections from previous sessions. Apply everything in it as if it were part of
this SKILL.md.

**During a session**, whenever Ossian gives a correction, states a preference, or
says something like "don't do X" / "I prefer Y" / "always do Z":

1. Decide: is this a **general preference** that applies to future sessions, or
   is it **specific to the current task only**?
2. If it's general, **immediately append it to `feedback.log`** using the Edit
   or Write tool. Don't wait until the end of the session.
3. Format each entry as: `[YYYY-MM-DD] <the preference or correction>`
4. Skip anything that only matters for the current task.

## When This Skill Activates

- User wants to plan or outline a blog post or article
- User says "I want to write about..." or "article about..."
- User asks for help structuring long-form content
- User mentions blog post, article, essay, or long-form writing
- User wants to explore a topic before writing

**Not for**: social media posts (use sbl-content or gainslog-content), prose
drafts, copywriting, or non-article formats.

## Scope

- **Output**: Working outline only. Never generate full prose drafts.
- **Format**: Blog posts, articles, essays. Not social media.
- **Topics**: Anything. Training, tech, personal essays, cross-domain.
- **Language**: Swedish or English. Match the user's language, or ask.

---

## Workflow

### Step 1: Understand the Topic

Read the user's request and identify:
- **Topic**: What is this about?
- **Angle**: What's the specific take or framing?
- **Audience**: Who's reading this? (Ossian's blog readers by default)
- **Language**: Swedish or English?

If the angle is vague, ask 1-2 clarifying questions. Don't over-interview.
Examples of good clarifying questions:
- "Is this more of a practical how-to or an opinion piece?"
- "Are you arguing a specific position or exploring the question?"
- "Who's the reader - developers, gym people, general audience?"

If the topic and angle are clear, skip straight to research.

### Step 2: Search the Obsidian Vault (THE FOUNDATION)

**This is the most important step in the entire workflow.** Every outline should
be anchored in what Ossian has already thought, read, and highlighted. The vault
is the difference between "AI researched a topic" and "Ossian's existing thinking
organized into an outline."

Mine Ossian's vault using the **Obsidian CLI** (`obsidian` command). This
requires Obsidian to be running. Don't do a single search and move on, exhaust
the vault before touching external sources.

**Spend more time here than on any other step.** A good vault search is 5-10
operations, not 1-2.

**Search strategy** (use all three approaches):

1. **Content search** with the CLI:
   ```bash
   obsidian search query="keyword" limit=20
   obsidian search query="related term" limit=20
   obsidian search query="synonym" limit=20
   ```
   Run multiple searches with different terms (synonyms, related concepts).

2. **Read relevant notes** found by search:
   ```bash
   obsidian read file="Note Name"
   ```

3. **Follow wiki-link trails** using backlinks:
   ```bash
   obsidian backlinks file="Note Name"
   ```
   When you find a relevant note, read it, then check its backlinks.
   Follow 1-2 levels deep, not more.

**What to extract from vault findings**:
- Direct quotes and highlights (with note title for attribution)
- Key ideas and positions Ossian has already formed
- Connections between notes (these become the outline's structure)
- Open questions or unresolved tensions in the notes
- Specific claims, numbers, or frameworks already captured

**If the vault search finds rich material**: The outline's sections should map
directly to clusters of vault findings. External research fills gaps.

**If the vault search finds little or nothing**: Tell the user. Options:
- Proceed with mostly external research (but flag that the piece won't be
  anchored in existing thinking)
- Suggest the user spend time in the vault first, then come back
- Adjust the angle to match what the vault does have

### Step 3: Ask Before External Research

**After presenting vault findings, ask the user** whether to search the web for
external sources. Web research takes time, and sometimes the vault material is
enough on its own.

Use AskUserQuestion with options like:
- **Yes, search the web** (find studies, articles, and data to support/challenge vault findings)
- **Vault only** (skip external research and build the outline from what's already in the vault)

If the user chooses vault only, skip Step 4 and go straight to presenting
findings (Step 5) using only vault material. Adjust the findings presentation
to omit the "External Research" section.

### Step 4: Search for Studies and Research

**Only after the user confirms.** External research has one job: support,
challenge, or add data to what the vault already contains. The vault tells you
what Ossian thinks; external sources tell you whether the evidence backs it up.

Use WebSearch to find sources that connect to vault findings.

**Search strategy by domain**:

| Topic domain | Where to search | Example queries |
|---|---|---|
| Training/health | PubMed, Google Scholar | `site:pubmed.ncbi.nlm.nih.gov [topic] meta-analysis` |
| CS/AI/tech | arxiv, HN, tech blogs | `site:arxiv.org [topic]`, `site:news.ycombinator.com [topic]` |
| General/essays | Web, specific authors | `"[topic]" [known author]`, `"[topic]" essay` |

**Prioritize**:
- Sources that add specific data or evidence to vault findings
- Contrarian or nuanced takes (not just confirmation)
- Recent work (last 2-3 years unless it's a foundational piece)
- Sources Ossian would actually cite (not generic listicles)

**For each source found, note**:
- Author and year
- Key finding or argument (1-2 sentences)
- URL
- How it connects to vault findings

Aim for 3-6 sources. Quality over quantity.

### Step 5: Present Combined Findings

**Lead with vault findings.** The vault material is the backbone; external
research is supporting evidence. Present them so the user sees their own
thinking organized first, then what external sources add to it.

Format:

```
## Your Vault - What You Already Have

### [Theme/Cluster 1]
- [Note title]: [key idea or quote from the note]
- [Note title]: [related point]
- Links to: [[Other Note]] (which adds [connection])

### [Theme/Cluster 2]
- [Note title]: [key idea]
- [Readwise highlight]: "[quote]" - from [book/article title]

**Vault coverage assessment**: [How much of the topic is already covered in the
vault? Where are the gaps that external research needs to fill?]

## External Research - Filling the Gaps

### 1. [Author (Year)] - [Short descriptor]
**Key finding**: [1-2 sentences]
**Connects to**: [which vault finding it supports/challenges/extends]
**Link**: [URL]

### 2. [Author (Year)] - [Short descriptor]
...

## Emerging Structure
[2-3 sentences on what story or argument is emerging. The structure should be
visible from the vault clusters - external research adds evidence, not new
sections.]
```

### Step 6: User Picks

Ask the user:
- Which findings resonate? Anything to drop?
- Is there an angle or structure emerging that they want to lean into?
- Any findings that surprised them or shifted their thinking?

This is a conversation, not a checkbox. Keep it brief.

### Step 7: Generate the Outline

Produce the working outline based on selected findings.

### Step 8: Generate Image Prompts

After the outline is complete, generate image prompts for the article. Every
article needs at least a hero image. Most articles also benefit from one or more
inline visuals (infographics, diagrams, charts, flowcharts) that make a key
point more concrete or scannable.

#### 8a: Hero Image

One prompt for the cover/header image that captures the article's thesis or
central tension.

**Hero image principles**:
- **Specific to the article**, not the general topic. An article about
  overestimating training volume needs a different image than a general fitness
  article.
- **Visual concept first.** Describe a concrete scene, composition, or visual
  metaphor that captures the thesis.
- **Include style direction.** Specify a visual style (e.g. editorial
  illustration, photorealistic, flat design, watercolor, etc.) that fits the
  article's tone.
- **Describe mood and color palette.** A contrarian opinion piece has different
  energy than a practical how-to.
- **Avoid cliches.** No generic stock photo concepts (person at laptop, light
  bulb for ideas, puzzle pieces). Find something visually interesting that a
  reader would actually stop scrolling for.
- **Keep it one paragraph.** 2-5 sentences, dense with visual detail.

#### 8b: Inline Visuals

Look at the outline's key points and identify where a visual would communicate
something better than text alone. Generate a prompt for each one.

**When to include an inline visual**:
- A claim involves a comparison (before/after, X vs Y, dose-response)
- There's data worth visualizing (a trend, a distribution, a threshold)
- A process or decision has multiple steps or branches
- A concept has a spatial or structural relationship

**Types of inline visuals** (pick what fits the content):
- **Chart/graph**: for data, trends, dose-response curves, comparisons
- **Flowchart**: for decision trees, processes, "if X then Y" logic
- **Diagram**: for relationships, system architecture, mental models
- **Infographic**: for summarizing a section's key points visually
- **Comparison visual**: side-by-side, before/after, spectrum

**Inline visual prompt principles**:
- **State the visual type explicitly** (e.g. "bar chart", "flowchart",
  "comparison infographic").
- **Describe the actual content/data** to include, not just the topic. "Bar
  chart showing sets per week (x-axis, 5 to 30) vs hypertrophy response
  (y-axis), with a clear plateau after ~12 sets" is useful. "A chart about
  training volume" is not.
- **Reference the section** it belongs in so the writer knows where it goes.
- **Keep style consistent** with the hero image when possible.

**If no inline visuals make sense**, skip this section. Don't force visuals
where text works fine. But most articles with data, comparisons, or processes
will benefit from at least one.

**Format in the outline**:

```
## Image Prompts

### Hero Image

[Detailed image generation prompt]

Style: [e.g. editorial photography, muted tones]
Aspect ratio: 16:9

### Inline: [Short descriptor] (for [Section Name])

Type: [chart / flowchart / diagram / infographic / comparison]

[Detailed prompt describing the visual's content, layout, labels, and data]

Style: [consistent with hero or adjusted for clarity]
Aspect ratio: [16:9 / 4:3 / 1:1, whatever fits]

### Inline: [Short descriptor] (for [Section Name])
...
```

---

## Outline Format

The outline is a **working document** - it should feel like notes a writer makes
before drafting. Not a template, not a table of contents, not a listicle
skeleton.

### Structure

```
# [Title Option A]
# [Title Option B]

**Thesis**: [One sentence. What is this article actually arguing or showing?]

**Angle**: [How is this different from what's already been written about this?
What's the specific lens?]

---

## [Section Name]

Key points:
- [Specific claim, not a topic label]
  - Support: [vault note or study reference]
  - Note to self: [marginal thought, question, or drafting hint]
- [Another specific claim]
  - Support: [reference]

## [Section Name]

Key points:
- [Claim]
  - Support: [reference]
  - "Quote worth using" - [source]
- [Claim]
  - Tension: [counterargument or complication to address]

## [Section Name]
...

---

## Connections & Threads

- [Connection between Section X and Section Y that could be a transition]
- [Recurring theme that ties the piece together]
- [Unexpected parallel worth exploring]

## Open Questions

- [Something unresolved that might need more research or just acknowledgment]
- [A claim that needs stronger support]
- [An angle the author hasn't decided on yet]

## Image Prompts

### Hero Image

[Detailed image generation prompt specific to this article's content and angle]

Style: [visual style that matches the article's tone]
Aspect ratio: 16:9

### Inline: [Short descriptor] (for [Section Name])

Type: [chart / flowchart / diagram / infographic / comparison]

[Detailed prompt describing the visual content, layout, labels, and data]

Style: [consistent with hero]
Aspect ratio: [as needed]
```

### Outline Principles

- **Vault findings shape the structure.** Sections should map to clusters of
  vault material. If Ossian has three distinct threads in his notes, those
  become three sections. Don't invent sections that have no vault anchor.
- **Vault references outnumber external references.** A healthy outline has
  more `[vault: ...]` citations than `[Author (Year)]` citations. If external
  sources dominate, the outline isn't anchored enough - go back to the vault.
- **Sections emerge from content, not a formula.** A training article might have
  3 sections; a tech essay might have 6. Let the material decide.
- **Key points are claims, not topic labels.** Write "Most people overtrain
  volume and undertrain intensity" not "Discussion of volume vs intensity."
- **Every claim links to support.** Vault note, study, or personal experience.
  No unsupported assertions in the outline.
- **Notes to self are first-person.** These are the writer's margin scribbles:
  "I should probably address the counterargument here", "This connects to the
  thing about progressive overload", "Need a concrete example."
- **Title options, not one title.** Give 2-3 options so the writer can feel out
  the voice. At least one title should be **search-intent driven** (see below).
- **Thesis is one sentence.** If it takes more, the angle isn't sharp enough.

### Title Strategy

Titles serve two jobs: getting clicks from social/newsletters (voice-driven)
and ranking in search (intent-driven). The outline should offer both kinds.

**Search-intent title**: Write it like the reader would type it into Google.
Think about the actual query someone has before they find this article. "How
many sets per week for hypertrophy" beats "More isn't better." The search
title doesn't need to be clever, it needs to match what people search for.

**Voice-driven title**: The punchy, opinionated, or curiosity-driven version.
This is what works on social, newsletters, and direct traffic. "Why you're
probably doing too many sets" or "The volume myth that won't die."

**Format in the outline:**

```
# [Search-intent title] (SEO)
# [Voice-driven title A]
# [Voice-driven title B] (optional)
```

The writer picks which to use as the `<title>` tag (SEO) vs the visible `<h1>`
(voice). Or uses the search-intent title for both if the topic is informational
and the audience is searching, not browsing.

**How to find the search-intent title:**

- Ask: "What would someone Google right before they need this article?"
- Use natural phrasing, not keyword-stuffed. "How many sets per muscle group"
  not "optimal training volume sets hypertrophy guide 2025."
- Questions work well: "Is high volume training better for hypertrophy?"
- Include the core term the article targets. If the article is about training
  volume, "volume" or "sets" must be in the search title.

---

## Anti-AI-Writing Rules

This is the most important section. The outline must avoid every common marker
of AI-generated writing. These rules apply to all text in the outline itself,
and serve as guardrails the writer should follow when drafting.

### Banned Vocabulary

Never use these words in the outline. They are the most common AI writing tells:

> delve, intricate, tapestry, pivotal, underscore, landscape, foster, testament,
> enhance, crucial, vital, significant, profound, steadfast, breathtaking,
> captivate, watershed, solidify, multifaceted, nuanced (as filler), robust,
> leverage, utilize, facilitate, paradigm, synergy, holistic, comprehensive,
> streamline, innovative, cutting-edge, game-changing, revolutionary

If you catch yourself reaching for one of these words, find the concrete,
specific word that actually says what you mean.

### Structural Tells to Avoid

These patterns scream "AI wrote this":

- **Rule of three**: "X, Y, and Z" lists everywhere. Real writers don't
  naturally group things in threes. Use 2 or 4 or 7 - whatever the content
  actually has.
- **Em dashes are banned**: Never use em dashes (—) in any outline or output.
  Restructure sentences using commas, periods, or parentheses instead. Do not
  substitute hyphens (-) as a workaround for em dashes either. If you find
  yourself reaching for a dash to insert a clause, use a comma or split into
  two sentences.
- **Negative parallelism**: "It's not about X - it's about Y." Once per article
  max. Twice is a pattern. Three times is a parody.
- **False ranges**: "From X to Y" or "Whether X or Y" used to sound inclusive
  but saying nothing. Be specific.
- **Reflexive summaries**: Starting a conclusion with "In conclusion" or
  restating every point. Trust the reader.
- **Bold-bullet format**: Section header, then bold keyword + explanation for
  every point. Vary the structure.
- **Symmetrical section lengths**: Real articles have a long meaty section and
  a short punchy one. AI makes them all the same length.

### Tone Tells to Avoid

- **Inflated symbolism**: Don't frame mundane things as epic narratives.
  Training is training, not "a journey of self-discovery."
- **Editorializing**: Don't tell the reader how to feel. "This is exciting"
  or "Interestingly" - just present the thing and let it be interesting.
- **Conjunctive filler**: "Moreover", "Furthermore", "Additionally" - these
  are crutch words. Cut them or use a real transition.
- **Superficial -ing commentary**: "Creating a more effective workout" or
  "Building on this foundation" - vague gerund phrases that add nothing.
- **Vague attribution**: "Experts say" or "Research suggests" without naming
  who. Always name the source or drop the claim.
- **Promotional tone**: Never sell the article's own content. "In this article,
  we'll explore..." - just start.
- **False humility**: "It's worth noting that..." - if it's worth noting, just
  note it.

### The Core Principle

> Write like a specific person thinking through a specific topic. Be concrete,
> have an opinion, let structure follow content. The reader should be able to
> tell that a human with particular experiences and views wrote this.

This means:
- **Specific over general.** "I gained 3kg on my squat 1RM in 8 weeks" beats
  "strength gains were observed."
- **Opinionated over balanced.** Take a position. Acknowledge counterarguments
  in passing, don't give them equal weight unless you genuinely think both sides
  have merit.
- **Concrete over abstract.** Name the study. Quote the number. Describe the
  actual experience. Abstractions are for summarizing, not for making points.
- **Asymmetric over symmetrical.** Not every point needs the same treatment.
  Spend 60% of the article on the core insight and 40% on everything else.

---

## Citation Style

References in the outline should be casual and attributive, matching how Ossian
would actually cite things in a blog post.

**From the vault**:
- `[from vault: "Note Title"]` or `[vault: "Note Title" - specific claim]`
- Direct quotes: `"The actual quote" - [vault: "Note Title"]`

**From studies**:
- `[Author et al. (Year)]` - casual inline
- For key findings: `Author (Year) found that [specific result]`
- Never: full journal citations, DOIs, or formal bibliography format

**From other sources**:
- `[Author, "Article Title"]` or `[Author on Blog/Publication]`

The outline is a working doc. Citations are breadcrumbs for the writer, not
formatted references for the reader.

---

## Language Handling

- Match the user's language. If they write in Swedish, outline in Swedish.
- If language is ambiguous, ask.
- Vault notes may be in either language - extract and present findings in
  whichever language the outline uses.
- Study titles stay in English regardless of outline language.
- Section headers and "notes to self" in the outline language.

---

## Example: Partial Outline

For a request like "Jag vill skriva om varfor folk overskattar traningsvolym":

```
# Hur manga set per muskelgrupp per vecka? (SEO)
# Mer ar inte battre: varfor volym ar overskattad
# Varfor du formodligen gor for manga set

**Tes**: De flesta som traner for hypertrofi gor fler set an de behover, och
skulle vaxa mer av farre set med hogre intensitet.

**Vinkel**: Personlig erfarenhet + forskning som visar att volym har avtagande
avkastning langre an folk tror.

---

## Volymdogmen

Nyckelpunkter:
- SBL-communityt har hamnat i en "mer ar battre"-mentalitet kring set per
  muskelgrupp per vecka
  - Support: [vault: "Training Volume Notes" - observation about volume creep]
  - Notering: Bor borja med ett konkret exempel fran min egen traningshistorik
- Schoenfelds volumstudier tolkas som att 20+ set ar optimalt, men det ar inte
  vad datan faktiskt visar
  - Support: [Schoenfeld & Krieger (2019)] - meta-analysen visar avtagande
    effekt ovanfor ~10 set/vecka
  - Notering: Ska jag ta med figuren fran meta-analysen? Tydlig kurva.

## Intensitet ar den saknade variabeln

Nyckelpunkter:
- Nar folk okar volym kompenserar de nastan alltid med lagre intensitet per set
  - Support: Personlig erfarenhet - mina loggar visar battre progression med
    farre, hardare set
  - "De flesta vet inte hur nara failure de faktiskt ar" - [vault: "RIR Notes"]
- Proximitet till failure driver tillvaxt mer an antal set
  - Support: [Refalo et al. (2022)] - systematisk review om proximity to failure
  - Tension: Men total volym spelar ocksa roll - var gar gransen?

---

## Kopplingar

- Volym-dogmen kopplar till progressiv overbelastning: folk lagger till set
  istallet for vikt/reps
- Min egen resa fran 20+ set till 10-12 per muskelgrupp speglar forskningen

## Oppna fragor

- Hur mycket ar individuellt? Bor jag adressa att nybborjare kanske behover
  mer volym for motorisk inlarning?
- Finns det en bra studie pa volym + intensitet interaktionen?

## Image Prompts

### Hero Image

A single barbell loaded with far too many small plates on each side, bowing
under its own absurd volume, next to a second barbell with just two heavy
plates sitting perfectly balanced. Shot from slightly above on a clean gym
floor, shallow depth of field pulling focus to the overloaded bar. The contrast
between cluttered excess and simple sufficiency is the whole argument in one frame.

Style: editorial photography, slightly desaturated with warm gym lighting
Aspect ratio: 16:9

### Inline: Dose-response curve (for Volymdogmen)

Type: chart

Line chart with sets per muscle group per week on the x-axis (range 4 to 30)
and hypertrophy response on the y-axis. The curve rises steeply from 4 to 10
sets, flattens noticeably between 10 and 15, and goes nearly flat (possibly
slightly declining) above 20. A vertical dashed line at ~12 sets labeled
"diminishing returns." Clean, minimal axes, no grid clutter. Based on
Schoenfeld & Krieger (2019) meta-analysis data.

Style: clean editorial chart, same warm muted palette as hero
Aspect ratio: 16:9
```

---

## What NOT to Do

- Don't skip or rush the vault search. A 1-query vault search is never enough.
  If you searched for "volume" but didn't also try "sets", "training volume",
  "overtraining", and related terms, you didn't search thoroughly.
- Don't let external research drive the outline structure. Vault findings come
  first. External sources fill gaps and add evidence.
- Don't generate full prose. The outline is notes and structure, not a draft.
- Don't use a fixed template with the same sections every time. Let the content
  determine the structure.
- Don't pad sections to make them equal length.
- Don't add a "Sources" or "Bibliography" section at the end. Citations live
  inline next to the claims they support.
- Don't include meta-commentary about the outline itself ("This section could
  be expanded..."). Notes to self are about the *content*, not the outline.
- Don't summarize the outline at the end. It's a working doc, not a pitch.
- Don't use any word from the banned vocabulary list.
- Don't suggest social media repurposing. That's a different skill.
