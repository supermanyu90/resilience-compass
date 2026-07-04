// scoring.dart
//
// 0–100 resilience score for the Incident Scanner.
//
// NOTE: The web app's exact formula lives in app.js. This is a faithful RECONSTRUCTION from the
// documented inputs (model severity + user likelihood + user control maturity). If app.js is
// provided, replace computeResilienceScore with its exact formula.
//
// Model:
//   inherentRisk   = severity(1..3) * likelihood(1..3)      -> 1..9, normalised to 0..1
//   controlFactor  = (controlMaturity(1..4) - 1) / 3        -> 0..1 effectiveness
//   residualRisk   = inherentRiskNorm * (1 - controlFactor) -> 0..1
//   resilience     = round(100 * (1 - residualRisk))        -> 0..100

import '../models/incident.dart';

class Scoring {
  Scoring._();

  static int _severityWeight(Severity s) {
    switch (s) {
      case Severity.low:
        return 1;
      case Severity.high:
        return 3;
      case Severity.medium:
      case Severity.unknown:
        return 2;
    }
  }

  /// [likelihood] is 1..3 (low/med/high); [controlMaturity] is 1..4 on the BCM maturity scale.
  static int computeResilienceScore({
    required Severity severity,
    required int likelihood,
    required int controlMaturity,
  }) {
    final sev = _severityWeight(severity);
    final lik = likelihood.clamp(1, 3);
    final ctrl = controlMaturity.clamp(1, 4);

    final inherentRiskNorm = (sev * lik - 1) / 8.0; // 0..1
    final controlFactor = (ctrl - 1) / 3.0; // 0..1
    final residualRisk = inherentRiskNorm * (1 - controlFactor); // 0..1
    final score = (100 * (1 - residualRisk)).round();
    return score.clamp(0, 100);
  }
}
