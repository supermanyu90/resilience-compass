// chat_bubble.dart — one message bubble in the BCM Assistant.

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'badges.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.strings});
  final ChatMessage message;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final assessment = message.assessment;
    final showScore = assessment != null && assessment.isScored;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary.withValues(alpha: 0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.isEmpty && message.isStreaming)
              _TypingDots()
            else
              SelectableText(
                message.text,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.45),
              ),
            if (showScore) ...[
              const SizedBox(height: 10),
              MaturityBadge(score: assessment.maturity!, label: strings.maturityLabel),
              if (assessment.citations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: assessment.citations
                      .map((c) => _CitationChip(c))
                      .toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value + i * 0.2) % 1.0);
            final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(radius: 3, backgroundColor: AppColors.textSecondary),
              ),
            );
          }),
        );
      },
    );
  }
}
