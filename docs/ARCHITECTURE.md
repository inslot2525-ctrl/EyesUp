# ARCHITECTURE.md — Pillion

Module boundaries, data flow, threading and ownership. This is the *why and where*.
`BUILD_SPEC.md` is the *exactly what*. Read this first, then that.

---

## 1. Design principles

1. **Everything on-device.** No network calls at all. Not for models, not for analytics, not for
   crash reporting. This is the privacy story and it is also why the app works in a basement parking
   lot. Anything that needs the internet is out of scope by definition.
2. **Every stage degrades, none of them throws.** A missing payout does not kill the pipeline; it
   produces a low-confidence offer that the UI badges and the scorer treats cautiously. A hackathon
   demo dies from an unhandled exception, never from a missing field.
3. **Tunables live in JSON on the device, not in Kotlin.** Regexes, benchmarks, weights, TTLs and
   speech templates all load from `/sdcard/Pillion/config/`. Changing behaviour must never require a
   rebuild — that is what makes Red Light productive.
4. **One-way data flow.** Capture → Parse → Queue → Score → Speak. The only feedback edge is the
   driver's accept/reject updating the threshold. No module reaches backwards.
5. **Each module is independently testable with a plain Kotlin unit test.** No module except Capture
   and Speak needs Android to be exercised. That is what lets two agents work in parallel.

---

## 2. Data flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│ :gigsim (separate APK, com.pillion.gigsim)                                │
│   Buttons: one per corpus payload, plus "STORM" (3 offers in 6s)         │
│   Posts real NotificationCompat notifications on per-app channels        │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │  Android OS notification bus
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ [1] CAPTURE  ·  com.pillion.app.capture                               │
│     PillionNotificationListener : NotificationListenerService             │
│     onNotificationPosted → filter by allow-listed package                │
│     → read extras: title, text, bigText, subText, infoText               │
│     → emit NotificationEvent onto a SharedFlow                           │
│     Also: dedupe by (package, title+text hash) within 3s                 │
└──────────────────────────────┬───────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ [2] PARSE  ·  com.pillion.app.parse                                   │
│     ParserCascade.parse(event) : OrderOffer                              │
│                                                                          │
│       Tier A  RegexParser        ~1ms    patterns from parsers.json      │
│                 │ confidence >= 0.75 ──────────────► return              │
│                 ▼ else, merge what it did find                           │
│       Tier B  EntityParser       ~40ms   ML Kit Entity Extraction        │
│                 │ confidence >= 0.60 ──────────────► return              │
│                 ▼ else                                                   │
│       Tier C  LlmParser          ~1-3s   MediaPipe Gemma3-1B-int4        │
│                 │ 3s timeout ──────────► return best-effort merge        │
│                                                                          │
│     Each tier fills only the fields still null. Confidence is the        │
│     fraction of required fields present, weighted by tier reliability.   │
└──────────────────────────────┬───────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ [3] QUEUE  ·  com.pillion.app.queue                                   │
│     OfferQueue — every live offer across every app                       │
│     Each offer has expiresAt = receivedAt + ttlSeconds(app)              │
│     Expired offers are swept every 1s                                    │
│     Exposes StateFlow<List<OrderOffer>> of live offers                   │
└──────────────────────────────┬───────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ [4] SCORE  ·  com.pillion.app.score                                   │
│     ScoringEngine.evaluate(offer, liveOffers, profile, clock) : Verdict  │
│       · effectiveKm = tripKm + pickupKm       (deadhead counted)         │
│       · ratePerKm   = payout / effectiveKm                               │
│       · benchmark   = scoring.json[hourBucket][offerKind]                │
│       · terms: rate, timeEfficiency, goalUrgency, zoneReturn, surge      │
│       · compare against every live offer → BEST / BEATEN_BY              │
│       · compare score against DriverProfile.threshold (EWMA)             │
│       → Verdict(decision, score, ratePerKm, reasons[], comparedAgainst[])│
└──────────────────────────────┬───────────────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ [5] SPEAK  ·  com.pillion.app.voice                                   │
│     VerdictPhraser: Verdict + Lang → String, from tts_templates.json     │
│     TtsSpeaker: android.speech.tts.TextToSpeech                          │
│       · AudioAttributes USAGE_ASSISTANCE_NAVIGATION_GUIDANCE (ducks      │
│         music instead of stopping it — matters for a real driver)        │
│       · QUEUE_FLUSH on a new higher-priority verdict                     │
└──────────────────────────────────────────────────────────────────────────┘
                               ▲
┌──────────────────────────────┴───────────────────────────────────────────┐
│ [6] LEARN  ·  com.pillion.app.score.DriverProfile                     │
│     accept → acceptedEwma updated with this offer's score                │
│     reject → rejectedEwma updated with this offer's score                │
│     threshold = midpoint(acceptedEwma, rejectedEwma), clamped            │
│     Persisted as JSON. Rendered as a moving bar in the UI.               │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ [7] VOICE IN  ·  com.pillion.app.voice.VoiceCommandListener           │
│     On-device SpeechRecognizer, push-to-talk                             │
│     Intents: WHY · REPEAT · ACCEPT · SKIP · STATUS                       │
│     WHY → speaks the last Verdict's reasons in full                      │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Threading

| Where | Thread | Why |
|---|---|---|
| `onNotificationPosted` | Binder/main | Must return in milliseconds. Only builds a `NotificationEvent` and emits to a flow. **No parsing here.** |
| Tier A regex | `Dispatchers.Default` | Pure CPU, microseconds |
| Tier B ML Kit | `Dispatchers.Default`, suspending | ML Kit is async; wrap in `suspendCancellableCoroutine` |
| Tier C LLM | dedicated single-thread dispatcher | `LlmInference` is not thread-safe and must be a singleton. One inference at a time, 3 s timeout, cancellable |
| Scoring | `Dispatchers.Default` | Pure function, trivially testable |
| TTS | main | `TextToSpeech` wants a main-thread-created instance |
| UI | main, Compose collecting `StateFlow` | |

The pipeline runs in a `PillionPipeline` singleton owned by the Application, on a
`CoroutineScope(SupervisorJob() + Dispatchers.Default)`. The listener service and the UI both talk to
it. This means the pipeline keeps working with no Activity on screen — which is the actual use case,
since the driver's screen is showing Uber, not us.

---

## 4. Persistence

No database. Three JSON files under `filesDir`:

| File | Contents | Written when |
|---|---|---|
| `profile.json` | thresholds, EWMAs, language, daily goal, today's earnings | after every accept/reject |
| `history.json` | last 200 `(offer, verdict, decision)` triples | after every decision |
| `session.json` | shift start time, offers seen, offers taken | on change |

Config is read from `/sdcard/Pillion/config/` if present, otherwise from bundled assets. See
`BUILD_SPEC.md` §7. On first run the app copies its bundled assets to `/sdcard/Pillion/config/` so
there is something to edit.

---

## 5. Module ownership — how two agents avoid collisions

Declare your module at the top of your PROGRESS entry. These boundaries are chosen so that two people
can work simultaneously with essentially zero shared files.

| Module | Package | Depends on | Can be built and tested standalone? |
|---|---|---|---|
| sim | `com.pillion.gigsim` (separate module) | corpus JSON | Yes — it is a whole separate app |
| capture | `com.pillion.app.capture` | model | Needs a device; test with `:gigsim` |
| parse | `com.pillion.app.parse` | model, config | **Yes** — pure unit tests against the corpus |
| queue | `com.pillion.app.queue` | model | **Yes** — pure unit tests with a fake clock |
| score | `com.pillion.app.score` | model, config | **Yes** — pure unit tests |
| voice | `com.pillion.app.voice` | model, config | Needs a device for TTS/ASR |
| ui | `com.pillion.app.ui` | everything | Compose previews |
| model | `com.pillion.app.model` | nothing | **Shared — change only with an ADR** |

`model` is the one shared surface. It holds the data classes and nothing else. Because it is shared,
any change to it must be committed on its own, pushed immediately, and announced in PROGRESS.

**Suggested split for a two-person / two-agent team:**
- Track 1: sim → capture → ui (device-facing, Red Light friendly)
- Track 2: parse → queue → score (pure logic, unit-testable, laptop friendly)
- They meet at `model`, which is written once, first, before either track starts.

---

## 6. Failure modes and how the architecture absorbs them

| Failure | What the architecture does |
|---|---|
| Notification has no parseable numbers | Offer created with nulls, confidence low, UI badges it "unclear", scorer returns `UNKNOWN` and the speaker says "Order from Swiggy, details unclear" |
| ML Kit model not downloaded yet | Tier B is skipped; cascade falls through to Tier C or returns Tier A's partial result |
| Gemma fails to load | `LlmParser.isAvailable = false` at init; the cascade never calls it; app is fully functional |
| TTS locale missing | `TtsSpeaker` falls back down a chain `mr-IN → hi-IN → en-IN → en-US`, and the UI shows which language is actually speaking |
| Listener killed by the OS | Foreground service + a heartbeat that logs; the UI shows a red "listener not connected" banner so it is never a silent failure on stage |
| Two offers tie | Deterministic tiebreak: higher `ratePerKm`, then earlier `receivedAt`. Never random — a demo must be repeatable |

---

## 7. What is deliberately not in this architecture

- No dependency-injection framework. Manual construction in `PillionApplication`. Hilt costs more than
  it returns on a 30-hour clock.
- No Room, no SQLite. See ADR-006.
- No network layer of any kind. There is nothing to configure and nothing to fail.
- No multi-module split beyond `:app` and `:gigsim`. Package boundaries are enough; Gradle module
  boundaries would cost build time we do not have.
- No `WorkManager`. Nothing here is deferrable — an offer expires in 30 seconds.
