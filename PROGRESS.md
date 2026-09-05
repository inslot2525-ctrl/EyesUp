# PROGRESS.md — Exhaustive work log

> **This file is the relay's memory.** Two Claude Code sessions alternate on this project; whichever
> one is running must be able to reconstruct the entire state of the world from this file alone,
> without asking a human a single question.
>
> **Append-only.** Never edit or delete a past entry. If a past entry was wrong, write a new entry
> that corrects it and say so explicitly.
>
> **Write an entry after every meaningful unit of work** — a feature landing, a build breaking, a
> decision being made, a device quirk being discovered, a demo being rehearsed, a conversation with
> an organiser. Do not batch a whole session into one entry at the end: if you hit your usage limit
> mid-task, the log must already be current.

---

## Entry template — copy this exactly

```markdown
### [E-0NN] YYYY-MM-DD HH:MM IST — <short imperative title>

- **Agent:** A (Arnav) | B (teammate) | Human
- **Phase:** Pre-event | Red Light | Green Light | Freeze | Eval
- **Module claimed:** capture | parse | score | queue | voice | ui | sim | docs | none
- **Duration:** ~NNm

**Goal.** One sentence: what this unit of work was trying to achieve.

**Did.**
- Bullet per concrete action. Be specific enough that someone could redo it.

**Files touched.**
- `path/to/file` — what changed and why.

**Commands run.**
```
exact commands, exact enough to re-run
```

**Result / verification.** What actually proved it works — a log line, a test result, a screenshot
path, an observed behaviour on the device. "It should work" is not a result.

**State after.** What now works end-to-end that did not before.

**Blockers / unknowns.** Anything unresolved, with the ID if it is a tracked blocker.

**Device telemetry banked.** Which of: notification listener · mic · speaker/TTS · GPS · camera ·
NPU/on-device model · Office Kit (mirror / remote control / clipboard / file transfer). Say what was
actually exercised, and for roughly how long.

**Decisions made.** Any ADR added to `docs/DECISIONS.md`, by ID. Write "none" if none.

**➡️ NEXT INSTRUCTION.**
> Written for an agent with zero context. Must contain: the exact task, the exact files and paths,
> the exact commands to run, and an acceptance criterion that says how they will know it is done.
> Include what NOT to touch. If there are two things to do, number them in priority order.
```

### What makes a NEXT INSTRUCTION good

**Bad:** "Continue working on the parser."

**Good:**
> 1. Add `RapidoParser` to `app/src/main/java/com/sarthi/copilot/parse/regex/`. It must handle the
>    three Rapido payload shapes in `docs/NOTIFICATION_CORPUS.md` §2.3, including the one with no
>    pickup distance. Register it in `ParserRegistry.kt` keyed on package `com.rapido.rider`.
>    Read patterns from `parsers.json` — do not hardcode regexes in Kotlin.
>    **Done when** `./gradlew :app:testDebugUnitTest --tests "*RapidoParserTest*"` passes 3/3.
> 2. Do **not** touch `ScoringEngine.kt` — Agent B is mid-edit there as of E-014.

---

# Log

---

### [E-001] 2026-09-05 10:30 IST — Rebuild the plan, spec the build, set up the relay

- **Agent:** A (Arnav)
- **Phase:** Pre-event
- **Module claimed:** docs
- **Duration:** ~90m

**Goal.** Take two loose planning documents and turn them into a complete, internally consistent
operating manual that a second Claude Code session can execute from cold, plus fix the technical
assumptions in the original plan that would have cost hours on the day.

**Did.**
- Read both original documents in full and audited every technical assumption.
- Found and corrected four assumptions that would have burned event hours:
  1. **The plan silently depended on having gig-driver accounts.** Uber Driver, Swiggy Delivery
     Partner and Rapido Captain all require document and vehicle onboarding. We will not have them.
     Replaced the in-app "demo simulator" with a **second APK, `:gigsim`, that posts genuine Android
     notifications** — this exercises the real capture path end to end and makes the demo repeatable.
     Recorded as ADR-002.
  2. **Gemini Nano / Android AICore was listed as the primary on-device model option.** AICore ships
     on Pixel 8 Pro+/Galaxy S24+, not on iQOO/vivo Funtouch OS. Removed it entirely; replaced with a
     three-tier cascade (regex → ML Kit Entity Extraction → MediaPipe Gemma3-1B-int4) so the
     on-device AI claim does not rest on a single risky component. ADR-003, ADR-004.
  3. **The pre-event checklist assumed a day and a half of prep.** Today is event day. Converted it
     into an Hour-0 checklist to run in the first 60 minutes on site.
  4. **Nothing addressed Funtouch OS background-process killing**, which is the single most likely
     way a notification listener silently dies on a vivo/iQOO device. Added to the risk register as
     R2 with a concrete mitigation and a 10-minute idle verification test.
- Sharpened the product itself: promoted **cross-app arbitration** from a Tier 1 differentiator to
  the headline feature and the pitch's lead, because it is the only part of the product a human
  genuinely cannot do while driving. ADR-001.
- Added three cheap, high-leverage scoring features: **deadhead-aware rate** (count the unpaid
  distance to pickup — the thing platforms hide), **earnings-goal urgency**, and **drop-zone return
  prospects** from a static Pune zone × hour table. ADR-005.
- Added **hot-reloadable JSON config on the device** (`/sdcard/Sarthi/config/`) so parser regexes,
  scoring weights and TTS templates can be tuned during Red Light from a phone text editor with no
  rebuild. This is the highest-value Red Light unlock in the plan. ADR-007.
- Proposed renaming the product to **Sarthi** (सारथी, the charioteer) — Marathi/Hindi-native for a
  Pune jury. Code identifier fixed at `com.sarthi.copilot` so the name cannot churn mid-build.
- Wrote the full specification set so a cold agent needs to guess nothing: architecture, concrete
  build spec with fixed class names and schemas, notification corpus, demo script and judge Q&A,
  fallback decision tree, device setup runbook, and the ADR log.
- Wrote the relay infrastructure: `CLAUDE.md` (standing rules), `HANDOFF.md` (live state),
  this file (`PROGRESS.md`).
- Seeded three runtime config files with real starting values.

**Files touched.**
- `CLAUDE.md` — new. Standing rules loaded automatically by any Claude Code session in this directory.
- `HANDOFF.md` — new. Live state of the world; rewritten at every handoff.
- `PROGRESS.md` — new. This file.
- `driver-copilot-iqoo-pune-gameplan.md` — rewritten. Added the change log (§2), the corrected
  architecture (§5), a real hour-by-hour schedule from Sat 11:00 to Sun 16:15 (§6), a ten-item risk
  register with triggers (§8), the Hour-0 checklist (§9), and a sleep/relay plan (§10).
- `driver-copilot-features-roadmap.md` — rewritten. Tier tables now carry acceptance criteria; added
  the strict 18-step build order with eval checkpoints, a concrete Red Light task list, a
  feature-to-rubric traceability matrix, and an explicit out-of-scope list.
- `docs/ARCHITECTURE.md` — new. Module boundaries, data flow, threading, ownership split.
- `docs/BUILD_SPEC.md` — new. Package layout, every class name, every data class, Gradle deps,
  manifest entries, JSON schemas, the scoring formula, the LLM prompt.
- `docs/NOTIFICATION_CORPUS.md` — new. Realistic payloads for five apps including sparse and
  adversarial cases, plus parser acceptance targets.
- `docs/DEMO_AND_PITCH.md` — new. The 90-second script, the stage runbook, the judge Q&A bank.
- `docs/RISKS_AND_FALLBACKS.md` — new. Decision tree per failure mode with time-boxed cutoffs.
- `docs/DEVICE_AND_TOOLING_SETUP.md` — new. Loaner phone setup, Funtouch gotchas, ADB, Office Kit
  discipline, build sanity check.
- `docs/DECISIONS.md` — new. Ten ADRs covering every judgement call above.
- `assets/config/parsers.json` — new. Seed regex patterns per gig app.
- `assets/config/scoring.json` — new. Seed benchmarks, weights, Pune zone × hour table, TTLs.
- `assets/config/tts_templates.json` — new. Seed verdict phrasings in English, Hindi, Marathi.
- `scripts/push-config.sh` / `scripts/push-model.sh` / `scripts/capture-logs.sh` — new helper scripts.

**Commands run.**
```
mkdir -p docs assets/config scripts
```

**Result / verification.** All files written and cross-referenced. Every document's internal links
point at a file that exists. No code has been compiled — none exists yet.

**State after.** A complete specification exists. Any Claude Code session can now be dropped into
this directory cold, read `CLAUDE.md` → `HANDOFF.md` → this entry, and start building step 1 of the
build order without asking a single clarifying question.

**Blockers / unknowns.**
- **B1** — the repo is not on a git remote. Until a private GitHub repo exists and both machines have
  cloned it, the relay has no transport. This is the top priority for the human.
- **B2** — the loaner device is not in hand. Everything device-specific is unverified.
- **B3** — the Gemma `.task` file is not staged on the laptop. Must be downloaded before arriving at
  the venue; venue Wi-Fi will not carry ~550 MB reliably.
- Every library version in `docs/BUILD_SPEC.md` is marked `VERIFY` — confirm at first Gradle sync and
  correct in place.
- The exact problem-statement text and the real Red/Green Light windows are still unconfirmed.
- We do not know what HackTracker actually instruments for the Office Kit score. Ask an organiser.

**Device telemetry banked.** None — no device in hand yet.

**Decisions made.** ADR-001 through ADR-010, all recorded in `docs/DECISIONS.md`.

**➡️ NEXT INSTRUCTION.**

> **For the human, before any agent continues (blocks everything else):**
> 1. Create a **private GitHub repo** and wire this directory to it:
>    ```
>    cd C:/Projects/iqoo
>    git init && git add -A && git commit -m "spec: Sarthi plan, build spec and relay infrastructure"
>    git branch -M main
>    git remote add origin git@github.com:<user>/sarthi-iqoo.git
>    git push -u origin main
>    ```
>    Give the teammate push access and have them clone it. **Unblocks B1.**
> 2. Download the Gemma model to the laptop **now, on non-venue Wi-Fi**:
>    `gemma3-1b-it-int4.task` from Kaggle/HuggingFace (LiteRT / MediaPipe `.task` format, ~550 MB).
>    Save it at `~/models/gemma3-1b-it-int4.task` and record the real path in `HANDOFF.md` §5.
>    **Unblocks B3.**
> 3. Install Office Kit from pc.vivoglobal.com and test screen mirror, remote control, clipboard sync
>    and file transfer once each **before** hacking starts. Speed here is scored.
>
> **For the next agent, once B1 is cleared — start the build:**
> 1. Read `docs/BUILD_SPEC.md` end to end. It fixes every name you will need. Do not invent any.
> 2. Scaffold the Gradle project exactly as specified in `docs/BUILD_SPEC.md` §2: root project
>    `sarthi`, two modules `:app` (`com.sarthi.copilot`) and `:gigsim` (`com.sarthi.gigsim`),
>    Kotlin + Compose, minSdk 26, targetSdk 35.
>    **Done when** `./gradlew :app:assembleDebug :gigsim:assembleDebug` succeeds and both APKs install.
> 3. Build **step 1 of the build order only**: `:gigsim` posting real OS notifications. Spec is in
>    `docs/BUILD_SPEC.md` §8; payloads come from `docs/NOTIFICATION_CORPUS.md`.
>    **Done when** pressing a button in `:gigsim` produces a system notification in the shade whose
>    title, text and bigText match the corpus entry exactly.
> 4. Do **not** start the notification listener until step 3 is verified on the real device. The
>    listener is impossible to debug if you cannot trust the input.
> 5. Write your PROGRESS entry as `E-002` before you do anything else, and update `HANDOFF.md`
>    Section 1.
>
> **Correct as you go:** every `VERIFY` marker in `docs/BUILD_SPEC.md` is a version or API I could not
> confirm without the toolchain in front of me. When you confirm or correct one, edit it in place and
> note it in your PROGRESS entry.

---
