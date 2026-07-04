// main.dart — Resilience Compass Mobile entry point.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'i18n/strings.dart';
import 'models/app_state.dart';
import 'models/tools_state.dart';
import 'services/gemma_service.dart';
import 'services/persistence.dart';
import 'theme/app_theme.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final persistence = await Persistence.create();
  final gemma = GemmaService();
  final toolsState = ToolsState(persistence)..load();

  final appState = AppState(languageCode: persistence.language ?? 'en');
  // Restore any previously selected jurisdictions (ISO is always on already).
  for (final id in persistence.jurisdictions) {
    if (id != 'iso22301') appState.toggleJurisdiction(id);
  }

  runApp(ResilienceApp(
    appState: appState,
    gemma: gemma,
    persistence: persistence,
    toolsState: toolsState,
  ));
}

class ResilienceApp extends StatelessWidget {
  const ResilienceApp({
    super.key,
    required this.appState,
    required this.gemma,
    required this.persistence,
    required this.toolsState,
  });

  final AppState appState;
  final GemmaService gemma;
  final Persistence persistence;
  final ToolsState toolsState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ToolsState>.value(value: toolsState),
        Provider<GemmaService>.value(value: gemma),
        Provider<Persistence>.value(value: persistence),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          title: 'Resilience Compass',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: Locale(app.languageCode),
          supportedLocales: kLanguageNames.keys.map((c) => Locale(c)).toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SetupScreen(),
        ),
      ),
    );
  }
}
