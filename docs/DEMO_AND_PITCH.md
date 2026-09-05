# DEMO_AND_PITCH.md

Demo and presentation is 10% of the score by itself, and it is the delivery mechanism for the 50%
that jury members assign for product quality, novelty and technical depth. This document is the
runbook. Rehearse from it, do not improvise.

---

## 1. The 90-second pitch

Timings are strict. Practise with a stopwatch. **Whoever is not speaking is holding the phone and
driving the demo** — never one person doing both.

### 0:00–0:15 · The problem
> "A delivery worker in Pune runs three platforms at once. Each one only ever shows you its own
> orders. So every few minutes they're making an economic decision — with incomplete information,
> on a thirty-second timer, while moving."

Flat, concrete, no adjectives. Do not say "revolutionary".

> **Framing rule — this matters.** Do **not** open with "drivers look at their phone while driving."
> It implies we are enabling phone use in traffic, and a sharp judge will turn it against us. The
> correct framing is: **"we move the decision from the screen to the voice layer."** The phone becomes
> a sensor and a copilot, not something the rider stares at.

### 0:15–0:40 · The insight and the mechanism
> "And the real problem isn't reading one offer — it's comparing three. A worker can eyeball one order
> at a red light. Nobody can hold three live offers from three platforms in their head, work out what
> each actually *nets* after the unpaid ride to the pickup and the fuel, and decide before the timers
> run out.
>
> EyesUp does that. It reads the notifications at the OS level, pulls the numbers out with three
> tiers of on-device AI, works out what each order really pays per hour after costs, ranks them
> against each other, and says one sentence out loud. No cloud, no account, no backend. Nothing
> leaves the device."

### 0:40–1:15 · Live demo
Hand the phone to a judge. Run the STORM sequence (§2).

### 1:15–1:30 · Close
> "Not a camera app. Not a voice-note app. This is a notification listener, an on-device model
> cascade, and a scoring engine that learns one driver's preferences — solving a problem that is
> currently solved by drivers looking at their phone in traffic.
>
> Everything you just heard ran on this device, offline."

---

## 2. Stage runbook — the demo, step by step

**Before you walk up:**
- [ ] Phone at >60% battery, brightness at max, Do Not Disturb **off**, volume at max
- [ ] Bluetooth speaker paired and tested, or rely on the phone's speaker if the room is quiet
- [ ] `:gigsim` open on the *second* phone, STORM button visible
- [ ] EyesUp open on the demo phone, listener status banner **green**
- [ ] `CLEAR ALL` pressed in `:gigsim` so the shade is empty
- [ ] Language set to whatever you will demo first
- [ ] Backup video ready in the gallery, one tap away

**The sequence:**

| # | Action | What the judge sees/hears | If it fails |
|---|---|---|---|
| 1 | Hand the phone to a judge | They are holding it. This matters — it is *their* experience, not a slide | — |
| 2 | Say: "This is off the internet. Airplane mode, if you like." Let them toggle it | Establishes the on-device claim before you make it | Nothing to fail |
| 3 | Press **STORM** on the second phone | 3 notifications land in 6 s; EyesUp speaks the arbitration verdict naming the winner and the runner-up | Fall to §4 |
| 4 | Ask them to say **"why"** to the phone | It explains its reasoning aloud | Tap the "Why" button instead — same output, no excuse needed |
| 5 | Tap **Reject** on the offer it recommended | The threshold bar visibly moves | Skip; do not draw attention |
| 6 | Switch language to Marathi, press STORM again | Same verdict, in Marathi | Switch to Hindi |
| 7 | Pull down the notification shade | Real OS notifications, honestly labelled `SIM · Rapido` | — |

**Total: about 35 seconds.** Anything longer and you lose the room.

---

## 3. The four things you must say out loud

These are worth score and none of them is obvious from watching:

1. **"On-device, no cloud, no account."** Privacy story and novelty story in one sentence.
2. **"This pays ₹100. You net ₹64 after fuel and the unpaid ride to the pickup — and that's ₹236 an
   hour, not ₹393."** The domain insight, and the line that makes a judge who knows the space lean
   forward. Lead with ₹/hour; per-km is the folk metric, per-hour is the correct one.
3. **"These are simulated notifications, because we can't get driver accounts — but they go through
   the real Android notification pipeline, exactly like the real apps would."** Say it *before*
   anyone asks. Disclosed is credible; discovered is fatal.
4. **"EyesUp advises. It never taps accept for you."** Pre-empts the "isn't this a bot" objection.

---

## 4. When the live demo fails

Have this rehearsed too. The recovery is worth more than the demo going right.

| Failure | Recovery, in order |
|---|---|
| No notification appears | Check the listener banner. If red: "the OS suspended our listener, one second" → toggle notification access off/on → re-run. If it does not come back in 10 s, go to the backup video |
| Notification captured but nothing spoken | Read the on-screen verdict aloud yourself and keep going. Do not troubleshoot audio on stage |
| Wrong verdict | Own it: "that's a scoring-weight call, and it's tunable — here's the config" and show `scoring.json`. A tunable system reads better than a lucky one |
| App crashes | Relaunch once. If it crashes twice, go straight to the backup video with one sentence: "let me show you the recorded run while this restarts" |
| Backup video also unavailable | Talk through the architecture diagram in `ARCHITECTURE.md` §2 with the phone in hand. You still get technical-depth credit |

**Rule: you get one recovery attempt, maximum 10 seconds, then you move on.** Judges forgive a
failure handled crisply. They do not forgive ninety seconds of a person poking at a phone.

---

## 5. Honesty rules — non-negotiable

- The simulator is disclosed, every time, unprompted.
- Tier A is described as rules-based. Do not call the regex layer "AI".
- If Gemma did not ship, we say the on-device model is ML Kit Entity Extraction. We do not describe
  a component that is not running.
- We do not claim the app works with live Uber/Swiggy accounts. We claim the pipeline is
  account-agnostic because it reads OS notifications, which is true and is a stronger claim anyway.
- Numbers in the demo are our constructed corpus, not scraped real orders. If asked, say so.

An honest hybrid survives technical questioning. An "it's all AI" claim collapses under one follow-up
question, in front of the same jury, and takes your technical-depth score with it.

---

## 6. Judge Q&A bank — prepare answers, do not improvise these

**"Is reading other apps' notifications even allowed?"**
> The driver grants Android's notification-access permission explicitly, in system settings, for
> their own device and their own notifications. It is the same OS API smartwatches and car
> head-units use. Nothing is transmitted, nothing is stored off-device, and we never automate an
> action inside another app — EyesUp advises, the driver taps. It is an accessibility-assistant
> pattern, not scraping.

**"Why wouldn't Uber just build this?"**
> They have no incentive to tell you their order is worse than Rapido's. A comparison tool is
> inherently cross-platform and inherently driver-aligned, so it can only exist on the driver's side
> of the glass. That is the whole reason this has to be a third app.

**"What's actually AI here? Isn't it just regex?"**
> Three tiers, and we are precise about which is which. Tier A is rules — deterministic and fast,
> and it handles the formats we have seen. Tier B is ML Kit's on-device entity extraction model,
> which pulls money and time entities out of text shapes we have never seen. Tier C is Gemma 3 1B
> quantised to int4 running through MediaPipe on this phone's NPU, prompted to emit JSON, for the
> long tail. Each tier only fills the fields the tier above left null, and confidence is tracked per
> field. We think an honest cascade is better engineering than pretending the regex is a model.

**"How does the scoring actually work?"**
> Payout divided by *effective* kilometres — trip distance plus the unpaid distance to the pickup —
> against a benchmark rate that varies by hour of day and order type. Then four adjustments: hourly
> earning rate, how far the driver is from their daily target and how much of the shift is left, the
> demand outlook of the drop zone, and surge. Then it is compared against every other offer still
> live. The accept/reject threshold is the midpoint of two exponentially-weighted averages — one
> over the scores of offers this driver accepted, one over the ones they rejected. So it converges
> on *this* driver's preferences in about a dozen decisions, and every step of it is explainable,
> which a trained model would not be.

**"Does it work while the driver is using another app?"**
> Yes — that is the point. The notification listener is a bound system service, so the pipeline runs
> with our app in the background and their gig app in the foreground. Verdicts come out of the
> speaker. The driver never sees our UI while driving.

**"What happens on a notification you can't parse?"**
> It degrades instead of failing. You get an offer with null fields, a low confidence score, a badge
> in the UI, and the spoken output becomes "order from Swiggy, details unclear" rather than a
> confident wrong answer. We would rather say nothing useful than say something wrong to someone
> driving. [Demo X1 if there is time.]

**"What would you build next?"**
> Two things. A real zone-demand model learned from the driver's own history instead of our static
> table. And shift-level planning — not "take this order" but "head towards Kharadi, that's where
> the evening volume is." The notification stream already contains enough signal for both.

**"How is this different from a camera app or a voice-note app?"**
> Different mechanism entirely. Those read what you point at or what you say. This reads the
> notification stream the OS is already delivering, which no other app at this event is touching,
> and it is the only input channel that lets you compare across platforms without integrating with
> any of them.

---

## 7. Slide backup (if slides are allowed)

Maximum five, and the demo is not one of them.

1. **The hazard** — one photograph of a mounted phone with three notifications. No text.
2. **The insight** — `₹186 / 12.4 km = ₹15/km` struck through, replaced by
   `₹186 / (12.4 + 3.1) km = ₹12/km`. One slide, one idea, the thing platforms hide.
3. **The pipeline** — the seven-box diagram from `ARCHITECTURE.md` §2, simplified.
4. **The cascade** — three tiers, what each costs in milliseconds, what each catches.
5. **On-device** — a list of what never leaves the phone, and the words "no server, no account".

---

## 8. Rehearsal log — fill this in

| # | When | Who presented | Duration | What broke | Fixed? |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

**Three full dry runs before Eval 2, with the real device and the real speaker, at stage distance.**
This is a scheduled task in the game plan (Sun 06:30–08:30), not something to do if there is time.
