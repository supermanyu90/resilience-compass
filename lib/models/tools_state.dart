// tools_state.dart
//
// Holds the two Tools-panel registers (local only), computes concentration risk, and produces the
// grounding text fed back into the BCM Assistant for the 'tolerance' and 'third-party' pillars.

import 'package:flutter/foundation.dart';

import '../services/persistence.dart';
import 'tools.dart';

class ToolsState extends ChangeNotifier {
  ToolsState(this._p);
  final Persistence _p;

  final List<ToleranceEntry> tolerances = [];
  final List<VendorEntry> vendors = [];

  /// Load persisted registers (synchronous — Persistence getters read a cached SharedPreferences).
  void load() {
    tolerances
      ..clear()
      ..addAll(_p.toleranceRegister.map(ToleranceEntry.fromMap));
    vendors
      ..clear()
      ..addAll(_p.vendorRegister.map(VendorEntry.fromMap));
    notifyListeners();
  }

  void addTolerance(ToleranceEntry e) {
    tolerances.add(e);
    _p.setToleranceRegister(tolerances.map((t) => t.toMap()).toList());
    notifyListeners();
  }

  void removeTolerance(int index) {
    if (index < 0 || index >= tolerances.length) return;
    tolerances.removeAt(index);
    _p.setToleranceRegister(tolerances.map((t) => t.toMap()).toList());
    notifyListeners();
  }

  void addVendor(VendorEntry e) {
    vendors.add(e);
    _p.setVendorRegister(vendors.map((v) => v.toMap()).toList());
    notifyListeners();
  }

  void removeVendor(int index) {
    if (index < 0 || index >= vendors.length) return;
    vendors.removeAt(index);
    _p.setVendorRegister(vendors.map((v) => v.toMap()).toList());
    notifyListeners();
  }

  /// Nth-parties depended on by 2+ distinct vendors, most-shared first.
  List<ConcentrationRisk> concentrationRisks() {
    final byParty = <String, _Agg>{};
    for (final v in vendors) {
      final seenForVendor = <String>{};
      for (final npRaw in v.nthParties) {
        final np = npRaw.trim();
        if (np.isEmpty) continue;
        final key = np.toLowerCase();
        if (!seenForVendor.add(key)) continue; // ignore a vendor listing the same party twice
        final agg = byParty.putIfAbsent(key, () => _Agg(np));
        if (!agg.vendors.contains(v.vendor)) agg.vendors.add(v.vendor);
      }
    }
    final risks = byParty.values
        .where((a) => a.vendors.length >= 2)
        .map((a) => ConcentrationRisk(nthParty: a.display, vendors: a.vendors))
        .toList()
      ..sort((x, y) => y.count.compareTo(x.count));
    return risks;
  }

  // ---- Grounding fed into the Assistant's system prompt ----

  String? toleranceGrounding() {
    if (tolerances.isEmpty) return null;
    final b = StringBuffer('Configured impact tolerances / recovery objectives:\n');
    for (final t in tolerances) {
      final obj = t.objectives.isEmpty ? '(no objectives set)' : t.objectives.join(', ');
      b.writeln('- ${t.service}: $obj');
    }
    return b.toString().trim();
  }

  String? thirdPartyGrounding() {
    if (vendors.isEmpty) return null;
    final b = StringBuffer('Mapped vendors and their Nth-party dependencies:\n');
    for (final v in vendors) {
      final svc = v.service.isNotEmpty ? ' (${v.service})' : '';
      final deps = v.nthParties.isEmpty ? '(none listed)' : v.nthParties.join(', ');
      b.writeln('- ${v.vendor}$svc: $deps');
    }
    final risks = concentrationRisks();
    if (risks.isNotEmpty) {
      b.writeln('Concentration risks (Nth-parties shared across vendors):');
      for (final r in risks) {
        b.writeln('- ${r.nthParty}: shared by ${r.vendors.join(", ")}');
      }
    }
    return b.toString().trim();
  }

  /// Grounding for a given pillar id, or null if that pillar has no attached tools data.
  String? groundingForPillar(String pillarId) {
    switch (pillarId) {
      case 'tolerance':
        return toleranceGrounding();
      case 'third-party':
        return thirdPartyGrounding();
      default:
        return null;
    }
  }
}

class _Agg {
  _Agg(this.display);
  final String display; // first-seen casing, for readable output
  final List<String> vendors = [];
}
