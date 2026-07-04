// disclaimer_card.dart — the always-available compliance disclaimer.

import 'package:flutter/material.dart';

import '../data/framework_data.dart';
import '../theme/app_theme.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              FrameworkData.disclaimer,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
