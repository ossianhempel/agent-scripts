---
name: "app-store-optimization"
description: >-
  App Store Optimization (ASO) toolkit for researching keywords, analyzing
  competitor rankings, generating metadata suggestions, and improving app
  visibility on Apple App Store and Google Play Store. Use when the user asks
  about ASO, app store rankings, app metadata, app titles and descriptions, app
  store listings, app visibility, or mobile app marketing on iOS or Android.
  Supports keyword research and scoring, competitor keyword analysis, metadata
  optimization, A/B test planning, launch checklists, and tracking ranking
  changes.
triggers:
  - ASO
  - app store optimization
  - app store ranking
  - app keywords
  - app metadata
  - play store optimization
  - app store listing
  - improve app rankings
  - app visibility
  - app store SEO
  - mobile app marketing
  - app conversion rate
---

# App Store Optimization (ASO)

---

## Keyword Research Workflow

Discover and evaluate keywords that drive app store visibility.

### Workflow: Conduct Keyword Research

1. Define target audience and core app functions:
   - Primary use case (what problem does the app solve)
   - Target user demographics
   - Competitive category
2. Generate seed keywords from:
   - App features and benefits
   - User language (not developer terminology)
   - App store autocomplete suggestions
3. Expand keyword list using:
   - Modifiers (free, best, simple)
   - Actions (create, track, organize)
   - Audiences (for students, for teams, for business)
4. Evaluate each keyword:
   - Search volume (estimated monthly searches)
   - Competition (number and quality of ranking apps)
   - Relevance (alignment with app function)
5. Score with Opportunity formula, then bucket into Primary / Secondary / Long-tail / Aspirational (see below)
6. Map keywords to metadata locations
7. Document keyword strategy for tracking
8. **Validation:** Keywords scored; placement mapped; no competitor brand names included; no plurals in iOS keyword field

### Keyword Evaluation Criteria

| Factor | Weight | High Score Indicators |
|--------|--------|-----------------------|
| Relevance | 35% | Describes core app function |
| Volume | 25% | 10,000+ monthly searches |
| Competition | 25% | Top 10 apps have <4.5 avg rating |
| Conversion | 15% | Transactional intent ("best X app") |

### Opportunity Score

Combine the signals into a single score per keyword to rank candidates:

```
Opportunity = (Volume × 0.4) + ((100 − Difficulty) × 0.3) + (Relevance × 0.3)
```

All three inputs on a 0–100 scale. Difficulty is inverted so lower competition raises the score. Use this to sort the keyword list before bucketing.

### Keyword Grouping (Strategic Buckets)

Group candidates into four buckets — placement and priority flow from the bucket:

| Bucket | Count | Where it lives | Notes |
|--------|-------|----------------|-------|
| **Primary** | 3–5 | Title or subtitle | Highest Opportunity Score; defines positioning |
| **Secondary** | 5–10 | Subtitle + keyword field (iOS) / short description (Android) | Good opportunity; rotate based on performance |
| **Long-tail** | 10–20 | Keyword field / full description | Lower volume, specific intent, easier to rank |
| **Aspirational** | 3–5 | Tracked only — not in metadata yet | High volume + high difficulty; long-term targets, don't sacrifice primary for these |

### Keyword Placement Priority

| Location | Search Weight |
|----------|---------------|
| App Title | Highest |
| Subtitle (iOS) | High |
| Keyword Field (iOS) | High |
| Short Description (Android) | High |
| Full Description | Medium |

### Keyword Strategy Output

When delivering a keyword research result, format as:

```
Top Keywords by Opportunity

| Keyword | Volume | Difficulty | Relevance | Opportunity | Current Rank | Bucket |
|---------|--------|------------|-----------|-------------|--------------|--------|
| ...     | 0–100  | 0–100      | 0–100     | computed    | rank or —    | Primary/Secondary/Long-tail/Aspirational |

Proposed placement:
  Title (30):     [primary keywords]
  Subtitle (30):  [secondary keywords]
  Keyword field (100): [remaining keywords, comma-separated, no spaces]

Tracking only:
  [aspirational keywords]
```

See: [references/keyword-research-guide.md](references/keyword-research-guide.md)

---

## Metadata Optimization Workflow

Optimize app store listing elements for search ranking and conversion.

### Workflow: Optimize App Metadata

1. Audit current metadata against platform limits:
   - Title character count and keyword presence
   - Subtitle/short description usage
   - Keyword field efficiency (iOS)
   - Description keyword density
2. Optimize title following formula:
   ```
   [Brand Name] - [Primary Keyword] [Secondary Keyword]
   ```
3. Write subtitle (iOS) or short description (Android):
   - Focus on primary benefit
   - Include secondary keyword
   - Use action verbs
4. Optimize keyword field (iOS only):
   - Remove duplicates from title
   - Remove plurals (Apple indexes both forms)
   - No spaces after commas
   - Prioritize by score
5. Rewrite full description:
   - Hook paragraph with value proposition
   - Feature bullets with keywords
   - Social proof section
   - Call to action
6. Validate character counts for each field
7. Calculate keyword density (target 2-3% primary)
8. **Validation:** All fields within character limits; primary keyword in title; no keyword stuffing (>5%); natural language preserved

### Platform Character Limits

| Field | Apple App Store | Google Play Store |
|-------|-----------------|-------------------|
| Title | 30 characters | 50 characters |
| Subtitle | 30 characters | N/A |
| Short Description | N/A | 80 characters |
| Keywords | 100 characters | N/A |
| Promotional Text | 170 characters | N/A |
| Full Description | 4,000 characters | 4,000 characters |
| What's New | 4,000 characters | 500 characters |

### Description Structure

```
PARAGRAPH 1: Hook (50-100 words)
├── Address user pain point
├── State main value proposition
└── Include primary keyword

PARAGRAPH 2-3: Features (100-150 words)
├── Top 5 features with benefits
├── Bullet points for scanability
└── Secondary keywords naturally integrated

PARAGRAPH 4: Social Proof (50-75 words)
├── Download count or rating
├── Press mentions or awards
└── Summary of user testimonials

PARAGRAPH 5: Call to Action (25-50 words)
├── Clear next step
└── Reassurance (free trial, no signup)
```

See: [references/platform-requirements.md](references/platform-requirements.md)

---

## Competitor Analysis Workflow

Analyze competitors to identify keyword gaps and positioning opportunities. Most data can be pulled via OpenASO MCP (`list_competitors`, `get_app_overview`, `list_reviews`, `list_screenshots`, rankings); fall back to manual lookup otherwise.

### Identifying Competitors

If the user doesn't already have a list, find them through:

1. **Category chart** — top apps in the same category/country
2. **Keyword overlap** — apps ranking for the same keywords (OpenASO's shared-keyword evidence)
3. **Similar apps** — Apple's "You Might Also Like" section on the listing
4. **User perception** — ask: "What would your users use if your app didn't exist?"

Aim for a **3–5 app mix**: 2 direct competitors + 1–2 aspirational (larger, more mature) + 1 emerging (rising fast). Avoid analyzing only the category leader — their playbook may not apply at your stage.

### Workflow: Analyze Competitor ASO Strategy

1. Build the competitor set using the mix above.
2. Extract competitor keywords from titles, subtitles, the first 100 words of descriptions, and OpenASO keyword rankings.
3. Build a competitor keyword matrix — which keywords each app targets, coverage % per keyword.
4. Identify keyword gaps:
   - Keywords competitors rank for that you don't
   - Keywords you rank for that competitors don't (your moat — protect)
   - Keywords where you're outranked (close the gap)
5. Analyze visual assets: icon, screenshots (count, first-3 strategy, text overlays), preview video.
6. Compare ratings and review patterns — themes, response practice.
7. Compare growth signals and monetization (see tables below).
8. Document positioning opportunities and threats.
9. **Validation:** 3+ competitors analyzed; keyword matrix complete; visual + ratings + monetization compared; gaps surfaced with volume evidence.

### Side-by-Side Comparison Tables

**Metadata**

| Element | You | Comp 1 | Comp 2 | Comp 3 |
|---------|-----|--------|--------|--------|
| Title | | | | |
| Subtitle | | | | |
| Title keywords | | | | |
| Title char usage | /30 | /30 | /30 | /30 |
| Subtitle char usage | /30 | /30 | /30 | /30 |
| Description hook (first line) | | | | |

**Keyword Gap**

| Keyword | Volume | Difficulty | Your Rank | Comp 1 | Comp 2 | Comp 3 | Priority |
|---------|--------|------------|-----------|--------|--------|--------|----------|

**Ratings & Reviews**

| Metric | You | Comp 1 | Comp 2 | Comp 3 |
|--------|-----|--------|--------|--------|
| Average rating | | | | |
| Total reviews | | | | |
| Recent trend (30d) | | | | |
| Top complaint | | | | |
| Top praise | | | | |
| Dev responds to 1–3★? | | | | |

**Growth Signals**

| Signal | You | Comp 1 | Comp 2 | Comp 3 |
|--------|-----|--------|--------|--------|
| Chart position (category) | | | | |
| Update frequency | | | | |
| In-App Events active? | | | | |
| Custom Product Pages? | | | | |
| Apple Search Ads presence? | | | | |
| Downloads / revenue (est) | | | | |

Downloads and revenue estimates are unsupported by OpenASO — label as estimates from third-party tools or omit.

**Monetization**

| Aspect | You | Comp 1 | Comp 2 | Comp 3 |
|--------|-----|--------|--------|--------|
| Price model | | | | |
| Subscription price | | | | |
| Free trial length | | | | |
| IAP count | | | | |
| Paywall timing | | | | |

### Gap Analysis Template

| Opportunity Type | Example | Action |
|------------------|---------|--------|
| Keyword gap | "habit tracker" — comp ranks #3, you don't rank | Add to keyword field |
| Feature gap | Competitor lacks widget | Highlight in screenshots |
| Visual gap | No videos in top 5 | Create app preview |
| Messaging gap | None mention "free" | Test free positioning |
| Review pain | Top complaint: "ads too aggressive" | Position as ad-light |

### Competitive Position Map

Plot the user vs competitors on visibility (chart position / install velocity) × ratings:

```
                    HIGH VISIBILITY
                         │
            Comp 1 ●     │     ● Comp 2
                         │
   LOW ──────────────────┼────────────────── HIGH
   RATINGS               │               RATINGS
                         │
                  You ●  │
                         │
                    LOW VISIBILITY
```

### Output Structure

1. **Executive Summary** — 2–3 paragraphs: landscape, your position, biggest opportunities.
2. **Comparison tables** — metadata / keyword gap / ratings / growth / monetization.
3. **Position map** — ASCII 2×2.
4. **Top Opportunities** — Quick Win, Keyword Gap, Creative Edge, Feature Gap, Market Gap.
5. **Threats to Monitor** — competitor moves to watch, market trends.

---

## App Launch Workflow

Execute a structured launch for maximum initial visibility.

### Workflow: Launch App to Stores

1. Complete pre-launch preparation (4 weeks before):
   - Finalize keywords and metadata
   - Prepare all visual assets
   - Set up analytics (Firebase, Mixpanel)
   - Build press kit and media list
2. Submit for review (2 weeks before):
   - Complete all store requirements
   - Verify compliance with guidelines
   - Prepare launch communications
3. Configure post-launch systems:
   - Set up review monitoring
   - Prepare response templates
   - Configure rating prompt timing
4. Execute launch day:
   - Verify app is live in both stores
   - Announce across all channels
   - Begin review response cycle
5. Monitor initial performance (days 1-7):
   - Track download velocity hourly
   - Monitor reviews and respond within 24 hours
   - Document any issues for quick fixes
6. Conduct 7-day retrospective:
   - Compare performance to projections
   - Identify quick optimization wins
   - Plan first metadata update
7. Schedule first update (2 weeks post-launch)
8. **Validation:** App live in stores; analytics tracking; review responses within 24h; download velocity documented; first update scheduled

### Pre-Launch Checklist

| Category | Items |
|----------|-------|
| Metadata | Title, subtitle, description, keywords |
| Visual Assets | Icon, screenshots (all sizes), video |
| Compliance | Age rating, privacy policy, content rights |
| Technical | App binary, signing certificates |
| Analytics | SDK integration, event tracking |
| Marketing | Press kit, social content, email ready |

### Launch Timing Considerations

| Factor | Recommendation |
|--------|----------------|
| Day of week | Tuesday-Wednesday (avoid weekends) |
| Time of day | Morning in target market timezone |
| Seasonal | Align with relevant category seasons |
| Competition | Avoid major competitor launch dates |

See: [references/aso-best-practices.md](references/aso-best-practices.md)

---

## A/B Testing Workflow

Test metadata and visual elements to improve conversion rates.

### Workflow: Run A/B Test

1. Select test element (prioritize by impact):
   - Icon (highest impact)
   - Screenshot 1 (high impact)
   - Title (high impact)
   - Short description (medium impact)
2. Form hypothesis:
   ```
   If we [change], then [metric] will [improve/increase] by [amount] because [rationale].
   ```
3. Create variants:
   - Control: Current version
   - Treatment: Single variable change
4. Calculate required sample size:
   - Baseline conversion rate
   - Minimum detectable effect (usually 5%)
   - Statistical significance (95%)
5. Launch test:
   - Apple: Use Product Page Optimization
   - Android: Use Store Listing Experiments
6. Run test for minimum duration:
   - At least 7 days
   - Until statistical significance reached
7. Analyze results:
   - Compare conversion rates
   - Check statistical significance
   - Document learnings
8. **Validation:** Single variable tested; sample size sufficient; significance reached (95%); results documented; winner implemented

### A/B Test Prioritization

| Element | Conversion Impact | Test Complexity |
|---------|-------------------|-----------------|
| App Icon | 10-25% lift possible | Medium (design needed) |
| Screenshot 1 | 15-35% lift possible | Medium |
| Title | 5-15% lift possible | Low |
| Short Description | 5-10% lift possible | Low |
| Video | 10-20% lift possible | High |

### Sample Size Quick Reference

| Baseline CVR | Impressions Needed (per variant) |
|--------------|----------------------------------|
| 1% | 31,000 |
| 2% | 15,500 |
| 5% | 6,200 |
| 10% | 3,100 |

### Test Documentation Template

```
TEST ID: ASO-2025-001
ELEMENT: App Icon
HYPOTHESIS: A bolder color icon will increase conversion by 10%
START DATE: [Date]
END DATE: [Date]
RESULTS:
├── Control CVR: 4.2%
├── Treatment CVR: 4.8%
├── Lift: +14.3%
├── Significance: 97%
└── Decision: Implement treatment
LEARNINGS:
- Bold colors outperform muted tones in this category
- Apply to screenshot backgrounds for next test
```

---

## Before/After Examples

### Title Optimization

**Productivity App:**

| Version | Title | Analysis |
|---------|-------|----------|
| Before | "MyTasks" | No keywords, brand only (8 chars) |
| After | "MyTasks - Todo List & Planner" | Primary + secondary keywords (29 chars) |

**Fitness App:**

| Version | Title | Analysis |
|---------|-------|----------|
| Before | "FitTrack Pro" | Generic modifier (12 chars) |
| After | "FitTrack: Workout Log & Gym" | Category keywords (27 chars) |

### Subtitle Optimization (iOS)

| Version | Subtitle | Analysis |
|---------|----------|----------|
| Before | "Get Things Done" | Vague, no keywords |
| After | "Daily Task Manager & Planner" | Two keywords, benefit clear |

### Keyword Field Optimization (iOS)

**Before (Inefficient - 89 chars, 8 keywords):**
```
task manager, todo list, productivity app, daily planner, reminder app
```

**After (Optimized - 97 chars, 14 keywords):**
```
task,todo,checklist,reminder,organize,daily,planner,schedule,deadline,goals,habit,widget,sync,team
```

**Improvements:**
- Removed spaces after commas (+8 chars)
- Removed duplicates (task manager → task)
- Removed plurals (reminders → reminder)
- Removed words in title
- Added more relevant keywords

### Description Opening

**Before:**
```
MyTasks is a comprehensive task management solution designed to help busy
professionals organize their daily activities and boost productivity.
```

**After:**
```
Forget missed deadlines. MyTasks keeps every task, reminder, and project
in one place—so you focus on doing, not remembering. Trusted by 500,000+
professionals.
```

**Improvements:**
- Leads with user pain point
- Specific benefit (not generic "boost productivity")
- Social proof included
- Keywords natural, not stuffed

### Screenshot Caption Evolution

| Version | Caption | Issue |
|---------|---------|-------|
| Before | "Task List Feature" | Feature-focused, passive |
| Better | "Create Task Lists" | Action verb, but still feature |
| Best | "Never Miss a Deadline" | Benefit-focused, emotional |

---

## Google Play (Android) Specifics

Google Play's algorithm differs fundamentally from iOS: the full description is indexed, there is no hidden keyword field, and ratings are continuous (never reset per version). Use this section whenever you're working on a Play Store listing.

### Indexing Model

| Field | Indexed | Notes |
|-------|---------|-------|
| Title (30 chars) | ✓ | Highest weight |
| Short description (80 chars) | ✓ | High weight; first thing in search results |
| Full description (4000 chars) | ✓ | Medium weight — keyword density matters |
| Developer name | ✓ | Low weight |
| Reviews and replies | ✓ | Common review words feed keyword signals |

No equivalent to the iOS 100-char keyword field. Keywords live in the description itself.

### Full Description Structure (Indexed)

```
[Hook — 2–3 sentences]
Lead with the core value prop. Primary keyword in the first 167 chars (above the fold).

[Feature bullets — 5–8 items]
• [Feature]: [Benefit]
Use keywords naturally. Vary phrasing — don't repeat exact phrases.

[Social proof]
"Trusted by X million users" / awards / press mentions

[Call to action]
Download [App Name] today — [value prop].

[Keyword-rich closing paragraph]
Variants, synonyms, and long-tail terms. Natural sentences, not lists.
```

**Keyword density rule:** Primary keyword 3–5 times across the full description (exact + variants). Never stuff.

### Feature Graphic (1024×500px)

Required for the Play Store. Appears at the top of the listing when no video is set.

- Show the core use case in a single image
- Legible text — no tiny copy
- Brand-consistent with screenshots
- Must work without text (text may be truncated on some surfaces)

### Ratings Strategy (Continuous Model)

Unlike iOS, Play ratings are **never reset** — every rating ever given counts toward your average.

To improve a rating:
1. Respond to every 1–3 star review (boosts the algorithmic signal)
2. Replies invite re-rating — users can update their review
3. Fix issues mentioned in low ratings, then reply: "Fixed in version X.X"
4. Use the Play In-App Review API: `ReviewManager.requestReviewFlow()` — prompt after a clear success moment, not on cold open

### Play Store Experiments (Native A/B)

Access: Play Console → Store listing experiments. Supports up to 3 variants for:

- Icon
- Feature graphic
- Screenshots
- Short description
- Full description

Rules: test one element at a time; run for minimum 7 days or until ~1,000 impressions per variant.

### Localization

Google Play indexes descriptions per language. Every locale is a fresh keyword opportunity — translate and localize, don't just auto-translate.

### Pre-Launch (Early Access)

Use Early Access to collect reviews before public launch, get indexed by Google before launch, and get editorial consideration from Google Play.

### Play Listing Audit Template

Score each field 1–10:

```
Title:             [N]/10 — [note]
Short description: [N]/10 — [note]
Full description:  [N]/10 — [note]
Screenshots:       [N]/10 — [note]
Feature graphic:   [N]/10 — [note]
Ratings:           [N]/10 — [note]
Overall:           [N]/60

Top 3 improvements:
1. [specific change with expected impact]
2. [specific change with expected impact]
3. [specific change with expected impact]
```

---

## Tools and References

### References

| Document | Content |
|----------|---------|
| [platform-requirements.md](references/platform-requirements.md) | iOS and Android metadata specs, visual asset requirements |
| [aso-best-practices.md](references/aso-best-practices.md) | Optimization strategies, rating management, launch tactics |
| [keyword-research-guide.md](references/keyword-research-guide.md) | Research methodology, evaluation framework, tracking |

---

## Platform Notes

| Platform / Constraint | Behavior / Impact |
|-----------------------|-------------------|
| iOS keyword changes | Require app submission |
| iOS promotional text | Editable without an app update |
| Android metadata changes | Index in 1-2 hours |
| Android keyword field | None — use description instead (see Google Play Specifics) |
| Android ratings | Continuous, never reset per version |
| Android A/B testing | Play Store Experiments, up to 3 variants, 7-day min |
| Keyword volume data | Estimates only; no official source |
| Competitor data | Public listings only |

**When not to use this skill:** web apps (use web SEO), enterprise/internal apps, TestFlight-only betas, or paid advertising strategy.

---

## Proactive Triggers

- **No keyword optimization in title** → App title is the #1 ranking factor. Include top keyword.
- **Screenshots don't show value** → Screenshots should tell a story, not show UI.
- **No ratings strategy** → Below 4.0 stars kills conversion. Implement in-app rating prompts.
- **Description keyword-stuffed** → Natural language with keywords beats keyword stuffing.

## Output Artifacts

| When you ask for... | You get... |
|---------------------|------------|
| "ASO audit" | Full app store listing audit with prioritized fixes |
| "Keyword research" | Keyword list with search volume and difficulty scores |
| "Optimize my listing" | Rewritten title, subtitle, description, keyword field |

## Communication

All output passes quality verification:
- Self-verify: source attribution, assumption audit, confidence scoring
- Output format: Bottom Line → What (with confidence) → Why → How to Act
- Results only. Every finding tagged: 🟢 verified, 🟡 medium, 🔴 assumed.
