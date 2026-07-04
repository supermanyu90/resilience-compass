// framework_data.dart
//
// Platform-agnostic regulatory dataset for Resilience Compass Mobile.
//
// SOURCE OF TRUTH: This is a Dart port of the FALLBACK dataset from the build prompt.
// If reference/resilience-suite/framework-data.js is provided, REPLACE the contents below with a
// verbatim port of that file (citations were fact-checked against primary sources — do not rephrase).
//
// Precision caveat (surface in the app disclaimer): ISO 22301 is clause-numbered (exact clause refs);
// HKMA/MAS/APRA/RBI/Fed are principles-based (refs point to a named section, not a clause number).
// This is a self-assessment aid, not legal advice or a certification audit, and does not guarantee compliance.

/// How a regulator's references are expressed — drives the citation-precision disclaimer.
enum CitationStyle { clauseNumbered, principlesBased }

class Jurisdiction {
  final String id;
  final String name;
  final String region;
  final String reference;
  final CitationStyle citationStyle;
  final bool alwaysOn; // ISO 22301 baseline is always active

  const Jurisdiction({
    required this.id,
    required this.name,
    required this.region,
    required this.reference,
    required this.citationStyle,
    this.alwaysOn = false,
  });
}

/// One of the 10 BCM self-assessment pillars.
class Pillar {
  final String id;
  final String title;
  final String prompt; // one-line framing used to seed the assistant's question

  const Pillar({required this.id, required this.title, required this.prompt});
}

class MaturityLevel {
  final int score; // 1..4
  final String label;
  const MaturityLevel(this.score, this.label);
}

class FrameworkData {
  FrameworkData._();

  /// ISO 22301 is the always-on baseline; the rest are user-selectable.
  static const List<Jurisdiction> jurisdictions = [
    Jurisdiction(
      id: 'iso22301',
      name: 'ISO 22301:2019',
      region: 'Baseline (always on)',
      reference: 'ISO 22301:2019 — clause references',
      citationStyle: CitationStyle.clauseNumbered,
      alwaysOn: true,
    ),
    Jurisdiction(
      id: 'hkma',
      name: 'HKMA',
      region: 'Hong Kong',
      reference: 'HKMA SPM OR-2 (Operational Resilience)',
      citationStyle: CitationStyle.principlesBased,
    ),
    Jurisdiction(
      id: 'mas',
      name: 'MAS',
      region: 'Singapore',
      reference: 'MAS Operational Resilience / ORM Guidelines',
      citationStyle: CitationStyle.principlesBased,
    ),
    Jurisdiction(
      id: 'apra',
      name: 'APRA',
      region: 'Australia',
      reference: 'APRA CPS 230 (Operational Risk Management)',
      citationStyle: CitationStyle.principlesBased,
    ),
    Jurisdiction(
      id: 'rbi',
      name: 'RBI',
      region: 'India',
      reference: 'RBI Guidance Note on Operational Risk Management & Operational Resilience (Apr 2024)',
      citationStyle: CitationStyle.principlesBased,
    ),
    Jurisdiction(
      id: 'us_interagency',
      name: 'Fed / OCC / FDIC',
      region: 'United States',
      reference: 'Interagency Paper on Sound Practices to Strengthen Operational Resilience',
      citationStyle: CitationStyle.principlesBased,
    ),
  ];

  /// The 10 BCM pillars, in the guided-assessment order.
  static const List<Pillar> pillars = [
    Pillar(
      id: 'governance',
      title: 'Governance & Board Oversight',
      prompt: 'How does the board and senior management own and oversee operational resilience?',
    ),
    Pillar(
      id: 'policy-scope',
      title: 'Policy & Scope',
      prompt: 'Is there a documented resilience/BCM policy, and how is its scope defined?',
    ),
    Pillar(
      id: 'critical-ops',
      title: 'Critical Operations / Critical Business Services',
      prompt: 'How are critical business services identified and mapped end to end?',
    ),
    Pillar(
      id: 'bia',
      title: 'Business Impact Analysis',
      prompt: 'How is the impact of disruption to critical services assessed over time?',
    ),
    Pillar(
      id: 'tolerance',
      title: 'Impact Tolerance & Recovery Objectives (RTO/RPO/MTPD/SRTO)',
      prompt: 'Are impact tolerances and recovery objectives set for each critical service?',
    ),
    Pillar(
      id: 'risk-assessment',
      title: 'Operational Risk Identification & Treatment',
      prompt: 'How are operational risks to critical services identified, assessed and treated?',
    ),
    Pillar(
      id: 'third-party',
      title: 'Third-Party / Vendor & Service Provider Management',
      prompt: 'How are third-party and Nth-party dependencies managed for resilience?',
    ),
    Pillar(
      id: 'bcdr-plans',
      title: 'Business Continuity & Disaster Recovery Plans',
      prompt: 'Are BC and DR plans documented, current, and actionable for critical services?',
    ),
    Pillar(
      id: 'testing',
      title: 'Scenario Testing & Exercises',
      prompt: 'How are severe-but-plausible scenarios tested against impact tolerances?',
    ),
    Pillar(
      id: 'monitoring',
      title: 'Monitoring, Reporting & Continuous Improvement',
      prompt: 'How is resilience monitored, reported to the board, and continuously improved?',
    ),
  ];

  /// Incident Scanner categories (keys are stable; translated labels live in i18n).
  static const List<String> incidentCategories = [
    'people',
    'process',
    'technology',
    'third-party',
    'cyber',
    'facilities',
  ];

  static const List<MaturityLevel> maturityScale = [
    MaturityLevel(1, 'Not started / ad hoc'),
    MaturityLevel(2, 'Partially defined'),
    MaturityLevel(3, 'Established & documented'),
    MaturityLevel(4, 'Advanced / continuously improved'),
  ];

  /// Supported UI + assistant-reply languages (BCP-47-ish codes).
  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'zh': '简体中文',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
  };

  static const String disclaimer =
      'ISO 22301 references are clause-numbered; HKMA, MAS, APRA, RBI and the US interagency '
      'guidance are principles-based (references point to a named section, not a clause number). '
      'Resilience Compass is a self-assessment aid — not legal advice or a certification audit — '
      'and does not guarantee regulatory compliance.';
}
