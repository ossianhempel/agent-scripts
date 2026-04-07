# In-App Copy

For UI strings inside the product: buttons, empty states, errors, onboarding,
permission prompts, push notifications, confirmations, toasts. Read SKILL.md
first — the core principles all apply.

In-app copy is where users *already chose you*. The job is no longer to sell —
it's to keep them moving and make them feel competent. Every string is either
moving them forward or making them stop and think. Aim for the first.

## Universal Rules

1. **Use the user's verbs.** "Save" beats "Persist". "Done" beats "Confirm".
2. **One job per string.** A button label, an error message, a toast — each
   says one thing.
3. **Active voice, present tense.** "We couldn't save your changes" beats
   "Your changes were unable to be saved".
4. **Plain English. Or plain Swedish.** No jargon. No product team words.
5. **Fail without blaming the user.** Errors should explain what happened and
   what to do next, not "Invalid input".
6. **Match the tone of the product.** Most of Ossian's apps are direct,
   confident, slightly dry. Don't get cute unless the product is cute.

## Buttons & CTAs

- **Verb + outcome**, not category. "Start tracking" > "Continue". "Log a set"
  > "Submit".
- **First person on commitments**: "Yes, delete my workout" > "Confirm".
- **Pair destructive actions with intent**: not "Delete?" but "Delete this
  workout? You can't undo this."
- **Primary CTA = the thing you want them to do.** Secondary CTA = the escape
  hatch. Don't make both look equal.

| Bad         | Good                       |
|-------------|----------------------------|
| Submit      | Save workout               |
| Continue    | Start tracking             |
| OK          | Got it / Sounds good       |
| Confirm     | Yes, delete                |
| Learn more  | See how it works           |

## Empty States

The empty state is the most important screen in your app — it's the first
impression of every feature. Treat it like a screenshot.

Structure:
- **One-line outcome** (what this screen will look like once it has content)
- **One-line action** (what to do to get there)
- **One CTA** (the verb)

Example (workout log, empty):
> No workouts yet.
> Log your first set and we'll start tracking your progress automatically.
> [ Log a set ]

Bad:
> Nothing here yet.
> [ Add ]

## Error Messages

Three parts: **what happened**, **why** (only if useful), **what to do next**.

- Don't blame the user. "Invalid email" → "That doesn't look like an email
  address — check for typos?"
- Don't show error codes unless the user is supposed to send them somewhere.
- Don't apologize three times. Once is enough.
- Offer the next action as a button if you can.

| Bad                        | Good                                              |
|----------------------------|---------------------------------------------------|
| Error 401                  | You're signed out. Sign in to keep going. [Sign in] |
| Invalid input              | Password needs at least 8 characters.             |
| Something went wrong       | Couldn't reach the server. Check your connection and try again. |

## Onboarding Strings

- **Each screen = one promise.** Same rule as App Store screenshots.
- **Skip the welcome screen.** Or replace it with a working screen.
- **Don't explain features. Show outcomes.** Same rules as App Store.
- **Permission prompts come *after* the user understands why** they're needed.
  Pre-prompt with a one-line reason; don't trigger the system dialog cold.

Pre-permission pattern:
> To remind you about your next workout, we need to send notifications.
> [ Sounds good ]   [ Not now ]

(Then trigger the OS prompt only if they tap "Sounds good".)

## Push Notifications

- **Specific > generic.** "You haven't logged in 3 days" > "We miss you!"
- **Earn the tap.** What does the user get if they open it?
- **One job per push.** Don't bundle.
- **Respect the user.** No fake urgency. No fake personalization. No "🚨".

| Bad                          | Good                                              |
|------------------------------|---------------------------------------------------|
| We miss you!                 | Your last workout was 6 days ago. Quick set?      |
| New features available!      | You can now log supersets in two taps.            |
| Don't forget to log!         | Yesterday's leg day is still unfinished.          |

## Confirmations & Toasts

- **Past tense for success.** "Workout saved." not "Workout will be saved."
- **Skip the toast if the UI already shows the result.** A toast saying "Set
  added" when the set just appeared in the list is noise.
- **Toasts are for invisible success.** When the result isn't visually
  obvious, confirm it.

## System Strings (loading, syncing, retrying)

- **Be honest about what's happening.** "Syncing your last 3 workouts…" >
  "Loading…"
- **Show progress when you can.** A progress bar with a number beats a spinner.
- **If it's slow, say what's slow.** "Uploading photos — this can take a
  minute on a slow connection."

## Sign-In / Auth

- **Be clear about what you're asking for and why.**
- **Don't say "create account" if "sign in" works.** Account creation is
  friction; phrase it like a step, not a commitment.
- **Forgot password should be visible, not buried.**

## Localization Notes

- Most of Ossian's apps default to Swedish (i18n via i18next, `sv.ts` /
  `en.ts`). Write source strings English-first if asked, but **always think
  about how they'll feel in Swedish** — Swedish is more direct, less salesy,
  shorter. Don't write English copy that only works because of marketing fluff
  the Swedish version will strip.
- German and Finnish run long — leave room in buttons.

## Quick Checklist

- [ ] Buttons are verbs + outcomes, not categories
- [ ] No "Submit", "Continue", "OK" without context
- [ ] Empty states promise an outcome and offer one action
- [ ] Errors say what happened and what to do next
- [ ] Onboarding screens each carry one message
- [ ] Push notifications are specific and earn the tap
- [ ] Toasts only fire when success isn't already visible
- [ ] No jargon, no apology spirals, no fake urgency
- [ ] Reads naturally in the target language (not just translated)
