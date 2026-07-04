// about_screen.dart — privacy statement + compliance disclaimer.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/disclaimer_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.aboutTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OfflineBadge(s.offlineBadge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.good),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.privacyNote,
                          style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                leading: const Icon(Icons.memory, size: 18, color: AppColors.textSecondary),
                title: Text(
                  'Model asset: $kGemmaModelAsset',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              DisclaimerCard(title: s.disclaimerTitle),
            ],
          ),
        ),
      ),
    );
  }
}
