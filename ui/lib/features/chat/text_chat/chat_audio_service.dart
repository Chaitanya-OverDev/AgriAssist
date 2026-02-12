import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatAudioService {
  final FlutterTts _flutterTts = FlutterTts();

  // Track which message index is currently speaking
  int? _playingMessageIndex;

  // Listener to notify UI to rebuild (for icon changes)
  VoidCallback? _onPlayingIndexChanged;

  ChatAudioService() {
    _initTts();
  }

  void _initTts() async {
    // Basic Configuration
    await _flutterTts.setLanguage("en-IN"); // Default to Indian English
    await _flutterTts.setSpeechRate(0.5);   // Normal speed
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Platform specific tweaks for iOS background audio
    if (!kIsWeb && Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.duckOthers
          ]
      );
    }

    // --- Handlers ---

    _flutterTts.setStartHandler(() {
      _onPlayingIndexChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });

    _flutterTts.setCancelHandler(() {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });
  }

  // --- Public Getters ---
  int? get playingMessageIndex => _playingMessageIndex;
  bool get isFetchingAudio => false;

  void addPlayingIndexListener(VoidCallback listener) {
    _onPlayingIndexChanged = listener;
  }

  void removePlayingIndexListener() {
    _onPlayingIndexChanged = null;
  }

  // --- Playback Logic ---

  Future<void> play(String rawText, int index) async {
    // 1. Toggle behavior: if clicking the same index, stop it.
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    // 2. Stop any currently playing audio
    await stop();

    // 3. Update state to show "playing" icon
    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    // 4. Clean the text to remove Markdown symbols
    String spokenText = _cleanMarkdown(rawText);

    if (spokenText.trim().isEmpty) {
      spokenText = "Content is not readable text.";
    }

    // 5. Speak
    await _flutterTts.speak(spokenText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _playingMessageIndex = null;
    _onPlayingIndexChanged?.call();
  }

  void dispose() {
    _flutterTts.stop();
    _onPlayingIndexChanged = null;
  }

  // --- Utility: Markdown Cleaner ---

  String _cleanMarkdown(String text) {
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) {
      return match.group(1) ?? "";
    });

    text = text.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (match) {
      return match.group(1) ?? "";
    });

    text = text.replaceAllMapped(RegExp(r'(\*\*|__)(.*?)\1'), (match) {
      return match.group(2) ?? "";
    });

    text = text.replaceAllMapped(RegExp(r'(\*|_)(.*?)\1'), (match) {
      return match.group(2) ?? "";
    });

    text = text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');

    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    text = text.replaceAll(RegExp(r'!\[(.*?)\]\(.*?\)'), '');

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}