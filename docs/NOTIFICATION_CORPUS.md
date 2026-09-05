# NOTIFICATION_CORPUS.md

The payloads the parser must handle, and the source of truth for `gigsim/src/main/assets/payloads.json`.

> **Provenance — read this before you trust anything here.** These payloads are **constructed to be
> realistic**, not captured from live driver accounts (we have none — see ADR-002). They cover the
> shapes real gig notifications take: value in the title, value in bigText, currency before or after
> the number, distance with and without a decimal, pickup distance sometimes present, and the sparse
> "you have a new order" case that carries no numbers at all.
>
> **If anyone on the team can capture a real payload at any point during the event, add it here
> immediately and mark it `[REAL]`.** Real payloads beat constructed ones and they are free corpus.
> A teammate's *customer-side* Swiggy/Zomato/Uber notifications also count and are easy to get.

> **Package names below are `VERIFY`.** It does not block anything: `:gigsim` posts from its own
> package and carries the impersonated app in the notification **channel id**, and
> `EyesUpNotificationListener` resolves the app from the channel id first. Package matching only
> matters if a real gig app is ever installed.

---

## 1. Field extraction targets

| Field | Required for a usable offer | Notes |
|---|---|---|
| `payoutRupees` | **Yes** | Without it there is no rate and the verdict is `UNCLEAR` |
| `tripKm` | **Yes** | The paid distance |
| `pickupKm` | No | Absence means deadhead is treated as 0 — flag it in the UI |
| `etaMinutes` | No | Falls back to `effectiveKm / avgSpeedKmph` |
| `pickupText` / `dropText` | No | Drives the zone lookup; unmatched zone → neutral 0.5 demand |
| `surgeMultiplier` | No | Defaults to 1.0 |

**Parser acceptance target: ≥ 90% of required fields extracted across §2, and 100% on the
"must-parse" payloads marked ★.** The §3 sparse cases must produce a low-confidence offer and never
an exception.

---

## 2. Payloads

Each entry gives `title`, `text`, `bigText` and the expected extraction. `bigText` is what
`BigTextStyle` puts in `EXTRA_BIG_TEXT`; where it is blank the notification is single-line.

### 2.1 Uber — channel `sim_uber`, package `com.ubercab.driver` (VERIFY)

★ **U1 — standard, value in bigText**
```
title:   New trip request
text:    ₹186 · 12.4 km trip
bigText: ₹186 · 12.4 km trip · 3.1 km away · 34 min · Kothrud → Hinjewadi Phase 2
```
→ payout 186, tripKm 12.4, pickupKm 3.1, eta 34, pickup "Kothrud", drop "Hinjewadi Phase 2", RIDE

★ **U2 — surge, currency written as Rs**
```
title:   UberX · 1.6x
text:    Rs 240 for 8.2 km
bigText: Rs 240 for 8.2 km · 2.0 km away · Baner → Viman Nagar
```
→ payout 240, tripKm 8.2, pickupKm 2.0, surge 1.6, RIDE

**U3 — long deadhead, should trigger `LONG_DEADHEAD`**
```
title:   New trip request
text:    ₹95 · 4.0 km trip
bigText: ₹95 · 4.0 km trip · 6.5 km away · 28 min · Wakad → Pimple Saudagar
```
→ payout 95, tripKm 4.0, pickupKm 6.5, eta 28. effectiveKm 10.5, rate ₹9.05/km — a clear SKIP.

### 2.2 Swiggy — channel `sim_swiggy`, package `in.swiggy.deliveryapp` (VERIFY)

★ **S1 — standard food order**
```
title:   New order · Swiggy
text:    ₹64 · 5.8 km
bigText: ₹64 · 5.8 km · Pickup 1.2 km away · Baner Road · Drop: Aundh
```
→ payout 64, tripKm 5.8, pickupKm 1.2, FOOD

**S2 — batched order, two drops**
```
title:   Batched order · 2 drops
text:    ₹118 · 9.4 km total
bigText: ₹118 · 9.4 km total · Pickup 0.8 km · Kalyani Nagar → Yerwada, Vishrantwadi
```
→ payout 118, tripKm 9.4, pickupKm 0.8, FOOD

**S3 — rain/peak bonus appended (two rupee values — the parser must take the total, not the bonus)**
```
title:   New order · Swiggy
text:    ₹72 + ₹15 rain bonus
bigText: ₹87 total · 6.1 km · Pickup 1.5 km away · Koregaon Park
```
→ payout 87, tripKm 6.1, pickupKm 1.5, FOOD
> **Parser note:** prefer a value adjacent to the word `total`. If two payouts are found and one is
> labelled `total`, that one wins. Put this as an earlier-priority pattern in `parsers.json`.

### 2.3 Rapido — channel `sim_rapido`, package `com.rapido.rider` (VERIFY)

★ **R1 — standard bike ride**
```
title:   New ride
text:    ₹142 · 9.0 km
bigText: ₹142 · 9.0 km · 1.8 km to pickup · Shivajinagar → Magarpatta
```
→ payout 142, tripKm 9.0, pickupKm 1.8, RIDE

**R2 — no pickup distance stated**
```
title:   Ride request
text:    ₹58 for 3.4 km
bigText:
```
→ payout 58, tripKm 3.4, pickupKm null, RIDE

**R3 — value only in the title**
```
title:   ₹210 · 14.5 km · Rapido Auto
text:    Tap to accept
bigText:
```
→ payout 210, tripKm 14.5, RIDE

### 2.4 Zomato — channel `sim_zomato`, package `com.application.zomato.rider` (VERIFY)

★ **Z1 — standard**
```
title:   Order available
text:    ₹58 · 4.2 km · 18 min
bigText: ₹58 · 4.2 km · 18 min · Pickup: Deccan · Drop: Shivajinagar
```
→ payout 58, tripKm 4.2, eta 18, FOOD

**Z2 — distance written with "kms"**
```
title:   New delivery
text:    Earn ₹91 · 7 kms
bigText: Earn ₹91 · 7 kms · 2 kms to restaurant · Kharadi
```
→ payout 91, tripKm 7.0, pickupKm 2.0, FOOD
> **Parser note:** the km pattern must accept `km`, `kms`, `KM`, `Km` and an optional space.

### 2.5 Porter — channel `sim_porter`, package `com.theporter.android.driverapp` (VERIFY)

★ **P1 — parcel**
```
title:   New booking · 2 Wheeler
text:    ₹165 · 11.2 km
bigText: ₹165 · 11.2 km · 2.4 km to pickup · Hadapsar → Kharadi · 40 min
```
→ payout 165, tripKm 11.2, pickupKm 2.4, eta 40, PARCEL

---

## 3. Sparse and adversarial — must NOT crash, must produce low confidence

**X1 — no numbers at all**
```
title:   New order!
text:    Tap to view details
```
→ payout null, tripKm null, confidence ≈ 0.05, decision `UNCLEAR`.
Spoken: "Order from Swiggy — details unclear."

**X2 — irrelevant notification from the same app (weekly summary)**
```
title:   Your week on Rapido
text:    You earned ₹4,820 across 61 rides
```
→ Must be **rejected as not an offer**, not parsed as a ₹4,820 ride.
> **Parser note:** require a distance to be present alongside a payout before creating an offer, and
> maintain a `rejectPatterns` list in `parsers.json` (`earned`, `weekly`, `summary`, `payout
> credited`, `rating`, `incentive unlocked`).

**X3 — number formatting with a comma**
```
title:   New booking
text:    ₹1,250 · 48.0 km · Pune → Mumbai outstation
```
→ payout 1250.0, tripKm 48.0. The payout regex must strip commas before parsing.

**X4 — payout in paise-style decimal**
```
title:   New order
text:    Rs.72.50 · 5.5 km
```
→ payout 72.5, tripKm 5.5. `Rs.` with no space must match.

**X5 — a notification with an update to an existing order (dedupe test)**
Post S1 twice within two seconds. The second must be suppressed by the 3-second dedupe on
`(app, hash(title+text))` and must not create a second offer or speak twice.

---

## 4. The STORM script — the arbitration demo

`:gigsim`'s STORM button posts exactly this, in this order:

| t | Payload | Rate (₹/effective km) |
|---|---|---|
| 0.0 s | **S1** Swiggy ₹64 · 5.8 km · 1.2 km pickup | ₹9.14/km |
| 2.5 s | **R1** Rapido ₹142 · 9.0 km · 1.8 km pickup | ₹13.15/km |
| 5.0 s | **U3** Uber ₹95 · 4.0 km · 6.5 km pickup | ₹9.05/km |

Expected behaviour, and what to rehearse:
1. At 0.0 s EyesUp speaks a verdict on S1 alone (a marginal TAKE at market rate).
2. At 2.5 s R1 arrives, scores higher, and EyesUp speaks the **arbitration line**:
   *"Take the Rapido one — ₹142 for 9 kilometres. That's 44% better than the Swiggy order."*
3. At 5.0 s U3 arrives, is beaten by the still-live R1, and is skipped with
   `BEATEN_BY_OTHER_OFFER` + `LONG_DEADHEAD`. EyesUp does not re-announce a winner it already named.

**This is the money moment of the whole demo.** It must be deterministic. Verify the three rates
above by hand against the implemented formula before Eval 1 and adjust the payloads — not the
formula — if the ordering ever comes out ambiguous.

---

## 5. `payloads.json` shape (for `:gigsim`)

```json
{
  "version": 1,
  "payloads": [
    {
      "id": "U1",
      "app": "UBER",
      "channelId": "sim_uber",
      "channelName": "SIM · Uber",
      "title": "New trip request",
      "text": "₹186 · 12.4 km trip",
      "bigText": "₹186 · 12.4 km trip · 3.1 km away · 34 min · Kothrud → Hinjewadi Phase 2",
      "group": "standard"
    }
  ],
  "storm": [
    { "id": "S1", "delayMs": 0 },
    { "id": "R1", "delayMs": 2500 },
    { "id": "U3", "delayMs": 5000 }
  ]
}
```

Keep this file and §2 of this document in sync. If they drift, §2 is the source of truth.
