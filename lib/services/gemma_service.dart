// gemma_service.dart
//
// The ONLY file that imports flutter_gemma. Everything else talks to Gemma through this façade,
// so if the SDK API shifts, the change is contained here.
//
// ── VERIFY AT BUILD TIME (flutter_gemma ^1.2.0) ──────────────────────────────────────────────
//  Confirmed from pub.dev README:
//    FlutterGemmaPlugin.instance.createModel(modelType:, preferredBackend:, maxTokens:)
//    model.createChat()  ->  chat.addQueryChunk(Message.text(text:, isUser:))
//    chat.generateChatResponseAsync()  (stream)   /   chat.generateChatResponse()  (single)
//    model.close()  ;  ModelType.gemmaIt  ;  PreferredBackend.gpu
//  To confirm when the toolchain is installed:
//    1. modelManager method for a BUNDLED asset — installModelFromAsset(assetName). A streaming
//       variant (…WithProgress) may exist; if so, wire it into loadModelFromAsset for smooth %.
//    2. The stream element type of generateChatResponseAsync — String token vs TextResponse.token.
//       _tokenOf() below tolerates both via dynamic, so no change should be needed.
//    3. Whether temperature/topK are set on createModel or createChat in this version (see TODO).
// ─────────────────────────────────────────────────────────────────────────────────────────────

import 'package:flutter_gemma/flutter_gemma.dart';

/// Bundled model asset. Must match the file placed in assets/models/ and the pubspec asset entry.
const String kGemmaModelAsset = 'gemma-3-1b-it-int4.litertlm';
const int kMaxTokens = 1024;

class GemmaService {
  // Typed dynamic to avoid coupling to the SDK's concrete model class name (InferenceModel).
  dynamic _model;

  bool get isLoaded => _model != null;

  /// Loads the bundled model. [onProgress] receives 0..1. For a bundled asset the meaningful
  /// phases are: copy asset into the app documents dir, then initialise the inference engine.
  Future<void> loadModelFromAsset({
    String assetName = kGemmaModelAsset,
    void Function(double progress)? onProgress,
  }) async {
    final gemma = FlutterGemmaPlugin.instance;
    onProgress?.call(0.02);

    // Copy the bundled weights into the app's documents directory (first launch only).
    await gemma.modelManager.installModelFromAsset(assetName);
    onProgress?.call(0.6);

    // Initialise the on-device inference engine (LiteRT-LM / GPU-preferred).
    // TODO(verify): if this version accepts temperature/topK here, set temperature ~0.3 for
    // steadier JSON extraction. Kept minimal now to guarantee compilation.
    _model = await gemma.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.gpu,
      maxTokens: kMaxTokens,
    );
    onProgress?.call(1.0);
  }

  dynamic _requireModel() {
    final m = _model;
    if (m == null) throw StateError('Gemma model not loaded');
    return m;
  }

  /// Start a fresh multi-turn chat seeded with [systemPrompt].
  Future<GemmaChat> startChat({required String systemPrompt}) async {
    final chat = await _requireModel().createChat();
    return GemmaChat._(chat, systemPrompt: systemPrompt);
  }

  /// One-shot completion in a throwaway chat. Returns the full concatenated response.
  Future<String> complete({
    required String systemPrompt,
    required String userText,
  }) async {
    final chat = await startChat(systemPrompt: systemPrompt);
    final buf = StringBuffer();
    await for (final token in chat.send(userText)) {
      buf.write(token);
    }
    return buf.toString();
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

/// Thin wrapper over the SDK chat object exposing a plain `Stream<String>` of tokens.
class GemmaChat {
  GemmaChat._(this._chat, {required this.systemPrompt});

  // Typed as dynamic to avoid coupling to the SDK's InferenceChat class name.
  final dynamic _chat;
  final String systemPrompt;
  bool _primed = false;

  /// Sends [userText] and streams the reply token-by-token.
  /// The system prompt is prepended to the first message of the session only.
  Stream<String> send(String userText) async* {
    final composed = _primed ? userText : '$systemPrompt\n\n--- Practitioner ---\n$userText';
    _primed = true;

    await _chat.addQueryChunk(Message.text(text: composed, isUser: true));
    await for (final dynamic response in _chat.generateChatResponseAsync()) {
      final token = _tokenOf(response);
      if (token != null && token.isNotEmpty) yield token;
    }
  }

  /// Tolerates both a String token and a TextResponse-like object with a `.token` getter.
  String? _tokenOf(dynamic response) {
    if (response is String) return response;
    try {
      final t = response.token;
      return t is String ? t : null;
    } catch (_) {
      return null; // non-text chunk (e.g. a function-call response) — skip
    }
  }
}
