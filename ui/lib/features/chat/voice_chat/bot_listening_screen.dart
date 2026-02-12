import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agriassist/core/services/auth_service.dart';
import 'package:agriassist/core/services/voice_recognition_service.dart';
import 'package:agriassist/core/services/chat_audio_service.dart';
import '../text_chat/text_chat_screen.dart';
import '../../../services/api_service.dart';

class BotListeningScreen extends StatefulWidget {
  const BotListeningScreen({super.key});

  @override
  State<BotListeningScreen> createState() => _BotListeningScreenState();
}

class _BotListeningScreenState extends State<BotListeningScreen> with SingleTickerProviderStateMixin {
  final VoiceRecognitionService _sttService = VoiceRecognitionService();
  final ChatAudioService _ttsService = ChatAudioService();

  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;

  String _statusText = "Initializing...";
  String _userTranscript = "";
  bool _isMicActive = false;
  bool _isProcessing = false;

  // --- LANGUAGE CONFIGURATION ---
  // ✅ Changed Default to Marathi
  String _selectedLocaleId = "mr-IN";

  final Map<String, String> _languages = {
    "मराठी (Marathi)": "mr-IN", // Put Marathi first
    "हिंदी (Hindi)": "hi-IN",
    "English": "en-IN",
  };

  int? _activeSessionId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startConversationFlow();
  }

  void _initAnimation() {
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _rippleAnim = CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic);
  }

  Future<void> _startConversationFlow() async {
    if (ApiService.currentUserId == null) {
      final storedId = await AuthService.getUserId();
      if (storedId != null) ApiService.currentUserId = storedId;
    }

    bool available = await _sttService.initialize();
    if (available) {
      await Future.delayed(const Duration(milliseconds: 500));
      _startListening();
    } else {
      if (mounted) setState(() => _statusText = "Microphone not available");
    }
  }

  void _startListening() {
    if (_isProcessing) return; // Don't listen if thinking

    if (mounted) {
      setState(() {
        _isMicActive = true;
        _statusText = "Listening (${_getLanguageShortName()})...";
        _userTranscript = "";
        _rippleController.repeat();
      });
    }

    _sttService.listen(
      localeId: _selectedLocaleId, //  Uses Marathi by default
      onResult: (text) {
        if (mounted) setState(() => _userTranscript = text);
      },
    );

    // Watch for silence/completion
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_sttService.isListening && _isMicActive) {
        timer.cancel();
        _onSpeechComplete();
      }
    });
  }

  Future<void> _onSpeechComplete() async {
    if (mounted) {
      setState(() {
        _isMicActive = false;
        _rippleController.stop();
      });
    }

    if (_userTranscript.trim().isEmpty) {
      if (mounted) {
        setState(() => _statusText = "काहीही ऐकू आले नाही."); // "Heard nothing" in Marathi
        Future.delayed(const Duration(seconds: 2), _startListening);
      }
      return;
    }

    _messages.add({"role": "user", "text": _userTranscript});
    await _sendMessageToApi(_userTranscript);
  }

  Future<void> _sendMessageToApi(String text) async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusText = "विचार करत आहे..."; // "Thinking..." in Marathi
      });
    }

    try {
      if (_activeSessionId == null) {
        _activeSessionId = await ApiService.createSession("Voice Conversation");
      }

      if (_activeSessionId != null) {
        final response = await ApiService.sendChatMessage(_activeSessionId!, text);

        if (response != null) {
          final botText = response['content'];
          _messages.add({"role": "bot", "text": botText, "id": response['id']});
          await _speakResponse(botText);
        } else {
          _speakError("सर्व्हर कनेक्ट करण्यात समस्या."); // Server error in Marathi
        }
      }
    } catch (e) {
      _speakError("काहीतरी चूक झाली."); // "Something went wrong"
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _speakResponse(String text) async {
    if (mounted) {
      setState(() {
        _statusText = "बोलत आहे..."; // "Speaking..."
        _rippleController.repeat();
      });
    }

    // ✅ Speak in Marathi (or selected language)
    await _ttsService.play(text, 999, languageCode: _selectedLocaleId);

    final completer = Completer();
    void listener() {
      if (_ttsService.playingMessageIndex == null && !completer.isCompleted) {
        completer.complete();
      }
    }
    _ttsService.addPlayingIndexListener(listener);
    await completer.future;
    _ttsService.removePlayingIndexListener();

    if (mounted) {
      _rippleController.stop();
      _startListening();
    }
  }

  Future<void> _speakError(String msg) async {
    if (mounted) setState(() => _statusText = msg);
    await _ttsService.play(msg, -1, languageCode: _selectedLocaleId);
  }

  void _goToTextChat() {
    _sttService.stop();
    _ttsService.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TextChatScreen(
          passedSessionId: _activeSessionId,
          passedMessages: _messages,
        ),
      ),
    );
  }

  String _getLanguageShortName() {
    // Returns "मराठी", "Hindi", etc.
    return _languages.entries
        .firstWhere((element) => element.value == _selectedLocaleId)
        .key.split(' ')[0];
  }

  @override
  void dispose() {
    _sttService.stop();
    _ttsService.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _goToTextChat,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0E3D3D).withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocaleId,
                icon: const Icon(Icons.language, color: Color(0xFF0E3D3D), size: 20),
                items: _languages.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.value,
                    child: Text(
                      entry.key.split(' ')[0],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && !_isProcessing) {
                    setState(() {
                      _selectedLocaleId = newValue;
                      _sttService.stop(); // Stop current listening
                      // Small delay to let STT engine reset
                      Future.delayed(const Duration(milliseconds: 200), _startListening);
                    });
                  }
                },
              ),
            ),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // --- RIPPLE ANIMATION ---
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _rippleAnim,
                builder: (_, __) {
                  final isAnimating = _isMicActive || (_statusText == "बोलत आहे...");
                  if (!isAnimating) return const SizedBox();

                  final scale = 1 + (_rippleAnim.value * 0.30);
                  final opacity = (1 - _rippleAnim.value) * 0.5;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.withOpacity(opacity), width: 6),
                      ),
                    ),
                  );
                },
              ),
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white,
                backgroundImage: const AssetImage('assets/images/farmer_listening.png'),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // --- TRANSCRIPT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Text(
                  _statusText,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E3D3D)
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _userTranscript.isEmpty && _isMicActive
                      ? "काहीतरी बोला..." // "Say something..." in Marathi
                      : _userTranscript,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),

          const Spacer(),

          // --- BUTTONS ---
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.keyboard, color: Colors.black),
                  onPressed: _goToTextChat,
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  backgroundColor: _isMicActive ? Colors.red : const Color(0xFF0E3D3D),
                  child: Icon(_isMicActive ? Icons.stop : Icons.mic),
                  onPressed: () {
                    if (_isMicActive) {
                      _sttService.stop();
                    } else {
                      _startListening();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}