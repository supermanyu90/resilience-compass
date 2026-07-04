# assets/models/

Place the license-accepted Gemma weight file here (e.g. `gemma-3-1b-it-int4.litertlm`) after the
Hugging Face / Kaggle step in `docs/PLAN.md` §3, then register the exact filename in `pubspec.yaml`
under `flutter: assets:` and load it via `fromAsset('assets/models/<file>.litertlm')`.

The weights are git-ignored (large, license-gated) — they live on the device only, never in the repo,
never synced anywhere. Bundling beats a live download for a conference-wifi demo.
