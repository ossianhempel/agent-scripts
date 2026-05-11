# ASO Experiment Tracking

A lightweight ledger for ASO experiments. Lives alongside canonical metadata at `./metadata/experiments/` and is updated through OpenASO refreshes.

## What this tracks

- **Visibility** (keyword rankings, score changes) — from OpenASO
- **Sentiment** (review theme shifts) — from OpenASO
- **Metadata diff** (what actually changed, per locale) — from `./metadata`

## What this does NOT track

OpenASO does not expose installs, conversion rate, impressions, or paid-campaign performance. If the user wants install lift, they must paste numbers from App Store Connect analytics manually into the experiment file. Never invent these.

## File layout

```
metadata/experiments/
  2026-05-11-arabic-keywords/
    experiment.json     # hypothesis + metadata diff + checkpoints
    baseline.json       # OpenASO snapshot at t0
    checkpoints/
      2026-05-18.json   # snapshot at t+7d
      2026-05-25.json   # snapshot at t+14d
```

## experiment.json schema

```json
{
  "id": "2026-05-11-arabic-keywords",
  "hypothesis": "Localizing Arabic keywords (currently identical to en-US) will lift ar-SA rankings on 'قرآن', 'تلاوة', 'أذان'.",
  "status": "running",
  "started_at": "2026-05-11",
  "min_observation_days": 14,
  "locales": ["ar-SA"],
  "countries": ["SA", "AE", "EG"],
  "changes": [
    {
      "field": "keywords",
      "locale": "ar-SA",
      "before": "quran, recitation, prayer, ...",
      "after": "قرآن, تلاوة, أذان, ..."
    }
  ],
  "target_keywords": ["قرآن", "تلاوة", "أذان"],
  "external_metrics": {
    "note": "Paste ASC conversion rate / impressions here manually if tracking",
    "conversion_rate_baseline": null,
    "conversion_rate_latest": null
  },
  "checkpoints": [
    { "date": "2026-05-18", "file": "checkpoints/2026-05-18.json" }
  ],
  "conclusion": null
}
```

## baseline.json / checkpoint schema

OpenASO snapshot frozen at the moment of capture:

```json
{
  "captured_at": "2026-05-11T14:22:00Z",
  "countries": ["SA", "AE", "EG"],
  "keyword_rankings": [
    { "country": "SA", "keyword": "قرآن", "rank": null, "popularity": 72 }
  ],
  "review_themes": {
    "SA": { "praise": [], "complaints": [], "feature_requests": [] }
  }
}
```

## Commands the skill exposes

### `start` — open a new experiment

1. Ask the user for: hypothesis, target keywords, locales/countries.
2. Compute the metadata diff (current `./metadata` vs. last git-committed state, scoped to the named locales).
3. Capture baseline via OpenASO: refresh rankings + reviews for the target keywords/countries, then write `baseline.json`.
4. Write `experiment.json` with status `running` and `min_observation_days: 14` (default; override only if user insists).

### `check` — re-snapshot and diff

1. Refresh OpenASO data for the experiment's countries/keywords.
2. Write a new file under `checkpoints/`.
3. Diff against baseline: rank deltas per keyword, popularity-score changes, new/disappeared review themes.
4. If `today - started_at < min_observation_days`, report deltas but **refuse to conclude** — print: *"Too early to call. N days observed, M required."*
5. Otherwise, summarize: clear win / clear regression / inconclusive (noise within ±N positions).

### `conclude` — close out

User-triggered only. Sets `status: "concluded"` and writes `conclusion` field (free text). The skill should ask the user to write the conclusion themselves rather than generating it — they hold the context (was there a competitor launch? an algorithm shift? a paid campaign running?).

## Interpretation rules

- **Ranking noise:** treat ±3 positions in the top 50, ±10 below that, as noise. Don't claim a win inside the noise band.
- **Confounders to flag:** if a checkpoint coincides with a new app version shipping (check `metadata/version/`), a major review-theme shift, or competitor changes from OpenASO, surface these — they may explain the delta independent of the experiment.
- **Locale isolation:** only compare a locale to itself. Don't aggregate ranking changes across countries.
- **One experiment per field per locale:** if a running experiment already touches `keywords` in `ar-SA`, refuse to start a second one on the same field+locale. Concurrent changes make attribution impossible.

## OpenASO disconnected

If OpenASO MCP isn't connected, `start` and `check` should fail loudly — there's no point in an experiment ledger without the data layer. Don't fall back to dummy baselines.
