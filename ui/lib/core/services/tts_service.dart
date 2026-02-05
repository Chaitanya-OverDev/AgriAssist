// lib/core/services/tts_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;

  // Initialize TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5); // Normal speed
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Setup completion handler for older TTS versions
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((error) {
        if (kDebugMode) print("TTS Error: $error");
        _isSpeaking = false;
      });

      _isInitialized = true;
      if (kDebugMode) print("✅ TTS Service Initialized");
    } catch (e) {
      if (kDebugMode) print("❌ TTS Initialization Error: $e");
    }
  }

  // Speak text
  static Future<void> speak(String text) async {
    try {
      if (!_isInitialized) await initialize();
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) print("❌ TTS Speak Error: $e");
      _isSpeaking = false;
    }
  }

  // Stop speaking
  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      if (kDebugMode) print("❌ TTS Stop Error: $e");
    }
  }

  // Check if speaking (manual tracking)
  static bool isSpeaking() {
    return _isSpeaking;
  }
}