# EyesUp (Driver Copilot) — iQOO City Battles Pune 2026 · Game Plan

**Event:** iQOO City Battles, Pune Weekend — **Sat 5 – Sun 6 September 2026**, 30-hour phone-first build
**Status of this document:** rewritten 2026-09-05, event day. This is no longer a pre-event plan; it is
an operating manual for the next 30 hours.
**Prize pool:** ₹6L split across student/professional pools (₹1.5L top prize per pool)
**Team size:** 1–3 (students only; cannot mix with professionals — *verify at check-in*)
**Track:** Smart Living (primary) / Open Innovation (fallback) — **confirm the exact PS text on the
dashboard within the first 30 minutes and record it in `PROGRESS.md`.**

> **Naming:** the product is **EyesUp** — the person who rides behind you. Every gig driver in India
> knows the word, it is one syllable-pair, it names the product's role exactly (the one riding along,
> watching, telling you what to do), and it sounds nothing like an AI product. Package identifier is
> fixed at `com.eyesup.app` (ADR-008). Runners-up: *Sarthi*, *Dhruv*.

> **Device (handbook p.01):** iQOO 15 — Snapdragon 8 Elite Gen 5, dedicated Q3 chip, 16 GB LPDDR5X,
> 14,000 mm² vapour chamber, 7,000 mAh. **One flagship loaner per person**, HackTracker pre-installed,
> Office Kit already paired at handover. This is a far stronger device than the first draft assumed —
> see ADR-012.

---

## 1. The problem, restated

Delivery and ride-share drivers run two or three gig apps simultaneously. Offers arrive seconds
apart, each with its own payout, pickup distance and trip distance, and each expires in 15–60
seconds. To judge them the driver looks at the phone — frequently while moving. That is the hazard.

But the deeper problem is not *reading* — it is **comparison**. A driver can eyeball one offer at a
red light. No human can hold three live offers from three apps in their head, normalise each one for
the unpaid distance to the pickup, weigh them against how far they still are from today's earnings
target, and decide before the timers run out.

**EyesUp does that, out loud, in the driver's language, without them touching the phone.** It listens
to incoming notifications at the OS level, extracts the numbers with an on-device NLU stack, scores
each offer against the driver's own accept/reject history, arbitrates between every offer currently
live across all their apps, and speaks a single verdict: *"Take the Rapido one — ₹142 for 9 km, and
it's 40% better than the Swiggy order."*

Everything runs on the device. Nothing is uploaded. There is no account, no login, no server.

---

## 2. What changed from the first draft, and why

This section exists so nobody re-argues settled points. Full reasoning lives in `docs/DECISIONS.md`.

| # | Change | Reason |
|---|---|---|
| 1 | **Cross-app arbitration promoted from "differentiator" to the headline.** | Single-offer take/skip is a rule a driver already has in their head. Comparing three live offers across three apps is something no human can do while driving. That is the demo moment and the novelty claim. |
| 2 | **A companion `:gigsim` APK that posts real Android notifications** replaces "in-app demo simulator". | We cannot get Uber Driver / Swiggy Delivery Partner accounts — onboarding needs documents and vehicle verification. The original plan quietly depended on having them. A second app posting genuine `NotificationCompat` payloads exercises the *entire real pipeline* — OS notification → `NotificationListenerService` → parse → score → speak — with zero fakery inside our app. It is also a better stage demo: repeatable, on cue, with a "storm" button. |
| 3 | **Gemini Nano / AICore removed as an option.** | AICore ships on Pixel 8 Pro+/Galaxy S24+. It is **not** on iQOO/vivo Funtouch OS. Chasing it would have burned Red Light hours to arrive at a dead end. |
| 4 | **NLU is now a three-tier on-device cascade**: regex → **ML Kit Entity Extraction** → MediaPipe Gemma3-1B-int4. | ML Kit Entity Extraction is a genuine offline on-device model, a few MB, near-zero risk, and pulls money/date-time entities out of arbitrary text. It gives us a real "on-device AI" claim even if the LLM never loads. Gemma becomes the impressive top tier instead of a single point of failure. |
| 5 | **Deadhead distance is counted in the rate.** | `payout ÷ (tripKm + pickupKm)` not `payout ÷ tripKm`. This is the domain insight that makes the scoring defensible and is the thing platforms do not show drivers. |
| 6 | **Earnings-goal awareness and drop-zone return prospects added to scoring.** | Cheap to build (a running total, a clock, a static Pune zone table) and turns a static ₹/km rule into something that sounds like it understands the job. |
| 7 | **Runtime config is hot-reloadable JSON on the device.** | Parser regexes, scoring weights and TTS templates load from `/sdcard/EyesUp/config/`. Means real tuning work is possible during **Red Light from a phone text editor with no rebuild**. This is the single most valuable Red Light unlock in the plan. |
| 8 | **Room dropped in favour of JSON files + DataStore.** | KSP/Room schema churn is a bad bet on a 30-hour clock. |
| 9 | **Camera fatigue check kept, but as a between-orders single shot** and explicitly framed for a driver-facing mount. | Continuous monitoring is not finishable and the mount caveat gets asked. Say it before a judge does. |
| 10 | **Pre-event checklist converted into an Hour-0 checklist.** | The original said "you have roughly a day and a half." It is now event day. |
| 11 | **Red/Green split corrected: Green is ~55%, Red ~45%** — and the eight real windows are now in §4. | The first draft had the ratio backwards and invented the schedule. The handbook (p.04) gives the actual bar. |
| 12 | **The local LLM now runs in shadow mode on every notification, and writes the "why" explanations.** | HackTracker "logs inference calls, tokens and thermals in real time" (p.01). On-device inference is *directly measured* for the 15% Creative Phone Use line. A model that fires rarely as a fallback banks almost nothing. ADR-011. |
| 13 | **Model tier upgraded; both a 1B and a 4B model are staged.** | The device is a Snapdragon 8 Elite Gen 5 with 16 GB RAM that the handbook says "runs quantised local LLMs at usable speed". Gemma 3 1B underuses it. ADR-012. |
| 14 | **`:gigsim` runs on a second loaner phone, not a personal one.** | One flagship phone per person (p.02), so a 2–3 person team has spare devices. ADR-013. |
| 15 | **No code may exist before 11:00.** | "Original work only: code written during the event window... Organisers may verify a project was built inside the event window" (p.03). Planning docs are not code, but the first source commit must be timestamped after hacking begins. ADR-014. |
| 16 | **OpenRouter credits are for coding assistance only, never in the product.** | The handbook's own tip to win: "The highest on-device builds will be preferred for the Top 10." A network call in the product would forfeit exactly the thing we are strongest on. ADR-015. |

---

## 3. Scoring rubric — and the one number that drives everything

| Criteria | Weight | Measured by |
|---|---|---|
| End product quality | 30% | Jury |
| Novelty and impact | 20% | Jury |
| Creative phone use (camera, voice, on-device AI) | 15% | HackTracker device data |
| Technical depth | 15% | Jury |
| Office Kit usage | 10% | HackTracker device data |
| Demo and presentation | 10% | Jury |

**25% of the score is raw device telemetry, not pitch.** You cannot talk your way into Creative Phone
Use or Office Kit points, and you cannot lose them by forgetting to mention something on stage.

This cuts two ways:

- *In our favour:* the product genuinely needs the notification listener, the microphone, the
  speaker, GPS, the NPU and (stretch) the camera. Nothing is bolted on. Every sensor we touch, we
  touch because the feature requires it.
- *Against us:* Office Kit's 10% does **not** accrue automatically just because we are building an
  Android app. It has to be deliberately, repeatedly used. Treat it as a scheduled task, not a
  convenience — see `docs/DEVICE_AND_TOOLING_SETUP.md` §8.

**What HackTracker actually measures — answered by the handbook, no longer a guess:**

- *"HackTracker captures **counts and durations** only (no keystrokes, screenshots, or browsing) for
  creative phone use and Office Kit scoring."* (p.02) → **both** matter. Keep the Office Kit session
  connected continuously **and** use its discrete features often.
- *"It sits on the device through the build, reads model outputs, and logs **inference calls, tokens
  and thermals** in real time."* (p.01) → **on-device inference is mechanically counted.** This is the
  single most actionable fact in the handbook, and it is why the local model now runs in shadow mode
  on every notification rather than as a rare fallback (ADR-011).
- *"Do not tamper with HackTracker under any circumstances. All crash and tamper logs are detected and
  will be penalised."* (p.04) → our notification listener must **strictly allow-list** our own
  simulator channels, must never touch HackTracker's battery or notification settings, and must never
  be pointed at HackTracker's own notifications. See risk R11.

---

## 4. Red Light / Green Light — the real windows

**Confirmed from the handbook (page 04). Full task-by-task plan: `docs/RED_LIGHT_PLAYBOOK.md`.**

> "Red light: Direct usage of laptops is restricted and will be monitored. Work on your phone, or
> access your laptop only via the Office Kit on your phone. Green light: Free to use anything."

| Window | Phase | Length |
|---|---|---|
| 11:00 – 14:00 | GREEN | 3h 00m |
| **14:00 – 15:30** | **RED (R1)** | 1h 30m |
| 15:30 – 16:30 | GREEN | 1h 00m |
| **16:30 – 19:00** | **RED (R2)** | 2h 30m |
| 19:00 – 22:00 | GREEN | 3h 00m |
| **22:00 – 01:00** | **RED (R3)** | 3h 00m |
| 01:00 – 06:30 | GREEN | 5h 30m |
| **06:30 – 09:00** | **RED (R4)** | 2h 30m |

**12h 30m green, 9h 30m red** — the handbook's "roughly 55/45" is Green/Red, not Red/Green. The
first draft of this document had that backwards.

> **The handbook warns timings may vary and will be announced at the venue. Confirm these in the
> first 15 minutes and correct this table in place.**

**Three consequences that drive the whole plan:**

1. **The last Green Light ends 06:30 Sunday, two and a half hours before Eval Round 2.** Code freeze
   is enforced by the format, not by discipline. Everything must be built and installed before 06:30.
2. **The 01:00–06:30 green block is 5h 30m — the largest single work window of the event.** Plan the
   sleep rotation around it, not through it.
3. **Red Light is where the Office Kit 10% is earned.** The laptop is reachable *only* through Office
   Kit, so using it is both the way to work and the way to score. Keep the session connected
   continuously and use its discrete features often — HackTracker measures counts *and* durations.

**What makes Red Light productive for us specifically:** all tunables — parser regexes, scoring
weights, the zone table, TTS phrasing — live in JSON on the device (ADR-007). Edit in a phone text
editor, tap Reload config, fire a payload from the GigSim phone, hear the result. Seconds per
iteration, no laptop. Install a phone text editor in the first 15 minutes; without it Red Light is
dead time.

---

## 4a. Phone-first posture — in BOTH phases

**Organiser tip, received directly:** HackTracker runs a 30-hour surveillance of the phone. The more
the phone is genuinely used, the better it reads to the judges. This is consistent with the handbook
(p.02): *"HackTracker captures counts and durations only ... for creative phone use and Office Kit
scoring."*

**The consequence: the previous plan's Green Light posture was wrong.** It said "Green Light is for
laptop heavy lifting, keep Office Kit open in the background." That leaves the phone idle for 12 of
30 hours and forfeits telemetry we cannot argue back.

**New default posture, Red and Green alike:** the phone is the device in your hands. The laptop is
driven *through* Office Kit remote control. Drop to direct laptop use only for the things that are
genuinely slower any other way — Gradle sync, dependency resolution, first-time SDK downloads, heavy
IDE refactors — and go straight back to the phone afterwards.

**Concrete rules:**

1. **Nobody's phone sleeps.** Stay-awake-while-charging on, all devices, all 30 hours. An idle phone
   banks nothing (risk R15).
2. **Rotate so someone is always on a phone**, even while another person is on the laptop. With one
   flagship per person there is no reason for any phone to be face-down on the table.
3. **Three phones, three jobs:** Phone A = EyesUp (demo device), Phone B = GigSim (payload firing),
   Phone C = ops — PROGRESS entries, docs, git and log reading via Office Kit remote control.
4. **Every payload fired is an inference call logged.** Tuning and telemetry are the same activity, so
   fire payloads liberally while tuning rather than reasoning about the regex in your head.
5. **Overnight soak loop.** GigSim gets a debug timer mode that fires a payload every 45-60s. Run it
   through the sleep rotation. This is a genuine soak test — it is how we verify the listener survives
   the night (risk R2, our top device risk) — and the device works continuously while we do not.
   **Read the results in the morning; a soak test nobody reads is just noise.**
6. **Office Kit stays connected continuously**, and its discrete features get used often. Counts *and*
   durations are both measured, so do both.
7. **Log it.** Every PROGRESS entry's *Device telemetry banked* field gets which sensors and which
   Office Kit features were exercised, and roughly for how long.

**The honesty boundary:** everything above is real work done on the phone, or a real test we actually
read. We do not fabricate activity. We would not be able to defend that, and we do not need to — this
product genuinely lives on the device.

---

## 5. System architecture (summary — full spec in `docs/ARCHITECTURE.md`)

```
  :gigsim app  ─┐                        ┌── real gig apps (if an account ever becomes available)
  (real OS      │                        │
   notifications)                        │
                ▼                        ▼
            ┌──────────────────────────────────────────┐
            │  Android OS notification bus             │
            └────────────────────┬─────────────────────┘
                                 ▼
       [1] CAPTURE   EyesUpNotificationListener  → NotificationEvent
                                 ▼
       [2] PARSE     Tier A  regex (config-driven, instant, deterministic)
                     Tier B  ML Kit Entity Extraction (on-device, offline)
                     Tier C  MediaPipe Gemma3-1B-int4 (on-device LLM, JSON out)
                                 → OrderOffer(payout, tripKm, pickupKm, eta, zones, confidence)
                                 ▼
       [3] QUEUE     OfferQueue — every live offer across every app, each with a TTL
                                 ▼
       [4] SCORE     ScoringEngine
                       effectiveKm = tripKm + pickupKm          (deadhead counted)
                       ratePerKm   = payout / effectiveKm
                       vs. hour/zone benchmark, earnings-goal urgency,
                       drop-zone return prospects, driver's adaptive threshold
                       → Verdict(decision, score, reasons[], comparedAgainst[])
                                 ▼
       [5] SPEAK     TtsSpeaker — templated Marathi / Hindi / English, ducks music
                                 ▼
       [6] LEARN     accept/reject → EWMA threshold update → visibly moves on screen
                                 ▲
       [7] VOICE     on-device SpeechRecognizer: "why" / "repeat" / "take it" / "skip"
```

Seven modules, each independently buildable and testable — and each a clean ownership boundary if
you are 2–3 people or two relaying agents.

---

## 6. Hour-by-hour plan — mapped to the real Red/Green windows

Agenda times are from the handbook (page 06). Phase column from page 04. **Confirm both at the venue.**

| Time | Phase | Deliverable — done means |
|---|---|---|
| 08:00 | — | Check-in, device handover. **One flagship iQOO 15 per person**, HackTracker pre-installed, Office Kit already paired. |
| 08:30 | — | Breakfast. Run the Hour-0 checklist (§9) while eating. Claim OpenRouter credits. Confirm the track. |
| 10:00 | — | Opening keynotes. Office Kit teach-in is covered here — pay attention, it is 10% of the score. |
| **11:00–14:00** | 🟢 **GREEN** | **Scaffold everything while the laptop is free.** Gradle project + both modules building; `model/` package written first (shared surface); `:gigsim` posting real notifications; listener capturing them onto the raw-event list. **Push the LLM `.task` file to the phone in this window** — it is the only long green block before you need it. Lunch 13:00, eat at the table. |
| **14:00–15:30** | 🔴 **RED (R1)** | Device qualification (battery whitelist, TTS packs, idle test, sensors) + Tier A regex tuning entirely from the phone via `parsers.json`. Playbook §3. |
| **15:30–16:30** | 🟢 GREEN | One hour only — spend it on what genuinely needs a laptop: `ScoringEngine` v1, `TtsSpeaker` wiring, any new dependency. Nothing else. |
| **16:30–19:00** | 🔴 **RED (R2)** | Tune `scoring.json` and `tts_templates.json` on the phone; get a Marathi speaker to check the MR block; UI polish via Office Kit remote control. **Last 45 minutes: rehearse Eval 1 twice.** High-Tea 17:00. |
| **19:00** | — | **EVALUATION ROUND 1.** Must show live: GigSim fires → real OS notification → captured → parsed → scored → spoken. |
| **19:00–22:00** | 🟢 GREEN | `OfferQueue` + **cross-app arbitration** + the STORM demo. Then the on-device LLM tier in shadow mode (ADR-011). This is the headline-feature window — do not let it slip. Dinner 21:00. |
| **22:00–01:00** | 🔴 **RED (R3)** | Run STORM twenty times until it is deterministic. Explainability copy in all three languages. ASR tested in the real hall. Second idle test. Heaviest Office Kit block of the event. Midnight refuel 00:30. |
| **01:00–06:30** | 🟢 GREEN | **The last green window — 5h 30m, the largest of the event. All remaining code lands here.** Adaptive threshold, earnings goal, zone table, voice commands, then stretch features. Sleep rotation inside this block (§10). |
| **06:30–09:00** | 🔴 **RED (R4)** | **FREEZE — enforced by the format, the laptop is unreachable.** Three full dry runs, backup video recorded, state reset, **repo + demo assets submitted on the Reskill platform.** Playbook §3. |
| **09:00** | — | **EVALUATION ROUND 2.** Treat this as the real deadline. Breakfast is at 09:00 too — eat before or after, not during. |
| 09:00–12:00 | 🟢 (assumed) | Only if Eval 2 was clean: stretch features. Otherwise rehearse and rest. **Confirm the repo submission actually landed.** |
| 12:00 | — | Lunch. |
| **13:00** | — | **Top 10 announced. Repos lock before the Top 10 pitches — nothing may be submitted after this.** |
| 13:45 | — | Top 10 pitch, if selected. Script in `docs/DEMO_AND_PITCH.md`. |
| 16:15 | — | Awards. |

---

## 7. Rubric-to-feature mapping

| Rubric line | How we earn it | Evidence on the day |
|---|---|---|
| End product quality (30%) | The whole pipeline runs live on the loaner phone, driven by real OS notifications, not an in-app mock | Storm demo + accept/reject + spoken verdict |
| Novelty and impact (20%) | Cross-app arbitration; deadhead-aware rate; the safety framing (what it removes is *looking at the phone*) | Lead the pitch here, not with the stack |
| Creative phone use (15%, telemetry) | Notification listener, on-device NLU on the NPU, TTS, on-device ASR, GPS, camera | All genuinely exercised, repeatedly, from Hour 1 |
| Technical depth (15%) | Honest three-tier NLU cascade with confidence handoff; EWMA-adaptive scoring; TTL'd cross-app queue | Be ready to draw the cascade on paper |
| Office Kit usage (10%, telemetry) | Scheduled, repeated phone↔laptop bridging — mirror, remote control, clipboard, file transfer | Log every session in PROGRESS with timestamps |
| Demo and presentation (10%) | Repeatable scripted demo, 90-second script, rehearsed ×3, backup video | `docs/DEMO_AND_PITCH.md` |

---

## 8. Risk register

| # | Risk | Likelihood | Mitigation | Trigger to act |
|---|---|---|---|---|
| R1 | No driver accounts, so no real notifications | **Certain** | `:gigsim` posts real OS notifications; corpus in `docs/NOTIFICATION_CORPUS.md` | Already mitigated by design |
| R2 | Funtouch OS kills the listener service in the background | **High** | Battery whitelist + autostart + allow background activity; verify with a 10-minute idle test | A notification is missed after idling |
| R3 | MediaPipe/Gemma will not load or is too slow on the loaner | **Medium-high** | Hard 00:00 cutoff; Tier B (ML Kit) is a complete on-device AI story on its own | Not loading by Sun 00:00 → stop, ship Tier B |
| R4 | Marathi offline TTS voice unavailable | **Medium** | Check at Hour 1. Fall back to Hindi + English and say so honestly | Missing `mr-IN` voice data |
| R5 | Office Kit remote control is laggy or unusable under Red Light | Medium | Rehearse before 11:00; the fallback is phone-native config tuning (§4), which needs no laptop | Lag makes editing impractical |
| R6 | Notification text too sparse to parse ("New order!") | Medium | The cascade degrades gracefully; the UI shows partial offers with a confidence badge; the corpus includes sparse examples | Confidence < 0.4 on real payloads |
| R7 | Demo fails on stage | Low-medium | Scripted `:gigsim`, code freeze at 06:30, rehearsed ×3, backup video on the phone | Any failure in dry runs |
| R8 | Judge challenges the legality of reading other apps' notifications | Medium | Prepared answer in `docs/DEMO_AND_PITCH.md` §6 — user-granted OS permission, on-device only, no automation of accepts | Asked in Q&A |
| R9 | Both Claude sessions hit limits simultaneously | Low | PROGRESS.md is current at all times; the humans can execute the NEXT INSTRUCTION themselves | — |
| R10 | Venue Wi-Fi cannot carry a ~550 MB model download | High | Push the model to the phone in the **11:00-14:00 green window**, the first and longest laptop block | Not on the phone by 14:00 |
| R11 | **Our notification listener touches HackTracker's notifications and looks like tampering** | Medium | Strict allow-list on our own `sim_*` channels only. Never modify HackTracker's battery or notification settings. Never log its payloads | Any HackTracker notification appears in our event list |
| R12 | **Repo submitted late - repos lock before the Top 10 pitches (13:00 Sun)** | Medium | Submit during R4 (06:30-09:00), not Sunday afternoon. Confirm it landed after Eval 2 | - |
| R13 | A judge questions whether the code was written in-window | Low | Git history starts after 11:00 Sat with a clean commit trail. This is an asset - offer it | Asked |
| R14 | Nothing to do in a Red window because the config loop was never built | Medium | Config plumbing is a priority in the first green block; phone text editor installed in Hour 0 | Anyone idle in R1 |
| R15 | **Phone sits idle for hours while everyone works on laptops** | **High** | Phone-first posture in both phases (SS4a). Rotate so someone is always on a phone. Overnight soak loop keeps the device working | Anyone's phone asleep for >20 min |

---

## 9. Hour-0 checklist (08:00-11:00, before hacking begins)

**Confirm and record in `PROGRESS.md`:**
- [ ] The exact track we are entering (seven tracks in the city battles - get the list, pick one)
- [ ] The real Red/Green windows announced at the venue; correct 4 and the playbook in place
- [ ] Team bucket confirmed as students; teams cannot mix buckets
- [ ] The Reskill submission URL and the hard cutoff time

**Devices (one flagship iQOO 15 per person):**
- [ ] Nominate **Phone A = demo device (EyesUp)**, **Phone B = GigSim**, **Phone C = ops** (docs,
      PROGRESS entries, git via Office Kit). Label them physically
- [ ] Developer options -> USB debugging on every phone; `adb devices` shows them; record serials
- [ ] **Stay awake while charging** ON for all phones - an idle phone banks nothing (R15)
- [ ] Battery optimisation off / autostart on for our app **only** - never touch HackTracker's settings
- [ ] TTS voice data for `en-IN`, `hi-IN`, `mr-IN` - download now, venue Wi-Fi is quietest at 08:30
- [ ] **Install a phone text editor** (Acode / QuickEdit / Markor). Without it, Red Light is dead time
- [ ] Phones stay in the venue. They are iQOO property and must be returned

**Tooling:**
- [ ] Office Kit is already paired at handover - **verify all four features**: screen mirror, remote
      control, clipboard sync, file transfer. Attend the 10:00 teach-in
- [ ] Android Studio opens, Gradle syncs on a throwaway project, JDK 17, `adb` on PATH
- [ ] Claim the team's **OpenRouter credits** at the tables. Coding assistance only, never in the
      product (ADR-015). Watch the burn rate - $25 goes fast on frontier models
- [ ] Private GitHub repo created, both machines cloned, both teammates pushing

**Models - start these downloads at 08:30, they run in the background:**
- [ ] `gemma3-1b-it-int4.task` (~550 MB) - the safe tier
- [ ] A 3-4B int4 `.task` (~2.5 GB) - the ambitious tier this device can actually run (ADR-012).
      If it is not down by 13:00, ship the 1B and stop

**Rules to hold:**
- [ ] **No source code before 11:00.** Docs and planning are fine; the first code commit must be
      timestamped after hacking begins (ADR-014)

---

## 10. Team, roles and sleep

| Module | Owner | Backup | Status |
|---|---|---|---|
| Capture + `:gigsim` | | | |
| Parse cascade (A/B/C) | | | |
| Scoring + queue | | | |
| Voice (TTS + ASR) | | | |
| UI + demo mode | | | |
| Pitch / demo lead | | | |

**Sleep rotation:** never have the whole team asleep at once, and never have the whole team awake at
04:00 either. Suggested: one person sleeps 01:00–04:00, the other 04:00–07:00. Whoever slept second
runs the Eval-2 demo — they will be the sharpest.

**Claude relay:** when a session nears its limit it must (1) write a final `PROGRESS.md` entry with a
complete `➡️ NEXT INSTRUCTION`, (2) update `HANDOFF.md`, (3) commit and push. The other agent starts
by reading `HANDOFF.md`. See `CLAUDE.md` §0.

---

## 11. What winning looks like on Sunday morning

A judge walks up. You hand them the phone. You press one button on a second phone. Three
notifications from three different gig apps land within six seconds. The phone in the judge's hand
says, in Marathi:

> *"Rapido घ्या — ९ किलोमीटरला ₹१४२. Swiggy चं ऑर्डर ४०% कमी आहे."*
> ("Take the Rapido one — ₹142 for 9 km. The Swiggy order pays 40% less.")

They ask why. You say "why" out loud to the phone, and it explains itself. You tap reject anyway, and
the threshold on screen visibly moves. Nothing touched the internet.

That is the demo. Everything in this plan exists to make those thirty seconds work.
