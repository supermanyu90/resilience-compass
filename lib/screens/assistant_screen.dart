// assistant_screen.dart
//
// Stage 2 (flagship): guided BCM self-assessment chat.
//  - Walks the 10 pillars one at a time (a fresh Gemma chat per pillar keeps context bounded).
//  - The model opens each pillar with a localized question, then evaluates the practitioner's
//    answer against the selected jurisdictions, cites the regulator by name, and emits a 1–4
//    maturity score (parsed from a trailing [[ASSESSMENT]] tag and stripped from the display).
//  - Free-form questions are answered without forcing a score.
//  - Changing language mid-session restarts the current pillar so replies switch language live.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/framework_data.dart';
import '../models/app_state.dart';
import '../models/assessment.dart';
import '../models/chat_message.dart';
import '../models/tools_state.dart';
import '../services/gemma_service.dart';
import '../services/json_extractor.dart';
import '../services/prompt_builder.dart';
import '../theme/app_theme.dart';
import '../widgets/badges.dart';
import '../widgets/chat_bubble.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<ChatMessage> _messages = [];
  final Map<String, PillarAssessment> _assessments = {};
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  GemmaChat? _chat;
  int _pillarIndex = 0;
  bool _busy = false;
  bool _opening = false;
  bool _complete = false;
  bool _started = false;
  String? _lastLang;

  List<Pillar> get _pillars => FrameworkData.pillars;
  Pillar get _pillar => _pillars[_pillarIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastLang = context.read<AppState>().languageCode;
      _openPillar(reset: true);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openPillar({bool reset = false}) async {
    if (_opening) return;
    _opening = true;
    final app = context.read<AppState>();
    final gemma = context.read<GemmaService>();
    final tools = context.read<ToolsState>();

    setState(() {
      if (reset) _messages.clear();
      _complete = false;
    });

    final sys = PromptBuilder.bcmSystemPrompt(
      pillar: _pillar,
      jurisdictions: app.activeJurisdictions,
      languageCode: app.languageCode,
      grounding: tools.groundingForPillar(_pillar.id),
    );

    try {
      _chat = await gemma.startChat(systemPrompt: sys);
      _started = true;
      await _generate(
        outgoing:
            'Introduce this pillar in one short, friendly sentence, then ask the practitioner to describe their current practice. Do not include any tag or score.',
        expectScore: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(
              ChatMessage.assistant(text: '⚠️ ${app.s.modelLoadError}\n$e'),
            ));
      }
    } finally {
      _opening = false;
    }
  }

  Future<void> _sendUser() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || _chat == null) return;
    _input.clear();
    setState(() => _messages.add(ChatMessage.user(text)));
    _scrollToEnd();
    await _generate(outgoing: text, expectScore: true);
  }

  Future<void> _generate({required String outgoing, required bool expectScore}) async {
    final chat = _chat;
    if (chat == null) return;
    final pillarId = _pillar.id;
    final msg = ChatMessage.assistant(streaming: true);
    setState(() {
      _busy = true;
      _messages.add(msg);
    });
    _scrollToEnd();

    final raw = StringBuffer();
    try {
      await for (final token in chat.send(outgoing)) {
        raw.write(token);
        setState(() => msg.text = JsonExtractor.displayText(raw.toString()));
        _scrollToEnd();
      }
      if (expectScore) {
        final a = JsonExtractor.extractAssessment(pillarId, raw.toString());
        if (a != null && a.isScored) {
          msg.assessment = a;
          _assessments[pillarId] = a;
        }
      }
      final shown = JsonExtractor.displayText(raw.toString());
      msg.text = shown.isEmpty ? raw.toString().trim() : shown;
    } catch (e) {
      msg.text = raw.isEmpty ? '⚠️ $e' : JsonExtractor.displayText(raw.toString());
    } finally {
      msg.isStreaming = false;
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _advance() {
    if (_busy) return;
    if (_pillarIndex < _pillars.length - 1) {
      setState(() => _pillarIndex++);
      _openPillar(reset: true);
    } else {
      setState(() => _complete = true);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _overallReadiness() {
    final scored = _assessments.values.where((a) => a.isScored).toList();
    if (scored.isEmpty) return 0;
    final sum = scored.map((a) => a.maturity!).reduce((x, y) => x + y);
    return (sum / scored.length / 4 * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;

    // Live language switch: restart the current pillar in the new language.
    if (_started && _lastLang != null && app.languageCode != _lastLang && !_busy && !_opening) {
      _lastLang = app.languageCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPillar(reset: true);
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: PillarProgress(
            index: _pillarIndex,
            total: _pillars.length,
            label: '${s.pillarProgressLabel(_pillarIndex + 1, _pillars.length)} · ${_pillar.title}',
          ),
        ),
        Expanded(
          child: _complete
              ? _ResultsView(assessments: _assessments, overall: _overallReadiness(), strings: s)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => ChatBubble(message: _messages[i], strings: s),
                ),
        ),
        if (!_complete) _inputArea(app),
      ],
    );
  }

  Widget _inputArea(AppState app) {
    final s = app.s;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendUser(),
                    decoration: InputDecoration(hintText: s.answerHint),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _sendUser,
                  child: _busy
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _busy ? null : _advance,
                  child: Text(s.skip, style: const TextStyle(color: AppColors.textSecondary)),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _advance,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    _pillarIndex < _pillars.length - 1 ? s.nextPillar : s.assessmentComplete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.assessments,
    required this.overall,
    required this.strings,
  });
  final Map<String, PillarAssessment> assessments;
  final int overall;
  final dynamic strings; // AppStrings

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.assessmentComplete,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Center(child: ScoreGauge(score: overall, size: 120)),
          const SizedBox(height: 8),
          Text(
            strings.overallReadiness,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ...FrameworkData.pillars.map((p) {
            final a = assessments[p.id];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p.title, style: const TextStyle(fontSize: 14)),
                trailing: (a != null && a.isScored)
                    ? MaturityBadge(score: a.maturity!, label: strings.maturityLabel)
                    : const Text('—', style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
