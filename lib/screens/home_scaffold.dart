// home_scaffold.dart
//
// Bottom-tab navigation between the BCM Assistant and the Incident Scanner, plus an in-session
// language switcher (so a judge can watch both the UI chrome AND the assistant's reply language
// change live) and an About action.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.dart';
import '../models/app_state.dart';
import '../services/persistence.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'scanner_screen.dart';
import 'tools_screen.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Flexible(
              child: Text(
                [s.assistantTitle, s.scannerTitle, s.tabTools][_index],
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            OfflineBadge(s.offlineBadge),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate),
            tooltip: s.chooseLanguage,
            onSelected: (code) {
              app.setLanguage(code);
              context.read<Persistence>().setLanguage(code);
            },
            itemBuilder: (_) => kLanguageNames.entries
                .map((e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          if (app.languageCode == e.key)
                            const Icon(Icons.check, size: 16, color: AppColors.primary)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(e.value),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: s.menuAbout,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [AssistantScreen(), ScannerScreen(), ToolsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            label: s.tabAssistant,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radar_outlined),
            selectedIcon: const Icon(Icons.radar),
            label: s.tabScanner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handyman_outlined),
            selectedIcon: const Icon(Icons.handyman),
            label: s.tabTools,
          ),
        ],
      ),
    );
  }
}
