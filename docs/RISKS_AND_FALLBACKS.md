# RISKS_AND_FALLBACKS.md

What to do when something breaks, decided in advance so nobody has to make a good judgement call at
3 a.m. on four hours of sleep.

**The governing rule: every fallback below is time-boxed. When the box expires, you take the
fallback. You do not extend the box.** The most expensive failure at a hackathon is not a broken
component — it is three hours spent on a component that was always going to be cut.

---

## 1. Master decision tree

```
Is the demo path working end-to-end right now?
│
├── YES → is it Sunday 06:30 or later?
│         ├── YES → FREEZE. Only demo-blocking bugs. Rehearse.
│         └── NO  → build the next item in the build order. Nothing else.
│
└── NO  → which stage is broken?
          ├── Capture   → §2   (highest priority, everything depends on it)
          ├── Parse     → §3
          ├── Score     → §4
          ├── Speak     → §5
          ├── Build     → §6
          └── Device    → §7
```

---

## 2. Capture is broken

### 2.1 Notification access granted, but nothing arrives

**Time box: 30 minutes.**

1. `adb shell dumpsys notification | grep -i sarthi` — is the listener bound?
2. `NotificationManagerCompat.getEnabledListenerPackages()` — does it contain us?
3. Toggle notification access **off and back on**. This rebinds the service and fixes it more often
   than any code change. Do this before debugging anything.
4. Reboot the phone, then re-check. Funtouch OS sometimes only rebinds listeners at boot.
5. Confirm `:gigsim` is actually posting: pull down the shade. If the shade is empty the problem is
   `POST_NOTIFICATIONS`, not the listener.

**Fallback:** an in-app "inject event" debug button that pushes a `NotificationEvent` straight onto
`NotificationEventBus`, bypassing the OS. Build this early anyway — it is a one-hour insurance policy
that lets every downstream module be developed while capture is broken. **It is a development tool,
not a demo path.** If the demo ever runs on the injector, you must say so on stage.

### 2.2 It works, then silently stops after a few minutes

This is R2, and on a vivo/iQOO device it is the most likely failure of the whole event.

1. Battery → find Sarthi → **do not optimise / allow high background power consumption**
2. Autostart / Auto-launch → **enable** for Sarthi
3. Recent-apps screen → long-press Sarthi's card → **lock** it
4. Start the foreground service with `FOREGROUND_SERVICE_SPECIAL_USE` and a persistent notification
5. Re-run the 10-minute idle test: post a `:gigsim` notification after 10 minutes of screen-off idle

**Never demo without having passed the 10-minute idle test on the actual loaner device.**

### 2.3 Duplicate offers appear

Dedupe on `(app, sha1(title + text))` within a 3-second window. Some apps repost a notification to
update its timer. Test with corpus X5.

---

## 3. Parse is broken

### 3.1 Tier A regex is not matching

**Time box: 20 minutes per app, and you fix it in JSON, not Kotlin.**

Edit `/sdcard/Sarthi/config/parsers.json` on the phone, press **Reload config**, re-fire the payload.
This loop is seconds long and needs no laptop. If you find yourself editing Kotlin to fix a regex,
stop — you have broken the design.

Common causes, in order of frequency: `kms` vs `km`; a comma in the number; `Rs.` with no space;
the value being in `bigText` and your test only reading `text`; two rupee values where you took the
first (see corpus S3).

### 3.2 ML Kit Entity Extraction will not initialise

**Time box: 45 minutes.** It downloads its model on first use — which needs network *once*. Do this
at the venue **early**, while Wi-Fi is quiet, and verify it before you need it.

**Fallback:** set `EntityParser.isAvailable = false`. The cascade skips it. Nothing else changes.

### 3.3 MediaPipe / Gemma will not load — **hard cutoff Sun 00:00**

**Time box: two hours, ending at Sun 00:00 sharp.**

Symptoms and what they mean:
- `UnsatisfiedLinkError` / missing native lib → ABI mismatch; check `abiFilters` includes `arm64-v8a`
- OOM on init → try the CPU backend instead of GPU; try a smaller model
- Model file not found → the path must be readable by the app. `/data/local/tmp/` is *not* readable
  by a normal app on all ROMs. Prefer `getExternalFilesDir(null)` and push there
- Init succeeds but inference takes >5 s → reduce `maxTokens` to 64; if still slow, cut it

**At 00:00, if it is not producing JSON on a corpus payload, you delete the dependency, set
`LlmParser.isAvailable = false`, and never mention it again.** Tier B is a complete and honest
on-device AI story on its own. This is not a loss; it is the plan working.

Log the decision in PROGRESS either way, with the reason.

---

## 4. Score is producing bad verdicts

Almost always weights, not code. Fix in `/sdcard/Sarthi/config/scoring.json`, reload, re-run the
STORM sequence.

| Symptom | Knob |
|---|---|
| Everything is a TAKE | Raise `benchmarkRupeesPerKm`, or raise the threshold clamp floor |
| Everything is a SKIP | Lower the benchmark |
| Arbitration never fires | Lower `arbitrationMargin` from 1.10 toward 1.05 |
| Arbitration fires on near-ties and looks arbitrary | Raise `arbitrationMargin` |
| Deadhead penalty never triggers | Lower `deadheadWarnShare` (default 0.35) |
| Threshold does not visibly move | Raise `ewmaAlpha` from 0.25 to 0.4 — the stage moment matters more than statistical elegance |

**Before Eval 1, hand-verify the three STORM rates against the implemented formula.** If the ordering
is ever ambiguous, change the *payloads*, not the formula. A deterministic demo is worth more than a
realistic one.

---

## 5. Speak is broken

| Symptom | Action |
|---|---|
| No audio at all | Check media volume, DND, and whether the phone is on a call. Check `TextToSpeech.OnInitListener` actually returned `SUCCESS` |
| `mr-IN` unavailable | `TtsSpeaker` falls back `mr-IN → hi-IN → en-IN → en-US` and the UI shows which is live. Demo in Hindi and say honestly that Marathi voice data was not on the loaner |
| Speech is cut off | You are calling `QUEUE_FLUSH` too eagerly. Only flush for a higher-priority verdict |
| It speaks over the driver's music badly | `AudioAttributes` with `USAGE_ASSISTANCE_NAVIGATION_GUIDANCE` — ducks rather than stops. Mention this on stage; it shows you thought about the real use |
| A literal `{payout}` is spoken | `VerdictPhraserTest` should have caught this. Add the missing template key and re-run the test |

**Download every voice pack in Hour 0.** They are large and the venue Wi-Fi will be worse later.

---

## 6. The build is broken

**Time box: 45 minutes before you revert.**

1. `git stash` your working changes and confirm `main` still builds. Now you know whether it is you
   or the environment.
2. `./gradlew clean` then rebuild once. Do not do this repeatedly — it costs minutes each time.
3. Version conflict → pin the exact version rather than letting the BOM resolve it.
4. If a *new dependency* broke it, remove the dependency. The feature it enabled is a Tier 3 feature
   by construction — nothing in Tier 0 or Tier 1 needs a dependency that is not already in.
5. `git reset --hard <last known good>` is always available. Small, frequent commits are what make
   this cheap — this is why `CLAUDE.md` R3 exists.

**Never let a broken build sit overnight while people sleep.** If it is broken at handoff, say so in
capitals in `HANDOFF.md` Section 1 and name the last known-good commit.

---

## 7. Device problems

| Problem | Action |
|---|---|
| ADB stops seeing the phone | Revoke USB debugging authorisations, replug, re-authorise. Try a different cable — venue cables are usually charge-only |
| Phone overheats and throttles | Lower brightness, close the gig apps, stop any LLM inference loops. Do not demo on a hot phone |
| Battery dies mid-build | Power bank plugged in from Hour 0, always. Never let the demo phone drop below 40% |
| Loaner device is wiped or swapped | Re-run the Hour-0 device checklist. Keep `scripts/push-config.sh` so restoring device state is one command |
| Office Kit disconnects | Re-pair. If it repeatedly fails, fall back to phone-native config tuning (roadmap §4) and log the outage in PROGRESS so the Office Kit gap is explainable |

---

## 8. Time-based triage — what to cut, when

| Clock | If you are behind, cut |
|---|---|
| Sat 17:00 | Marathi. Ship English + Hindi. Add Marathi later if it returns |
| Sat 22:00 | Tier B and Tier C both. Tier A regex alone is a working demo. Say "rules-based with a model fallback we didn't ship" — honesty costs less than a broken component |
| Sun 00:00 | Gemma, unconditionally. This is a hard cutoff, not a judgement call |
| Sun 02:00 | Zone table and earnings goal. Keep the arbitration |
| Sun 04:00 | Voice commands. Keep the "Why" **button** — same story, no ASR risk |
| Sun 06:30 | Everything. Freeze. From here you only fix what breaks the 35-second stage sequence |

**Never cut, at any hour:** capture, Tier A parse, deadhead-aware scoring, TTS in one language,
cross-app arbitration, the STORM demo. That set is the product. Everything else is decoration.
