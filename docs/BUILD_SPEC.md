# BUILD_SPEC.md — the exact thing to build

**This file is binding.** Every package, class, function and JSON key you need is named here. Do not
invent alternatives — two agents inventing `Order` and `OrderOffer` for the same concept is the
fastest way to make this relay painful.

If you need a new name, **add it to this file in the same commit** that introduces it.

Markers used below:
- `VERIFY` — a version or API surface that could not be confirmed without the toolchain. Confirm at
  first Gradle sync, correct in place, and note it in your PROGRESS entry.

---

## 1. Identity

| Thing | Value |
|---|---|
| Root Gradle project | `eyesup` |
| Main app module | `:app` — applicationId `com.eyesup.app` |
| Simulator module | `:gigsim` — applicationId `com.eyesup.gigsim` |
| App display name | `EyesUp` |
| Simulator display name | `EyesUp GigSim` |
| minSdk | 26 |
| targetSdk / compileSdk | 35 |
| Kotlin JVM target | 17 |
| Language | Kotlin only. No Java files. |
| UI | Jetpack Compose, Material 3 |

---

## 2. Gradle scaffolding

`settings.gradle.kts`:
```kotlin
rootProject.name = "eyesup"
include(":app", ":gigsim")
```

`:app` dependencies — `VERIFY` every version at first sync:
```kotlin
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")                      // VERIFY
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")     // VERIFY
    implementation("androidx.activity:activity-compose:1.9.2")           // VERIFY
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))  // VERIFY
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")   // VERIFY
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")   // VERIFY
    implementation("androidx.datastore:datastore-preferences:1.1.1")           // VERIFY

    // Tier B — on-device entity extraction (offline model, small)
    implementation("com.google.mlkit:entity-extraction:16.0.0-beta5")          // VERIFY

    // Tier C — on-device LLM. Add ONLY when you reach build-order step 11.
    // implementation("com.google.mediapipe:tasks-genai:0.10.24")              // VERIFY

    // T3.3 stretch — face landmarks
    // implementation("com.google.mediapipe:tasks-vision:0.10.14")             // VERIFY

    testImplementation("junit:junit:4.13.2")
}
```

Also apply the `kotlinx-serialization` plugin. `:gigsim` needs only core-ktx, Compose and
kotlinx-serialization.

> **Adding `tasks-genai` roughly doubles APK size and Gradle sync time. Do not add it until step 11.**
> If it breaks the build, the correct move is to remove it and move on — see `RISKS_AND_FALLBACKS.md`
> §3.

---

## 3. Package layout (`:app`)

```
com.eyesup.app
├── EyesUpApplication.kt          // constructs the pipeline singleton
├── model/                        // SHARED — change only with an ADR
│   ├── NotificationEvent.kt
│   ├── OrderOffer.kt
│   ├── Verdict.kt
│   ├── GigApp.kt
│   ├── Enums.kt                  // OfferKind, Decision, ReasonCode, ExtractionMethod, Lang
│   └── DriverProfile.kt
├── config/
│   ├── ConfigRepository.kt       // load + hot reload from /sdcard/EyesUp/config/
│   ├── ParsersConfig.kt
│   ├── ScoringConfig.kt
│   └── TtsTemplatesConfig.kt
├── capture/
│   ├── EyesUpNotificationListener.kt
│   └── NotificationEventBus.kt   // MutableSharedFlow<NotificationEvent>
├── parse/
│   ├── ParserCascade.kt
│   ├── RegexParser.kt            // Tier A
│   ├── EntityParser.kt           // Tier B, ML Kit
│   ├── LlmParser.kt              // Tier C, MediaPipe
│   └── ParseUtil.kt              // number/currency/unit normalisation
├── queue/
│   └── OfferQueue.kt
├── score/
│   ├── ScoringEngine.kt
│   ├── ProfileRepository.kt
│   └── ZoneTable.kt
├── voice/
│   ├── TtsSpeaker.kt
│   ├── VerdictPhraser.kt
│   └── VoiceCommandListener.kt
├── pipeline/
│   └── EyesUpPipeline.kt         // wires 1→2→3→4→5, owns the CoroutineScope
└── ui/
    ├── MainActivity.kt
    ├── HomeScreen.kt             // offer cards + threshold bar + listener status
    ├── OfferCard.kt
    ├── SettingsScreen.kt         // language, daily goal, reload config
    └── theme/
```

---

## 4. Data model — copy these verbatim

```kotlin
// model/GigApp.kt
enum class GigApp(val pkg: String, val label: String, val defaultTtlSeconds: Int) {
    UBER   ("com.ubercab.driver",        "Uber",   25),
    RAPIDO ("com.rapido.rider",          "Rapido", 20),
    SWIGGY ("in.swiggy.deliveryapp",     "Swiggy", 45),
    ZOMATO ("com.application.zomato.rider","Zomato",45),
    PORTER ("com.theporter.android.driverapp","Porter",30),
    UNKNOWN("",                          "Unknown",30);

    companion object {
        // :gigsim posts from com.eyesup.gigsim; the channel id carries the impersonated app,
        // so resolution must check the channel id first, then the package.
        fun fromChannelOrPackage(channelId: String?, pkg: String): GigApp = ...
    }
}
```

```kotlin
// model/Enums.kt
enum class OfferKind { RIDE, FOOD, PARCEL, UNKNOWN }
enum class Decision  { TAKE, SKIP, BEST_OF_N, UNCLEAR }
enum class ExtractionMethod { REGEX, ENTITY, LLM, MIXED, NONE }
enum class Lang { EN, HI, MR }

enum class ReasonCode {
    GOOD_RATE, POOR_RATE,
    LONG_DEADHEAD,            // pickup distance is a big share of effectiveKm
    BEATS_OTHER_OFFER,        // beat something else live
    BEATEN_BY_OTHER_OFFER,
    SURGE_ACTIVE,
    GOAL_URGENT,              // behind on the daily target, late in the shift
    GOAL_MET,
    DEAD_DROP_ZONE,           // drops you where nothing comes back
    HOT_DROP_ZONE,
    ABOVE_YOUR_THRESHOLD, BELOW_YOUR_THRESHOLD,
    LOW_CONFIDENCE
}
```

```kotlin
// model/NotificationEvent.kt
@Serializable
data class NotificationEvent(
    val id: String,               // UUID
    val sourcePackage: String,    // the posting package (com.eyesup.gigsim in the demo)
    val channelId: String?,
    val app: GigApp,              // resolved gig app
    val title: String?,
    val text: String?,
    val bigText: String?,
    val subText: String?,
    val postedAt: Long,           // epoch millis
) {
    val fullText: String get() = listOfNotNull(title, text, bigText, subText).joinToString(" · ")
}
```

```kotlin
// model/OrderOffer.kt
@Serializable
data class OrderOffer(
    val id: String,
    val app: GigApp,
    val kind: OfferKind,
    val payoutRupees: Double?,
    val tripKm: Double?,
    val pickupKm: Double?,
    val etaMinutes: Int?,
    val pickupText: String?,
    val dropText: String?,
    val surgeMultiplier: Double?,
    val extractedBy: ExtractionMethod,
    val confidence: Float,        // 0f..1f
    val receivedAt: Long,
    val expiresAt: Long,
    val rawEventId: String,
) {
    val effectiveKm: Double? get() =
        tripKm?.let { it + (pickupKm ?: 0.0) }
    val ratePerKm: Double? get() =
        payoutRupees?.let { p -> effectiveKm?.takeIf { it > 0.1 }?.let { p / it } }
    fun isLive(now: Long) = now < expiresAt
}
```

```kotlin
// model/Verdict.kt
@Serializable
data class Verdict(
    val offerId: String,
    val decision: Decision,
    val score: Double,            // 0..100
    val threshold: Double,        // the driver's threshold at decision time
    val ratePerKm: Double?,
    val reasons: List<ReasonCode>,
    val comparedAgainst: List<String>,   // offer ids considered
    val beatenBy: String?,               // offer id, if any
    val createdAt: Long,
)
```

```kotlin
// model/DriverProfile.kt
@Serializable
data class DriverProfile(
    val lang: Lang = Lang.EN,
    val dailyGoalRupees: Double = 1200.0,
    val earnedTodayRupees: Double = 0.0,
    val shiftStartEpoch: Long = 0L,
    val shiftEndHour: Int = 23,          // local hour the driver plans to stop
    val acceptedScoreEwma: Double = 60.0,
    val rejectedScoreEwma: Double = 40.0,
    val ewmaAlpha: Double = 0.25,
    val acceptCount: Int = 0,
    val rejectCount: Int = 0,
) {
    val threshold: Double get() =
        ((acceptedScoreEwma + rejectedScoreEwma) / 2.0).coerceIn(20.0, 85.0)
}
```

---

## 5. The scoring formula — implement exactly this

`ScoringEngine.evaluate(offer, liveOffers, profile, config, nowMillis): Verdict`

```
1. If offer.payoutRupees == null || offer.effectiveKm == null:
       return Verdict(UNCLEAR, score = 0.0, reasons = [LOW_CONFIDENCE])

2. rate        = offer.ratePerKm
   benchmark   = config.benchmarkFor(hourBucket(now), offer.kind)     // ₹/km
   rateTerm    = clamp(rate / benchmark, 0.0, 2.0)                    // 1.0 == market rate

3. minutes     = offer.etaMinutes ?: estimateMinutes(offer.effectiveKm, config.avgSpeedKmph)
   hourlyRate  = offer.payoutRupees / (minutes / 60.0)
   timeTerm    = clamp(hourlyRate / config.targetHourlyRupees, 0.0, 2.0)

4. deadheadShare = (offer.pickupKm ?: 0.0) / offer.effectiveKm
   deadheadPenalty = if (deadheadShare > config.deadheadWarnShare) -config.deadheadPenalty else 0.0
       // and add ReasonCode.LONG_DEADHEAD

5. remaining   = max(0.0, profile.dailyGoalRupees - profile.earnedTodayRupees)
   hoursLeft   = max(0.5, profile.shiftEndHour - currentHourFraction)
   needPerHour = remaining / hoursLeft
   goalTerm    = clamp(needPerHour / config.targetHourlyRupees, 0.0, 1.5)
       // high goalTerm == behind schedule == be less picky
       // reason GOAL_URGENT if goalTerm > 1.2, GOAL_MET if remaining == 0.0

6. zoneTerm    = config.zoneTable.demandAt(offer.dropZone, hourBucket(now))   // 0.0..1.0
       // reason DEAD_DROP_ZONE if < 0.3, HOT_DROP_ZONE if > 0.75

7. surgeTerm   = (offer.surgeMultiplier ?: 1.0) - 1.0    // 0.0 when no surge

raw = config.wRate      * rateTerm
    + config.wTime      * timeTerm
    + config.wGoal      * goalTerm
    + config.wZone      * zoneTerm
    + config.wSurge     * surgeTerm
    + deadheadPenalty

score = clamp(raw * 50.0, 0.0, 100.0)      // weights sum to ~2.0 → mid-market lands near 50-60

8. CROSS-APP ARBITRATION — the headline feature
   rivals = liveOffers.filter { it.id != offer.id && it.isLive(now) }
   best   = rivals.maxByOrNull { scoreOf(it) }
   if (best != null && scoreOf(best) > score * config.arbitrationMargin)   // margin default 1.10
       decision = SKIP; beatenBy = best.id; reasons += BEATEN_BY_OTHER_OFFER
   else if (rivals.isNotEmpty() && score > threshold)
       decision = BEST_OF_N; reasons += BEATS_OTHER_OFFER
   else
       decision = if (score >= profile.threshold) TAKE else SKIP
       reasons += if (score >= threshold) ABOVE_YOUR_THRESHOLD else BELOW_YOUR_THRESHOLD

9. Deterministic tiebreak when scores are equal: higher ratePerKm, then earlier receivedAt.
   NEVER random — the demo must be repeatable.
```

**Learning update** (`ProfileRepository.recordDecision`):
```
accept: acceptedScoreEwma = α * score + (1-α) * acceptedScoreEwma ; acceptCount++
reject: rejectedScoreEwma = α * score + (1-α) * rejectedScoreEwma ; rejectCount++
threshold is derived, always the clamped midpoint — never stored directly
```
The UI renders `threshold` as a bar. Rejecting two decent offers must visibly move it. Verify this
by hand before the demo — it is a scripted stage moment.

---

## 6. Parser cascade contract

```kotlin
interface OfferParser {
    val method: ExtractionMethod
    suspend fun parse(event: NotificationEvent, partial: OrderOffer?): OrderOffer?
}
```

`ParserCascade.parse(event)`:
1. `RegexParser` → if `confidence >= 0.75`, return.
2. `EntityParser` (skip if ML Kit model unavailable) — fill only null fields → if `>= 0.60`, return.
3. `LlmParser` (skip if unavailable) — 3 s `withTimeoutOrNull` — fill only null fields.
4. Return the merged result with `extractedBy = MIXED` if more than one tier contributed.

**Confidence** = weighted fraction of fields present:
`payout 0.40 · tripKm 0.30 · pickupKm 0.15 · eta 0.10 · kind 0.05`, then multiplied by the tier
reliability of the *lowest* tier that contributed: `REGEX 1.0 · ENTITY 0.9 · LLM 0.8`.

### Tier C prompt (LlmParser) — use exactly this

```
You extract structured data from Indian gig-work notifications. Reply with ONLY a JSON object,
no prose, no markdown fence.

Schema:
{"payout": number|null, "trip_km": number|null, "pickup_km": number|null,
 "eta_min": number|null, "pickup": string|null, "drop": string|null,
 "kind": "RIDE"|"FOOD"|"PARCEL"|null, "surge": number|null}

Rules: payout is rupees as a number, no symbol. trip_km is the distance being paid for.
pickup_km is the distance to reach the pickup. Use null for anything not stated.

Notification: <<<{TEXT}>>>
JSON:
```
Config: `temperature = 0.0`, `topK = 1`, `maxTokens = 128`. Strip anything before the first `{` and
after the last `}` before parsing. Any parse failure returns null — never throws.

---

## 7. Config files — schema and location

Bundled at `app/src/main/assets/config/*.json`. On first run, `ConfigRepository` copies them to
`/sdcard/EyesUp/config/`. Thereafter that directory wins, so it can be edited on the phone. The
Settings screen has a **Reload config** button that re-reads without restarting the app. A malformed
file falls back to the bundled asset and shows a toast — **never crashes**.

Seed contents live in `assets/config/` at the repo root; copy them into `app/src/main/assets/config/`
when you scaffold the module.

### `parsers.json`
```json
{
  "version": 1,
  "apps": {
    "RAPIDO": {
      "ttlSeconds": 20,
      "kind": "RIDE",
      "patterns": {
        "payout":   ["(?:₹|Rs\\.?\\s?)\\s*([0-9]{2,5}(?:\\.[0-9]{1,2})?)"],
        "tripKm":   ["(?:drop|trip|ride)[^0-9]{0,15}([0-9]+(?:\\.[0-9])?)\\s*(?:km|KM)"],
        "pickupKm": ["([0-9]+(?:\\.[0-9])?)\\s*(?:km|KM)\\s*(?:away|to pickup)"],
        "etaMin":   ["([0-9]{1,3})\\s*min"]
      }
    }
  }
}
```
Named-group-free by design: group 1 is always the value. Multiple patterns per field are tried in
order; first match wins.

### `scoring.json`
Keys consumed by `ScoringConfig`: `benchmarkRupeesPerKm` (by hour bucket × offer kind),
`targetHourlyRupees`, `avgSpeedKmph`, `deadheadWarnShare`, `deadheadPenalty`, `arbitrationMargin`,
weights `wRate`/`wTime`/`wGoal`/`wZone`/`wSurge`, and `zones` (Pune zone × hour-bucket demand 0–1).

Hour buckets: `EARLY` 05–08, `MORNING` 08–12, `AFTERNOON` 12–17, `EVENING` 17–21, `NIGHT` 21–05.

### `tts_templates.json`
Keyed `lang → templateKey → string`, with `{app} {payout} {km} {rate} {rival} {pct}` placeholders.
Template keys map 1:1 to `Decision` plus a short phrase per `ReasonCode`.

---

## 8. `:gigsim` spec

A single Compose screen. One button per corpus payload, grouped by app, plus:

- **STORM** — posts three offers from three different apps at t=0s, t+2.5s, t+5s. The arbitration demo.
- **SPARSE** — posts the deliberately unparseable payloads, to show graceful degradation.
- **CLEAR ALL** — cancels every posted notification.

Implementation notes:
- One `NotificationChannel` per impersonated app, `channelId = "sim_uber"`, `"sim_rapido"`, etc.
  `EyesUpNotificationListener` resolves the `GigApp` from the channel id.
- Channel *name* must read `SIM · Rapido`, not `Rapido`. **We do not impersonate real companies; we
  label the simulation honestly.** A judge who pulls down the shade sees the truth.
- Use `NotificationCompat.BigTextStyle` so `EXTRA_BIG_TEXT` is populated — several corpus payloads
  put the detail there, exactly like the real apps.
- Payloads are read from `gigsim/src/main/assets/payloads.json`, generated from
  `docs/NOTIFICATION_CORPUS.md`. Editing the corpus and the JSON together keeps them honest.
- Requires `POST_NOTIFICATIONS` runtime permission on API 33+. Ask on first launch.

---

## 9. Manifest essentials (`:app`)

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
<uses-permission android:name="android.permission.CAMERA"/>          <!-- T3.3 only -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"/>

<service
    android:name=".capture.EyesUpNotificationListener"
    android:exported="true"
    android:label="EyesUp"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService"/>
    </intent-filter>
</service>
```

Open the grant screen with
`Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")`.
Check whether it is granted with
`NotificationManagerCompat.getEnabledListenerPackages(context).contains(packageName)`.

**On API 33+, writing to `/sdcard/EyesUp/` needs `MANAGE_EXTERNAL_STORAGE` or the app-specific
external dir.** `VERIFY` on the device. If scoped storage blocks it, use
`getExternalFilesDir(null)` → `/sdcard/Android/data/com.eyesup.app/files/config/` instead and
update every reference to the config path in one commit.

---

## 10. Tests worth writing (and only these)

| Test | Why |
|---|---|
| `RegexParserTest` — every corpus payload, expected fields | This is the one that saves you on stage |
| `ScoringEngineTest` — a known offer scores in an expected band; a worse rival flips the decision | The arbitration logic is the pitch |
| `OfferQueueTest` — TTL expiry with an injected clock | Silent bugs here look like "the demo randomly didn't work" |
| `VerdictPhraserTest` — every `Decision` × every `Lang` produces a non-empty string with no leftover `{placeholder}` | An unrendered `{payout}` spoken aloud on stage is unrecoverable |

No UI tests. No instrumentation tests. There is not time and they will not pay for themselves.

---

## 11. Definition of "the build is healthy"

```bash
./gradlew :app:assembleDebug :gigsim:assembleDebug
./gradlew :app:testDebugUnitTest
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb install -r gigsim/build/outputs/apk/debug/gigsim-debug.apk
adb shell am start -n com.eyesup.app/.ui.MainActivity
```
All five succeed → healthy. Run this before every handoff and record the result in your PROGRESS
entry.
