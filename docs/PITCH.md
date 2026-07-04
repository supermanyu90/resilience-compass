# Resilience Compass — 2-minute pitch

_Track: Gemma Edge / On-Device. Scoring: Demo 50% · Impact 25% · Creativity 15% · Pitch 10%._
_Everything below is generated live by Gemma 3 4B running locally via Ollama — nothing leaves the machine._

---

## One-liner
> **Resilience Compass is an on-device compliance copilot for banks. Its centerpiece: a live crisis
> simulator where Gemma invents a disaster tailored to your bank, runs the tabletop with you, grades
> your decisions against the regulators, and writes the board report — entirely offline.**

## The hook (~15s)
> "Operational resilience is now hard regulation everywhere at once — APRA CPS 230, the EU's DORA, the
> UK, RBI, HKMA, MAS, the US Fed. They all demand you test *severe-but-plausible* scenarios. But the
> data — your incidents, your vendor dependencies — is too sensitive for a cloud LLM, and a resilience
> tool that needs the cloud fails exactly when the cloud does. So banks need AI for resilience, but
> can't use cloud AI for it. We run Gemma on the device."

## What it is (~10s)
> "Resilience Compass. The hero is a **live crisis tabletop** run by on-device Gemma; behind it sits a
> regulator-cited BCM assistant, an incident scanner, and a vendor-risk mapper. Six languages. Offline."

## Live demo — the crisis simulation (~70s)
> _(Chrome at localhost:8422, Incognito, model chip shows `gemma3:4b`. It opens on the Crisis Simulator.)_

1. **Point at the hero card.** "It already knows this bank's weak spot —" (the **⚠️ AWS single-point-of-failure
   across FIS, Temenos and nCino** chip). "Everything from here is Gemma, on this laptop. **Start the exercise.**"
2. **Gemma invents the crisis** — e.g. *"AWS Outage – Cascade Effect"* — grounded in that exact concentration,
   with a timed inject and a decision question. "It didn't pull a template; it wrote a scenario for *our* risk."
3. **Make a call** — type: *"Invoke crisis management, fail payments over to the DR region, notify the
   regulator of a likely impact-tolerance breach."*
4. **Gemma reacts like an examiner** — it assesses your decision **naming ISO 22301 / HKMA / APRA**, then
   **escalates**: *"T+15m — Temenos is now failing inside the DR region too."* "It's adapting to what I chose."
5. **One more decision, then → End & report.** Gemma writes an **after-action board report**: scenario,
   decisions & assessment, **gaps vs regulators (ISO by clause)**, **P1/P2/P3 remediation**, and an overall
   **resilience rating out of 100**. "That's a board paper — written on-device, in ~10 seconds."
6. **THE moment — airplane mode ON.** Run another turn. It still answers. "No network. This is what
   on-device, privacy-first resilience actually looks like."

_Optional 10s beats if time allows:_ on the hero, **"Seed from an architecture diagram"** → Gemma reads an
uploaded diagram and rebuilds the vendor map (on-device vision). Or 🧰 → Scanner → **"Generate response
pack"** (root cause + regulator notice + customer comms + remediation from one incident).

## Why it's different (~15s)
> "Three things: it **grounds** the crisis in your real vendor concentration, so it's your bank, not a
> generic drill; it **reads diagrams** on-device to build that map; and it **synthesises** the whole
> exercise into a board-ready report with regulator citations — all offline, in six languages."

## Close (~10s)
> "It turns a slow, consultant-led tabletop into an instant, private, on-device rehearsal — the only kind
> a bank can run on this data. Built on Gemma. Offline-first. Working today."

---

## Demo choreography — do this BEFORE you present
- [ ] `ollama serve` running, `node demo_preview/serve.js` running, **Chrome at http://localhost:8422**.
- [ ] Use a **fresh / Incognito** window so the **seeded data** loads — that's what puts the **AWS SPOF chip**
      on the hero (and grounds the scenario).
- [ ] Wait for the header to show the **`gemma3:4b` chip** (it auto-connects + warms on load; first scenario is then ~6s, turns ~3s).
- [ ] Have your two decisions on the clipboard. (Optional) have an architecture-diagram image ready for the vision beat.
- [ ] Run one full exercise once beforehand so you know the rhythm.

## If something breaks (backups)
- **Slow first response** → the model is still warming; wait for the `gemma3:4b` chip before Start.
- **A turn stalls / odd output** → just hit **End & report** (it works from any point), or **↻ Run another**.
- **"offline" in the header / a call fails** → Ollama stopped; `ollama serve` in a terminal, refresh, it re-connects.
- **Model note** → the app is pinned to `gemma3:4b` for speed even if `gemma4:12b` is installed. Don't switch to 12B live — it's much slower per turn on a laptop.
- **Worst case** → fall back to the Advisor (BCM assistant citations + maturity) and screenshots; the crisis sim is the reliable headline.

## How this maps to the rubric
- **Demo (50%)** — a live, adaptive crisis with regulator-cited coaching, a generated board report, and the
  airplane-mode proof. Interactive, not a dashboard.
- **Impact (25%)** — simultaneous global regulation × un-cloudable data = an urgent, real need; scenario testing is mandated.
- **Creativity (15%)** — grounded scenario generation, on-device vision, synthesis-to-report, multilingual.
- **Pitch (10%)** — this script; keep to ~2 minutes and let the simulation carry it.
