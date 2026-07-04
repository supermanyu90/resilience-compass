// prompt_builder.dart
//
// System prompts for the BCM wizard and the incident classifier.
// If reference/resilience-suite/app.js is provided, replace these with its verbatim prompts.
//
// Design note: Gemma 3 1B is small, so prompts are explicit, short, and ask for a single
// machine-readable tag that json_extractor.dart parses. Keep instructions terse and unambiguous.

import '../data/framework_data.dart';
import '../i18n/strings.dart';

/// Marker the assistant appends after a scored evaluation. Parsed + stripped before display.
const String kAssessmentTag = '[[ASSESSMENT]]';

class PromptBuilder {
  PromptBuilder._();

  static String _jurisdictionBlock(List<Jurisdiction> js) {
    return js.map((j) {
      final style = j.citationStyle == CitationStyle.clauseNumbered
          ? 'cite exact clause numbers'
          : 'principles-based — cite the named section/principle, not a clause number';
      return '- ${j.name} (${j.region}): ${j.reference} — $style';
    }).join('\n');
  }

  static String _replyLanguage(String languageCode) =>
      kLanguageReplyName[languageCode] ?? 'English';

  /// System prompt for a single pillar's chat session.
  static String bcmSystemPrompt({
    required Pillar pillar,
    required List<Jurisdiction> jurisdictions,
    required String languageCode,
    String? grounding,
  }) {
    final lang = _replyLanguage(languageCode);
    final groundingBlock = (grounding != null && grounding.trim().isNotEmpty)
        ? '\n\nThe practitioner has already entered this data in the Tools panel — use it directly in your evaluation and refer to the specifics:\n${grounding.trim()}'
        : '';
    return '''
You are Resilience Compass, an expert operational-resilience and business-continuity (BCM) advisor for banks. You help a practitioner self-assess their organisation against regulatory expectations.

ALWAYS reply in $lang.

The practitioner selected these regulatory frameworks. When you evaluate an answer, cite the specific, relevant framework by name and section:
${_jurisdictionBlock(jurisdictions)}

Citation rules:
- ISO 22301 is clause-numbered — cite exact clause numbers (e.g. "ISO 22301 clause 8.4.2").
- HKMA, MAS, APRA, RBI and the US interagency guidance are principles-based — cite the named section/theme, never an invented clause number.
- Never fabricate a citation. If unsure of an exact reference, name the framework and the relevant theme only.

You are currently assessing this pillar:
"${pillar.title}" — ${pillar.prompt}$groundingBlock

Maturity scale: 1 = Not started/ad hoc, 2 = Partially defined, 3 = Established & documented, 4 = Advanced/continuously improved.

How to respond:
- If the practitioner DESCRIBES their current practice: give a concise evaluation (<= 120 words) grounded in the selected frameworks, name the main gap, and cite by name. Then, on a NEW final line, append exactly one tag — valid JSON only, no angle brackets or placeholders — for example:
$kAssessmentTag {"maturity": 2, "citations": ["ISO 22301 clause 8.4.2", "APRA CPS 230 (Recovery objectives)"], "rationale": "Recovery objectives exist but are not board-approved."}
Set "maturity" to your actual integer score from 1 to 4.
- If the practitioner ASKS A QUESTION instead of answering: answer it helpfully and concisely, grounded in the selected frameworks, and DO NOT append the $kAssessmentTag tag.

This is a self-assessment aid, not legal advice or a certification audit. Never claim it guarantees compliance.''';
  }

  /// System prompt for the incident classifier (one-shot, JSON only).
  static String incidentSystemPrompt({
    required List<Jurisdiction> jurisdictions,
    required String languageCode,
  }) {
    final lang = _replyLanguage(languageCode);
    final cats = FrameworkData.incidentCategories.join(', ');
    return '''
You are Resilience Compass, an operational-resilience incident classifier for banks.

Classify the incident the user provides into EXACTLY ONE category from this list:
$cats

Return ONLY a single valid JSON object and nothing else — no markdown fences, no commentary:
{"category": "<one of: $cats>", "severity": "low|medium|high", "impactArea": "<short phrase in $lang>", "rationale": "<one short sentence in $lang>"}''';
  }

  /// Localised opening question for a pillar (deterministic — no inference needed).
  static String pillarQuestion(Pillar pillar) => pillar.prompt;
}
