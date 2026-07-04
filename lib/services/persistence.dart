// persistence.dart
//
// Local-only storage (shared_preferences). Mirrors the web app's localStorage use.
// NOTHING here is ever synced off-device.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Persistence {
  Persistence(this._prefs);
  final SharedPreferences _prefs;

  static Future<Persistence> create() async =>
      Persistence(await SharedPreferences.getInstance());

  static const _kLanguage = 'rc_language';
  static const _kJurisdictions = 'rc_jurisdictions';
  static const _kSetupComplete = 'rc_setup_complete';
  static const _kToleranceRegister = 'rc_tolerance_register';
  static const _kVendorRegister = 'rc_vendor_register';

  // ---- Setup prefs ----
  String? get language => _prefs.getString(_kLanguage);
  Future<void> setLanguage(String v) => _prefs.setString(_kLanguage, v);

  List<String> get jurisdictions =>
      _prefs.getStringList(_kJurisdictions) ?? const <String>[];
  Future<void> setJurisdictions(List<String> v) =>
      _prefs.setStringList(_kJurisdictions, v);

  bool get setupComplete => _prefs.getBool(_kSetupComplete) ?? false;
  Future<void> setSetupComplete(bool v) => _prefs.setBool(_kSetupComplete, v);

  // ---- Tools-panel registers (stretch feature). Stored as JSON, local only. ----
  List<Map<String, dynamic>> get toleranceRegister => _decodeList(_kToleranceRegister);
  Future<void> setToleranceRegister(List<Map<String, dynamic>> v) =>
      _prefs.setString(_kToleranceRegister, jsonEncode(v));

  List<Map<String, dynamic>> get vendorRegister => _decodeList(_kVendorRegister);
  Future<void> setVendorRegister(List<Map<String, dynamic>> v) =>
      _prefs.setString(_kVendorRegister, jsonEncode(v));

  List<Map<String, dynamic>> _decodeList(String key) {
    final s = _prefs.getString(key);
    if (s == null || s.isEmpty) return [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
