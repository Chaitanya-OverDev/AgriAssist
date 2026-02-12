import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint("STT Init Exception: $e");
      return false;
    }
  }

  // UPDATED: Added 'localeId' parameter
  void listen({
    required Function(String) onResult,
    required String localeId, // <--- Key Change
    Function(double)? onSoundLevel,
  }) {
    if (!_isAvailable) return;

    _speech.listen(
      onResult: (val) => onResult(val.recognizedWords),
      onSoundLevelChange: onSoundLevel,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId, // <--- Forces Marathi (or selected lang)
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}