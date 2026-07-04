# Resilience Compass — 2-minute pitch

_Track: Gemma Edge / On-Device. Scoring: Demo 50% · Impact 25% · Creativity 15% · Pitch 10%._
_Everything below runs on real Gemma (Gemma 4 12B) locally via Ollama — nothing leaves the machine._

---

## One-liner
> **Resilience Compass is an on-device compliance copilot for banks — it self-assesses operational
> resilience against the regulators that apply to you, powered entirely by Gemma running locally, so
> the bank's most sensitive data never leaves the device.**

## The hook (say first, ~15s)
> "Every bank on earth is now under operational-resilience regulation — APRA CPS 230, the EU's DORA,
> the UK, RBI, HKMA, MAS, the US Fed. They all demand continuous self-assessment. But the data
> involved — incident details, control gaps, vendor dependencies — is the most sensitive in the bank.
> You can't paste that into ChatGPT. So banks need AI for resilience, but can't use cloud AI for it.
> That's the gap we fill."

## What it is (~15s)
> "Resilience Compass runs Gemma **on the device**. Three parts: a **BCM Assistant** that grades your
> practice against the regulators and cites them by clause; an **Incident Scanner** that classifies and
> scores incidents; and a **Tools** layer that maps vendor concentration risk — and feeds it back into
> the AI. Six languages. Phone and browser. All offline."

## Live demo — the heart of it (~65s)
> _(App open at localhost:8422 in Chrome, model already Connected/warm, Assistant pre-advanced to the
> **Third-Party** pillar — see checklist below.)_

1. **Point at the "Offline · On-device" badge.** "Everything you're about to see is Gemma running on
   this laptop. Watch."
2. **Type a real answer** (Third-Party pillar):
   > `We use FIS, Temenos and nCino, reviewed at onboarding, but we don't track their sub-providers.`
   → Gemma streams an evaluation, cites **ISO 22301** by clause + the regulator, and — because the
   Tools register is grounded in — **names your AWS concentration risk across all three vendors**, then
   drops a **Maturity 2** badge. _"It didn't give generic advice — it flagged MY single point of failure."_
3. **Switch language** (top-right) to **हिन्दी** or **中文**, ask again → same expertise, now in the
   user's language. _"Still 100% on-device."_
4. **Scanner tab** → paste:
   > `Core banking database cluster down for 3 hours overnight; all customers affected.`
   → **technology / high** + a resilience score.
5. **Tools tab** → point at the **AWS concentration flag** (shared by 3 vendors). _"That's what actually
   causes systemic outages — a shared dependency nobody mapped."_
6. **THE moment — turn on airplane mode.** Ask one more question. It still answers.
   > "No network. Still working. That is what on-device, privacy-first AI means for a bank."

## Why it's different (Creativity, ~15s)
> "Three things you won't see elsewhere: a **grounding loop** — your vendor and tolerance registers feed
> the model's prompts, so advice is about *your* bank; **Nth-party concentration-risk detection**; and
> **regulator-precise citations** with an honest clause-vs-principles distinction. One Gemma codebase,
> mobile and web."

## Close (~10s)
> "Resilience Compass turns a slow, consultant-heavy, spreadsheet process into an instant, private,
> on-device copilot — the only kind a bank can actually use for this data. Built on Gemma. Offline-first.
> Working today."

---

## Demo choreography — do this BEFORE you present
- [ ] `ollama serve` running, `node serve.js` running, **Chrome open at http://localhost:8422**.
- [ ] Use a **fresh / Incognito** window so the **seeded demo data** loads (2 tolerances, 4 vendors, AWS
      concentration). If you'd already added your own Tools entries, they take precedence — Incognito avoids that.
- [ ] Click **Connect to on-device Gemma → Start** so the model is **warm** (first call is ~8s cold, then ~1–2s).
- [ ] In the Assistant, press **Next pillar** until you reach **Third-Party / Vendor** (the grounding +
      concentration payoff lands here). Your first live answer then triggers the grounded evaluation.
- [ ] Have the two demo texts (the pillar answer + the incident) on your clipboard.

## If something breaks (backups)
- **Slow first token** → it's the model loading into memory; the warm-up step above prevents it.
- **A maturity badge doesn't appear** → the evaluation text still shows; keep going (the parser has a
  regex fallback, so this is rare).
- **"Could not reach Gemma"** → a terminal ran out of `ollama serve`; restart it, refresh, re-Connect.
- **Total failure** → fall back to the mobile story (Flutter + flutter_gemma) and screenshots, but the
  web demo is the reliable live path.

## How this maps to the rubric
- **Demo (50%)** — the airplane-mode moment + real clause-level citations + the grounded concentration
  call are the proof it genuinely runs and genuinely helps.
- **Impact (25%)** — simultaneous global regulation × un-cloudable data = an urgent, real need.
- **Creativity (15%)** — grounding loop, Nth-party concentration risk, multilingual, dual-platform.
- **Pitch (10%)** — this script; keep it to ~2 minutes, let the live demo carry it.
