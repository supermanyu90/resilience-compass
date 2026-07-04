// incident.dart
//
// Result of the Incident Scanner: the model's classification plus the combined resilience score.

enum Severity { low, medium, high, unknown }

Severity severityFromString(String? v) {
  switch ((v ?? '').trim().toLowerCase()) {
    case 'low':
      return Severity.low;
    case 'medium':
    case 'moderate':
      return Severity.medium;
    case 'high':
    case 'critical':
    case 'severe':
      return Severity.high;
    default:
      return Severity.unknown;
  }
}

/// The model's structured classification of a pasted incident.
class IncidentClassification {
  /// One of FrameworkData.incidentCategories keys (people/process/technology/third-party/cyber/facilities).
  final String category;
  final Severity severity;
  final String impactArea;
  final String rationale;

  const IncidentClassification({
    required this.category,
    required this.severity,
    required this.impactArea,
    this.rationale = '',
  });
}

/// Full scanner outcome: classification + the 0–100 resilience score derived from it
/// together with the user-supplied likelihood and control maturity.
class IncidentResult {
  final IncidentClassification classification;
  final int resilienceScore; // 0–100

  const IncidentResult({
    required this.classification,
    required this.resilienceScore,
  });
}
