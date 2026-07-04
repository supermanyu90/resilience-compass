// badges.dart — small reusable status widgets.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Offline · On-device" pill — the app's always-visible trust signal.
class OfflineBadge extends StatelessWidget {
  const OfflineBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.good.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.good.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.good, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.good,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured 1–4 maturity chip, e.g. "Maturity 3/4".
class MaturityBadge extends StatelessWidget {
  const MaturityBadge({super.key, required this.score, required this.label});
  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.maturity(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label $score/4',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// 0–100 circular resilience gauge.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, this.size = 96});
  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreBand(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linear pillar progress with a "Pillar n of total" caption.
class PillarProgress extends StatelessWidget {
  const PillarProgress({
    super.key,
    required this.index,
    required this.total,
    required this.label,
  });
  final int index; // 0-based
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (index + 1) / total,
            minHeight: 6,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
