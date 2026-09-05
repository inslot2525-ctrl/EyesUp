# HANDOFF.md — Live state of the world

> **You are a Claude Code session picking up a relay build.** Read this file completely before doing
> anything. It takes five minutes and it is always current. Then read the last three entries of
> `PROGRESS.md` and follow the final `➡️ NEXT INSTRUCTION`.
>
> **The session that is ending owns updating this file.** Never leave it stale. If you are about to
> hit your usage limit, updating this file and pushing is more important than finishing your code.

---

## Section 1 — Snapshot (rewrite this section every handoff)

| Field | Value |
|---|---|
| **Last updated** | 2026-09-05 11:05 IST · handbook + feature-list integration |
| **Updated by** | Agent A (Arnav's Claude Code, Opus 5) |
| **Event clock** | **Hacking begins 11:00.** Now in the 11:00-14:00 GREEN window - the longest laptop block before Eval 1 (19:00). |
| **Current phase** | Pre-event / Hour-0 prep |
| **Build state** | **No code exists yet.** Planning and specification only. |
| **Last commit** | `1003921` — spec: Pillion plan, build spec and two-agent relay infrastructure |
| **Latest PROGRESS entry** | `E-002` |
| **Next task** | See `PROGRESS.md` -> E-002 -> NEXT INSTRUCTION. Scaffold Gradle, write `model/` first, then `:gigsim`. |

### What works right now
- Nothing is built. The specification is complete, matches the official handbook, and is internally
  consistent. Feature set decided and tiered; 18 ADRs recorded.

### What is broken or unverified right now
- Everything device-related is **unverified** - we have not touched the loaner phones.
- The Red/Green windows in gameplan §4 are read off a photographed bar chart. The handbook says
  timings may vary and will be announced at the venue. **Confirm and correct in place.**
- The seven track names are unknown.
- All library versions in `docs/BUILD_SPEC.md` are marked `VERIFY` and must be confirmed at first
  Gradle sync.

### Blockers
| ID | Blocker | Owner | Unblocks when |
|---|---|---|---|
| B1 | Git initialised locally and committed, but **no remote is set**, so the relay has no transport | Human | A private GitHub repo exists, `git remote add origin` + `git push -u origin main` is done, and the teammate has cloned it |
| B2 | Loaner device not in hand | Human | Check-in, Sat 08:00 |
| B3 | Neither model file staged | Human | 1B (~550 MB) and 3-4B (~2.5 GB) downloaded and pushed to the phone during the 11:00-14:00 green window (ADR-012) |

---

## Section 2 — How the relay works (stable; do not rewrite)

Two Claude Code sessions alternate as usage limits are hit:

- **Agent A** — Arnav's machine
- **Agent B** — teammate's machine

They never run at the same time on the same files. Coordination is entirely through this repo.

### Ending a session (the outgoing agent's checklist)

1. Finish or cleanly abandon the current edit — never leave a file half-written.
2. Append a `PROGRESS.md` entry using the template, including a complete `➡️ NEXT INSTRUCTION`.
3. Rewrite **Section 1** of this file: snapshot, what works, what is broken, blockers.
4. `git add -A && git commit -m "handoff: <one line>" && git push`
5. Tell the human, in one line: what landed, what is next, and anything they must do by hand.
6. **Confirm your `➡️ NEXT INSTRUCTION` ends with the handoff reminder** (see below). The protocol only
   survives if every session passes it on.

**Every `➡️ NEXT INSTRUCTION` must end with this line, verbatim:**

> **Before you finish:** you own the handoff too. Keep `PROGRESS.md` current as you go, run the
> *Ending a session* checklist in `HANDOFF.md` §2 in full, and end your own NEXT INSTRUCTION with this
> same reminder. Assume your session could end without warning.

**Hand off early rather than late.** Usage limits do not warn you. If you are unsure whether you have
room for one more feature, you do not — write the handoff instead. A clean handoff with a half-finished
feature beats a finished feature the next agent cannot find or trust.

### Starting a session (the incoming agent's checklist)

1. `git pull`
2. Read this file's Section 1.
3. Read the last three entries of `PROGRESS.md`.
4. Read `docs/DECISIONS.md`. Do not reopen a settled decision.
5. `git log --oneline -15` and `git status` — trust the repo over the prose.
6. If `app/` exists, run the build sanity check (`docs/DEVICE_AND_TOOLING_SETUP.md` §7).
7. Start on the last `➡️ NEXT INSTRUCTION` unless the human redirects you.
8. **Accept that you now own the next handoff.** Write your first `PROGRESS.md` entry before you write
   any code, so that even a five-minute session leaves a trace.

### Rules that prevent relay collisions

- **One agent, one module at a time.** Declare the module you are working in at the top of your
  PROGRESS entry. The other agent must not touch it until you log that you are done.
- **Never rename anything** defined in `docs/BUILD_SPEC.md` without adding an ADR in the same commit.
- **Commit small and push often.** An unpushed commit does not exist for the relay.
- **If you find the log and the code disagree, the code is truth** — fix the log immediately and note
  the discrepancy in your entry.

---

## Section 3 — Thirty-second product brief (stable)

**Pillion** is an Android app for gig drivers. It reads incoming order notifications from Uber, Rapido,
Swiggy, Zomato and Porter at the OS level, extracts payout / trip distance / pickup distance / ETA
using a three-tier on-device NLU cascade, scores each offer against the driver's own history, their
daily earnings goal and the drop zone's return prospects, **compares it against every other offer
currently live across all their apps**, and speaks a one-line verdict in Marathi, Hindi or English.
Nothing leaves the device.

The headline feature is the cross-app comparison. Lead with it.

Because we cannot get driver accounts, all input comes from `:gigsim`, a second APK that posts
genuine Android notifications carrying realistic gig-app payloads. This is disclosed openly on stage:
it exercises the real notification pipeline, and it makes the demo repeatable.

---

## Section 4 — Where to find things (stable)

| I need... | Read |
|---|---|
| Standing rules for every session | `CLAUDE.md` |
| What happened and what to do next | `PROGRESS.md` (bottom) |
| Strategy, schedule, risks | `driver-copilot-iqoo-pune-gameplan.md` |
| Feature tiers and build order | `driver-copilot-features-roadmap.md` |
| Module boundaries and data flow | `docs/ARCHITECTURE.md` |
| Exact class names, deps, schemas | `docs/BUILD_SPEC.md` |
| Payloads to parse against | `docs/NOTIFICATION_CORPUS.md` |
| Pitch, stage runbook, judge Q&A | `docs/DEMO_AND_PITCH.md` |
| What to do when something breaks | `docs/RISKS_AND_FALLBACKS.md` |
| Phone/laptop/Office Kit setup | `docs/DEVICE_AND_TOOLING_SETUP.md` |
| Why a decision was made | `docs/DECISIONS.md` |
| Runtime-tunable values | `assets/config/*.json` |

---

## Section 5 — Environment facts (update when they change)

| Thing | Value |
|---|---|
| Primary working dir | `C:\Projects\iqoo` |
| Platform | Windows 11, PowerShell + Git Bash both available |
| Git remote | *(not set — see B1)*  ·  local branch: `main`, 1 commit |
| Loaner device model | *(fill in at check-in)* |
| Android version / OS skin | *(fill in — expect Funtouch OS)* |
| Device serial for `adb -s` | *(fill in)* |
| Android Studio version | *(fill in)* |
| JDK version | *(fill in — 17 expected)* |
| Gemma model path (laptop) | *(fill in)* |
| Gemma model path (device) | `/sdcard/Android/data/com.pillion.app/files/llm/model.task` — app-private external dir, readable by the app on every target API level. Do **not** use `/data/local/tmp/`; it is not readable by a normal app on all ROMs. |
| Config dir on device | `/sdcard/Pillion/config/` — falls back to `/sdcard/Android/data/com.pillion.app/files/config/` if scoped storage blocks it (`scripts/push-config.sh` detects this and tells you) |
