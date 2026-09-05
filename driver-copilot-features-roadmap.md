# Pillion (Driver Copilot) — Feature List, Winning Plan & Build Order

**iQOO City Battles, Pune · Sat 5 – Sun 6 September 2026**
Companion to `driver-copilot-iqoo-pune-gameplan.md`. That file is *strategy and schedule*; this file
is *what we build and in exactly what order*. When the two disagree, this file wins on build order.

---

## 1. The winning plan in one paragraph

Every feature below traces to a rubric line. **25% of the score (Creative Phone Use 15% + Office Kit
10%) is raw device telemetry** — unrecoverable by pitching, unlosable by forgetting to mention it. So
every module is chosen partly because it genuinely exercises a different capability of the phone, not
because it sounds good on a slide.

**The winning angle in one sentence:** Pillion is not a notification reader — it is a hands-free
arbitrator that compares every live gig offer across every app the driver runs, normalised for the
unpaid distance platforms hide, and speaks one answer in the driver's own language, entirely
on-device.

---

## 2. Feature list, tiered

### Tier 0 — must ship. The demo does not exist without these.

| # | Feature | Why it's Tier 0 | Acceptance criterion |
|---|---|---|---|
| T0.1 | **`:gigsim` companion app** posting real OS notifications for 5 gig apps | We have no driver accounts. This is the only input source, and it makes the demo repeatable | Pressing a button in `:gigsim` produces a system notification with the correct title/text/bigText |
| T0.2 | **Notification capture** via `NotificationListenerService`, allow-listed by package | The foundation everything sits on | Every `:gigsim` post appears in Pillion's raw-event list within 500 ms |
| T0.3 | **Tier A regex extraction**, driven by `assets/config/parsers.json` | Fast, deterministic, safe on stage; config-driven so it is tunable from the phone | ≥ 90% field extraction on the corpus in `docs/NOTIFICATION_CORPUS.md` |
| T0.4 | **Net-earnings scoring v1** — effective distance `tripKm + pickupKm`, minus personalised fuel cost, expressed as **₹/hour** and a 0-100 Smart Score | The domain insight, upgraded: drivers care about what they *keep*, not the headline payout. ₹/hour is the correct comparator because time is the scarce resource | A `Verdict` with a Smart Score, a net-₹ figure, a ₹/hour figure and at least one reason code, for every parsed offer |
| T0.5 | **Templated TTS verdict**, English first, then Hindi + Marathi. **Lead the spoken line with ₹/hour**, not ₹/km | The whole product is "it talks so you don't look". "₹393 an hour versus ₹236" lands harder than any per-km figure | Verdict is spoken within 1.5 s of the notification landing |
| T0.6 | **Offer list UI** with confidence badges and accept/reject buttons | Judges need to see what the phone heard | Cards render, tapping accept/reject persists the decision |

### Tier 1 — the differentiators. Build once Tier 0 is solid.

| # | Feature | Why | Acceptance criterion |
|---|---|---|---|
| T1.1 | **Cross-app arbitration + `OfferQueue` with TTLs** — **the headline feature** | No human can compare three live offers from three apps while driving. This is the novelty claim and the demo moment | 3 offers within 6 s produce exactly one spoken winner naming the runner-up |
| T1.2 | **Verdict explainability** — reason codes surfaced in UI and speech | "Take it" is a black box; "take it, 40% better than the Swiggy one" is a product | Every verdict carries ≥ 1 human-readable reason |
| T1.3 | **Adaptive threshold (EWMA)** that visibly moves on accept/reject | The live "it learns me" stage moment | Rejecting two good offers visibly raises the threshold bar on screen |
| T1.4 | **Tier B on-device NLU — ML Kit Entity Extraction** | A genuine offline on-device model, tiny, near-zero risk. Our on-device AI claim survives even if Gemma never loads | A payload regex cannot parse still yields payout and/or time |
| T1.5 | **Earnings-goal urgency** — "you're ₹340 from your ₹1,200 target and it's 8pm" | Cheap, emotional, and makes the scoring sound like it understands the job | Goal progress bar + urgency term visibly affects the verdict |
| T1.5 | **AI Shift Strategist** — target, earned, time left, required rate vs current rate, spoken coaching | Upgrades the goal-urgency term into a demoable feature. The arithmetic already exists; this is presentation | "You're ₹320 behind target — prioritise jobs above ₹250/hour" is spoken and the panel updates live |
| T1.6 | **Drop-zone return prospects** from a static Pune zone × hour table | "This drops you in Hinjewadi at 22:00 — you will deadhead back." Locally specific, judges from Pune will feel it | A low-demand drop zone measurably lowers the score |
| T1.7 | **Zero-Look Mode** — motion detected → one huge card, touch disabled, voice only | The hero feature *name*. Mechanically close to what the app already does; the naming and the motion trigger are the upgrade, and the accelerometer banks another sensor | Above the motion threshold the UI collapses and interaction is refused, with a spoken explanation |
| T1.8 | **Conversational voice loop** — "what have I got", "why", "compare", "accept", "how much have I earned" | Promoted from Tier 3: the rubric rewards voice and the product is voice-first, so it was mis-tiered. Intent parsing runs on the **local LLM** — a genuine LLM job that also banks the inference calls HackTracker counts | Five intents recognised offline; the "Why" **button** remains as the demo-safe fallback |

### Tier 2 — process and demo points. Not code, but real score, easy to lose by accident.

| # | Item |
|---|---|
| T2.1 | **Scheduled Office Kit bridging** — mirror, remote control, clipboard, file transfer — repeated through the whole event and logged in PROGRESS with timestamps |
| T2.2 | **Grant the notification permission live on stage.** Turn the scariest part of the product into the privacy story before anyone asks |
| T2.3 | **Say the "this is not a camera app / not a voice-note app" beat out loud** in the pitch |
| T2.4 | **A recorded backup video** of a perfect demo run, on the phone, ready to play if hardware betrays you |
| T2.5 | **Rehearse the 90-second pitch three times** with the real device and real speaker at stage distance |
| T2.6 | **Priority preference** — one onboarding question (maximise earnings / minimise fuel / finish early / heading home) reweights the score |
| T2.7 | **Home Direction mode** — a bearing comparison; orders heading home get a bonus. "Pays ₹18 less but takes you 4 km toward home" |

### Tier 3 — flagship stretch. Only after Eval 2 is clean.

| # | Feature | Risk | Buildable version |
|---|---|---|---|
| T3.1 | **Tier C on-device LLM** — MediaPipe `LlmInference` with Gemma3-1B-IT int4 | Medium-high: load time, memory, backend support | JSON-only extraction prompt, temp 0, 3 s timeout, falls back to Tier B. **Hard cutoff Sun 00:00** |
| T3.2 | **Voice command loop** — on-device `SpeechRecognizer` for "why" / "repeat" / "skip anyway" | Medium | Push-to-talk with a large target, not always-listening. Honest framing: mounted phone, thumb on a big button |
| T3.3 | **Camera OCR ingestion** — stationary worker points the camera at an order screen; ML Kit Text Recognition (offline) → the same normaliser → the same decision engine | Low-medium | **Replaces the camera fatigue check** (ADR-018). This is a coherent *second ingestion path* for platforms whose notifications are too sparse to parse, so the camera is used for something the product actually needs. ML Kit OCR is on-device and offline |
| T3.4 | **GPS consistency check** | High | Not true ground-truth distance. Instead: cross-check whether two apps' claimed distances for the same pickup point agree, and flag the lowballer. Same story, far less engineering |

### Explicitly out of scope — do not build these

- **An accessibility service that reads other apps' UI.** This is a positioning call, not a time call —
  we would reject it with unlimited time. It contradicts ADR-009, Play policy restricts accessibility
  services to accessibility purposes, and it turns a defensible driver-side assistant into something a
  judge can reasonably call scraping. The notification listener is the honest channel and the stronger
  technical claim. See `docs/FEATURE_REVIEW.md`.
- **A demand-prediction model trained on simulated data.** "We trained it on data we generated" is a
  credibility landmine in front of a technical jury. The static zone × hour table tells the same story
  honestly and survives the follow-up question.
- **Traffic-aware routing or multi-order route optimisation.** Routing needs a network API, which
  forfeits the on-device story the handbook explicitly rewards. Route optimisation is a TSP variant.
- **Daily-earnings dashboards, streaks, gamification.** Retention features. Nothing in the rubric
  scores retention and no judge sees day two.
- **Camera-based fatigue monitoring.** Dropped in favour of OCR ingestion (ADR-018) — it was a sensor
  looking for a justification.
- Any account, login, or sync flow.
- A trained ML model for scoring. The EWMA heuristic tells the same story on stage and is explainable
  under questioning, which a half-trained model is not.
- Support for more than the 5 seeded apps.
- A settings screen beyond: language picker, daily earnings goal, reload-config button.
- Automating the accept tap in the gig app itself. It would break platform terms and it is the one
  thing that turns a defensible assistant into an indefensible bot. **Pillion advises; the driver acts.**

---

## 3. Strict build order — this is law (see `CLAUDE.md` R4)

Follow this even under time pressure. Do not start step N+1 while step N is broken.

```
 1.  :gigsim app posting real notifications                  [T0.1]  Red Light
 2.  NotificationListenerService capture + raw event list    [T0.2]  Red Light
 3.  Tier A regex parser from parsers.json → OrderOffer      [T0.3]  Red Light
 4.  Offer card UI + confidence badge                        [T0.6]  Red Light
 5.  ScoringEngine v1 (deadhead-aware) → Verdict             [T0.4]  Red/Green
 6.  TtsSpeaker, English                                     [T0.5]  Red/Green
 7.  Hindi + Marathi templates                               [T0.5]  → EVAL 1
─────────────────────────────────────────────────────────── EVAL 1 · Sat 19:00
 8.  OfferQueue + cross-app arbitration + storm demo         [T1.1]  Green
 9.  Reason codes + explainability in UI and speech          [T1.2]  Green
10.  Tier B ML Kit Entity Extraction                         [T1.4]  Green
11.  Tier C Gemma via MediaPipe  — HARD CUTOFF Sun 00:00     [T3.1]  Green
12.  Adaptive EWMA threshold + accept/reject learning        [T1.3]  Green
13.  Shift Strategist: goal, required rate, spoken coaching  [T1.5]  Green
14.  Pune zone × hour table + return-leg penalty             [T1.6]  Green
15.  Zero-Look Mode + motion trigger                          [T1.7]  Green
15b. Voice command loop, LLM intent parsing                   [T1.8]  Green
15c. Priority preference + Home Direction (cheap, if time)    [T2.6/7] Green
─────────────────────────────────────────────────────────── FREEZE · Sun 06:30
16.  Demo hardening, dry runs ×3, backup video               [T2.4/5]
─────────────────────────────────────────────────────────── EVAL 2 · Sun 09:00
17.  Camera OCR ingestion (ML Kit Text Recognition)           [T3.3]  only if clean
18.  GPS consistency check                                   [T3.4]  only if clean
```

**A flawless five-feature demo beats a nine-feature demo where half visibly breaks on stage.** If you
are behind at Sun 04:00, cut from the bottom of the list, never from the middle.

---

## 4. What to do during Red Light, concretely

The format's biggest avoidable loss is idling during the phone-only stretch. These are all
genuinely phone-first tasks — nobody should ever be waiting for Green Light.

1. **Tune `parsers.json` on the phone.** Open `/sdcard/Pillion/config/parsers.json` in a text editor,
   change a regex, hit *Reload config* in the app, fire the matching `:gigsim` payload, see whether
   it parses. Full iteration loop, no laptop, no rebuild. This is the highest-value Red Light work
   in the whole plan.
2. **Tune `scoring.json`** the same way — benchmarks, weights, zone table, TTL values.
3. **Tune `tts_templates.json`** the same way and listen to each phrase through the actual speaker.
   Get a Marathi speaker at the venue to check the phrasing.
4. **Capture payloads.** If any teammate has a real gig app installed as a *customer*, capture those
   notification formats too — they are free corpus.
5. **Device qualification:** the 10-minute idle test for R2, the TTS voice-pack audit, GPS fix time,
   camera framing on a mount, ASR accuracy in a noisy hall.
6. **Drive Android Studio through Office Kit remote control** for anything that does need a build.
   Real work *and* Office Kit telemetry at the same time.
7. **Pitch rehearsal.** Costs nothing, needs no device, worth 10% of the score.

---

## 5. Feature-to-rubric traceability

| Feature | End product 30% | Novelty 20% | Phone use 15% | Tech depth 15% | Office Kit 10% | Demo 10% |
|---|---|---|---|---|---|---|
| Notification capture (T0.2) | ●●● | ●● | ●●● | ●● | | ● |
| Tier A regex (T0.3) | ●●● | | | ● | | |
| Tier B ML Kit (T1.4) | ●● | ● | ●●● | ●●● | | |
| Tier C Gemma (T3.1) | ● | ●● | ●●● | ●●● | | ● |
| Deadhead scoring (T0.4) | ●●● | ●●● | | ●●● | | ●● |
| Cross-app arbitration (T1.1) | ●●● | ●●● | | ●●● | | ●●● |
| TTS verdict (T0.5) | ●●● | ● | ●●● | | | ●●● |
| Voice commands (T3.2) | ●● | ●● | ●●● | ●● | | ●● |
| Adaptive threshold (T1.3) | ●● | ●● | | ●●● | | ●●● |
| Earnings goal (T1.5) | ●● | ●● | | ● | | ●● |
| Zone return-leg (T1.6) | ●● | ●●● | ● (GPS) | ●● | | ●● |
| Camera fatigue (T3.3) | ● | ●● | ●●● | ●● | | ●● |
| Office Kit bridging (T2.1) | | | | | ●●● | |
| Live permission grant (T2.2) | | ●● | | | | ●●● |

Read the columns, not the rows: the two thin columns are Office Kit and Demo, and both are earned by
*process*, not code. Do not let a coding sprint eat them.

---

## 6. Definition of done, per tier

- **Tier 0 done** = a judge can hold the phone, someone presses a `:gigsim` button, and the phone
  speaks a correct verdict in a language the judge chose. No laptop in the loop.
- **Tier 1 done** = the same, but with three offers at once and a spoken comparison, plus a
  threshold that visibly moves when you reject.
- **Tier 3 done** = the same, plus the phone says "you have been driving four hours, your blink rate
  is up, take a break" when asked.

If Tier 0 is not done by Sat 19:00, stop building and make Tier 0 flawless. That is the whole game.
