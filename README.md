# Resilience Compass

**An on‑device compliance copilot for banks.** Resilience Compass helps operational‑resilience and
business‑continuity (BCM) teams self‑assess against the regulators that apply to them, triage incidents,
and map vendor concentration risk — powered entirely by **Gemma running locally**, so the bank's most
sensitive data never leaves the device. Its centerpiece is a **live crisis simulator**: Gemma invents a
disaster tailored to your bank, runs the tabletop with you, grades your decisions against the regulators,
and writes the board report — offline.

> Built for Google's Gemma **Edge / On‑Device** hackathon track — *"Best mobile, web, or edge
> application running Gemma locally for offline, privacy‑first inference."*

- 🔴 **Live crisis simulator** — Gemma runs an interactive, grounded tabletop exercise and writes the after‑action board report.
- 🔒 **Private by construction** — no network calls after the model loads; inputs, chats, and registers stay on the device.
- 📶 **Works offline** — put the machine in airplane mode and it keeps answering.
- 🌍 **6 languages** — English, हिन्दी, 简体中文, Español, Français, Português.
- 🏛️ **Regulator‑aware** — cites ISO 22301, the EU's **DORA**, HKMA, MAS, APRA, RBI, and the US Fed/OCC/FDIC by name.

---

## Table of contents
- [Partners](#partners)
- [Why on‑device](#why-on-device)
- [What it does](#what-it-does)
- [Two implementations](#two-implementations)
- [Run the web demo (real Gemma)](#run-the-web-demo-real-gemma)
- [Architecture](#architecture)
- [Partner deployment (SUSE K3s + NVIDIA NIM)](#partner-deployment-suse-k3s--nvidia-nim)
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

## Partners

| Partner | Product | Role in Resilience Compass |
|---|---|---|
| **Google** | **Gemma** (3 4B on web · 3n / small quantized on mobile) | The on‑device LLM behind every reply — the live crisis simulator, BCM assistant, incident scanner, Dr. Owl, and on‑device vision. |
| **NVIDIA** | **NIM** (Gemma inference microservice) | Optional GPU‑accelerated, OpenAI‑compatible inference backend — drop‑in via `serve.js` (`MODEL_BACKEND=openai`). Edge story via **Jetson**. |
| **SUSE** | **K3s** + **NeuVector** | Edge‑Kubernetes deployment of the whole stack (Traefik, `local‑path` storage); zero‑trust container security for the banking workload. |
| **Nebius** | **AI Studio** | Hosted, OpenAI‑compatible cloud / no‑GPU inference tier — same backend switch, zero code change. |

Local Ollama runs Gemma by default (offline / on‑device); the NVIDIA and Nebius backends share one
OpenAI‑compatible path in `serve.js`, so switching is just configuration. See
[Partner deployment](#partner-deployment-suse-k3s--nvidia-nim) and [`deploy/`](deploy/).

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

### 🔴 Crisis Simulator (the hero)
An **interactive tabletop exercise** run entirely by on‑device Gemma. It:
- invents a **severe‑but‑plausible** disruption **grounded in your real weak spot** — e.g. the AWS
  single‑point‑of‑failure shared across FIS, Temenos and nCino;
- runs the exercise **turn by turn** — it drops timed injects, you type your decisions, and it **assesses
  each one against the named regulators** (ISO 22301 / HKMA / APRA / …) and **escalates** realistically;
- ends by **synthesising an after‑action board report** — scenario, decisions & assessment, gaps vs
  regulators (ISO by clause), **P1/P2/P3 remediation**, and an overall **resilience rating /100**.

Regulators mandate exactly this kind of scenario testing — here it's instant, private, and offline. On a
laptop with `gemma3:4b`: ~6 s to the first scenario, ~3 s per turn, ~10 s for the report.

### 🧰 The advisor toolkit (behind the hero)
- **BCM Assistant** — a guided self‑assessment across **10 resilience pillars**; for each you describe
  your practice and Gemma evaluates it against the regulators you picked, **cites them by name/clause**,
  and extracts a **1–4 maturity score** (with citation chips). Free‑form questions welcome. Streams in the
  selected language (switch mid‑session and the next reply follows).
- **Incident Scanner** — paste an incident; Gemma returns strict‑JSON category/severity/impact, combined
  with your likelihood + control maturity into a **0–100 resilience score**. A one‑click **Response Pack**
  drafts root cause + regulator notification + customer comms + remediation.
- **Tools** — an **Impact Tolerance Configurator** (RTO/RPO/MTPD/SRTO) and an **Nth‑Party Dependency
  Mapper** with **concentration‑risk detection** (any provider used by 2+ vendors = a single point of
  failure). These registers **ground** both the crisis scenario and the assistant.

### 👁️ On‑device vision
On the Crisis Simulator, **"Seed from an architecture diagram"** lets Gemma **read an uploaded image**
(architecture / vendor diagram) and rebuild your vendor map — perception on‑device, no cloud.

Everything persists locally only (browser `localStorage` / on‑device storage), never synced.

## Two implementations

| | Web demo (`demo_preview/`) | Flutter mobile app (`lib/`) |
|---|---|---|
| **Runtime** | Real Gemma via **local Ollama** | **`flutter_gemma`** (LiteRT‑LM engine) |
| **Model** | Pinned to **`gemma3:4b`** for snappy live inference (falls back to newest Gemma if absent) | Small quantized Gemma bundled as an asset (e.g. Gemma 3 1B int4) |
| **Status** | ✅ Verified working end‑to‑end (incl. the Crisis Simulator + on‑device vision) | 🧩 Code‑complete; pending Flutter toolchain to compile |
| **Best for** | A live, on‑laptop crisis‑simulation demo on `localhost` | The native on‑device story on a phone |

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
Open **http://localhost:8422** in Chrome. It **auto‑connects** to the local model (the header shows a
`gemma3:4b` chip once warm) and lands on the **Crisis Simulator** — press **Start the exercise**. Tap 🧰
for the advisor toolkit (BCM Assistant / Incident Scanner / Tools); 🔴 returns to the simulator.

> **Tip:** open in an **Incognito** window to load the seeded demo data (two tolerances and four vendors
> where three share *AWS*, so the concentration flag and grounding light up immediately).

### Choosing a model
The app is **pinned to `gemma3:4b`** for snappy live inference; if it isn't installed, it falls back to
the newest Gemma present. `gemma4:12b` is smarter but noticeably slower per turn on a laptop — keep the
live demo on 4B.

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

## Partner deployment: SUSE K3s + NVIDIA NIM

`serve.js` is **backend‑agnostic** — the browser always speaks one API and the proxy translates to
**Ollama** *or* any **OpenAI‑compatible** endpoint, so the app runs unchanged on an **NVIDIA NIM** (a
Gemma inference microservice) by setting two env vars (verified locally against an OpenAI `/v1`
endpoint). `deploy/` ships a **Dockerfile** + **K3s manifests** to run the whole stack on **SUSE K3s**
(edge Kubernetes, Traefik ingress, `local‑path` storage), with an optional **NVIDIA NIM** GPU variant and
a note for **SUSE NeuVector** zero‑trust security, and can point at **Nebius AI Studio** (hosted Gemma)
as a cloud / no‑GPU tier. Sensitive inference stays on the cluster — still offline / on‑device. See
**[deploy/README.md](deploy/README.md)**.

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
| **DORA** — Regulation (EU) 2022/2554 | European Union | Article‑numbered (exact articles + RTS) |

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
│  ├─ index.html            #   Hero-first UI: Crisis Simulator + advisor toolkit + on-device vision + Ollama
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

- ✅ Web demo with **real local Gemma** — verified end‑to‑end: the **Crisis Simulator** (grounded scenario
  → adaptive injects → regulator‑cited coaching → after‑action board report), on‑device **vision** seeding,
  BCM evaluation with citations + maturity, incident JSON classification, and grounded concentration risk.
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
