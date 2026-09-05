# DECISIONS.md — Architecture Decision Record

**Do not reopen a decision recorded here.** If you genuinely think one is wrong, append a new ADR that
supersedes it, say why, and note it in `PROGRESS.md`. Silently doing something different is how a
relay build ends up with two incompatible halves.

Format: one decision, the context, what was chosen, what was rejected, and the consequence.

---

## ADR-001 — Cross-app arbitration is the headline feature, not a differentiator
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** The original plan framed the product as "read the notification, say take or skip", with
cross-app comparison listed as a Tier 1 nice-to-have.

**Decision.** Cross-app arbitration is the product's central claim and the lead of the pitch.
Single-offer take/skip is table stakes.

**Why.** An experienced driver already has a ₹/km rule in their head; telling them one offer is
below it is not worth installing an app for. What no human can do — at all, let alone while driving —
is hold three live offers from three different apps in working memory, normalise each for unpaid
pickup distance, and decide inside a 20-second window. That is the only part of this product that is
genuinely impossible without it, so it is the part that earns the novelty score.

**Rejected.** Leading with the safety framing alone. Safety is the *why it matters*, but a jury has
seen many safety framings; they have not seen cross-platform offer arbitration.

**Consequence.** `OfferQueue` moves early in the build order (step 8, immediately after Eval 1). The
STORM demo becomes the centre of the stage sequence. The scoring engine must be able to score a
whole set, not just one offer.

---

## ADR-002 — Input comes from a companion `:gigsim` APK, not from real gig apps
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** The original plan's first Red Light task was "install the gig apps and capture live
notification payloads." It also listed a demo simulator as a separate Tier 0 item.

**Decision.** Build `:gigsim`, a second installable app that posts genuine Android notifications
carrying realistic gig-app payloads. It is the only input path we plan around.

**Why.** Uber Driver, Swiggy Delivery Partner, Zomato Delivery and Rapido Captain all require
document-based driver onboarding — licence, vehicle registration, sometimes a background check. We
will not have accounts at a hackathon, so "capture live payloads" was a task that could never have
completed, and the plan quietly depended on it. Posting from a second app instead exercises the
entire real pipeline — OS notification bus → `NotificationListenerService` → parse → score → speak —
with no mocking anywhere inside the product. It is also strictly better for the demo: repeatable,
on cue, and it makes the three-offers-in-six-seconds arbitration demo possible at all, which waiting
for real orders never would have been.

**Rejected.** (a) An in-app simulator that injects `NotificationEvent` directly — it would bypass the
listener, which is the technically interesting part, and it would be dishonest to demo. (b) Rooting
or using an accessibility service to read the gig apps' UI — slower, more fragile, and a much harder
ethics question. (c) Waiting for real orders — impossible.

**Consequence.** `:gigsim` becomes step 1 of the build order. `GigApp` is resolved from the
notification **channel id**, not the package name, so the product is unchanged whether the sender is
`:gigsim` or a real app. The simulator must be disclosed on stage every time.

---

## ADR-003 — No Gemini Nano, no Android AICore
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** The original plan listed "Gemini Nano via Android AI Core (if the loaner device supports
it)" as the first on-device model option.

**Decision.** Remove it entirely. Do not check for it, do not plan around it.

**Why.** AICore is not a generic Android API. It ships on a short allow-list of devices — Pixel 8
Pro and later, Galaxy S24 and later — and is not present on vivo/iQOO Funtouch OS. "Check on arrival"
would have cost Red Light hours to arrive at a known dead end.

**Consequence.** All on-device inference goes through ML Kit and MediaPipe, both of which are
device-agnostic. See ADR-004.

---

## ADR-004 — On-device NLU is a three-tier cascade, not one model
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Tier A regex (config-driven) → Tier B ML Kit Entity Extraction → Tier C MediaPipe
Gemma3-1B-IT int4. Each tier fills only the fields the tier above left null. Confidence is tracked
per field and per tier.

**Why.** A single-model design makes the entire "on-device AI" claim — which is 15% of the score —
contingent on one risky component loading on unfamiliar hardware. The cascade removes the single
point of failure: ML Kit Entity Extraction is a genuine offline on-device model that is a few
megabytes and near-certain to work, so even if Gemma never loads we can truthfully say an on-device
model is doing extraction. Gemma becomes upside rather than a dependency. The cascade is also more
defensible under questioning than "it's all AI", because it is what a serious engineer would actually
build: cheap deterministic path first, expensive general path only for the long tail.

**Rejected.** (a) Regex only — no on-device AI claim, and 15% of the score is on-device AI. (b) LLM
only — too slow for a 20-second offer window, and one bad load kills the demo. (c) Training a small
custom model — no time, no labelled data, and it would be less explainable than the cascade.

**Consequence.** `ParserCascade` with an `isAvailable` flag per tier. Tier C carries a hard cutoff at
Sun 00:00 (see `RISKS_AND_FALLBACKS.md` §3.3).

---

## ADR-005 — Scoring counts deadhead distance, earnings-goal urgency and drop-zone demand
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Rate is `payout / (tripKm + pickupKm)`, not `payout / tripKm`. The score additionally
carries a goal-urgency term and a drop-zone demand term from a static Pune zone × hour table.

**Why.** Deadhead is the domain insight: the unpaid kilometres to reach a pickup are real cost, and
platforms do not surface them, so a tool that does is immediately credible to anyone who knows the
space. Goal urgency (how far from today's target, how much shift is left) is what actually drives a
real driver's accept decision late in a shift, and it costs a running total and a clock. Drop-zone
demand — "this leaves you in Hinjewadi at 22:00, you will drive back empty" — is a static table, an
hour of work, and lands hard with a Pune jury.

**Rejected.** A flat ₹/km threshold. It is a rule the driver already has; encoding it adds nothing.

**Consequence.** `pickupKm` becomes a field the parser tries hard to extract. `ScoringConfig` grows
the zone table. All of it is tunable from `scoring.json` on the device.

---

## ADR-006 — No Room, no SQLite. JSON files plus DataStore
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Persist `DriverProfile`, decision history and session state as kotlinx-serialization
JSON in `filesDir`. Preferences in DataStore.

**Why.** Total persisted data is a profile object and a few hundred decision records — hundreds of
kilobytes. Room brings KSP, an annotation processor, a schema, migrations and a class of build
failure that is expensive to debug at 3 a.m., in exchange for query capability we will never use.

**Consequence.** No queries; everything is loaded into memory. Fine at this scale. If history ever
needs to be large, cap it at 200 records and drop the oldest.

---

## ADR-007 — Runtime config is hot-reloadable JSON on the device
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Parser patterns, scoring weights, the zone table, TTLs and TTS templates load from
`/sdcard/Sarthi/config/*.json`, seeded from bundled assets on first run, with a **Reload config**
button in Settings.

**Why.** This is the single most valuable Red Light unlock in the plan. Red Light is ~55% of the
event and it is phone-only; without this, every parser tweak needs a laptop, a rebuild and an
install. With it, the loop is: edit JSON in a phone text editor → tap Reload → fire a `:gigsim`
payload → hear the result. Seconds, no laptop. It also makes a "wrong verdict" on stage recoverable —
you show the config and say it is tunable, which reads as engineering rather than luck.

**Consequence.** Nothing tunable may be hardcoded in Kotlin. A malformed config falls back to the
bundled asset and shows a toast — it must never crash. Requires a phone text editor installed in
Hour 0, and a `VERIFY` on scoped-storage access to `/sdcard/Sarthi/` on the loaner's API level.

---

## ADR-008 — The product is named Sarthi; the code identifier never changes
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Display name **Sarthi** (सारथी, the charioteer). `applicationId` fixed at
`com.sarthi.copilot` on day one.

**Why.** "Driver Copilot" is descriptive but generic. Sarthi is the word for the person who drives
the chariot while the warrior fights — Krishna was Arjuna's sarthi — so it means "the one who
handles the driving decisions for you" natively in both Marathi and Hindi, in front of a Pune jury.
Fixing the identifier separately from the display name means a late change of heart about branding
costs one string, not a refactor.

**Consequence.** If the team prefers the old name, change only the display string. Never rename the
package mid-build.

---

## ADR-009 — Sarthi never automates an action inside another app
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** No accessibility-service tapping, no auto-accept, no interaction with any gig app's UI.
Sarthi reads notifications and speaks. The driver acts.

**Why.** Auto-accepting would breach every platform's terms, would be the one thing that turns a
defensible driver-side assistant into an indefensible bot, and is exactly the objection a sharp judge
reaches for. Declining to build it is also a better answer than defending it: "Sarthi advises, the
driver taps" ends that line of questioning in one sentence.

**Consequence.** The `ACCEPT` voice intent marks our internal record and updates the threshold — it
does not accept the order in the gig app. Say this plainly if asked.

---

## ADR-010 — Camera work is a single shot between orders, not continuous monitoring
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** T3.3 is a "how am I doing" button that takes one front-camera frame, runs MediaPipe
Face Landmarker on-device, and speaks a fatigue read. Landmarks are transient and never stored.
Continuous monitoring is out of scope.

**Why.** Continuous monitoring is not finishable in the remaining hours, drains battery during a
demo, and invites a privacy question we would rather answer with "one frame, on device, discarded."
The mount caveat is real and unavoidable — most dash mounts face forward, so a driver-facing fatigue
check needs a specific setup. **Say that on stage before a judge says it**; volunteering a limitation
reads as rigour, being caught on one reads as overselling.

**Consequence.** T3.3 is attempted only after Eval 2 is clean, and it is cut without discussion if
anything in Tier 0 or Tier 1 is shaky.

---

## Template for new ADRs

```markdown
## ADR-0NN — <one-line decision>
**Date:** YYYY-MM-DD · **Status:** Accepted | Superseded by ADR-0MM

**Context.** What forced a decision.
**Decision.** What we are doing.
**Why.** The reasoning, including anything non-obvious.
**Rejected.** What else was considered and why it lost.
**Consequence.** What this obliges the code or the team to do.
```
