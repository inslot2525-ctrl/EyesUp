# DEVICE_AND_TOOLING_SETUP.md

Everything about the physical setup. Run §1–§6 in the first hour on site; §8 runs all weekend.

---

## 1. Loaner phone — first fifteen minutes

- [ ] Record the exact model and Android/Funtouch version in `HANDOFF.md` §5
- [ ] Settings → About phone → tap **Build number** 7× → developer options unlocked
- [ ] Developer options → **USB debugging** on
- [ ] Developer options → **Stay awake while charging** on (you will thank yourself at 3 a.m.)
- [ ] Plug into the laptop, accept the RSA fingerprint prompt on the phone
- [ ] `adb devices` → shows `device`, not `unauthorized`. Record the serial in `HANDOFF.md` §5
- [ ] `adb shell getprop ro.product.model` and `adb shell getprop ro.build.version.release`
- [ ] Set a screen timeout of at least 5 minutes
- [ ] Turn **off** any battery saver mode

---

## 2. ADB over Wi-Fi (do this — it survives cable problems and frees the port for charging)

```bash
adb tcpip 5555
adb shell ip route            # read the phone's IP off the last line
adb connect <PHONE_IP>:5555
adb devices                   # should now list <PHONE_IP>:5555
```
Record the IP in `HANDOFF.md` §5. If the phone changes networks you must redo this.

---

## 3. Text-to-speech voice packs — do this early, on quiet Wi-Fi

Settings → Additional settings → **Text-to-speech output** (path varies on Funtouch; also reachable
via Accessibility).

- [ ] Engine: Google Text-to-speech / Speech Services by Google
- [ ] Install voice data for **en-IN**, **hi-IN**, **mr-IN**
- [ ] Tap "Listen to an example" for each and confirm audio actually plays
- [ ] Record in `PROGRESS.md` which locales are genuinely present

If `mr-IN` is unavailable, that is R4 — demo in Hindi and say so honestly. Do not fake it by feeding
Marathi text to a Hindi voice without saying so; the pronunciation will be audibly wrong to a Pune
jury, which is worse than not having it.

---

## 4. Funtouch OS background-kill settings — the highest-value ten minutes of the event

A vivo/iQOO ROM will kill a notification listener within minutes unless you do all of this. Menu
names vary by version; hunt for the equivalent.

- [ ] Settings → Battery → **High background power consumption** → allow EyesUp
- [ ] Settings → Battery → Background power consumption management → EyesUp → **Allow high background
      power consumption** / **Don't optimise**
- [ ] Settings → Apps → Special app access → **Autostart** → enable EyesUp
- [ ] Settings → Apps → EyesUp → Battery → **Unrestricted**
- [ ] Recent apps → swipe up to reveal the card menu → **Lock** the EyesUp card
- [ ] Settings → Apps → Special app access → **Notification access** → enable EyesUp
- [ ] Settings → Apps → Special app access → **Display over other apps** → enable (needed if you add
      an overlay later; harmless now)

**Then run the verification test and log the result:**
1. Post a `:gigsim` notification. Confirm EyesUp captures it.
2. Lock the screen. Wait **10 minutes**, untouched.
3. Post another `:gigsim` notification without unlocking.
4. Unlock. Did EyesUp capture the second one?

**If the answer is no, the demo is not safe and this is your top priority.** Re-check the list,
reboot, and add the foreground service. Record the result in `PROGRESS.md` either way.

---

## 5. Laptop toolchain

- [ ] Android Studio opens; JDK 17 selected; `adb` on PATH (`adb --version`)
- [ ] Gradle sync succeeds on a throwaway empty project — proves the environment before you blame
      your own code
- [ ] Emulator **not** running. It eats RAM you need and you are testing on a real device anyway
- [ ] Git configured: `git config user.name` and `user.email` set on both machines

---

## 6. Model and config staging

```bash
# Config — run this whenever you change assets/config/*.json on the laptop
bash scripts/push-config.sh

# Gemma model — only at build-order step 11
bash scripts/push-model.sh ~/models/gemma3-1b-it-int4.task
```

The Gemma `.task` file is roughly 550 MB. **It must be on the laptop before you arrive.** Pushing it
over USB takes about a minute; downloading it on venue Wi-Fi may take an hour or may not finish.

---

## 7. Build sanity check — run before every handoff

```bash
./gradlew :app:assembleDebug :gigsim:assembleDebug
./gradlew :app:testDebugUnitTest
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb install -r gigsim/build/outputs/apk/debug/gigsim-debug.apk
adb shell am start -n com.eyesup.app/.ui.MainActivity
```

Paste the result — pass or the actual error — into your `PROGRESS.md` entry. "It built fine" without
the command output is not a verification.

Useful during development:
```bash
adb logcat -c && adb logcat | grep -E "EyesUp|AndroidRuntime"
adb shell dumpsys notification | grep -i eyesup        # is the listener bound?
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
```

---

## 8. Office Kit — this is 10% of the score, treat it as a scheduled task

Office Kit (pc.vivoglobal.com) bridges the phone and the laptop: screen mirroring, remote control,
clipboard sync, file transfer. **Usage is measured by HackTracker from device data, so it cannot be
recovered by mentioning it in the pitch.**

### Setup, before hacking starts
- [ ] Installed on the laptop, phone app present, both on the same Wi-Fi, paired
- [ ] **Screen mirror** — phone screen visible on the laptop
- [ ] **Remote control** — control the laptop *from the phone*. This is the important direction:
      it is what makes Red Light productive
- [ ] **Clipboard sync** — copy on the phone, paste on the laptop, and back
- [ ] **File transfer** — move a file each way
- [ ] Time yourself doing each once. Under pressure you want this to be muscle memory

### Discipline during the event

| When | Do |
|---|---|
| Every Red Light window | Drive Android Studio on the laptop *through* Office Kit remote control. Real work and telemetry at the same time |
| Every config change | Move `parsers.json` / `scoring.json` between devices via Office Kit file transfer instead of `adb push`, at least some of the time |
| Every log you need to read | Copy the logcat line to the laptop with clipboard sync |
| Every Green Light hour | Keep the mirror session **open**, even when working on the laptop. Do not disconnect |
| Every PROGRESS entry | Fill in the **Device telemetry banked** field with which Office Kit features you used and roughly for how long |

> **Ask an organiser at check-in what HackTracker actually counts** — continuous connection time, or
> discrete feature uses? The answer changes whether you leave a session open or deliberately use
> features repeatedly. Record the answer in `PROGRESS.md` immediately. Until you know, do both.

---

## 9. Physical kit checklist

- [ ] Power bank ×2, charged
- [ ] USB-C cable that carries **data**, not just charge — test it with `adb devices` before you trust it
- [ ] Laptop charger
- [ ] Bluetooth speaker for demo audio (or verify the phone is loud enough at stage distance)
- [ ] Second phone for `:gigsim` — the demo needs two devices
- [ ] Phone mount, if you are attempting the camera fatigue check (T3.3) — it must face the driver
- [ ] Headphones for testing TTS without annoying the whole hall at 3 a.m.
- [ ] A text editor app on the phone that can edit files in `/sdcard/` (Acode, QuickEdit, or similar)
      — **install this in Hour 0; it is what makes Red Light config tuning possible**

---

## 10. Sensor verification — do each once, early, and log it

| Sensor | Test | Passes when |
|---|---|---|
| Notification listener | Post from `:gigsim` | Event appears in EyesUp within 500 ms |
| Speaker / TTS | Speak one phrase per locale | Audible and correctly pronounced |
| Microphone / ASR | On-device `SpeechRecognizer`, say "why" | Transcript returns offline (airplane mode on) |
| GPS | Request one fix outdoors or by a window | Fix in under 30 s |
| Camera | Open the front camera preview | Face visible and well-framed on a mount |
| NPU / on-device model | One ML Kit extraction, then one Gemma inference | Returns within budget (40 ms / 3 s) |

Every one of these that passes is Creative Phone Use score you have actually banked. Every one you
skip is score you cannot argue for later.
