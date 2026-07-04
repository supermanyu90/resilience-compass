// setup_screen.dart
//
// Stage 1: language + jurisdiction pickers + on-device model load with a real progress bar.
// This is the first visible proof of "on-device" to judges.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/framework_data.dart';
import '../i18n/strings.dart';
import '../models/app_state.dart';
import '../services/gemma_service.dart';
import '../services/persistence.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/disclaimer_card.dart';
import 'home_scaffold.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Future<void> _loadModel() async {
    final app = context.read<AppState>();
    final gemma = context.read<GemmaService>();
    final persist = context.read<Persistence>();

    app.setModelLoading();
    try {
      await gemma.loadModelFromAsset(onProgress: app.setModelProgress);
      app.setModelReady();
      // Persist chosen setup locally (never synced).
      await persist.setLanguage(app.languageCode);
      await persist.setJurisdictions(app.selectedJurisdictions.toList());
    } catch (e) {
      app.setModelError(app.s.modelLoadError);
    }
  }

  void _start() {
    final app = context.read<AppState>();
    context.read<Persistence>().setSetupComplete(true);
    app.completeSetup();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.appTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.appSubtitle,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OfflineBadge(s.offlineBadge),
                ],
              ),
              const SizedBox(height: 24),
              Text(s.setupWelcome, style: _sectionTitle),
              const SizedBox(height: 16),

              // Language
              Text(s.chooseLanguage, style: _label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kLanguageNames.entries.map((e) {
                  final selected = app.languageCode == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) {
                      app.setLanguage(e.key);
                      context.read<Persistence>().setLanguage(e.key);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Jurisdictions
              Text(s.chooseJurisdictions, style: _label),
              const SizedBox(height: 4),
              Text(
                s.jurisdictionHint,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...FrameworkData.jurisdictions.map((j) => _JurisdictionTile(j: j, s: s)),
              const SizedBox(height: 20),

              DisclaimerCard(title: s.disclaimerTitle),
              const SizedBox(height: 24),

              _ModelLoadArea(onLoad: _loadModel, onStart: _start),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static const _sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

class _JurisdictionTile extends StatelessWidget {
  const _JurisdictionTile({required this.j, required this.s});
  final Jurisdiction j;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final selected = j.alwaysOn || app.isJurisdictionSelected(j.id);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: CheckboxListTile(
        value: selected,
        onChanged: j.alwaysOn ? null : (_) => app.toggleJurisdiction(j.id),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text('${j.name} · ${j.region}'),
        subtitle: Text(
          j.reference,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        secondary: j.alwaysOn
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.isoAlwaysOn,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              )
            : null,
      ),
    );
  }
}

class _ModelLoadArea extends StatelessWidget {
  const _ModelLoadArea({required this.onLoad, required this.onStart});
  final VoidCallback onLoad;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    switch (app.modelStatus) {
      case ModelStatus.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onLoad,
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(s.loadModel),
          ),
        );
      case ModelStatus.loading:
        final pct = (app.modelProgress * 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.loadingModel}  $pct%', style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: app.modelProgress == 0 ? null : app.modelProgress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceAlt,
              ),
            ),
          ],
        );
      case ModelStatus.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.good, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.modelReady,
                    style: const TextStyle(color: AppColors.good, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onStart, child: Text(s.start)),
          ],
        );
      case ModelStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              app.modelError ?? s.modelLoadError,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onLoad,
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
          ],
        );
    }
  }
}
