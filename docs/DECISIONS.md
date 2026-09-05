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
`/sdcard/EyesUp/config/*.json`, seeded from bundled assets on first run, with a **Reload config**
button in Settings.

**Why.** This is the single most valuable Red Light unlock in the plan. Red Light is ~55% of the
event and it is phone-only; without this, every parser tweak needs a laptop, a rebuild and an
install. With it, the loop is: edit JSON in a phone text editor → tap Reload → fire a `:gigsim`
payload → hear the result. Seconds, no laptop. It also makes a "wrong verdict" on stage recoverable —
you show the config and say it is tunable, which reads as engineering rather than luck.

**Consequence.** Nothing tunable may be hardcoded in Kotlin. A malformed config falls back to the
bundled asset and shows a toast — it must never crash. Requires a phone text editor installed in
Hour 0, and a `VERIFY` on scoped-storage access to `/sdcard/EyesUp/` on the loaner's API level.

---

## ADR-008 - The product is named EyesUp; the code identifier never changes
**Date:** 2026-09-05 - **Status:** Accepted (final; earlier candidates Sarthi and Pillion were dropped before any code existed)

**Decision.** The product is **EyesUp**. `applicationId` fixed at `com.eyesup.app` from the first
source commit. Repo: `https://github.com/NotArnav03/EyesUp.git`.

**Why.** It is an imperative, not a noun - it is the instruction the product exists to make possible,
and it is what a driving instructor says. It names the *benefit* rather than the mechanism, which is
the right level for a jury: nobody has to be told what EyesUp is for. It also lines up exactly with
the two things the pitch now leads on - the reframe ("we move the decision from the screen to the
voice layer", `DEMO_AND_PITCH.md` §1) and Zero-Look Mode (ADR-017). The name, the framing and the
hero feature all say the same thing.

Earlier candidates: *Sarthi* (good, but a saturated register at Indian hackathons) and *Pillion*
(accurate but describes the mechanism, not the outcome).

**Consequence.** Never rename the package mid-build. Renaming was free while no code existed; after
the first source commit it is not, and ADR-014 puts that commit at 11:00. The display name and the
identifier are separate, so a branding change later costs one string.

---

## ADR-009 — EyesUp never automates an action inside another app
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** No accessibility-service tapping, no auto-accept, no interaction with any gig app's UI.
EyesUp reads notifications and speaks. The driver acts.

**Why.** Auto-accepting would breach every platform's terms, would be the one thing that turns a
defensible driver-side assistant into an indefensible bot, and is exactly the objection a sharp judge
reaches for. Declining to build it is also a better answer than defending it: "EyesUp advises, the
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

## ADR-011 — The local LLM runs in shadow mode on every notification, and writes the explanations
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** The handbook (p.01) says HackTracker *"reads model outputs, and logs inference calls,
tokens and thermals in real time."* On-device inference is therefore mechanically counted toward the
15% Creative Phone Use line. ADR-004 had the LLM as a rarely-triggered last-resort fallback, which
would fire on almost nothing and bank almost nothing.

**Decision.** The local LLM runs on **every** captured notification, in parallel with the regex path
rather than after it, and it additionally generates the long-form "why" explanations and parses voice
intents.

**Why.** Two genuine product uses, not padding: shadow extraction gives us a live confidence check
against the deterministic path (and the UI can show "the local model agrees", which is a good demo
beat), and natural-language explanation and intent parsing are exactly what a small LLM is for. The
regex path still owns the demo-critical fast lane, so reliability is unaffected. And every inference
is measured.

**Rejected.** Firing the model on a timer with synthetic input purely to generate telemetry. We could
not defend it and we do not need to.

**Consequence.** `ParserCascade` gains a shadow path that never blocks the verdict. `LlmParser` must
be non-blocking, cancellable and strictly single-instance. If inference cost becomes a thermal
problem, throttle the shadow path — never the fast path.

---

## ADR-012 — Stage two model sizes; the device is far stronger than assumed
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** The loaner is an iQOO 15: Snapdragon 8 Elite Gen 5, dedicated Q3 chip, 16 GB LPDDR5X,
14,000 mm² vapour chamber. The handbook says it *"runs quantised local LLMs at usable speed"*.

**Decision.** Stage both `gemma3-1b-it-int4` (~550 MB, safe) and a 3–4B int4 `.task` (~2.5 GB,
ambitious). Ship whichever loads and performs. Push both in the 11:00–14:00 green window.

**Why.** Gemma 3 1B underuses this hardware, and extraction quality on messy notification text
improves noticeably at 3–4B. The vapour chamber means sustained inference is realistic, which is what
shadow mode (ADR-011) needs. But the 4B download is the risk, so the 1B remains the guaranteed path.

**Consequence.** If the 4B is not downloaded by 13:00, ship the 1B and stop. The hard Tier C cutoff at
Sun 00:00 (`RISKS_AND_FALLBACKS.md` §3.3) still applies to both.

---

## ADR-013 — GigSim runs on a second loaner phone
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Phone A = EyesUp (demo), Phone B = GigSim, Phone C = ops. Label them physically.

**Why.** One flagship loaner per person (handbook p.02), so a 2–3 person team has spare devices and
nobody needs to bring a personal phone. It also means all three devices are generating telemetry
rather than one.

**Consequence.** The demo needs two phones on stage. Both must be charged and both must be in the
venue — the devices are iQOO property and cannot leave.

---

## ADR-014 — No source code exists before 11:00 Saturday
**Date:** 2026-09-05 · **Status:** Accepted

**Context.** Handbook p.03: *"Original work only: code written during the event window. No shipping a
pre-built product... Organisers may verify a project was built inside the event window."*

**Decision.** Planning documents, specifications and config seeds are written before the start — those
are not a product. **The first source commit must be timestamped after 11:00.**

**Why.** Compliance, obviously. But also: a clean commit trail starting at 11:00 is an *asset*. If
anyone asks whether this was built in-window, we offer the git history rather than defending
ourselves.

**Consequence.** Commit small and often from 11:00 onward — the history is evidence, so make it
legible.

---

## ADR-015 — OpenRouter credits are for coding assistance only, never in the product
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** The $25 of OpenRouter credit is used for agentic coding tools. **No shipped code path
makes a network call to any model.**

**Why.** The handbook's own tip to win (p.04): *"Build apps that run locally and on-device, including
the backend, using on-device LLMs... The highest on-device builds will be preferred for the Top 10."*
A single cloud call in the product forfeits the exact thing we are strongest on, for capability we do
not need. On-device inference also costs zero credits.

**Consequence.** There is no networking dependency in the app at all. If a judge asks what happens
offline, the answer is "nothing changes" — and they can test it.

---

## ADR-016 — Scoring is net earnings per hour, not gross rupees per kilometre
**Date:** 2026-09-05 · **Status:** Accepted · **Refines ADR-005**

**Decision.** The headline metric is **net ₹/hour**: payout, minus fuel cost over the *effective*
distance (trip + pickup), divided by effective time. Fuel cost is personalised from one onboarding
question ("what's your mileage?") and a petrol price in config.

**Why.** Gross ₹/km was half-right. Drivers care about what they keep, and time — not distance — is
the scarce resource, so ₹/hour is the correct comparator. "This pays ₹100, you net ₹64, that's ₹236 an
hour not ₹393" is a materially stronger line than any per-km figure, and the fuel model makes the
deadhead insight concrete: unpaid pickup kilometres now cost actual rupees.

**Consequence.** `OrderOffer` gains derived `netRupees` and `netPerHour`. `ScoringConfig` gains
`petrolPricePerLitre`; `DriverProfile` gains `vehicleKmpl`. The spoken template leads with ₹/hour.
Every demo payload's ranking must be hand-verified against this formula — see `NOTIFICATION_CORPUS.md`
§4.

---

## ADR-017 — Zero-Look Mode is a named feature with a motion trigger
**Date:** 2026-09-05 · **Status:** Accepted

**Decision.** Above a motion threshold (accelerometer / Activity Recognition), the UI collapses to one
large card, touch interaction is refused with a spoken explanation, and the product is voice-only.

**Why.** Mechanically this is close to what the app already did — the *name* and the trigger are the
upgrade, and a named hero feature is worth real points in a 90-second pitch. It also banks another
sensor for Creative Phone Use, and it is the cleanest expression of the reframe: the decision moves
off the screen entirely.

**Consequence.** Never claim it makes driving safe. It is a safety-oriented mode, framed as reducing
what the product asks of the driver's attention — not as a guarantee.

---

## ADR-018 — Camera OCR ingestion replaces the camera fatigue check
**Date:** 2026-09-05 · **Status:** Accepted · **Supersedes ADR-010**

**Decision.** The camera feature is a stationary "point at an order screen" path: ML Kit Text
Recognition (offline, on-device) → the same normaliser → the same decision engine. The fatigue check
is dropped.

**Why.** The roadmap previously cut screen-OCR as camera-use-for-its-own-sake. That was wrong for this
version of it: OCR ingestion is a coherent *second input path* for platforms whose notifications are
too sparse to parse, so the camera is doing something the product actually needs. The fatigue check
was the opposite — a sensor looking for a justification, with a mount caveat we would have had to
apologise for on stage.

**Consequence.** ADR-010 is superseded; do not build the fatigue check. Both remain Tier 3 —
attempted only after Eval 2 is clean.

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
