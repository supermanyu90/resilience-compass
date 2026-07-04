// json_extractor.dart
//
// Robustly pull structured data out of a small model's free-form output.
// Handles JSON wrapped in prose, code fences, or trailing text.

import 'dart:convert';

import '../models/assessment.dart';
import '../models/incident.dart';
import '../data/framework_data.dart';
import 'prompt_builder.dart';

class JsonExtractor {
  JsonExtractor._();

  /// Returns the first balanced `{...}` JSON object substring in [s], or null.
  /// Walks brace depth while respecting string literals + escapes.
  static String? firstJsonObject(String s) {
    final start = s.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < s.length; i++) {
      final ch = s[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == '\\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return s.substring(start, i + 1);
      }
    }
    return null; // unbalanced
  }

  static Map<String, dynamic>? _tryDecodeObject(String s) {
    final obj = firstJsonObject(s);
    if (obj == null) return null;
    try {
      final decoded = jsonDecode(obj);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// The visible chat text: everything before the assessment tag, trimmed.
  static String displayText(String raw) {
    final idx = raw.indexOf(kAssessmentTag);
    final visible = idx >= 0 ? raw.substring(0, idx) : raw;
    return visible.trim();
  }

  /// Parse the trailing [[ASSESSMENT]] tag into a PillarAssessment.
  /// Returns null when the model didn't emit one (e.g. it answered a free-form question).
  static PillarAssessment? extractAssessment(String pillarId, String raw) {
    final idx = raw.indexOf(kAssessmentTag);
    if (idx < 0) return null;
    final tail = raw.substring(idx + kAssessmentTag.length);
    final map = _tryDecodeObject(tail);
    if (map == null) return null;

    int? maturity;
    final m = map['maturity'];
    if (m is int) {
      maturity = m;
    } else if (m is num) {
      maturity = m.round();
    } else if (m is String) {
      maturity = int.tryParse(m.trim());
    }
    if (maturity != null) maturity = maturity.clamp(1, 4);

    final citations = <String>[];
    final c = map['citations'];
    if (c is List) {
      for (final e in c) {
        final t = e?.toString().trim();
        if (t != null && t.isNotEmpty) citations.add(t);
      }
    }

    return PillarAssessment(
      pillarId: pillarId,
      maturity: maturity,
      rationale: map['rationale']?.toString().trim(),
      citations: citations,
    );
  }

  /// Parse the incident classifier's JSON output.
  static IncidentClassification? extractIncident(String raw) {
    final map = _tryDecodeObject(raw);
    if (map == null) return null;

    final rawCat = (map['category'] ?? '').toString().trim().toLowerCase();
    final category = FrameworkData.incidentCategories.contains(rawCat)
        ? rawCat
        : _closestCategory(rawCat);

    return IncidentClassification(
      category: category,
      severity: severityFromString(map['severity']?.toString()),
      impactArea: (map['impactArea'] ?? map['impact_area'] ?? '').toString().trim(),
      rationale: (map['rationale'] ?? '').toString().trim(),
    );
  }

  /// Best-effort fallback if the model returns a near-miss category label.
  static String _closestCategory(String raw) {
    if (raw.isEmpty) return 'process';
    for (final cat in FrameworkData.incidentCategories) {
      if (raw.contains(cat) || cat.contains(raw)) return cat;
    }
    if (raw.contains('vendor') || raw.contains('supplier') || raw.contains('party')) {
      return 'third-party';
    }
    if (raw.contains('it') || raw.contains('system') || raw.contains('tech')) {
      return 'technology';
    }
    return 'process';
  }
}
