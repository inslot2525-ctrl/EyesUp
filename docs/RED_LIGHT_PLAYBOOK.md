# RED_LIGHT_PLAYBOOK.md

**What Red Light actually means (handbook, page 04):**
> "Red light: Direct usage of laptops is restricted and will be monitored. Work on your phone, or
> access your laptop only via the Office Kit on your phone."
> "Green light: Free to use anything — phone, laptop, any setup."

So the laptop is not gone during Red Light — it is **only reachable through Office Kit remote control
from the phone**. That is deliberate, and it is also how you bank the Office Kit 10%. Red Light is
not a phase to survive; it is the phase the scoring is designed around.

---

## 1. The windows

Read off the handbook's Red/Green bar (page 04). **The handbook says timings may vary and will be
announced at the venue — confirm these in the first 15 minutes and correct this table in place.**

| Window | Phase | Length | Notes |
|---|---|---|---|
| 11:00 – 14:00 | 🟢 GREEN | 3h 00m | Hacking begins. Lunch 13:00. |
| **14:00 – 15:30** | 🔴 **RED** | **1h 30m** | R1 |
| 15:30 – 16:30 | 🟢 GREEN | 1h 00m | Short. Spend it only on things that need a laptop. |
| **16:30 – 19:00** | 🔴 **RED** | **2h 30m** | R2. High-Tea 17:00. Ends at Eval Round 1. |
| 19:00 – 22:00 | 🟢 GREEN | 3h 00m | Eval 1 at 19:00. Dinner 21:00. |
| **22:00 – 01:00** | 🔴 **RED** | **3h 00m** | R3. Midnight refuel 00:30. |
| 01:00 – 06:30 | 🟢 GREEN | 5h 30m | **The last green window. All code must be finished here.** |
| **06:30 – 09:00** | 🔴 **RED** | **2h 30m** | R4. Freeze. Eval Round 2 at 09:00. |

**Totals: 12h 30m green, 9h 30m red** — matches the handbook's "roughly 55/45" Green/Red rhythm.

> **The single most important scheduling consequence: the last Green Light ends at 06:30 on Sunday,
> two and a half hours before Evaluation Round 2.** After 06:30 you cannot touch a laptop directly.
> Code freeze is not a discipline choice — it is enforced by the format. Everything must be built and
> installed on the phone before 06:30.

---

## 2. The Red Light iteration loop — build this first, it is what makes Red Light productive

The reason the app reads its config from `/sdcard/EyesUp/config/*.json` (ADR-007) is this loop:

```
   edit JSON in a phone text editor  →  tap "Reload config" in the app
              →  press a payload button on the GigSim phone
              →  hear the verdict
              →  repeat
```

Seconds per iteration. No laptop, no Gradle, no reinstall. **If you find yourself needing the laptop
to change a regex, a scoring weight or a spoken phrase, the config plumbing is broken and fixing it
is your top Green Light priority.**

Install a phone text editor (Acode / QuickEdit / Markor) in the first 15 minutes. Without it, Red
Light is dead time.

---

## 3. What to do in each Red window

### 🔴 R1 · 14:00–15:30 (1h 30m) — device qualification + parser tuning

Two people, two tracks, in parallel.

**Track A — device qualification (do this once, properly, now):**
- [ ] Notification access granted to EyesUp; listener banner shows green
- [ ] Battery optimisation OFF, autostart ON, recents card locked (Funtouch kills listeners — see
      `DEVICE_AND_TOOLING_SETUP.md` §4). **Do not touch HackTracker's battery settings.**
- [ ] TTS voice data present for `en-IN`, `hi-IN`, `mr-IN` — listen to each
- [ ] Start the **10-minute idle test**: post a notification, lock the screen, wait, post again
- [ ] GPS fix outdoors; front camera framing; on-device `SpeechRecognizer` with Wi-Fi off
- [ ] Log every result in `PROGRESS.md` — each passing sensor is Creative Phone Use banked

**Track B — Tier A parser tuning, entirely on the phone:**
- [ ] Fire every payload in `NOTIFICATION_CORPUS.md` §2 from the GigSim phone, one at a time
- [ ] For each miss, edit `parsers.json` → Reload config → re-fire
- [ ] Target: 100% on the ★ payloads, ≥90% overall
- [ ] Then fire §3 (sparse/adversarial). X2 must be **rejected** as not-an-offer. Nothing may crash
- [ ] Commit `parsers.json` back to the repo via Office Kit file transfer

**Office Kit during R1:** keep the mirror session open the whole window. Use remote control to run
`git commit` and to read logcat on the laptop. Use clipboard sync to move regexes between devices.

### 🔴 R2 · 16:30–19:00 (2h 30m) — scoring, speech, and Eval 1 rehearsal

Eval Round 1 is at 19:00 and this window ends exactly there. Budget the last 45 minutes for rehearsal
and do not let building eat it.

- [ ] **16:30–17:15** Tune `scoring.json` on the phone until verdicts feel right. Knob table is in
      `RISKS_AND_FALLBACKS.md` §4. Hand-verify the three STORM rates.
- [ ] **17:15–17:45** Tune `tts_templates.json`. Listen to every phrase out loud through the speaker.
      **Find a Marathi speaker on the floor and have them read the MR block** — the templates are
      flagged `_nativeSpeakerCheck: PENDING` and a Pune jury will hear a wrong phrasing instantly.
- [ ] **17:45–18:15** UI polish via Office Kit remote control — the parts that are just Compose
      tweaks and a reinstall.
- [ ] **18:15–19:00** **Rehearse Eval 1 twice, end to end, out loud, with both phones.** Time it.
      Write what broke into `PROGRESS.md`.

### 🔴 R3 · 22:00–01:00 (3h 00m) — the arbitration window

This is the longest Red block and it lands right after the Green window where cross-app arbitration
gets built. Use it to make the headline feature *reliable*, not to build more.

- [ ] Run the **STORM sequence twenty times in a row.** It must produce the identical spoken verdict
      every single time. Any nondeterminism here loses you the demo. Fix ties, ordering and TTL races
      by tuning `arbitrationMargin` and the payload numbers — not the formula.
- [ ] Tune the explainability copy — every `ReasonCode` phrase in all three languages, spoken aloud.
- [ ] Test on-device ASR in the actual noisy hall, not at your table. Establish how close you have to
      hold the phone. If it is unreliable at demo distance, the "Why" **button** is the demo path and
      the voice loop is a bonus — decide this now, not on stage.
- [ ] Run the 10-minute idle test again after all the new code. Listeners die quietly.
- [ ] Charge everything. Midnight refuel at 00:30.
- [ ] **Office Kit heavily:** all commits, all log reading, all file moves through it for three hours.
      This is your biggest single Office Kit banking opportunity of the event.

### 🔴 R4 · 06:30–09:00 (2h 30m) — freeze, rehearse, submit

**No new features. None.** The laptop is unreachable and Eval 2 is at 09:00.

- [ ] **06:30** Declare freeze in `PROGRESS.md`. Confirm the installed APK on the demo phone is the
      one you want — you cannot rebuild without Office Kit and you should not want to.
- [ ] **06:30–07:00** Full dry run #1. Note every stumble.
- [ ] **07:00–07:20** Fix only demo-blocking bugs, and only through config or Office Kit.
- [ ] **07:20–07:50** Full dry run #2. Different person presents.
- [ ] **07:50–08:10** **Record the backup video** — one flawless 35-second run, saved to the phone
      gallery, one tap from the demo screen.
- [ ] **08:10–08:40** Full dry run #3, at stage distance, with the speaker, with someone playing judge
      and asking two questions from `DEMO_AND_PITCH.md` §6.
- [ ] **08:40–09:00** Reset state: clear all notifications, reset the driver profile so the threshold
      demo starts clean, charge to 100%, volume max, DND off.
- [ ] **Submission:** push the repo and upload demo assets to the Reskill platform. Repos lock before
      the Top 10 pitches, and late submission carries scoring penalties. Do not leave this to Sunday
      afternoon — do it here, from the phone, via Office Kit.

---

## 4. The general rule for any Red Light minute you have not planned

In priority order:

1. **Tune a config file and hear the result.** Always available, always useful, needs nothing.
2. **Re-run the STORM demo.** Repetition is what makes it deterministic on stage.
3. **Rehearse the pitch out loud.** It is 10% of the score and costs nothing but embarrassment.
4. **Write your `PROGRESS.md` entry.** The relay depends on it and Red Light is when you have hands
   free.
5. **Use Office Kit for something you would otherwise do on the laptop later.** It is measured.

**Never during Red Light:** open the laptop lid directly, start a Gradle build you cannot drive from
the phone, or sit idle waiting for Green. Laptop use is monitored and the format punishes idling more
than it punishes slow building.

---

## 5. Office Kit discipline — the 10% you cannot argue for later

The handbook is explicit: *"HackTracker captures counts **and durations** only ... for creative phone
use and Office Kit scoring."* Both are measured, so do both:

- **Duration:** keep the Office Kit session **connected continuously**, in Red and Green alike. Do not
  disconnect when you switch to the laptop during Green.
- **Counts:** use its discrete features repeatedly — screen mirror, remote control, clipboard sync,
  file transfer. Move every config file, every log excerpt, every commit through it rather than
  through `adb push` some of the time.

Office Kit is already paired on the loaner at handover (handbook, page 02), so there is no setup cost
— only the discipline of actually using it. Record every session in your `PROGRESS.md` entry's
**Device telemetry banked** field with a rough duration.

---

## 6. Creative Phone Use — what HackTracker is actually watching

The handbook says HackTracker *"sits on the device through the build, reads model outputs, and logs
inference calls, tokens and thermals in real time."*

**Read that again: it counts on-device inference calls and tokens.** That is a direct, mechanical
measurement of the 15% Creative Phone Use line, and it rewards the local model doing real, continuous
work rather than sitting idle as a rarely-triggered fallback.

This is why ADR-011 puts the local LLM in **shadow mode** — it runs on every captured notification
alongside the regex path, and it generates the long-form "why" explanations. Both are genuine uses
that improve the product; neither is padding. The regex path still owns the demo-critical fast lane,
so reliability is unaffected.

During Red Light, every payload you fire while tuning is also an inference call being logged. **Tuning
and telemetry are the same activity.** Fire payloads liberally.
