# Resilience Compass Mobile — Build Plan & Setup Guide

_Status: scaffolding started while awaiting 4 decisions (see "Open decisions" below). No toolchain
has been installed yet — that's a large commitment I'm holding until you confirm._

Target: Google Gemma Edge / On-Device hackathon. Scoring — Impact 25%, **Demo 50%**, Creativity 15%,
Pitch 10%. Optimize for a small set of features that work flawlessly **offline**, live, in front of judges.

---

## 0. Open decisions (blocking full build)

I asked these up front; answer whenever you're back and I'll proceed:

1. **Reference folder** — `reference/resilience-suite/` (framework-data.js, i18n.js, app.js) is NOT
   present. Options: (a) you drop it in so I port verbatim [best fidelity]; (b) I proceed on the
   fallback dataset baked into `lib/data/framework_data.dart`; (c) point me at the real prototype if
   it's elsewhere on disk.
2. **Demo device** — Android phone (recommended), iPhone, or emulator/simulator only.
3. **Toolchain** — OK to install the full Flutter + platform SDK stack on this Mac? Nothing is
   installed today (only Homebrew).
4. **Gemma model access** — do you already have the Gemma license accepted on Hugging Face or Kaggle,
   or do you need the walkthrough in §3?

My default recommendation if you say nothing: **Android physical phone + LiteRT-LM engine + Gemma 3 1B
int4 bundled as an asset**, BCM Assistant built first.

---

## 1. flutter_gemma — verified current state (checked against live pub.dev)

- **Version 1.2.0**, published very recently. Supports Android, iOS, Web, macOS, Windows, Linux.
- Two swappable engines:
  - **`flutter_gemma_litertlm`** — `.litertlm` format. **Cross-platform default / recommended.** ← use this.
  - `flutter_gemma_mediapipe` — `.task`/`.bin` format; no web CPU backend; reportedly heading to maintenance.
- **Model candidates for mobile** (int4/int8, pre-quantized):
  - **Gemma 3 1B int4 (~500 MB)** — safe to bundle, fast, our default for a reliable demo.
  - **Gemma 3n E2B** — stronger multilingual/reasoning, larger (~1.5–3 GB) — quality upgrade if bundle/download size is acceptable.
  - Gemma 3 270M (~300 MB) — tiniest, likely too weak for nuanced compliance reasoning.
- **Loading:** `fromAsset('assets/models/<model>.litertlm')` for a bundled model (best for a live demo);
  network download with progress only as a fallback if too big to bundle.
- **Min platforms:** iOS 16.0+, Android arm64-v8a.
- **API shape:** create model → `createChat()` → add message → `generateChatResponse()` /
  `generateChatResponseAsync()` stream. Multi-turn history persists on the chat object.
- ⚠️ Exact method names above came from a quick doc fetch and may be slightly off — I'll pin them
  against the real README the moment we start writing service code.

---

## 2. Toolchain setup (run only after you approve — §0.3)

Current machine: macOS (Apple Silicon), Homebrew present. **No Flutter/Dart/Xcode/Android SDK/CocoaPods.**

### Android path (recommended for demo)
```bash
# Flutter SDK
brew install --cask flutter        # or git clone the stable channel
flutter --version

# Android Studio + SDK + platform tools
brew install --cask android-studio
# then open Android Studio once -> SDK Manager -> install SDK + build-tools + a device image
flutter doctor --android-licenses
flutter doctor                     # resolve everything until Android is a ✓
```
Enable USB debugging on the phone, plug in, `flutter devices` should list it.

### iOS path (only if demoing on iPhone)
```bash
# Xcode from the App Store (large, GUI install — needs your hands)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods
```
Deploying to a physical iPhone also needs a free Apple Developer account + a provisioning profile.

### Create the app around this scaffold
```bash
cd "resilience_compass_mobile"
flutter create .          # fills in android/ ios/ platform folders around existing lib/
flutter pub get
```

---

## 3. Gemma model — license + fetch walkthrough (needs your account)

You must accept the Gemma license once, under your own account, before the weights are downloadable.

**Option A — Hugging Face**
1. Log in at huggingface.co, open the Gemma model page (e.g. `google/gemma-3-1b-it` or a LiteRT `.litertlm` repo).
2. Click "Agree and access repository."
3. Create a read token (Settings → Access Tokens).
4. Give me the token when we fetch; I'll pull the `.litertlm` file and drop it in `assets/models/`.

**Option B — Kaggle**
1. Log in at kaggle.com, open the Gemma model card, accept the license.
2. Grab `kaggle.json` API credentials (Account → Create New Token).
3. I'll pull the mobile-tuned `.litertlm`/`.task` variant.

Then: bundle the file under `assets/models/`, register it in `pubspec.yaml` assets, and on first
launch copy it into the app documents dir. **Bundled beats live download for a conference-wifi demo.**

---

## 4. Feature build order (each stage demoable before the next)

1. **Setup flow** — language picker (6) + jurisdiction multi-select (ISO always on) + model load with
   a real progress bar. First visible proof of "on-device."
2. **BCM Assistant (flagship)** — guided chat across the 10 pillars: evaluate answer vs picked
   jurisdictions, cite regulator by name, extract 1–4 maturity score, allow free-form questions,
   reply in the selected language. **Get this rock solid first.**
3. **Incident Scanner** — paste incident → Gemma returns category/severity/impact-area JSON → combine
   with user likelihood/control-maturity into the 0–100 resilience score.
4. **Tools panel (stretch)** — Impact Tolerance Configurator + Nth-Party Dependency Mapper with
   concentration-risk flagging (2+ vendors sharing an Nth-party), fed back into the Assistant's
   grounding for the 'tolerance' and 'third-party' pillars. Only if time allows.

Nav: bottom tab bar / segmented control between Scanner and Assistant. Reuse the web app's dark theme
for side-by-side visual continuity in the pitch.

State: setState/Provider (keep it simple). Persist the two Tools registers with shared_preferences/hive,
**local only, never synced.**

---

## 5. Hard offline / privacy constraints

- **No network calls at all after model load.** Audit for accidental analytics/crash-reporting SDKs.
- **Airplane-mode test is the money demo** — verify core flows offline before calling anything done.
- No user data (incident text, transcripts, tolerance/vendor registers) ever leaves the device.

## 6. Acceptance checklist (demo-ready gate)

- [ ] Builds & runs on ≥1 real device/emulator per targeted platform.
- [ ] Model loads fully offline after first launch (airplane-mode pass).
- [ ] BCM Assistant: jurisdiction-cited response + parsed maturity score for ≥3 pillars in a row, no crash.
- [ ] Language switch mid-session changes both UI chrome and assistant reply language.
- [ ] Incident Scanner returns category/severity/score for a pasted incident.
- [ ] No network request after model load — verified with a proxy/network inspector, not just eyeballing.
- [ ] Compliance disclaimer visible (setup or About).

---

## 7. Build-readiness review (Dart written, not yet compiled)

The full Dart app is written but **cannot be compiled here** (no toolchain). A static pass was done for
imports, types, and Dart syntax. What's implemented:

```
lib/
  main.dart                  app entry, providers (Provider), MaterialApp, 6-locale localization
  data/framework_data.dart   10 pillars, 6 jurisdictions (+citation-style flag), categories, disclaimer
  i18n/strings.dart          6-language UI table (en/hi/zh/es/fr/pt) + reply-language map
  theme/app_theme.dart       dark palette + ThemeData (targets current-stable Flutter)
  models/                    app_state, chat_message, assessment, incident, tools, tools_state (ChangeNotifiers)
  services/
    gemma_service.dart       ONLY file importing flutter_gemma (load-from-asset, chat, stream, dispose)
    prompt_builder.dart      BCM wizard + incident classifier system prompts (jurisdiction/lang aware)
    json_extractor.dart      balanced-brace JSON extraction; strips the [[ASSESSMENT]] tag from display
    scoring.dart             0–100 resilience score (reconstructed formula — replace with app.js if given)
    persistence.dart         shared_preferences, local-only
  screens/                   setup, home_scaffold (3-tab +lang switch), assistant, scanner, tools, about
  widgets/                   badges (offline/maturity/score/progress), chat_bubble, disclaimer_card
```

**Fixed during review:** an illegal raw-string backslash (`r'\'` → `'\\'`) in json_extractor;
loosened the model handle to `dynamic` so a differing SDK class name can't break the build; pinned
the SDK/Flutter constraints to match the `withValues`/`CardThemeData` APIs used.

**Privacy audit (dependency level):** deps are `flutter_gemma`, `shared_preferences`, `provider`,
`flutter_localizations` — none phone home. No analytics/crash-reporting SDK is present. Still do the
airplane-mode + network-inspector test on the built app before calling it done.

### VERIFY when the toolchain is installed (in priority order)
1. Add the **engine plugin** dependency (`flutter_gemma_litertlm`) per the current README (pubspec note).
2. In `gemma_service.dart`, confirm `FlutterGemmaPlugin.instance.modelManager.installModelFromAsset(...)`
   is the correct load-from-asset call; wire the `…WithProgress` stream variant if it exists for a
   smooth progress bar.
3. Confirm the `generateChatResponseAsync()` element type (String vs `TextResponse.token`) — `_tokenOf()`
   already tolerates both, so likely no change.
4. Optionally set `temperature ~0.3` (steadier JSON) once you confirm where this version accepts it.
5. Put the real `.litertlm` weights in `assets/models/`, set `kGemmaModelAsset` + the pubspec asset entry
   to the exact filename. Set Android `minSdk`/`arm64-v8a` (and iOS 16 if you ever target iPhone).

### When the toolchain arrives — exact run sequence
```bash
cd "resilience_compass_mobile"
flutter create .          # generates android/ ios/ around the existing lib/
# re-add the engine plugin + asset entry if flutter create reset pubspec (it shouldn't)
flutter pub get
flutter analyze           # first real compile check — resolve any SDK-name VERIFY items here
flutter run -d <android-device-id>
```

## 8. Built / deferred
- **Tools panel — BUILT** (`screens/tools_screen.dart`, `models/tools.dart`, `models/tools_state.dart`).
  Impact Tolerance Configurator + Nth-Party Dependency Mapper with concentration-risk detection (flags
  any Nth-party shared by 2+ vendors). Entries persist locally via `toleranceRegister`/`vendorRegister`
  and are fed back into the Assistant: opening the `tolerance` or `third-party` pillar injects the
  relevant register into the system prompt (`ToolsState.groundingForPillar` → `PromptBuilder`). Added as
  a third bottom-nav tab.
- **Verbatim reference port** *(deferred)* — if `reference/resilience-suite/` is dropped in, replace the fallback
  data in `framework_data.dart`, the strings in `i18n/strings.dart`, the prompts in `prompt_builder.dart`,
  and the formula in `scoring.dart` with the fact-checked originals.
