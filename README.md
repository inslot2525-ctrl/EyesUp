# Sarthi — iQOO City Battles Pune 2026

On-device Android copilot for gig drivers. Reads incoming order notifications at the OS level,
extracts payout / distance / pickup distance with a three-tier on-device NLU cascade, scores each
offer against the driver's own history, earnings goal and drop-zone prospects, **compares it against
every other offer currently live across all their apps**, and speaks a one-line verdict in Marathi,
Hindi or English. Nothing leaves the device.

---

## If you are a human picking this up

Read `driver-copilot-iqoo-pune-gameplan.md` (strategy and schedule), then
`driver-copilot-features-roadmap.md` (what to build, in what order).
The Hour-0 checklist is gameplan §9.

## If you are a Claude Code session picking this up

1. `CLAUDE.md` — standing rules
2. `HANDOFF.md` — live state of the world
3. `PROGRESS.md` — bottom of file; the last `NEXT INSTRUCTION` is your task

Do not skip step 1.

## Repo map

```
CLAUDE.md                              standing rules for every session
HANDOFF.md                             live state, rewritten at every handoff
PROGRESS.md                            append-only work log — the relay's memory
driver-copilot-iqoo-pune-gameplan.md   strategy, rubric, schedule, risk register
driver-copilot-features-roadmap.md     feature tiers + strict build order
docs/ARCHITECTURE.md                   module boundaries, data flow, threading
docs/BUILD_SPEC.md                     exact packages, classes, deps, schemas, formulas
docs/NOTIFICATION_CORPUS.md            payloads to parse against
docs/DEMO_AND_PITCH.md                 90-second script, stage runbook, judge Q&A
docs/RISKS_AND_FALLBACKS.md            decision tree for when things break
docs/DEVICE_AND_TOOLING_SETUP.md       phone, ADB, Office Kit, Funtouch gotchas
docs/DECISIONS.md                      ADR log
assets/config/*.json                   hot-reloadable runtime config
scripts/*.sh                           adb helpers
```

## Two-agent relay

Two Claude Code sessions alternate as usage limits are hit. Coordination is entirely through this
repo — `PROGRESS.md` for what happened, `HANDOFF.md` for what is true now. The protocol is in
`HANDOFF.md` §2. Commit small, push often; an unpushed commit does not exist for the relay.
