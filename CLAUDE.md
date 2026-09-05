# CLAUDE.md — Read this first, every session

You are working on **EyesUp** (product name; internal/legacy name "Driver Copilot"), an Android app
built during the **iQOO City Battles Pune hackathon, Sat 5 – Sun 6 Sept 2026**, a 30-hour
phone-first build.

Two Claude Code sessions work on this project **in relay** (Agent A on Arnav's machine, Agent B on a
teammate's machine). When one hits its usage limit, the other picks up. **The relay only works if the
progress log is perfect.** That is your single most important standing obligation.

---

## 0. Onboarding — do this at the start of EVERY session, before any other work

1. Read `HANDOFF.md` (5-minute state-of-the-world; tells you what is true right now).
2. Read the **last 3 entries** of `PROGRESS.md`, bottom of file. The final entry's
   `➡️ NEXT INSTRUCTION` block is your task unless the user says otherwise.
3. Read `docs/DECISIONS.md` — do not re-litigate a decision already recorded there.
4. Run `git log --oneline -15` and `git status` to see what actually landed vs. what the log claims.
5. If the repo has an `app/` directory, run the build sanity check in `docs/DEVICE_AND_TOOLING_SETUP.md`
   §7 before writing code.

Then, and only then, start work.

---

## 1. Non-negotiable working rules

**R0 — Hand off exactly the way you were handed to.** The relay is symmetric and self-perpetuating.
You were able to start cold because the previous session left a perfect log; the next session gets the
same, from you, without being asked. Concretely, **you own the handoff from the moment you start**:
- Assume every message could be your last — usage limits do not warn you. Keep `PROGRESS.md` current
  as you go, never "at the end".
- The moment you notice you are running long, **stop building and hand off.** A clean handoff with a
  half-finished feature beats a finished feature nobody can find.
- Run the *Ending a session* checklist in `HANDOFF.md` §2 in full. Not most of it.
- **Tell the next agent to do the same.** Your `➡️ NEXT INSTRUCTION` must end with the handoff
  reminder, so the protocol reproduces itself down the chain and never decays.
- Never assume the next agent is the same model, has your context, or will read anything you did not
  write down. Write for a stranger.

**R1 — Log everything.** After *every* meaningful unit of work (a feature lands, a build breaks, a
decision is made, a device quirk is found, a demo is rehearsed), append an entry to `PROGRESS.md`
using the template at the top of that file. Never batch a session's work into one entry at the end —
if you hit your limit mid-task, the log must already be current. **The log is the handoff.**

**R2 — Every entry ends with an instruction.** The `➡️ NEXT INSTRUCTION` block is written *for a
different agent with zero context*. It must name exact files, exact commands, and an acceptance
criterion. "Continue the parser" is a failed instruction. "Add a `RapidoParser` to
`app/src/main/java/com/eyesup/copilot/parse/regex/` matching the 3 payloads in
`docs/NOTIFICATION_CORPUS.md` §2.3; done when `RegexParserTest` passes 3/3" is a good one.

**R3 — Commit constantly.** Small commits, present-tense messages, push after every entry.
`git add -A && git commit -m "..." && git push`. An unpushed commit does not exist for the relay.

**R4 — Build order is law.** Follow `driver-copilot-features-roadmap.md` §5 build order even under
time pressure. Do not start a Tier 1 feature while a Tier 0 feature is broken. A flawless five-feature
demo beats a nine-feature demo that visibly breaks on stage.

**R5 — Demo reliability > feature count.** From Sun 06:30 the code is frozen except for
demo-blocking bugs. Anything not working by then is cut and never mentioned on stage.

**R6 — Never invent names.** Package names, class names, JSON keys and file paths are fixed in
`docs/BUILD_SPEC.md`. If you need a new one, add it to BUILD_SPEC in the same commit. Two agents
inventing `Order` and `OrderOffer` for the same thing is the #1 way this relay produces merge pain.

**R7 — Honesty in the pitch.** Rules-based fast path is called rules-based. The simulator is
disclosed. Nothing is claimed to run on-device that doesn't. See `docs/DEMO_AND_PITCH.md` §5.

**R8 — Bank device telemetry deliberately.** 25% of the score is raw device data (Creative Phone Use
15% + Office Kit 10%) that no pitch can recover. See `docs/DEVICE_AND_TOOLING_SETUP.md` §8 and log
every Office Kit session in PROGRESS.md.

---

## 2. What we are building, in one paragraph

Gig drivers run 2–3 apps at once (Uber, Rapido, Swiggy, Zomato, Porter) and glance at the phone
mid-ride to judge whether an incoming order is worth taking. EyesUp is an on-device Android copilot
that reads incoming order notifications at the OS level, extracts payout/distance/pickup-time with a
three-tier on-device NLU stack, scores each offer against the driver's own history, their earnings
goal, the time of day and the drop zone's return prospects — **and compares it against every other
offer currently open across all their apps** — then speaks a one-line verdict in Marathi, Hindi or
English. Nothing leaves the device.

**The headline feature is cross-app arbitration.** A human cannot compare a Swiggy order against a
Rapido offer that arrived 40 seconds ago while driving. EyesUp can. Lead with that.

---

## 3. Map of this repo

| Path | What it is |
|---|---|
| `CLAUDE.md` | This file. Standing rules. |
| `HANDOFF.md` | Live state of the world. Updated at every session end. **Read first.** |
| `PROGRESS.md` | Append-only exhaustive work log. The relay's memory. |
| `driver-copilot-iqoo-pune-gameplan.md` | Strategy, rubric, schedule, risk register. |
| `driver-copilot-features-roadmap.md` | Feature tiers + strict build order. |
| `docs/ARCHITECTURE.md` | Module boundaries, data flow, ownership split. |
| `docs/BUILD_SPEC.md` | Concrete implementation spec: packages, classes, deps, schemas. |
| `docs/NOTIFICATION_CORPUS.md` | Real/realistic notification payloads to parse against. |
| `docs/DEMO_AND_PITCH.md` | 90-second script, stage runbook, judge Q&A. |
| `docs/RISKS_AND_FALLBACKS.md` | Decision tree for when something breaks. |
| `docs/DEVICE_AND_TOOLING_SETUP.md` | Phone, ADB, Office Kit, vivo/Funtouch gotchas. |
| `docs/DECISIONS.md` | ADR log. Why things are the way they are. |
| `assets/config/*.json` | Hot-reloadable runtime config (parsers, scoring, TTS templates). |
| `scripts/` | Helper scripts (adb push config, model push, log capture). |

---

## 4. Tech stack (fixed — do not substitute without an ADR)

Kotlin · Jetpack Compose · minSdk 26 / targetSdk 35 · `NotificationListenerService` ·
ML Kit Entity Extraction (on-device) · MediaPipe LLM Inference (Gemma3-1B-IT int4) ·
Android `TextToSpeech` · on-device `SpeechRecognizer` · MediaPipe Face Landmarker (stretch) ·
kotlinx.serialization + DataStore for persistence (**no Room** — see ADR-006).

Second app module `:gigsim` posts real Android notifications that impersonate gig-app payloads, so
the production notification path is exercised end-to-end without driver accounts. See ADR-002.

---

## 5. Hard constraints to keep in mind

- **No driver accounts.** We cannot log into Uber Driver / Swiggy DP. All input comes from the
  `:gigsim` app or from a captured corpus. Design accordingly; never block on "real orders".
- **Funtouch OS kills background services.** Battery whitelisting and autostart must be configured on
  the loaner phone or the notification listener silently dies. See DEVICE setup §4.
- **Venue wifi is not a download plan.** Every model, voice pack and dependency must be staged
  locally before it is needed.
- **Red Light (~55% of hours) is phone-only**, bridged to the laptop through Office Kit. Plan
  phone-native work for those windows; see roadmap §4.
