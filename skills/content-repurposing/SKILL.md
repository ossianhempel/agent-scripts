---
name: content-repurposing
description: >
  Turn longform content into short-form posts that convert. Takes an article,
  blog post, vault note, newsletter, podcast transcript, or any longform piece
  and extracts standalone insights, then generates ready-to-post content for
  Instagram (standard + viral-growth mode), Twitter/X (single tweets + threads),
  and short-form video scripts (Reels/TikTok). Niche-agnostic. References the
  copywriter skill for hooks, emotional framing, and anti-AI rules.
  Triggers: "repurpose this", "turn this into posts", "make posts from this
  article", "extract content from", "atomize this", "short-form from this",
  "make reels from this", "tweets from this article", "content from this".
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, WebSearch, WebFetch]
---

# Content Repurposing

One longform piece in. Multiple short-form pieces out.

The input carries the thinking. Your job is extraction, not invention. Every
output should trace back to a specific claim, insight, or story in the source
material. If it doesn't, you made it up.

## Feedback Log (DO THIS FIRST)

**At the start of every session, before doing anything else**, read the file
`feedback.log` in this skill's folder. It contains accumulated preferences and
corrections from previous sessions. Apply everything in it as if it were part
of this SKILL.md.

**During a session**, whenever Ossian gives a correction, states a preference,
or says something like "don't do X" / "I prefer Y" / "always do Z":

1. Decide: is this a **general preference** that applies to future sessions, or
   is it **specific to the current task only**?
2. If it's general, **immediately append it to `feedback.log`** using the Edit
   or Write tool. Don't wait until the end of the session.
3. Format each entry as: `[YYYY-MM-DD] <the preference or correction>`
4. Skip anything that only matters for the current task.

## When This Skill Activates

- User provides longform content and wants short-form posts made from it
- User says "repurpose", "atomize", "turn this into posts", "make content from"
- User has an article, blog post, newsletter, transcript, or vault note and
  wants to extract social media content
- User wants to generate multiple posts from a single source

**Not for**: writing original posts from a topic (use sbl-content or
gainslog-content), writing copy from scratch (use copywriter), or outlining
articles (use article-outline).

## Copywriter Skill Reference

Before generating any output, load the copywriter skill's core principles and
the relevant format reference. These are your writing rules:

- `skills/copywriter/SKILL.md` - core principles, desire-first framing, pain
  beats aspiration, the rewrite mindset, anti-AI rules, banned vocabulary
- `skills/copywriter/references/ig-captions.md` - IG caption structure, hook
  formulas, viral-growth mode, emotional framing
- Apply everything from the copywriter skill as if it were written here. When
  in doubt, the copywriter rules win.

**Key copywriter principles to always apply:**

- Outcome first, feature second
- Pain and reassurance outperform positive framing
- One message per unit
- The Hand Test (does the text sell without visuals?)
- Cut every word that isn't pulling weight
- All anti-AI writing rules (banned vocabulary, structural tells, tone tells)

## Supported Input Types

Anything longform:

- Blog posts and articles (URL or pasted text)
- Obsidian vault notes
- Newsletter issues
- Podcast or video transcripts
- Research papers or study summaries
- Book highlights or chapter notes
- Long Twitter/X threads
- Documentation or guides

If given a URL, use WebFetch to retrieve the content first.

## Output Formats

### 1. Instagram Post (Standard)

A complete IG post with caption, following the structure from the copywriter's
ig-captions reference. Hook line, body, closing line, CTA, hashtags.

Best for: insights that need 2-3 sentences of context to land.

### 2. Instagram Post (Viral-Growth / 7-Second Video)

The 7-second looping video format from the copywriter's ig-captions reference.
On-screen hook text + "read description below..." + long caption that delivers
the value. Best for: listicle hooks ("5 signs...", "3 mistakes...") extracted
from the source.

Output includes:
- On-screen text (the hook, sized for 7 seconds)
- Caption (repeat hook + numbered bullets + closing + CTA + hashtags)

### 3. Tweet (Single)

One standalone tweet. 280 characters max. The insight must land in one shot.
No thread setup, no "here's what I learned" preamble. Just the claim.

Best for: contrarian takes, surprising stats, quotable one-liners, reframes.

### 4. Twitter/X Thread

2-6 tweets that build on each other. First tweet is the hook (must stand
alone in the timeline). Each subsequent tweet adds one point. Last tweet is
the takeaway or CTA.

Best for: multi-step arguments, frameworks, numbered lists, stories with
a payoff.

### 5. Short-Form Video Script (Reels/TikTok)

Timed text segments for a 15-30 second video. Each segment is 1-2 sentences
displayed for 3-5 seconds. Hook in the first segment. Build to a payoff.

Output includes:
- Text segments with timestamps
- B-roll suggestion (what visuals to pair with each segment)
- On-screen text (what the viewer reads)
- Optional: voiceover script (if the format calls for narration)

Best for: insights with a clear problem-solution arc or a surprising reveal.

## Workflow

### Step 1: Ingest the Source

Read the full source material. If it's a URL, fetch it. If it's a vault note,
read it. If it's pasted text, work with what you have.

**Don't skim.** Read the whole thing. The best repurposing comes from
understanding the full argument, not just grabbing surface-level bullet points.

### Step 2: Extract Standalone Insights

Go through the source and pull out every claim, insight, story, stat, or
reframe that could stand on its own. Each extraction should:

- Make sense without the rest of the article
- Have a clear "so what" (why would someone care?)
- Be specific enough to hook (not "exercise is good" but "your rest periods
  are probably too short for hypertrophy")

Present the extractions as a numbered list:

```
## Extracted Insights

1. [Insight] - [which output format fits best]
2. [Insight] - [format]
3. [Insight] - [format]
...
```

Aim for 5-15 extractions depending on source length. Don't pad. If the source
only has 3 good standalone insights, extract 3.

### Step 3: User Picks

Ask the user:
- Which insights to turn into posts?
- Any format preferences? (all IG, mix of formats, tweets only, etc.)
- Target audience / niche for this batch? (needed for hooks and hashtags)
- Any CTA to include? (app download, follow, link in bio, etc.)

If the user already specified formats or preferences in their initial request,
skip the questions that are already answered. Don't over-interview.

### Step 4: Generate Content

For each selected insight, generate the full post in the chosen format.

**Before writing each piece:**
1. Name the desire or fear it taps into (from copywriter core principles)
2. Pick the emotional framing: pain, reassurance, or aspiration
3. Choose the hook formula (from ig-captions reference)

**For each piece, output:**
- The complete, ready-to-post content
- A one-line note on what it's optimizing for (e.g., "Pain framing, listicle
  hook, targets fear of wasted effort")
- Source reference: which part of the original article this came from

### Step 5: Batch Summary

After generating all pieces, provide a posting plan:

```
## Posting Plan

| # | Format | Hook (first 10 words) | Framing | Source section |
|---|--------|----------------------|---------|---------------|
| 1 | IG Viral-Growth | "5 signs your..." | Pain | Section 2 |
| 2 | Tweet | "Most people think..." | Contrarian | Section 4 |
| 3 | Reel script | "Your [X] is broken..." | Fear | Section 1 |
```

If the user is posting these to grow an account, suggest a posting order
(strongest hook first, or space similar angles apart).

## Extraction Patterns

These are the patterns to look for when mining longform content. Not every
article has all of these, but most have several.

### Listicle Extraction

Any list in the source (steps, tips, mistakes, signs, reasons) can become a
viral-growth IG post or a thread. The source says "here are 7 things..." and
you extract those 7 things as a single post.

### Contrarian Claim

Any point where the author disagrees with conventional wisdom. These make the
strongest single tweets and hook lines. Look for "most people think X, but
actually Y" patterns, even when they're not stated that explicitly.

### Surprising Stat

Any specific number that challenges expectations. "600 videos per month" or
"80% of downloads came from <1% of videos." Stats travel far on their own.

### Framework or Mental Model

Any 2x2, spectrum, hierarchy, or named framework. These work as carousel posts,
threads, or video scripts. "The 3 stages of..." or "There are two types of..."

### Story with a Payoff

Any anecdote or case study with a clear before/after. These work best as
video scripts or threads. "I tried X, expected Y, got Z instead."

### Reframe

Any moment where the author reframes a familiar concept. "It's not about
volume, it's about proximity to failure." These are single-tweet gold.

### Quotable Line

Any sentence that reads like it was designed to be screenshotted. Pull it
verbatim (with attribution) or adapt it.

## Hook Adaptation

When turning an extraction into a hook, use the formulas from the copywriter's
ig-captions reference. The most reliable for repurposed content:

- **Listicle with stakes:** "5 [things/signs/reasons] that [outcome]"
- **Silent warning:** "X things that are silently [bad outcome]"
- **Mistake call-out:** "The #1 mistake [audience] makes when [situation]"
- **Fear diagnosis:** "Your [thing] is [bad state] and here is why"
- **Contrarian claim:** "You don't need [common thing]"

**Default to negativity or reassurance framing.** Pain hooks outperform
positive ones across every platform. "5 signs something is wrong" beats
"5 signs you're doing it right." This is loss aversion, not manipulation.

If the source material is inherently positive or aspirational, use
reassurance: "It's normal if...", "You're not behind because..."

## Quality Gates

Before outputting any piece, check:

1. **Traceable?** Can you point to the exact part of the source this came from?
   If not, you invented it. Cut it.
2. **Standalone?** Would this make sense to someone who never read the source?
   If it needs context from the article, it's not ready.
3. **One message?** Does this piece say one thing? If it's trying to cover two
   insights, split it or pick the stronger one.
4. **Hook lands in 2 seconds?** Read just the first line. Does it create
   curiosity, fear, or recognition? If not, rewrite the hook.
5. **Hand Test passes?** Cover any imagined visual. Does the text sell alone?
6. **No AI tells?** Check against the anti-AI writing rules in
   `skills/copywriter/SKILL.md` (banned vocabulary, structural tells, tone
   tells). All of those rules apply to short-form output too.

## Anti-Patterns

- Don't summarize the article. You're extracting hooks, not writing a recap.
- Don't invent insights that aren't in the source. Every output traces back.
- Don't generate 15 posts when 5 are strong. Quality over volume. Cut the weak
  ones before presenting.
- Don't use the same hook formula for every piece. Vary the angles.
- Don't skip the extraction step and jump straight to writing posts. The
  extraction is where the quality comes from.
- Don't write generic posts that could come from any article on the topic.
  The specificity of the source material is the whole point.
- Don't over-attribute. "As [Author] said in their article..." is unnecessary
  for most social posts. The insight should stand on its own.

## Language

- Match the user's language. If they write in Swedish, output in Swedish.
- If the source is in English but the user writes in Swedish (or vice versa),
  ask which language the output should be in.
- Source quotes can stay in the original language if the audience would
  understand them. Otherwise, translate naturally.

## Example

**Input**: A 2000-word article about why most people overtrain volume and
should focus on intensity instead.

**Extracted insights**:

1. Most lifters do more sets than they need, and would grow more from fewer,
   harder sets - IG Viral-Growth
2. Schoenfeld's meta-analysis shows diminishing returns above ~10 sets/week,
   but people cite it as proof for 20+ - Tweet
3. When people add volume, they almost always compensate with lower intensity
   per set - IG Standard
4. "Nobody would do 30-rep deadlifts, but people program 30 sets per muscle
   and call it optimal" - Tweet (quotable line)
5. The author cut from 20+ sets to 10-12 per muscle group and saw better
   results - Reel script (story with payoff)

**Generated (example - Insight #1 as Viral-Growth IG):**

On-screen text (7 seconds):
```
5 signs you're doing
too many sets

read description below...
```

Caption:
```
5 signs you're doing too many sets 👇

1. Your last 2-3 sets feel like going through the motions, not actual effort
2. You've added sets over time but your strength hasn't moved
3. You can't remember the last time a set felt genuinely hard
4. Your sessions take 90+ minutes but your logbook looks the same as 6 months ago
5. You keep adding volume because "more is better" but you've never tested less

More sets is the default answer. But past a point, you're just accumulating
fatigue, not growth stimulus. The research shows diminishing returns after
~10 sets per muscle per week. Most people are well past that line.

Try cutting 30% of your volume next block. Push the sets you keep closer to
failure. Track what happens.

-
[CTA]
-

#gym #hypertrophy #training #workout
```

Optimizing for: Pain framing, listicle hook, targets fear of wasted effort.
Source: Sections 1-2 of the original article.
