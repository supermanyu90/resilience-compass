# Resilience Compass Mobile

On-device (Google Gemma) operational-resilience assistant for banks — **offline, privacy-first**.
Flutter port of the Resilience Compass web prototype, for Google's Gemma Edge/On-Device hackathon.

Three areas, all running Gemma locally with **no network calls after the model loads**:
- **BCM Assistant** — a guided self-assessment across 10 resilience pillars that evaluates your answer
  against the regulators you selected (ISO 22301, HKMA, MAS, APRA, RBI, Fed/OCC/FDIC), cites them by
  name, and extracts a 1–4 maturity score. Replies in any of 6 languages.
- **Incident Scanner** — paste an incident, Gemma classifies category/severity/impact on-device, and it
  combines with your likelihood + control maturity into a 0–100 resilience score.
- **Tools panel** — Impact Tolerance Configurator + Nth-Party Dependency Mapper with concentration-risk
  detection (flags any Nth-party shared by 2+ vendors). This data grounds the Assistant's Tolerance and
  Third-Party pillars.

## Status

The Dart application is **fully written** but **not yet compiled** — this machine has no Flutter/Android
toolchain installed (holding that install per instruction). See **`docs/PLAN.md`** for:
- toolchain setup commands and the exact `flutter create . → pub get → analyze → run` sequence,
- the Gemma model license + fetch walkthrough (Hugging Face / Kaggle),
- a `VERIFY when the toolchain is installed` checklist for the few `flutter_gemma` API details to confirm,
- the staged feature roadmap and demo acceptance checklist.

## Layout

- `lib/` — the app (data, i18n, models, services, screens, widgets). `services/gemma_service.dart` is the
  only file that touches `flutter_gemma`, so SDK changes are contained there.
- `assets/models/` — drop the license-accepted `.litertlm` weights here (git-ignored).
- `reference/` — drop the original `resilience-suite/` web app here to port its content verbatim.
- `docs/PLAN.md` — build plan, setup, and readiness notes.

## Privacy

No user data (incident text, chat transcripts, tolerance/vendor registers) ever leaves the device.
Dependencies are `flutter_gemma`, `shared_preferences`, `provider`, `flutter_localizations` — none
phone home. Verify with an airplane-mode + network-inspector test on the built app.

_Self-assessment aid — not legal advice, a certification audit, or a guarantee of compliance._
