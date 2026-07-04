// assessment.dart
//
// Result of evaluating a user's answer for one BCM pillar.

class PillarAssessment {
  final String pillarId;

  /// 1–4 maturity score, or null if the model couldn't extract one
  /// (e.g. the user asked a free-form question instead of answering).
  final int? maturity;

  /// Short natural-language justification from the model.
  final String? rationale;

  /// Named regulator citations, e.g. "ISO 22301 clause 8.4.2",
  /// "APRA CPS 230 (Recovery objectives)".
  final List<String> citations;

  const PillarAssessment({
    required this.pillarId,
    this.maturity,
    this.rationale,
    this.citations = const [],
  });

  bool get isScored => maturity != null;
}
