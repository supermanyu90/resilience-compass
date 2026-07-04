# reference/

Drop the existing web app here as `reference/resilience-suite/` with its three files:

- `framework-data.js` — 10 BCM pillars + citations, incident categories, jurisdictions, languages, maturity scale
- `i18n.js` — UI strings for en, hi, zh, es, fr, pt
- `app.js` — chat wizard + incident classifier prompts, JSON-extraction parsing, resilience scoring, Tools-panel logic

Once it's here I'll port the citations, UI strings, prompts, and scoring formula **verbatim** into `lib/`
(replacing the fallback port currently in `lib/data/framework_data.dart`). The compliance content was
already fact-checked against primary sources — it will not be re-researched or rephrased.
