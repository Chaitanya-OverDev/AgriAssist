import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatAudioService {
  final FlutterTts _flutterTts = FlutterTts();

  int? _playingMessageIndex;
  VoidCallback? _onPlayingIndexChanged;

  ChatAudioService() {
    _initTts();
  }

  void _initTts() async {
    // We set a generic default here, but the 'play' method will override it
    await _flutterTts.setLanguage("mr-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // iOS background audio settings
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

    // Handlers
    _flutterTts.setStartHandler(() => _onPlayingIndexChanged?.call());
    _flutterTts.setCompletionHandler(() {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });
    _flutterTts.setCancelHandler(() {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });
    _flutterTts.setErrorHandler((msg) {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });
  }

  int? get playingMessageIndex => _playingMessageIndex;

  void addPlayingIndexListener(VoidCallback listener) {
    _onPlayingIndexChanged = listener;
  }

  void removePlayingIndexListener() {
    _onPlayingIndexChanged = null;
  }

  // UPDATED: Now accepts 'languageCode'
  Future<void> play(String rawText, int index, {String languageCode = "mr-IN"}) async {
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();
    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    // 1. Set the language dynamically
    await _flutterTts.setLanguage(languageCode);

    // 2. Clean text
    String spokenText = _cleanMarkdown(rawText);
    if (spokenText.trim().isEmpty) spokenText = "maiti uplabdh nahi"; // "Info not available" in Marathi

    // 3. Speak
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

  String _cleanMarkdown(String text) {
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? "");
    text = text.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (match) => match.group(1) ?? "");
    text = text.replaceAllMapped(RegExp(r'(\*\*|__)(.*?)\1'), (match) => match.group(2) ?? "");
    text = text.replaceAllMapped(RegExp(r'(\*|_)(.*?)\1'), (match) => match.group(2) ?? "");
    text = text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'!\[(.*?)\]\(.*?\)'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}