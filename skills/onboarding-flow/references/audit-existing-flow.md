# Auditing an Existing Onboarding Flow

Use this reference when the user already has an onboarding flow and wants to diagnose drop-off or score it — not when they're building from scratch (that's the main SKILL.md). The main flow assumes builder mode; this file covers auditor mode.

## The Activation Principle

**Activation ≠ sign-up.** Activation is the first time the user gets real value from your app. Identify it before scoring anything.

| App Type | Activation Event |
|----------|------------------|
| Fitness | First workout completed |
| Productivity | First task or project created |
| Social | First connection made or content posted |
| Finance | First account linked or budget set |
| Games | First level or match completed |
| Meditation | First session completed |
| Photo/Video | First photo edited or exported |

**Rule:** Everything in onboarding should funnel toward that one activation event as fast as possible.

## Initial Audit Questions

1. What is the activation event for this app?
2. What % of new users reach it within 24 hours? (baseline)
3. Where do users drop off? (which step, if known)
4. How long is the current onboarding? (steps, screens, seconds)
5. Is there a funnel tracking it? (Firebase, Mixpanel, Amplitude)

## Screen-by-Screen Scorecard

Map every screen from app open to activation, then score each:

```
App open → [Screen 1] → [Screen 2] → ... → Activation event
```

For each screen:

| Factor | Question | Score |
|--------|----------|-------|
| **Necessity** | Can the user reach activation without this screen? | 0 = remove it |
| **Timing** | Is this the right moment for this ask? | |
| **Value exchange** | Does the user understand why this benefits them? | |
| **Cognitive load** | How many decisions does this require? | |

Flag each screen: **Required** | **Value-adding** | **Friction only**. Remove or defer everything that scores as friction only.

## Permission Prompt Timing

Permissions are the #1 drop-off point. Always show a native-looking pre-permission screen (priming) before triggering the system prompt — users who understand the "why" grant at 2–3× the rate.

| Permission | When to ask | Never ask |
|------------|-------------|-----------|
| Push notifications | After activation, not before | On cold open |
| Location | When the feature needs it | During sign-up |
| Camera / microphone | Contextually, when used | Before any value |
| Contacts | When a social feature is used | In onboarding |
| Tracking (ATT) | After user is invested | On first open |

iOS notification permission and ATT are one-shot — if denied, you're stuck with Settings deep-linking. Never trigger them without priming.

## Sign-Up Friction

| Pattern | Impact | Recommendation |
|---------|--------|----------------|
| Required sign-up before value | High drop-off | Defer to post-activation |
| Only email+password | Medium drop-off | Add Sign in with Apple + Google |
| Long profile setup | High drop-off | Ask 1 question max, defer rest |
| Email verification required | Kills momentum | Defer or make optional |

**Guest mode** — letting users experience core value before requiring an account — typically converts guest → registered at 40–60%, vs. 15–30% for a hard sign-up gate.

## Funnel Benchmarks

Compare the audited flow against these reference rates. Below "Poor" usually means a structural problem, not a copy tweak.

| Step | Good | Poor |
|------|------|------|
| App open → first interaction | > 85% | < 70% |
| Sign-up conversion | > 60% | < 40% |
| Push permission grant | > 50% | < 30% |
| Activation (D0) | > 40% | < 20% |
| Day 1 retention | > 30% | < 15% |

## Paywall Placement Timing

| Placement | Works When |
|-----------|------------|
| Before activation | Almost never — user has no reference for value |
| At activation moment | Strong — user just felt the value |
| Post-activation, D1 | Strongest for subscription apps |
| Contextual (feature gate) | Good for feature-based paywall |

## Audit Output Format

```
Current flow:
  [Screen 1] — Required / friction
  [Screen 2] — Value-adding
  ...
  [Activation event] — Step N

Drop-off analysis:
  Biggest drop: [screen] ([X]% exit if known)
  Estimated cause: [hypothesis]

Recommended changes:
1. [Remove / defer X] — Expected impact: [lift in activation]
2. [Reorder Y before Z] — Expected impact: [rationale]
3. [Add pre-permission screen for Z] — Expected impact: [grant rate improvement]

Revised flow:
  Open → [Screen] → [Screen] → Activation → Sign-up → Permissions
  Steps removed: [N]
  Time to activation: [Xs → Xs]
```

## Pre-Permission Screen Copy Template

```
[Icon representing the permission]

[Benefit headline — what the user gets]
e.g., "Get notified when your goal is complete"

[One-line explanation]
e.g., "We'll only send you reminders you set — no spam."

[Allow]     [Not now]
```

Always frame around the user's benefit, never the app's need.

## When to Use Audit Mode vs. Builder Mode

- **Audit mode (this file):** existing flow, measurable drop-off, "why are users leaving at step 3?"
- **Builder mode (main SKILL.md):** new app or full rebuild, no flow exists or it's not worth saving.

If the audit surfaces structural problems (wrong activation event, paywall before value, mandatory sign-up before activation), switch to builder mode and redesign from Phase 1.
