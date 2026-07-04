// scanner_screen.dart
//
// Stage 3: paste/describe an incident -> Gemma classifies it on-device (category/severity/impact
// as JSON) -> combine with user-picked likelihood + control maturity into the 0–100 resilience score.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/incident.dart';
import '../services/gemma_service.dart';
import '../services/json_extractor.dart';
import '../services/prompt_builder.dart';
import '../services/scoring.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _input = TextEditingController();
  int _likelihood = 2; // 1..3
  int _control = 2; // 1..4
  IncidentResult? _result;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    final app = context.read<AppState>();
    final gemma = context.read<GemmaService>();

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final sys = PromptBuilder.incidentSystemPrompt(
        jurisdictions: app.activeJurisdictions,
        languageCode: app.languageCode,
      );
      final raw = await gemma.complete(systemPrompt: sys, userText: text);
      final cls = JsonExtractor.extractIncident(raw);
      if (cls == null) {
        setState(() => _error = app.s.modelLoadError);
        return;
      }
      final score = Scoring.computeResilienceScore(
        severity: cls.severity,
        likelihood: _likelihood,
        controlMaturity: _control,
      );
      setState(() => _result = IncidentResult(classification: cls, resilienceScore: score));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _severityLabel(Severity sev, AppState app) {
    final s = app.s;
    switch (sev) {
      case Severity.low:
        return s.low;
      case Severity.high:
        return s.high;
      case Severity.medium:
        return s.medium;
      case Severity.unknown:
        return '—';
    }
  }

  Color _severityColor(Severity sev) {
    switch (sev) {
      case Severity.low:
        return AppColors.good;
      case Severity.high:
        return AppColors.danger;
      default:
        return AppColors.warn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.scannerIntro, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(hintText: s.incidentHint),
            ),
            const SizedBox(height: 16),

            Text(s.likelihood, style: _label),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 1, label: Text(s.low)),
                ButtonSegment(value: 2, label: Text(s.medium)),
                ButtonSegment(value: 3, label: Text(s.high)),
              ],
              selected: {_likelihood},
              onSelectionChanged: (v) => setState(() => _likelihood = v.first),
            ),
            const SizedBox(height: 16),

            Text(s.controlMaturity, style: _label),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {_control},
              onSelectionChanged: (v) => setState(() => _control = v.first),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _analyze,
                icon: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.radar),
                label: Text(_busy ? s.analyzing : s.analyze),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],

            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(
                result: _result!,
                strings: s,
                severityLabel: _severityLabel(_result!.classification.severity, app),
                severityColor: _severityColor(_result!.classification.severity),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _label = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.strings,
    required this.severityLabel,
    required this.severityColor,
  });
  final IncidentResult result;
  final dynamic strings; // AppStrings
  final String severityLabel;
  final Color severityColor;

  String _categoryLabel(String key) {
    if (key.isEmpty) return '—';
    final spaced = key.replaceAll('-', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = result.classification;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                ScoreGauge(score: result.resilienceScore),
                const SizedBox(height: 6),
                Text(
                  strings.resilienceScore,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(strings.category, _categoryLabel(c.category)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${strings.severity}: ',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: severityColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(severityLabel,
                            style: TextStyle(color: severityColor, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _kv(strings.impactArea, c.impactArea.isEmpty ? '—' : c.impactArea),
                  if (c.rationale.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.rationale,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        children: [
          TextSpan(text: '$k: ', style: const TextStyle(color: AppColors.textSecondary)),
          TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
