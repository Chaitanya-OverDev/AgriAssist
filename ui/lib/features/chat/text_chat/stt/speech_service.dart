import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart'; // Add this

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // FIX: Change Function(String) to the proper Result callback
  void startListening(Function(SpeechRecognitionResult) onResult) async {
    await _speech.listen(
      onResult: onResult,
      localeId: "en_IN", // Change this to "hi_IN" for Hindi or "mr_IN" for Marathi
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  void stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}