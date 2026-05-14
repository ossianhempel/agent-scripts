# In-App Copy

For everything inside a consumer mobile product: UI strings, buttons, empty
states, errors, onboarding, permission prompts, push notifications,
confirmations, toasts, paywall transitions, account creation prompts. Read
SKILL.md first — the core principles all apply.

In-app copy is where users *already chose you*. The job is no longer to sell —
it's to keep them moving, make them feel competent, and at key moments
re-sell them on the value they're getting. Every string is either moving
them forward, making them stop and think, or wasting a moment that could
have hyped them up. Aim for the first or third.

## The Three Foundational Rules (consumer mobile)

Sophistication loses. Obviousness wins. The product can be sophisticated under
the hood — the surface has to be brain-dead simple.

### 1. Show value in 3 seconds or less

Any user-facing surface — screenshot, empty state, paywall, onboarding screen,
push preview — has to communicate the value in under 3 seconds. If a user
can't tell what they get out of it before their thumb moves, it's dead.

Test it: glance for 3 seconds, look away. Can you say what it does for you?
If not, cut, simplify, or rewrite.

### 2. Write for a 3rd grader

Short words. Short sentences. No jargon, no industry language, no clever
phrasing that requires a second read. If a 9-year-old wouldn't understand it,
rewrite it.

This isn't about treating users as stupid. It's about removing every
millisecond of friction between seeing the words and getting the point.
Smart people scrolling fast read like 3rd graders.

| Too smart                          | 3rd-grader version              |
|------------------------------------|---------------------------------|
| "Optimize your nutrition"          | "Eat better"                    |
| "Track macronutrients effortlessly"| "Snap a photo. See the calories."|
| "Maximize your training output"    | "Lift more. Every week."        |

### 3. Buttons so obvious you can't get lost

Button labels tell the user exactly what happens when they tap. No
cleverness. No branded verbs. No ambiguity. If a user has to think about
which button to tap, the button has failed. The path through the app
should feel like the only possible path.

When in doubt, dumb it down further than feels comfortable. You will almost
never go too simple.

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

- **Verb + outcome**, not category. "Start tracking" not "Continue". "Log a set"
  not "Submit".
- **First person on commitments**: "Yes, delete my workout" not "Confirm".
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
| Get Started | (still fine) — beats "Begin Your Journey" |
| New Entry   | Log Workout                |

## Hype-Moment Copy (account creation, paywall reveal, plan summary)

Most in-app strings are utility. A handful of moments are *not* utility —
they're the moment the user sees what they're getting. Account creation
prompts, paywall transitions, "here's your personalized plan" reveals,
end-of-onboarding summaries.

**This is the single thing agents get wrong most often.** They write
neutral, descriptive copy at moments that should be making the user feel
like they're getting away with something. The user has just done work
(answered questions, picked goals, waited for generation). Reward them.

### Rules for hype moments

1. **Highlight the value they're getting**, not the action they need to take.
   The CTA is the small part. The reframe of what they already have is
   the big part.
2. **Anchor against cost / effort / time saved.** What would this have
   cost them with a PT, a coach, a nutritionist, hours of research? Name
   it. Make the free thing feel expensive.
3. **Make them feel grateful, not pitched at.** Frame it like they got
   lucky, not like you're selling. "You're the one getting a great deal
   here" energy.
4. **Reframe generic features as personalized outcomes.** "Weekly schedule"
   is a feature. "A complete program built around the answers you just gave"
   is a personalized outcome.
5. **Add scarcity or urgency when it's honest.** "Save it before you lose
   it", "We built this just now — create an account so it's still here when
   you come back". Never invent fake countdowns.

### Before / After

These are real examples from a Swedish fitness app at the account-creation
prompt right after onboarding. The "before" copy is correct but flat. The
"after" copy hypes up the value the user just received.

**Account creation headline**

Before:
> We built it around your answers. Create an account so it's still here
> when you start lifting.

After:
> A program like this would cost thousands at a personal trainer.
>
> Create an account so we can save it for you now.

Swedish original (for reference):
> "Ett sådant här skräddarsytt program hade kostat tusentals kronor hos
> en PT. Skapa ett konto så vi kan spara det åt dig nu."

**Plan summary bullets**

| Flat (feature-named)              | Hyped (value-framed)                                             |
|-----------------------------------|------------------------------------------------------------------|
| Weekly schedule and start date    | Complete training program covering the next {N} weeks            |
| The exercises you picked or were recommended | Exercises picked specifically to grow muscle as fast as possible |
| Goals and progression for the first block    | Personal goals that adapt to what you can actually handle        |

Swedish originals:
- "Veckoschema och startdatum" → "Komplett träningsprogram som sträcker
  sig {antal veckor} veckor"
- "Övningarna du valde eller fick rekommenderade" → "Övningar specifikt
  utvalda för att maximera muskeltillväxt så snabbt som möjligt"
- "Mål och progression för första blocket" → "Personliga mål som anpassar
  sig efter vad du klarar av"

### The pattern

Flat copy names *what the screen contains*. Hyped copy names *what the user
walked away with and what it would have cost otherwise*. Same data, totally
different feeling.

When you see flat in-app copy at a hype moment, default to this rewrite:

1. What did the user just receive? (Be concrete: a 12-week program, a
   personalized macro target, a custom routine.)
2. What would that have cost in the real world? (A PT session, a
   nutritionist, hours of research, a $200 plan.)
3. What's the urgency to act now? (Save it before it's gone, lock it in,
   come back to it later.)

Then write the copy. The CTA is almost an afterthought.

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
- **End of onboarding is a hype moment, not a summary.** See the Hype-Moment
  section above. The user just did work — make the payoff feel huge.

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
- **If the account-creation moment comes right after onboarding, treat
  it as a hype moment** (see above). Don't waste it on "Create your account
  to continue."

## Localization Notes

- Most of Ossian's apps default to Swedish (i18n via i18next, `sv.ts` /
  `en.ts`). Write source strings English-first if asked, but **always think
  about how they'll feel in Swedish** — Swedish is more direct, less salesy,
  shorter. Don't write English copy that only works because of marketing fluff
  the Swedish version will strip.
- The hype-moment examples above are Swedish-native. The pattern (anchor
  against cost, name what they received, add urgency) translates cleanly —
  it isn't a hype-up-with-adjectives pattern, it's a reframe-the-value
  pattern, which survives translation.
- German and Finnish run long — leave room in buttons.

## Quick Checklist

- [ ] 3-second value test: glance, look away, can you say what it does?
- [ ] 3rd-grader test: would a 9-year-old understand every word?
- [ ] Buttons are verbs + outcomes, not categories
- [ ] No "Submit", "Continue", "OK" without context
- [ ] Empty states promise an outcome and offer one action
- [ ] Errors say what happened and what to do next
- [ ] Onboarding screens each carry one message
- [ ] Push notifications are specific and earn the tap
- [ ] Toasts only fire when success isn't already visible
- [ ] Hype moments (account creation, paywall, plan reveal) reframe value
      against cost/effort, don't just describe what's on screen
- [ ] No jargon, no apology spirals, no fake urgency
- [ ] Reads naturally in the target language (not just translated)
