// tools.dart
//
// Data models for the Tools panel: Impact Tolerance Configurator + Nth-Party Dependency Mapper.
// All local-only; serialised to/from the shared_preferences registers.

/// One critical service's impact tolerance / recovery objectives (mirrors the 'tolerance' pillar).
class ToleranceEntry {
  final String service;
  final String rto; // Recovery Time Objective
  final String rpo; // Recovery Point Objective
  final String mtpd; // Maximum Tolerable Period of Disruption
  final String srto; // Survival / Stressed RTO

  const ToleranceEntry({
    required this.service,
    this.rto = '',
    this.rpo = '',
    this.mtpd = '',
    this.srto = '',
  });

  Map<String, dynamic> toMap() =>
      {'service': service, 'rto': rto, 'rpo': rpo, 'mtpd': mtpd, 'srto': srto};

  factory ToleranceEntry.fromMap(Map<String, dynamic> m) => ToleranceEntry(
        service: (m['service'] ?? '').toString(),
        rto: (m['rto'] ?? '').toString(),
        rpo: (m['rpo'] ?? '').toString(),
        mtpd: (m['mtpd'] ?? '').toString(),
        srto: (m['srto'] ?? '').toString(),
      );

  /// Non-empty objective pairs, e.g. ["RTO 4h", "RPO 15m"].
  List<String> get objectives {
    final out = <String>[];
    if (rto.isNotEmpty) out.add('RTO $rto');
    if (rpo.isNotEmpty) out.add('RPO $rpo');
    if (mtpd.isNotEmpty) out.add('MTPD $mtpd');
    if (srto.isNotEmpty) out.add('SRTO $srto');
    return out;
  }
}

/// One vendor and the Nth-party providers it depends on (mirrors the 'third-party' pillar).
class VendorEntry {
  final String vendor;
  final String service;
  final List<String> nthParties;

  const VendorEntry({
    required this.vendor,
    this.service = '',
    this.nthParties = const [],
  });

  Map<String, dynamic> toMap() =>
      {'vendor': vendor, 'service': service, 'nthParties': nthParties};

  factory VendorEntry.fromMap(Map<String, dynamic> m) {
    final raw = m['nthParties'];
    final list = raw is List
        ? raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return VendorEntry(
      vendor: (m['vendor'] ?? '').toString(),
      service: (m['service'] ?? '').toString(),
      nthParties: list,
    );
  }
}

/// An Nth-party depended on by 2+ vendors — a concentration risk.
class ConcentrationRisk {
  final String nthParty;
  final List<String> vendors;

  const ConcentrationRisk({required this.nthParty, required this.vendors});

  int get count => vendors.length;
}
