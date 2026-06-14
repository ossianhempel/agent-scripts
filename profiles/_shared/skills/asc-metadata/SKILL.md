---
name: asc-metadata
description: Audit, write, translate, and sync App Store listing metadata with the `asc` CLI on canonical files under `./metadata`. Use to run an ASO/keyword audit, localize descriptions/keywords/subtitle/name to multiple languages, or write engaging localized "What's New" release notes (from git log, bullets, or free text) plus promotional text.
---

# asc metadata

App Store listing content: research it (ASO audit), translate it (localization), and write the per-release notes. These share auth, deterministic ID resolution, and the canonical `./metadata` layout — but each holds distinct, sometimes *opposing* rules, so read the one you need.

## Pick the reference

| You are... | Read |
|---|---|
| Auditing metadata for keyword waste, field utilization, gaps, competitor signals, review themes (offline + OpenASO MCP) | [`reference/aso-audit.md`](reference/aso-audit.md) — pulls in [`aso_rules.md`](reference/aso_rules.md) and [`experiments.md`](reference/experiments.md) |
| Translating/syncing description, keywords, subtitle, name to many locales | [`reference/localize-metadata.md`](reference/localize-metadata.md) |
| Writing "What's New" release notes (+ optional promotional text) | [`reference/whats-new-writer.md`](reference/whats-new-writer.md) — pulls in [`release_notes_guidelines.md`](reference/release_notes_guidelines.md) |

## Watch the model conflict

These two rules coexist here and contradict each other on purpose — honor whichever the active task calls for:

- **Keywords / subtitle / description are indexed** → optimize for search (audit + localize). Keyword localization is **research, not literal translation**.
- **"What's New" is NOT indexed** → write for humans, lead with the single biggest change in the first ~170 chars; keyword echo is optional spice, never stuffing.

Localization discipline applies across all three: resolve IDs deterministically (never `head -1`), use formal register per locale (Sie/вы/vous/usted/u/Lei), validate character limits, and show drafts before uploading.

> Related: pricing and RevenueCat catalog work lives in **asc-pricing**; build/submit flow lives in **asc-release**.
