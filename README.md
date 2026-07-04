# Resilience Compass

**An on‑device compliance copilot for banks.** Resilience Compass helps operational‑resilience and
business‑continuity (BCM) teams self‑assess against the regulators that apply to them, triage incidents,
and map vendor concentration risk — powered entirely by **Gemma running locally**, so the bank's most
sensitive data never leaves the device.

> Built for Google's Gemma **Edge / On‑Device** hackathon track — *"Best mobile, web, or edge
> application running Gemma locally for offline, privacy‑first inference."*

- 🔒 **Private by construction** — no network calls after the model loads; inputs, chats, and registers stay on the device.
- 📶 **Works offline** — put the machine in airplane mode and it keeps answering.
- 🌍 **6 languages** — English, हिन्दी, 简体中文, Español, Français, Português.
- 🏛️ **Regulator‑aware** — cites ISO 22301, HKMA, MAS, APRA, RBI, and the US Fed/OCC/FDIC by name.

---

## Table of contents
- [Why on‑device](#why-on-device)
- [What it does](#what-it-does)
- [Two implementations](#two-implementations)
- [Run the web demo (real Gemma)](#run-the-web-demo-real-gemma)
- [Architecture](#architecture)
- [The Flutter mobile app](#the-flutter-mobile-app)
- [Regulatory coverage](#regulatory-coverage)
- [How scoring works](#how-scoring-works)
- [Repository structure](#repository-structure)
- [Privacy & data handling](#privacy--data-handling)
- [Tech stack](#tech-stack)
- [Status & roadmap](#status--roadmap)
- [Docs](#docs)
- [Disclaimer](#disclaimer)

---

## Why on‑device

Operational resilience became hard regulation almost everywhere at once — APRA **CPS 230** (Australia),
the EU's **DORA**, the UK PRA/FCA rules, **RBI**'s 2024 guidance, **HKMA**, **MAS**, and the US
**Fed/OCC/FDIC** interagency paper. Every regulated bank must continuously self‑assess against these.

But the data involved — incident details, control gaps, vendor dependencies, recovery objectives — is
among the most sensitive in the institution. Compliance teams **can't** paste it into a cloud LLM:
data‑residency law (DPDP/GDPR), third‑party‑risk policy, and the simple fact that a resilience tool
which depends on the cloud fails exactly when the cloud does.

**The gap:** banks need AI help with resilience, but can't use cloud AI for it. Resilience Compass runs
Gemma locally, closing that gap.

## What it does

### 1. BCM Assistant (flagship)
A guided self‑assessment across **10 resilience pillars** (governance, policy & scope, critical
operations, business impact analysis, impact tolerance, risk assessment, third‑party management,
BC/DR plans, testing, monitoring). For each pillar you describe your current practice in your own words;
Gemma:
- evaluates it against the **regulators you selected**,
- **cites them by name and section** (ISO 22301 by clause; the principles‑based regimes by named theme),
- extracts a **1–4 maturity score** (parsed from a structured `[[ASSESSMENT]]` tag and shown as a badge + citation chips),
- and answers **free‑form questions** at any point instead of forcing a score.

Replies stream in whichever of the 6 languages is selected — switch language mid‑session and the
assistant's next reply follows.

### 2. Incident Scanner
Paste or describe an operational incident. Gemma classifies it on‑device into one of six categories
(people, process, technology, third‑party, cyber, facilities) with a severity and impact area, returned
as strict JSON. That combines with your chosen **likelihood** and **control maturity** into a **0–100
resilience score**.

### 3. Tools panel
- **Impact Tolerance Configurator** — record RTO / RPO / MTPD / SRTO per critical service.
- **Nth‑Party Dependency Mapper** — map vendors and their Nth‑party providers, with **concentration‑risk
  detection**: any provider depended on by **2+ vendors** is flagged as a single point of failure.
- **Grounding loop** — these registers are fed back into the BCM Assistant's prompt, so when you reach
  the *Impact Tolerance* or *Third‑Party* pillar, the model reasons about **your** actual data (e.g. "you
  rely on AWS across FIS, Temenos and nCino — a concentration risk").

Registers persist locally only (browser `localStorage` / on‑device storage), never synced.

## Two implementations

| | Web demo (`demo_preview/`) | Flutter mobile app (`lib/`) |
|---|---|---|
| **Runtime** | Real Gemma via **local Ollama** | **`flutter_gemma`** (LiteRT‑LM engine) |
| **Model** | Auto‑detects newest installed Gemma (`gemma4:12b`, else `gemma3:4b`) | Small quantized Gemma bundled as an asset (e.g. Gemma 3 1B int4) |
| **Status** | ✅ Verified working end‑to‑end | 🧩 Code‑complete; pending Flutter toolchain to compile |
| **Best for** | A live, on‑laptop demo on `localhost` | The native on‑device story on a phone |

Both share the same domain model, prompt engineering, and parsing logic.

## Run the web demo (real Gemma)

This runs **genuine Gemma inference locally** — the browser talks to a local Ollama server; nothing goes
to the cloud.

### Prerequisites
- **[Ollama](https://ollama.com)** (local model server)
- **Node.js** (for the zero‑dependency static + proxy server)
- **Google Chrome** (or any modern browser)

### Steps
```bash
# 1) Install + start Ollama, then pull a Gemma model
brew install ollama
ollama serve                 # or: brew services start ollama
ollama pull gemma3:4b        # snappy (~3 GB). For the bigger model: ollama pull gemma4:12b

# 2) Serve the web app (from the repo root)
node demo_preview/serve.js
#    → Resilience Compass demo → http://localhost:8422
```
Open **http://localhost:8422** in Chrome → **Connect to on‑device Gemma** (it auto‑detects the model and
warms it) → **Start**.

> **Tip:** open in an **Incognito** window to load the seeded demo data (two tolerances and four vendors
> where three share *AWS*, so the concentration flag and grounding light up immediately).

### Choosing a model
The app auto‑selects the **newest** installed Gemma generation. Keep both installed and it uses
`gemma4:12b`; remove it (or only install `gemma3:4b`) for faster streaming on a laptop.

| Model | Download | Feel on a laptop |
|---|---|---|
| `gemma3:4b` | ~3 GB | Snappy (~1–2 s warm) — recommended for a live, timed demo |
| `gemma4:12b` | ~7.5 GB | Smarter, but slower first token |

### Offline / airplane‑mode test
Once the model is pulled, turn on **airplane mode** and keep using the app — it still answers, because
Gemma runs locally. This is the core proof for the on‑device track.

## Architecture

```
                 ┌───────────────────────────── your machine ─────────────────────────────┐
  Google Chrome  │   demo_preview/serve.js (Node, no deps)              Ollama (:11434)     │
  localhost:8422 │   ├─ serves index.html + assets                     ├─ Gemma 3 4B /      │
      ▲          │   └─ reverse‑proxies /api/*  ──stream──►  ───────►   │   Gemma 4 12B      │
      │          │        (same origin → no CORS)                       └─ on‑device weights │
      └──────────┤◄─────────────── streamed NDJSON tokens ◄──────────────────────────────── │
                 └────────────────────────────────────────────────────────────────────────┘
```

- **Same‑origin proxy** — the browser only ever talks to `localhost:8422`; `serve.js` pipes `/api/*`
  through to Ollama, so there's no CORS and no `OLLAMA_ORIGINS` configuration.
- **Streaming** — Ollama's NDJSON stream is piped straight to the browser, so tokens render live.
- **Prompts & parsing** — the BCM/incident system prompts and the `[[ASSESSMENT]]` / JSON extraction are
  shared with the Flutter app (`lib/services/prompt_builder.dart`, `lib/services/json_extractor.dart`).

## The Flutter mobile app

The native app under `lib/` targets **Android/iOS** via `flutter_gemma` (LiteRT‑LM engine, a small
quantized Gemma bundled as an asset). It is **code‑complete but not yet compiled** — the build machine
has no Flutter toolchain installed. All SDK calls are isolated in `lib/services/gemma_service.dart` so
the rest of the app is engine‑agnostic.

When a toolchain is available:
```bash
flutter create .          # generates android/ ios/ around the existing lib/
flutter pub get
flutter analyze           # first real compile check
flutter run -d <device>
```
Getting the model file requires accepting the Gemma license on Hugging Face or Kaggle, then placing the
`.litertlm` weights under `assets/models/`. See **[docs/PLAN.md](docs/PLAN.md)** for the full setup,
the license walkthrough, and the `VERIFY`‑at‑build‑time checklist.

## Regulatory coverage

| Framework | Jurisdiction | Reference style |
|---|---|---|
| **ISO 22301:2019** | Baseline (always on) | Clause‑numbered (exact clauses) |
| **HKMA** SPM OR‑2 | Hong Kong | Principles‑based (named section) |
| **MAS** Operational Resilience / ORM | Singapore | Principles‑based |
| **APRA** CPS 230 | Australia | Principles‑based |
| **RBI** Guidance Note (Apr 2024) | India | Principles‑based |
| **Fed / OCC / FDIC** Interagency Paper | United States | Principles‑based |

The app preserves the honest distinction that ISO is clause‑numbered while the others are
principles‑based — and instructs the model never to fabricate a clause number for a principles‑based
regime.

## How scoring works

**Maturity (BCM Assistant):** `1` Not started/ad hoc · `2` Partially defined · `3` Established &
documented · `4` Advanced/continuously improved — extracted from the model's structured tag.

**Resilience score (Incident Scanner), 0–100:**
```
inherentRisk   = severity(1..3) × likelihood(1..3)      → normalised to 0..1
controlFactor  = (controlMaturity(1..4) − 1) / 3        → 0..1 effectiveness
residualRisk   = inherentRiskNorm × (1 − controlFactor) → 0..1
resilience     = round(100 × (1 − residualRisk))        → 0..100
```

**Concentration risk (Tools):** any Nth‑party listed by **≥ 2 distinct vendors** is flagged, ranked by
how many vendors share it.

## Repository structure

```
resilience_compass_mobile/
├─ demo_preview/            # Real-Gemma web demo (this is the live localhost artifact)
│  ├─ index.html            #   Resilience Compass UI + Ollama inference + shared prompts/parsing
│  └─ serve.js              #   Zero-dep Node static server + streaming Ollama reverse-proxy
├─ lib/                     # Flutter app
│  ├─ data/framework_data.dart      # 10 pillars, 6 jurisdictions, categories, disclaimer
│  ├─ i18n/strings.dart             # 6-language UI table
│  ├─ models/                       # app_state, chat_message, assessment, incident, tools, tools_state
│  ├─ services/                     # gemma_service (SDK-isolated), prompt_builder, json_extractor, scoring, persistence
│  ├─ screens/                      # setup, home_scaffold, assistant, scanner, tools, about
│  ├─ widgets/                      # badges, chat_bubble, disclaimer_card
│  └─ main.dart
├─ docs/
│  ├─ PLAN.md               # Build plan, toolchain + model-license setup, readiness checklist
│  └─ PITCH.md              # 2-minute pitch script + demo choreography
├─ assets/models/           # (git-ignored) bundled Gemma weights go here
├─ reference/               # (git-ignored) drop the original web app here to port verbatim
├─ pubspec.yaml
└─ README.md
```

## Privacy & data handling

- **No network calls after the model is loaded** — the dependency set (`flutter_gemma`,
  `shared_preferences`, `provider`, `flutter_localizations` on mobile; Ollama + a Node static/proxy on
  web) contains no analytics or crash‑reporting SDKs.
- **No user data leaves the device** — incident text, chat transcripts, and the tolerance/vendor
  registers are processed on‑device and stored locally only.
- **Model weights are never committed** — `.gitignore` excludes `.litertlm/.task/.bin/.gguf`, `.env`,
  and `kaggle.json`.

## Tech stack

- **On‑device LLM:** Google **Gemma** (via Ollama on web; `flutter_gemma` / LiteRT‑LM on mobile)
- **Web demo:** vanilla HTML/CSS/JS, Node (built‑ins only) for static serving + reverse proxy
- **Mobile:** Flutter / Dart, Provider, `shared_preferences`
- **No backend, no cloud** — everything runs locally

## Status & roadmap

- ✅ Web demo with **real local Gemma** — verified end‑to‑end (BCM evaluation with citations + maturity,
  incident JSON classification, grounded concentration risk).
- ✅ Flutter app — code‑complete across setup, assistant, scanner, tools, about.
- ⏳ Compile & run the Flutter app on a device once a toolchain is available.
- ⏳ Optional: port the original web prototype's fact‑checked dataset verbatim if provided.

## Docs

- **[docs/PLAN.md](docs/PLAN.md)** — build plan, toolchain + Gemma‑license setup, feature roadmap, acceptance checklist.
- **[docs/PITCH.md](docs/PITCH.md)** — 2‑minute pitch script, demo choreography, and rubric mapping.

## Disclaimer

Resilience Compass is a **self‑assessment aid — not legal advice, a certification audit, or a guarantee
of regulatory compliance.** ISO 22301 references are clause‑numbered; HKMA, MAS, APRA, RBI, and the US
interagency guidance are principles‑based (references point to a named section, not a clause number).
