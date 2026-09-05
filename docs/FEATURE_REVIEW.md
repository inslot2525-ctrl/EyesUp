# FEATURE_REVIEW.md — verdict on the teammate's 25-point feature list

Reviewed 2026-09-05, ~11:00, against the handbook and the time actually remaining.

**Summary.** The list is stronger than the existing plan on *product framing* — net earnings, ₹/hour
as the headline metric, the "Zero-Look" name, the Shift Strategist, and especially the closing
reframe are all genuine upgrades and are now adopted. It is weaker on *feasibility discipline*: about
a third of it needs data, routing or network we do not have, and one item (accessibility scraping)
would actively damage the pitch. Adopted items are folded into the roadmap tiers; rejected items are
recorded here so nobody re-proposes them at 3 a.m.

**The one structural warning:** even the "MUST BUILD" list in §23 is twelve features. We have one
5h30m green window left after Eval 1. The build order in `driver-copilot-features-roadmap.md` §3
still governs. Adopting an idea into a tier is not a commitment to ship it.

---

## Adopted — these change the product for the better

| # | Feature | Verdict | Cost | Now lives in |
|---|---|---|---|---|
| 7, 8 | **True net earnings + personal fuel model** | **Adopt, high priority.** This is the best idea in the list. Ask mileage once ("45 kmpl"), take the petrol price, derive ₹/km fuel cost, subtract it. "This pays ₹100, but you net ₹64 after fuel and time" is a far stronger line than any rate comparison, and gig workers genuinely think this way. It also makes our deadhead insight land harder — unpaid pickup km now cost *actual rupees*, not just an abstract penalty. | ~45 min. One number, one multiply. | T0.4 (scoring), ADR-016 |
| 1 | **₹/hour as the spoken headline metric** | **Adopt.** He is right and the previous plan was half-wrong. ₹/km is the driver's folk metric, but time is the scarce resource, so ₹/hour is the correct comparator. "₹393 an hour versus ₹236" is a much sharper demo line than "₹13/km versus ₹9/km". The formula already computed this as `timeTerm`; it was just buried. Speak both, lead with ₹/hour. | ~15 min. Already computed. | T0.5, BUILD_SPEC §5 |
| 20, 4 | **Zero-Look Mode + Driving Mode** | **Adopt the name and the motion trigger.** Mechanically this is what the app already did — the naming is the upgrade, and a named hero feature is worth real points in a 90-second pitch. The accelerometer/Activity Recognition trigger is cheap and banks another sensor for Creative Phone Use. Above a motion threshold: screen goes to one huge card, interaction disabled, voice only. | ~1h incl. motion detection. | T1.7, ADR-017 |
| 24 | **AI Shift Strategist** | **Adopt.** This is the existing `goalUrgency` term with a proper face on it: target, current, time left, required rate vs current rate, spoken coaching. The arithmetic already exists; this is presentation, and it converts a scoring term into a demoable feature. | ~1h. | T1.5 (upgraded) |
| 3, 15, 19 | **Conversational voice loop, promoted to Tier 1** | **Adopt the promotion.** Voice was Tier 3; the rubric rewards it and the product is voice-first, so that was mis-tiered. Use the on-device LLM for intent parsing rather than keyword matching — that is a genuine LLM job *and* it banks inference calls, which HackTracker counts directly. Keep the "Why" **button** as the demo-safe path. | ~1.5h. | T1.8, ADR-011 |
| 16, 17 | **Priority preference + Home Direction** | **Adopt as Tier 2.** One onboarding question ("maximise earnings / minimise fuel / finish early / heading home") reweights the score. Home Direction is a bearing comparison against the drop zone. Both are cheap and both produce good spoken lines — "pays ₹18 less but takes you 4 km toward home" is a strong demo beat. | ~45 min combined. | T2.6, T2.7 |
| 2 | **A single "Smart Score" number** | **Adopt the presentation.** The engine already produces a 0–100 score; surfacing it as one number a judge can grasp instantly ("Blinkit, score 89") is worth doing. The mechanism is unchanged. | ~0. Already built. | T0.4 |
| 22 | **Use the phone hard, in both phases** | **Already adopted**, and reinforced by the organiser's tip. See gameplan §4a. | — | Playbook §7 |
| Closing | **The framing reframe** | **Adopt, and this matters.** "We move the decision from the screen to the voice layer" is materially safer and stronger than "we help drivers who look at their phone while driving" — the old framing implies we enable phone use in traffic, which a sharp judge will turn against us. The pitch opener is rewritten. | ~0. | DEMO_AND_PITCH §1 |

---

## Adopted with a change

| # | Feature | What changes and why |
|---|---|---|
| 5C | **Camera OCR ingestion** | **Adopted, and it replaces the camera fatigue check.** The roadmap previously cut "photograph the screen for OCR" as camera-use-for-its-own-sake. That judgement was wrong for *this* version of it: a stationary worker pointing the camera at an order screen, ML Kit Text Recognition (offline, on-device) → the same normaliser → the same decision engine, is a *coherent second ingestion path* for platforms whose notifications are too sparse to parse. It uses the camera for something the product actually needs. The fatigue check does not — it was a sensor looking for a justification. **Swap them: OCR ingestion becomes the camera feature, the fatigue check is dropped.** Supersedes ADR-010. |
| 10, 12 | **"Should I wait?" / "Where should I go?"** | **Adopted only in the form already planned** — the static Pune zone × hour table, presented honestly as domain heuristics, with "the next version learns this from the driver's own history" as the answer when asked. **Do not train a model on simulated data and present it as prediction.** "We trained it on data we generated" is a credibility landmine in front of a technical jury, and it is the kind of thing that gets asked. The heuristic version tells the same story and survives the follow-up question. |
| 9 | **Route-aware comparison** | **Adopted only as a static zone-pair travel-time table**, if there is time at all. Real traffic-aware routing needs a network API, which forfeits the on-device story the handbook explicitly rewards ("the highest on-device builds will be preferred for the Top 10"). Multi-order route optimisation is a TSP variant and is not a 30-hour feature. |

---

## Rejected

| # | Feature | Why not |
|---|---|---|
| 5B | **Accessibility service to scrape other apps' UI** | **Reject, firmly.** This is the one item in the list that could actively cost us. It contradicts ADR-009, Play policy restricts accessibility services to accessibility purposes, and it converts a defensible driver-side assistant into something a judge can reasonably call scraping. The teammate hedges it himself in the same paragraph. The notification listener is the honest channel and is a *stronger* technical claim anyway, because it is the OS's own delivery mechanism. **Not a time call — a positioning call. We would reject this with unlimited time.** |
| 11, 18 | **Daily earnings dashboard, gamification, efficiency streaks** | Retention features. Nothing in the rubric scores retention, no judge sees day two, and they cost hours that Tier 0/1 needs. Cut. |
| 9b | **Multi-order route optimisation** | Not a 30-hour feature. |
| 3b | **"Accept" that actually accepts in the gig app** | Keep the voice command, keep ADR-009's boundary: it marks our internal record and updates the threshold. It never taps accept in another app. Say this plainly if asked — it is the answer that ends the "isn't this a bot" line of questioning. |

---

## One correction to the list's own numbers

The worked example in §1 ranks Blinkit best at ₹393/hour. That is right on ₹/hour — but it ignores
pickup distance, which is the whole insight the product is built on. A ₹72 / 2.4 km job with a 3 km
ride to the pickup is a ₹72 / 5.4 km job in reality, and the ranking can flip. **Every metric in the
list must be computed on effective distance and effective time, including the deadhead.** That is
already how `BUILD_SPEC.md` §5 specifies it; the demo payload numbers must be checked against it by
hand so the ranking is unambiguous on stage.

---

## What this does to the plan

Net effect: **two new Tier 1 items** (Zero-Look Mode, voice loop promoted), **one Tier 0 upgrade**
(net earnings + fuel replaces raw ₹/km as the headline), **two cheap Tier 2 items** (priority
preference, home direction), **one Tier 3 swap** (OCR ingestion in, fatigue check out), and a
**rewritten pitch opener**.

Nothing is removed from the critical path. The build order in `driver-copilot-features-roadmap.md` §3
is unchanged through step 9 — capture, parse, score, speak and cross-app arbitration still come
first, in that order, and a flawless five-feature demo still beats a broken twelve-feature one.
