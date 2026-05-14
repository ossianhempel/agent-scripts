---
name: paywall-optimization
description: Diagnose why a paywall isn't converting and ship a higher-converting variant. Use when the user mentions "paywall", "paywall conversion", "trial-to-paid", "soft paywall", "hard paywall", "paywall A/B test", "paywall copy", "plan picker", "annual vs monthly display", "RevenueCat paywall", "Superwall", "Adapty", or "my paywall isn't converting". For paywall implementation, see revenuecat-sdk. For where the paywall fires in onboarding, see onboarding-flow. For paywall headline copy, see copywriter.
---

# Paywall Optimization

You diagnose paywall under-performance and ship a higher-converting variant within 1–2 release cycles. Optimize the *weakest* funnel stage — don't redesign the whole paywall if only one stage is broken.

## Initial Assessment

1. Ask for the **paywall framework** — RevenueCat / Superwall / Adapty / native StoreKit
2. Ask for current **paywall view → CTA tap** and **trial → paid** rates (last 30 days)
3. Ask for a **screenshot of the current paywall** (or 2–3 if there are variants)
4. Ask for **plan structure** — monthly, annual, lifetime, weekly? Which price points?
5. If RevenueCat is connected, pull subscription metrics first (see `revenuecat-api`)

## Diagnose Before You Redesign

Run the paywall conversion funnel before changing anything:

| Stage | Healthy | Red Flag |
|-------|---------|----------|
| App open → paywall view | 60–95% (depends on placement) | <50% (paywall buried) |
| Paywall view → CTA tap | 25–45% | <15% (copy/offer weak) |
| CTA tap → purchase confirm | 70–90% | <50% (StoreKit friction or price shock) |
| Trial start → paid conversion | 25–60% (varies by category) | <15% (wrong audience or price) |

Identify the weakest stage. Optimize that stage only.

- Trial-to-paid is broken → it's a lifecycle problem (trial nurture, dunning, value moments during trial), not a paywall problem.
- Paywall view rate is low → it's a placement/routing problem — route to `onboarding-flow`.

## The 7-Element Paywall Audit

Score each element 1–5 from the screenshot. Anything ≤2 is a quick win, anything 3 is an A/B test candidate.

1. **Headline** — states the outcome, not the feature. "Unlock unlimited workouts" beats "Pro Plan".
2. **Value props** — 3–5 max, benefit-led, scannable in <3 seconds.
3. **Social proof** — rating, review count, user count, or named testimonials. Above the fold.
4. **Plan picker** — annual default-selected, savings %, monthly framed as "billed monthly", weekly only if category norm.
5. **Price anchoring** — annual shown as monthly equivalent ("$3.33/mo, billed annually") + total ("$39.99/yr").
6. **Trust elements** — "Cancel anytime", "No charge until X date", visible restore button.
7. **CTA** — single primary action, action verb ("Start free trial"), high-contrast.

## Paywall Placement Strategy

| Placement | Best for | Risk |
|-----------|----------|------|
| **Hard paywall** (after onboarding, before app) | High-intent installs, high-LTV apps | Tanks D1 retention; needs strong store creative |
| **Soft paywall** (after value moment) | Most consumer apps | Lower trial start rate |
| **Feature-gated** (paywall on premium feature tap) | Utility / productivity | Low conversion volume |
| **Time / usage gated** (free for N days/uses, then paywall) | Habit-forming apps | Hard to tune the gate |
| **Multiple paywalls** (different placements + designs) | Mature apps with Superwall/RevenueCat targeting | Engineering complexity |

If the user has no data, default to **soft paywall after first value moment**.

## Pricing Display Patterns

The display matters more than the price. Test these:

| Pattern | When to use |
|---------|-------------|
| **Annual default + savings %** ("Save 67%") | Most apps — anchors high, increases LTV |
| **Free trial CTA primary, plans secondary** | Trial-led products |
| **Single plan, single price** | Simple utilities; reduces choice paralysis |
| **3-tier (Basic / Pro / Pro+)** | Apps with feature differentiation; middle is anchor |
| **Lifetime as decoy** | Reframes subscription as "the cheap option" |
| **Localized currency + copy** | Required for non-US markets — Apple localizes price automatically, your display copy must match |

## A/B Testing Playbook

Test **one element at a time**. Sample-size floors for detecting ~10% lift:

| Baseline conversion | Min users per variant |
|---------------------|-----------------------|
| 5% | ~6,000 |
| 15% | ~2,000 |
| 30% | ~1,000 |

**Test priority order** (ship one per cycle):

1. Headline copy (highest leverage) — pair with `copywriter`
2. Trial offer (3-day vs 7-day vs no trial)
3. Plan default (annual vs monthly pre-selected)
4. CTA copy ("Start free trial" vs "Try free for 7 days" vs "Continue")
5. Social proof element (rating vs user count vs testimonial)
6. Visual style (clean vs bold vs photo background)
7. Number of plans (1 vs 2 vs 3)

**Tools**: Superwall (no-deploy paywall tests, recommended), RevenueCat Experiments, Adapty A/B, or native via remote config.

## Common Mistakes

- Testing 5 things at once — invalidates the result.
- Optimizing trial start while ignoring trial-to-paid (different problem — see lifecycle/dunning).
- Killing tests at p=0.05 without sample size — false positives in low-traffic apps.
- Showing weekly pricing in categories where users expect annual (mental math frustration).
- No restore-purchase button — guaranteed Apple rejection.
- Hiding "cancel anytime" — kills conversion among trial-skeptics.

## Output Template

```
PAYWALL DIAGNOSTIC — <App Name>

Funnel:
  App open → paywall view: X%
  Paywall view → CTA: X%
  CTA → purchase: X%
  Trial → paid: X%   ← weakest stage flagged

7-Element Audit:
  1. Headline:     X/5  — <note>
  2. Value props:  X/5  — <note>
  3. Social proof: X/5  — <note>
  4. Plan picker:  X/5  — <note>
  5. Price anchor: X/5  — <note>
  6. Trust:        X/5  — <note>
  7. CTA:          X/5  — <note>

QUICK WINS (ship this week):
  - <change 1>
  - <change 2>

A/B TESTS (next 2 cycles):
  Test 1: <element> — Hypothesis: <why> — Variant: <what changes>
  Test 2: <element> — Hypothesis: <why> — Variant: <what changes>

EXPECTED LIFT: +X% trial start, +Y% trial→paid
```

## Cross-Skill Handoffs

- Implementing the paywall (StoreKit, RevenueCat offerings/packages, display logic) → `revenuecat-sdk`
- Managing paywall resources via RevenueCat API → `revenuecat-api`
- Where the paywall fires in onboarding (placement, sequencing, demo-output continuity) → `onboarding-flow`
- Headline / value-prop / CTA copy iteration → `copywriter`
- A/B testing the App Store page that drives paywall traffic → `app-store-optimization`
