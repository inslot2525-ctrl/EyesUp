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
> 1. Add `RapidoParser` to `app/src/main/java/com/pillion/copilot/parse/regex/`. It must handle the
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
- Added **hot-reloadable JSON config on the device** (`/sdcard/Pillion/config/`) so parser regexes,
  scoring weights and TTS templates can be tuned during Red Light from a phone text editor with no
  rebuild. This is the highest-value Red Light unlock in the plan. ADR-007.
- Proposed renaming the product to **Pillion** (सारथी, the charioteer) — Marathi/Hindi-native for a
  Pune jury. Code identifier fixed at `com.pillion.app` so the name cannot churn mid-build.
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
>    git init && git add -A && git commit -m "spec: Pillion plan, build spec and relay infrastructure"
>    git branch -M main
>    git remote add origin git@github.com:<user>/pillion-iqoo.git
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
>    `pillion`, two modules `:app` (`com.pillion.app`) and `:gigsim` (`com.pillion.gigsim`),
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

### [E-002] 2026-09-05 11:05 IST — Fold in the official handbook, the organiser tip, and the teammate's feature list

- **Agent:** A (Arnav)
- **Phase:** Pre-event → Green Light (hacking begins 11:00)
- **Module claimed:** docs
- **Duration:** ~40m

**Goal.** Replace every assumption in the plan with what the official handbook actually says, act on an organiser's direct tip about HackTracker, and rule on a 25-point feature list from a teammate.

**Did.**
- Read all six handbook pages and corrected the plan against them:
  1. **The Red/Green ratio was backwards.** The handbook says "Green Light / Red Light rhythm, roughly 55/45" — Green is the larger share. The real windows are now in gameplan §4: 8 alternating blocks totalling 12h30m green / 9h30m red.
  2. **The last Green Light ends 06:30 Sunday**, 2.5 hours before Eval Round 2. Code freeze is enforced by the format, not chosen. Rescheduled everything around this — the 01:00–06:30 green block is the largest work window of the event and all remaining code must land there.
  3. **HackTracker measures counts *and* durations, and logs inference calls, tokens and thermals.** This answered the open question from E-001 and drove ADR-011.
  4. **Device is an iQOO 15** — SD 8 Elite Gen 5, 16 GB, vapour chamber. Far stronger than assumed; staging a 3–4B model alongside the 1B (ADR-012).
  5. **One flagship loaner per person**, Office Kit pre-paired, HackTracker pre-installed. GigSim moves to a second loaner (ADR-013); no personal phone needed.
  6. **"Original work only... organisers may verify a project was built inside the event window."** No source code before 11:00 (ADR-014). Docs written earlier are planning, not a product.
  7. **Repos lock before the Top 10 pitches (13:00 Sun).** Submission moved into the R4 window.
  8. **"The highest on-device builds will be preferred for the Top 10."** OpenRouter credits are for coding assistance only; no network call ships in the product (ADR-015).
- Acted on the organiser's tip (30-hour phone surveillance, use the phone as much as possible): added gameplan §4a **Phone-first posture in both phases**. The previous plan left the phone idle for 12 of 30 hours during Green Light — a real forfeit. New default: phone in hand always, laptop driven through Office Kit, direct laptop use only for Gradle/dependency work. Three phones, three jobs. Overnight soak loop that doubles as the R2 listener-survival test.
- Reviewed the teammate's 25-point feature list in full — verdict per item in `docs/FEATURE_REVIEW.md`. Adopted: net earnings + personal fuel model, ₹/hour as the spoken headline, Zero-Look Mode, Shift Strategist, voice loop promoted to Tier 1, priority preference, home direction, the Smart Score presentation, and the pitch reframe. Swapped camera OCR ingestion in for the fatigue check. Rejected: accessibility-service scraping (a positioning call, not a time call), demand prediction trained on simulated data, traffic routing, gamification.
- Renamed the project **Sarthi → Pillion** across all 19 files (ADR-008 updated). One word, every Indian gig driver knows it, names the product's role exactly, sounds nothing like an AI product. Package fixed at `com.pillion.app`. Free to do now because no code exists.
- Made the relay handoff protocol **self-perpetuating**: `CLAUDE.md` R0 and `HANDOFF.md` §2 now require every session to hand off the way it was handed to, and every `➡️ NEXT INSTRUCTION` must end with the handoff reminder verbatim so the protocol cannot decay down the chain.

**Files touched.**
- `driver-copilot-iqoo-pune-gameplan.md` — §4 real Red/Green windows; **new §4a phone-first posture**; §6 rewritten against the real agenda; §2 rows 11–16; §3 HackTracker answered; risks R11–R15; §9 Hour-0 rewritten for 08:00–11:00.
- `driver-copilot-features-roadmap.md` — T0.4/T0.5 upgraded to net ₹/hour; new T1.5/T1.7/T1.8, T2.6/T2.7; T3.3 swapped to OCR; out-of-scope expanded; build order updated.
- `docs/RED_LIGHT_PLAYBOOK.md` — **new.** Per-window task lists for R1–R4, the config iteration loop, Office Kit discipline, what HackTracker watches.
- `docs/FEATURE_REVIEW.md` — **new.** Adopt/modify/reject verdict on all 25 teammate proposals.
- `docs/DECISIONS.md` — ADR-011 through ADR-018. ADR-018 supersedes ADR-010.
- `docs/DEMO_AND_PITCH.md` — pitch opener reframed to "move the decision from the screen to the voice layer"; ₹/hour leads the domain-insight line.
- `CLAUDE.md`, `HANDOFF.md` — handoff protocol made self-perpetuating.
- All 19 files — Sarthi → Pillion rename.

**Commands run.**
```
git init && git add -A && git commit    # 3 commits, branch main
python                                  # in-place edits across all docs
grep -c "^## ADR-" docs/DECISIONS.md    # → 19
```

**Result / verification.** 19 ADR headings present, ADR-011…018 all confirmed by grep. Rename verified across 19 files. No code written — correct, hacking had not begun.

**State after.** The plan matches the official handbook exactly rather than inferring from another city's format. Every open question from E-001 about HackTracker is answered. The feature set is decided and tiered. The relay protocol is self-reinforcing.

**Blockers / unknowns.**
- **B1 still open** — no git remote. Now urgent; the relay cannot function without it.
- **B2** — loaner devices not yet in hand.
- **B3** — neither model file staged. Both downloads must start now and land before 13:00.
- The Red/Green windows in §4 are read off a photographed bar chart. The handbook says timings may vary and will be announced at the venue. **Confirm in the first 15 minutes and correct in place.**
- The seven track names are unknown. Get the list and pick one.

**Device telemetry banked.** None — devices not in hand. From 11:00 this field must never be empty again (gameplan §4a).

**Decisions made.** ADR-011 … ADR-018. ADR-018 supersedes ADR-010.

**➡️ NEXT INSTRUCTION.**

> **Human, first — these block everything:**
> 1. Create the private GitHub repo and push (commands in E-001). Teammate clones it. **Unblocks B1.**
> 2. Start both model downloads now: `gemma3-1b-it-int4.task` (~550 MB) and a 3–4B int4 `.task` (~2.5 GB). If the 4B is not down by 13:00, ship the 1B and stop (ADR-012).
> 3. Confirm at the venue and correct in place: the real Red/Green windows (gameplan §4 and `docs/RED_LIGHT_PLAYBOOK.md` §1), the seven track names, and the Reskill submission URL and cutoff.
>
> **Next agent — build, in this order. We are in the 11:00–14:00 GREEN window, the longest laptop block before Eval 1. Use it for what only a laptop can do.**
> 1. Read `docs/BUILD_SPEC.md` end to end. Every package, class and JSON key is fixed there. Invent nothing; if you need a new name, add it to BUILD_SPEC in the same commit.
> 2. Scaffold per BUILD_SPEC §2: root project `pillion`, modules `:app` (`com.pillion.app`) and `:gigsim` (`com.pillion.gigsim`), Kotlin + Compose, minSdk 26, targetSdk 35. **Done when** `./gradlew :app:assembleDebug :gigsim:assembleDebug` succeeds and both APKs install.
> 3. Write the `model/` package **first and alone**, then commit and push it before touching anything else. It is the one shared surface between the two work tracks (`ARCHITECTURE.md` §5) and a conflict there is the most expensive merge in this project.
> 4. Build **step 1 of the build order only**: `:gigsim` posting real OS notifications. Spec in BUILD_SPEC §8, payloads from `NOTIFICATION_CORPUS.md`. **Done when** a button in `:gigsim` produces a system notification whose title, text and bigText match the corpus entry exactly, seen in the shade on the real phone.
> 5. **Push both model files to the phone in this window** — it is the last long laptop block before they are needed (`scripts/push-model.sh`).
> 6. Get the config plumbing working (`ConfigRepository` + Reload button, ADR-007) **before 14:00**. If it is not done, the R1 Red window has no work in it and the whole phone-first plan stalls.
> 7. Do **not** start the notification listener until step 4 is verified on the real device — the listener is impossible to debug if you cannot trust the input.
> 8. Do **not** write any code before 11:00 (ADR-014). Check the clock.
>
> **Correct as you go:** every `VERIFY` marker in `docs/BUILD_SPEC.md` is a version or API I could not confirm without the toolchain. Fix them in place and note it in your entry.
>
> **Before you finish:** you own the handoff too. Keep `PROGRESS.md` current as you go, run the *Ending a session* checklist in `HANDOFF.md` §2 in full, and end your own NEXT INSTRUCTION with this same reminder. Assume your session could end without warning.

---
