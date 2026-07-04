// app_state.dart
//
// App-wide session state (Provider ChangeNotifier). Kept deliberately simple.

import 'package:flutter/foundation.dart';

import '../data/framework_data.dart';
import '../i18n/strings.dart';

enum ModelStatus { idle, loading, ready, error }

class AppState extends ChangeNotifier {
  AppState({this.languageCode = 'en'});

  String languageCode;

  /// ISO 22301 is always on and cannot be removed.
  final Set<String> _selectedJurisdictions = {'iso22301'};

  ModelStatus modelStatus = ModelStatus.idle;
  double modelProgress = 0; // 0..1
  String? modelError;

  bool setupComplete = false;

  // ---- Derived ----
  AppStrings get s => stringsFor(languageCode);

  Set<String> get selectedJurisdictions => Set.unmodifiable(_selectedJurisdictions);

  /// Active jurisdictions in canonical order (ISO baseline first).
  List<Jurisdiction> get activeJurisdictions => FrameworkData.jurisdictions
      .where((j) => j.alwaysOn || _selectedJurisdictions.contains(j.id))
      .toList();

  bool get isReady => modelStatus == ModelStatus.ready;

  // ---- Mutations ----
  void setLanguage(String code) {
    if (code == languageCode || !kLanguageNames.containsKey(code)) return;
    languageCode = code;
    notifyListeners();
  }

  bool isJurisdictionSelected(String id) => _selectedJurisdictions.contains(id);

  void toggleJurisdiction(String id) {
    final j = FrameworkData.jurisdictions.firstWhere(
      (e) => e.id == id,
      orElse: () => throw ArgumentError('Unknown jurisdiction: $id'),
    );
    if (j.alwaysOn) return; // ISO baseline is locked on
    if (!_selectedJurisdictions.add(id)) {
      _selectedJurisdictions.remove(id);
    }
    notifyListeners();
  }

  void setModelLoading() {
    modelStatus = ModelStatus.loading;
    modelProgress = 0;
    modelError = null;
    notifyListeners();
  }

  void setModelProgress(double p) {
    modelProgress = p.clamp(0, 1).toDouble();
    if (modelStatus != ModelStatus.loading) modelStatus = ModelStatus.loading;
    notifyListeners();
  }

  void setModelReady() {
    modelStatus = ModelStatus.ready;
    modelProgress = 1;
    modelError = null;
    notifyListeners();
  }

  void setModelError(String message) {
    modelStatus = ModelStatus.error;
    modelError = message;
    notifyListeners();
  }

  void completeSetup() {
    setupComplete = true;
    notifyListeners();
  }
}
