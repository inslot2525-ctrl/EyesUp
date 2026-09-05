# Sarthi (Driver Copilot) — iQOO City Battles Pune 2026 · Game Plan

**Event:** iQOO City Battles, Pune Weekend — **Sat 5 – Sun 6 September 2026**, 30-hour phone-first build
**Status of this document:** rewritten 2026-09-05, event day. This is no longer a pre-event plan; it is
an operating manual for the next 30 hours.
**Prize pool:** ₹6L split across student/professional pools (₹1.5L top prize per pool)
**Team size:** 1–3 (students only; cannot mix with professionals — *verify at check-in*)
**Track:** Smart Living (primary) / Open Innovation (fallback) — **confirm the exact PS text on the
dashboard within the first 30 minutes and record it in `PROGRESS.md`.**

> **Naming:** the product is pitched as **Sarthi** (सारथी — the charioteer; Krishna was Arjuna's
> sarthi, the original copilot). It reads instantly to an Indian jury, is Marathi/Hindi-native for a
> Pune venue, and beats "Driver Copilot" as a name on a slide. Package/code identifier is
> `com.sarthi.copilot`. If the team prefers the old name, only the display string changes — do not
> rename packages mid-build.

---

## 1. The problem, restated

Delivery and ride-share drivers run two or three gig apps simultaneously. Offers arrive seconds
apart, each with its own payout, pickup distance and trip distance, and each expires in 15–60
seconds. To judge them the driver looks at the phone — frequently while moving. That is the hazard.

But the deeper problem is not *reading* — it is **comparison**. A driver can eyeball one offer at a
red light. No human can hold three live offers from three apps in their head, normalise each one for
the unpaid distance to the pickup, weigh them against how far they still are from today's earnings
target, and decide before the timers run out.

**Sarthi does that, out loud, in the driver's language, without them touching the phone.** It listens
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
| 7 | **Runtime config is hot-reloadable JSON on the device.** | Parser regexes, scoring weights and TTS templates load from `/sdcard/Sarthi/config/`. Means real tuning work is possible during **Red Light from a phone text editor with no rebuild**. This is the single most valuable Red Light unlock in the plan. |
| 8 | **Room dropped in favour of JSON files + DataStore.** | KSP/Room schema churn is a bad bet on a 30-hour clock. |
| 9 | **Camera fatigue check kept, but as a between-orders single shot** and explicitly framed for a driver-facing mount. | Continuous monitoring is not finishable and the mount caveat gets asked. Say it before a judge does. |
| 10 | **Pre-event checklist converted into an Hour-0 checklist.** | The original said "you have roughly a day and a half." It is now event day. |

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

> **Assumption to verify at check-in:** we do not know exactly what HackTracker instruments. Ask an
> organiser directly: *what counts as Office Kit usage, and does it need to be active continuously or
> just used?* Record the answer in `PROGRESS.md` immediately — it may change how we schedule the day.

---

## 4. Red Light / Green Light — the format, and how we exploit it

**Red Light (~55% of the 30 hours) — phone only.** You work from the phone. This does not remove the
laptop's compute: Office Kit screen-mirrors and remote-controls the laptop from the phone, so the
phone remains the device in your hands while the laptop still compiles. That is almost certainly why
Office Kit is scored at all — the bridge *is* the phone-first mechanic.

Red Light is not a phase to survive. It is where we do work that is genuinely better on a phone:

- Getting `NotificationListenerService` bound and verified on the actual loaner device
- Firing `:gigsim` payloads and watching the real capture path
- **Tuning parser regexes, scoring weights and TTS templates by editing
  `/sdcard/Sarthi/config/*.json` in a phone text editor and hitting "Reload config" — no rebuild**
- TTS voice-pack checks, microphone/ASR checks, GPS fix checks, camera framing checks
- Battery-optimisation and autostart whitelisting on Funtouch OS
- Driving Android Studio on the laptop *through* Office Kit remote control — banks Office Kit
  telemetry while doing real work

**Green Light (~45%) — both devices unlocked.** Heavy lifting: Gradle/dependency work, MediaPipe
model integration, cross-module debugging, anything miserable one-handed. **Keep Office Kit running
anyway** — the telemetry does not pause because Green Light started.

**The failure mode this format punishes:** idling or improvising during the phone-only stretch. Every
Red Light window below has named, concrete deliverables. If you finish them early, tune configs.

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
       [1] CAPTURE   SarthiNotificationListener  → NotificationEvent
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

## 6. Hour-by-hour plan (Sat 11:00 → Sun 16:15)

Verify the real schedule at check-in and correct this table in place. Phase labels assume the
published city-battle format; adjust when the actual Red/Green windows are announced.

| Time | Phase | Deliverable — done means |
|---|---|---|
| **Sat 08:00–10:00** | — | Check-in, loaner device handover. Run the Hour-0 checklist (§9). Confirm track/PS text. Ask the HackTracker question. |
| **Sat 10:00–11:00** | — | Keynote. In parallel: laptop toolchain + Office Kit paired and rehearsed. |
| **Sat 11:00–12:00** | **Red Light** | Device ready: USB debugging on, ADB authorised, battery/autostart whitelisted, notification access granted, TTS voice packs present for en-IN/hi-IN/mr-IN. Logged in PROGRESS. |
| **Sat 12:00–14:00** | Red Light | **First light.** Skeleton app + `:gigsim` installed. A `:gigsim` button posts a notification; Sarthi captures it and shows the raw payload on screen. An end-to-end signal exists. |
| **Sat 14:00–16:00** | Red Light | Tier A regex parser driven by `assets/config/parsers.json`; `OrderOffer` populated for all 5 seeded apps; offer cards render. Tuning happens by editing config on the phone. |
| **Sat 16:00–17:30** | Red/Green | ScoringEngine v1 (deadhead-aware ₹/km vs. flat benchmark) + `TtsSpeaker` speaking English verdicts. **The core loop talks.** |
| **Sat 17:30–19:00** | — | Hindi + Marathi templates. Freeze. Rehearse the Round-1 walkthrough twice. Charge everything. |
| **Sat 19:00** | **EVAL 1** | Must show live: `:gigsim` fires → real OS notification → captured → parsed → scored → spoken. Anything beyond this is bonus. |
| **Sat 20:00–22:00** | Green Light | `OfferQueue` + cross-app arbitration + the "storm" demo (3 offers in 6s → one spoken winner). **This is the money feature — do not let it slip.** |
| **Sat 22:00–00:00** | Green Light | Tier B ML Kit Entity Extraction; then Tier C Gemma via MediaPipe. Model pushed by ADB/Office Kit, never downloaded at the venue. Hard stop at 00:00 — if Gemma is not loading, Tier B is the on-device AI story and that is fine. |
| **Sun 00:00–02:00** | Green Light | Adaptive threshold (EWMA), accept/reject UI, explainability: every verdict lists its reasons. |
| **Sun 02:00–04:00** | Green Light | Earnings-goal urgency + Pune zone/hour table + return-leg penalty. Sleep rotation starts (§10). |
| **Sun 04:00–05:30** | Green Light | Voice command loop (on-device ASR): "why", "repeat", "skip anyway". Push-to-talk, large target. |
| **Sun 05:30–06:30** | — | Buffer / sleep swap / bug burn-down. |
| **Sun 06:30–08:30** | — | **Code freeze.** Demo hardening only. Full dry run ×3 with the actual phone, actual speaker, actual stage distance. Record a backup video of a perfect run. |
| **Sun 09:00** | **EVAL 2** | Treat as the real deadline. Tier 0 flawless + as much Tier 1 as landed. |
| **Sun 09:30–13:00** | Green Light | Stretch only if Eval 2 was clean: camera fatigue check, then GPS consistency check. Otherwise rehearse, fix, rest. |
| **Sun 13:30** | — | Top 10 announced. If selected → final pitch prep from `docs/DEMO_AND_PITCH.md`. |
| **Sun 16:15** | — | Awards. |

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
| R10 | Venue Wi-Fi cannot carry a ~550 MB model download | High | Model staged on the laptop **before arriving**; pushed by ADB/Office Kit | — |

---

## 9. Hour-0 checklist (do these in the first 60 minutes — it is event day now)

- [ ] Confirm the track and copy the **exact** problem-statement text into `PROGRESS.md`
- [ ] Ask an organiser what HackTracker measures for Office Kit; record the answer
- [ ] Confirm the real Red/Green Light windows and correct §6 in place
- [ ] Loaner phone: developer options → USB debugging → authorise ADB → `adb devices` shows it
- [ ] Loaner phone: battery optimisation OFF for Sarthi, autostart ON, allow background activity
- [ ] Loaner phone: Settings → Text-to-speech → verify `en-IN`, `hi-IN`, `mr-IN` voice data; download anything missing now, while the venue Wi-Fi is quiet
- [ ] Laptop: Android Studio opens, Gradle sync succeeds, `adb` on PATH
- [ ] Office Kit installed (pc.vivoglobal.com), paired, and screen mirror + remote control + clipboard + file transfer each tested once
- [ ] Gemma `.task` model file present on the laptop — do **not** plan to download it at the venue
- [ ] Private GitHub repo created, both teammates have push access, both machines cloned
- [ ] Both Claude Code sessions have read `CLAUDE.md` and `HANDOFF.md`
- [ ] Speaker tested for demo audio at stage distance
- [ ] Power banks charged; a second phone with a text editor for config tuning

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
