---
name: asc-aso-audit
description: Run an offline ASO audit on canonical App Store metadata under `./metadata` and surface keyword gaps, competitor signals, and review themes using OpenASO MCP. Use after pulling metadata with `asc metadata pull`.
---

# asc ASO audit

Run a two-phase ASO audit: offline checks against local metadata files, then live keyword, competitor, and review research via OpenASO MCP.

## Preconditions

- Metadata pulled locally into canonical files via `asc metadata pull --app "APP_ID" --version "1.2.3" --dir "./metadata"`.
- If metadata came from `asc migrate export` or `asc localizations download`, normalize it into the canonical `./metadata` layout before running this skill.
- For Phase 2 research: OpenASO running locally with the target app added, and OpenASO MCP connected to this AI client (optional — offline checks run without it). Setup docs: https://openaso.thirdtechapps.com/docs/mcp/setup

## Before You Start

1. Read `aso_rules.md` to understand the rules each check enforces.
2. Identify the **latest version directory** under `metadata/version/` (highest semantic version number). Use this for all version-level fields.
3. The **primary locale** is `en-US` unless the user specifies otherwise.

## Metadata File Paths

- **App-info fields** (`subtitle`): `metadata/app-info/{locale}.json`
- **Version fields** (`keywords`, `description`, `whatsNew`): `metadata/version/{latest-version}/{locale}.json`
- **App name**: May not be present in exported metadata. If `name` is missing from the app-info JSON, fetch it via `asc apps info list` or ask the user. Do not flag it as a missing-field error.

## Phase 1: Offline Checks

Run these 5 checks against the local metadata directory. No network calls required.

### 1. Keyword Waste

Tokenize the `subtitle` field (and `name` if available). Flag any token that also appears in the `keywords` field — it is already indexed and wastes keyword budget.

```
Severity: ⚠️ Warning
Example:  "quran" appears in subtitle AND keywords — remove from keywords to free 6 characters
```

How to check:
1. Read `metadata/app-info/{locale}.json` for `subtitle` (and `name` if present)
2. Read `metadata/version/{latest-version}/{locale}.json` for `keywords`
3. Tokenize subtitle (+ name):
   - **Latin/Cyrillic scripts:** split by whitespace, strip leading/trailing punctuation, lowercase
   - **Chinese/Japanese/Korean:** split by `、` `，` `,` or iterate characters — each character or character-group is a token. Whitespace tokenization does not work for CJK.
   - **Arabic:** split by whitespace, then also generate prefix-stripped variants (remove ال prefix) since Apple likely normalizes definite articles. For example, "القرآن" in subtitle should flag both "القرآن" and "قرآن" in keywords.
4. Split keywords by comma, trim whitespace, lowercase
5. Report intersection (including fuzzy matches from prefix stripping)

### 2. Underutilized Fields

Flag fields using less than their recommended minimum:

| Field | Minimum | Limit | Rationale |
|-------|---------|-------|-----------|
| Keywords | 90 chars | 100 | 90%+ usage maximizes indexing |
| Subtitle | 20 chars | 30 | 65%+ usage recommended |

```
Severity: ⚠️ Warning
Example:  keywords is 62/100 characters (62%) — 38 characters of indexing opportunity unused
```

### 3. Missing Fields

Flag empty or missing required fields: `subtitle`, `keywords`, `description`, `whatsNew`.

Note: `name` may not be in the export — only flag it if the app-info JSON explicitly contains a `name` key with an empty value.

```
Severity: ❌ Error
Example:  subtitle is empty for locale en-US
```

### 4. Bad Keyword Separators

Check the `keywords` field for formatting issues:
- Spaces after commas (`quran, recitation`)
- Semicolons instead of commas (`quran;recitation`)
- Pipes instead of commas (`quran|recitation`)

```
Severity: ❌ Error
Example:  keywords contain spaces after commas — wastes 3 characters
```

### 5. Cross-Locale Keyword Gaps

Compare `keywords` fields across all available locales. Flag locales where keywords are identical to the primary locale (`en-US` by default) — this usually means they were not localized.

```
Severity: ⚠️ Warning
Example:  ar keywords identical to en-US — likely not localized for Arabic market
```

How to check:
1. Load keywords for all locales
2. Compare each non-primary locale against the primary
3. Flag exact matches (case-insensitive)

### 6. Description Keyword Coverage

Check whether keywords appear naturally in the `description` field. While Apple does **not** index descriptions for search, users who see their search terms reflected in the description are more likely to download — this improves conversion rate, which indirectly boosts rankings.

```
Severity: 💡 Info
Example:  3 of 16 keywords not found in description: namaz, tarteel, adhan
```

How to check:
1. Load `keywords` and `description` for each locale
2. For each keyword, check if it appears as a substring in the description (case-insensitive)
3. Account for inflected forms: Arabic root matches, verb conjugations (e.g., "memorizar" ≈ "memorices"), and case declensions (e.g., Russian "сура" ≈ "суры")
4. Report missing keywords per locale — recommend weaving them naturally into existing sentences
5. Do NOT flag: Latin-script keywords in non-Latin descriptions (e.g., "quran" in Cyrillic text) — these target separate search paths

## Phase 1.5: Listing Health Checks

The Phase 1 checks cover metadata text. These cover the qualitative dimensions that drive conversion: screenshots, video, icon, ratings, and conversion signals. Use OpenASO MCP where possible to pull real data; otherwise ask the user.

### 7. Screenshots

Fetch via OpenASO: *"List screenshots for [app] in [country]."* (`list_screenshots`). If unavailable, ask the user.

| Check | What to look for |
|-------|------------------|
| Slot usage | All 10 slots filled? (iOS allows up to 10) |
| First 3 | Strongest features / clearest value prop shown first? |
| Text overlays | Benefit-driven captions, readable at thumbnail size? |
| Consistency | Cohesive visual language across slots? |
| Localization | Per-locale screenshots, not just one set? |
| Device frames | Modern frames (or intentionally frameless)? |

### 8. App Preview Video

| Check | What to look for |
|-------|------------------|
| Exists | Has a preview video? (Apple allows up to 3) |
| Hook | First 3 seconds carry the value prop? |
| Length | 15–30 seconds? |
| Sound-off | Works without audio (captions/UI text)? |

### 9. Icon

| Check | What to look for |
|-------|------------------|
| Distinctiveness | Stands out vs. category siblings (check via OpenASO competitor list)? |
| Simplicity | Readable at small thumbnail size? |
| Category fit | Matches user expectations for the category? |
| No text | Avoids text — unreadable at small sizes? |

### 10. Ratings & Reviews

Fetch via OpenASO: app overview + reviews (`get_app_overview`, `list_reviews`).

| Check | What to look for |
|-------|------------------|
| Average | 4.5+ stars? |
| Volume | Sufficient count vs. category median? |
| Recent trend | Last 30 days trending up or down? |
| Developer responses | Replies to 1–3 star reviews? |
| Themes | Recurring complaints flagged by OpenASO review prompt? |

### 11. Conversion Signals

| Check | What to look for |
|-------|------------------|
| Promotional text (170 chars) | Used for timely messaging? Editable without resubmission |
| What's New | Informative, not "Bug fixes"? Recent enough? |
| In-App Events | Active events for visibility? |
| Custom Product Pages | Multiple variants by audience/channel? |

## Phase 2: OpenASO MCP Keyword & Competitor Research

If OpenASO MCP is connected and the app is added in OpenASO, run live keyword, competitor, and review research. **Cover the relevant store countries, not just the US store** — keyword popularity, competitors, and review themes vary dramatically across markets.

OpenASO is driven primarily by **natural-language asks**: the assistant chooses the right OpenASO tools (Apps, Keywords, Rankings, Reviews, Competitors, Screenshots, Websites, Localization) and may invoke OpenASO's built-in research prompts (review themes, keyword brief, competitor landscape, localization analysis, ASO action plan). Use the prompts below as starting points and adapt to the audit context.

### Steps

1. **Verify the app is tracked.** Ask: *"List my tracked OpenASO apps."* If the target app isn't present, ask the user to add it in OpenASO (search by name or App Store ID) and re-run. Don't try to invent app IDs or track on the user's behalf.

2. **Cover the relevant storefronts.** For every locale present in `./metadata` that corresponds to a real App Store territory (e.g., `ar-SA` → Saudi Arabia, `fr-FR` → France, `tr` → Turkey, `de-DE` → Germany), ask: *"Refresh rankings and reviews for [app] in [country list]."* OpenASO refreshes stale data before computing gaps. If countries aren't tracked yet, ask: *"Add tracking for [app] in [country list]."*

3. **Keyword gap research (per country).** Trigger OpenASO's built-in keyword brief:
   > *"Review my tracked keywords for [app] in [country], find weak or noisy terms, score keyword quality, and suggest 10 keywords worth testing next. Use shared-keyword competitor evidence."*

   This is the highest-value pass — OpenASO scores keyword quality, checks ranking evidence, and uses shared rankings to surface terms competitors hold that you don't.

4. **Competitor landscape.** Trigger the competitor landscape prompt:
   > *"Find competitors that rank on the same keywords as [app] in [country], then compare their ratings, review themes, screenshots, and positioning."*

   Useful for separating real competitors (recurring across many keywords) from one-offs, and for spotting positioning angles you can mirror or counter.

5. **Optional — review theme pass.** When refreshing description, promotional text, or what's-new copy, trigger the review theme prompt:
   > *"Summarize the main praise, complaints, feature requests, and pricing objections for [app] in [country list]. Don't quote individual reviewers."*

   The vocabulary users repeat in reviews is the vocabulary that converts in copy. Feed it back into Phase 1's description-coverage check.

6. **Optional — localization opportunities.** When the audit spans multiple locales:
   > *"Compare [app] and competitors across [list of locales]. Recommend where metadata-only localization is enough and where screenshots should be localized too."*

   Pairs naturally with Phase 1 Check #5 (cross-locale keyword gaps).

7. **Diff against local metadata.** For every keyword OpenASO suggests, check whether it already appears as a token in `subtitle`, `name` (if available), or `keywords` from the local metadata files — apply the same tokenization rules as Phase 1 Check #1 (CJK character split, Arabic prefix-stripping, etc.). Surface only the genuine gaps.

8. **Surface gaps.** Report results ranked by OpenASO's quality/popularity score (highest first), grouped by country. Always include the source (competitor evidence vs. keyword suggestion vs. review-vocabulary insight).

### Prompt discipline

OpenASO works best with focused asks. When invoking it:
- Name the app and the countries explicitly. ("Use US and UK only" beats "use the main markets".)
- State the outcome you want. ("10 keywords worth testing this week" beats "any keyword ideas".)
- Start narrow on the first pass (1–2 countries), widen after the first result lands.
- Tell OpenASO when small live refreshes are okay vs. when to use only stored data — refreshes cost API time.

### Cross-Field Combo Strategy

When recommending keyword additions, consider how single words combine across indexed fields (title + subtitle + keywords). For example:
- Adding "namaz" to keywords when "vakti" is already present enables matching the search "namaz vakti" (66 popularity)
- Adding "holy" to keywords when "Quran" is in the subtitle enables matching "holy quran" (58 popularity)

Flag high-value combos in recommendations.

### Skip Conditions

- OpenASO MCP not connected → skip Phase 2 with note: *"Connect OpenASO MCP to run keyword and competitor research. Setup: https://openaso.thirdtechapps.com/docs/mcp/setup"*
- OpenASO not running (HTTP transport) → ask the user to launch OpenASO and start the MCP server, then retry
- App not added in OpenASO → skip with note: *"Add [app] to OpenASO (search or App Store ID), then re-run the audit"*
- Country not tracked for a locale → ask OpenASO to add tracking before querying that store

## Phase 3: Experiment Tracking (optional)

When the user is making ASO changes they want to measure — new keywords, localized metadata, rewritten subtitle, swapped screenshots — open an experiment in `./metadata/experiments/` so the impact is observable later instead of relying on memory.

This phase is **opt-in per audit**. Trigger it when the user says things like *"track this change"*, *"I want to see if this works"*, *"start an experiment"*, or after recommending a non-trivial metadata change they accept.

Three actions:

- **`start`** — capture a baseline OpenASO snapshot (rankings + review themes for the target keywords/countries), record the metadata diff, write `experiment.json` with `status: running`.
- **`check`** — re-snapshot via OpenASO, diff against baseline, report rank/score/theme deltas. **Refuses to conclude before `min_observation_days` (default 14)** — ranking changes are too noisy earlier than that.
- **`conclude`** — user-triggered. Set status to concluded; ask the user to write the conclusion (they know the confounders — competitor launches, algorithm shifts, paid campaigns).

Read `experiments.md` for the file layout, JSON schemas, and interpretation rules (noise bands, confounder flagging, one-experiment-per-field-per-locale).

Honest scope: OpenASO measures **visibility and sentiment**, not installs or conversion rate. If the user wants install lift, they paste ASC analytics numbers into the experiment file manually. Do not invent these metrics.

If OpenASO MCP isn't connected, `start` and `check` fail loudly — don't fake baselines.

## Output Format

Present results as a single audit report. The report covers only the latest version directory.

```
### ASO Audit Report

**App:** [name] | **Primary Locale:** [locale]
**Metadata source:** [path including version number]

#### Field Utilization

| Field | Value | Length | Limit | Usage |
|-------|-------|--------|-------|-------|
| Name | ... | X | 30 | X% |
| Subtitle | ... | X | 30 | X% |
| Keywords | ... | X | 100 | X% |
| Promotional Text | ... | X | 170 | X% |
| Description | (first 50 chars)... | X | 4000 | X% |

#### ASO Score Card

Score each dimension 0–10. Skip any factor you couldn't observe (don't guess). Weighted overall on observed factors only.

```
Overall ASO Score: [X]/100  (based on N observed factors)

Title:              [X]/10   weight 15%
Subtitle:           [X]/10   weight 10%
Keyword Field:      [X]/10   weight 15%
Description:        [X]/10   weight 5%
Screenshots:        [X]/10   weight 15%
Preview Video:      [X]/10   weight 5%
Ratings & Reviews:  [X]/10   weight 15%
Icon:               [X]/10   weight 5%
Keyword Rankings:   [X]/10   weight 10%
Conversion Signals: [X]/10   weight 5%
```

#### Offline Checks

| # | Check | Severity | Field | Locale | Detail |
|---|-------|----------|-------|--------|--------|
| 1 | Keyword waste | ⚠️ | keywords | en-US | "quran" duplicated in subtitle |

**Summary:** X errors, Y warnings across Z locales

#### Keyword Gap Analysis (OpenASO MCP)

| Keyword | Country | Score | Source | In Metadata? | Suggested Action |
|---------|---------|-------|--------|--------------|------------------|
| quran recitation | US | 72 | competitor evidence | ❌ | Add to keywords |
| namaz vakti | TR | 66 | suggestion (combo with subtitle) | partial | Add "namaz" to keywords |

#### Recommendations

Group by effort tier:

**Quick Wins (today)** — errors, keyword waste, separator fixes, underutilization
1. ...

**High-Impact (this week)** — screenshot/video reworks, keyword additions from OpenASO gaps, localization fills
1. ...

**Strategic (this month)** — rating recovery, custom product pages, in-app events, multi-locale screenshot localization
1. ...
```

## Notes

- Offline checks work without any network access — they read local files only.
- OpenASO research is additive — the audit is useful even without it.
- Run this skill after `asc metadata pull` to ensure canonical metadata files are current.
- For keyword-only follow-up after the audit, prefer the canonical keyword workflow:
  - `asc metadata keywords diff --app "APP_ID" --version "1.2.3" --dir "./metadata"`
  - `asc metadata keywords apply --app "APP_ID" --version "1.2.3" --dir "./metadata" --confirm`
  - `asc metadata keywords sync --app "APP_ID" --version "1.2.3" --dir "./metadata" --input "./keywords.csv"` when importing external keyword research
- After making changes, re-run the audit to verify fixes.
- The Field Utilization table includes promotional text for completeness, but no check validates its content (it is not indexed by Apple).