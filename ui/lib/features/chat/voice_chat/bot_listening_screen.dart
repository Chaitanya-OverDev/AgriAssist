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

  String _selectedLocaleId = "mr-IN";

  final Map<String, String> _languages = {
    "मराठी (Marathi)": "mr-IN",
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
    );
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
    if (_isProcessing) return;

    if (mounted) {
      setState(() {
        _isMicActive = true;
        _statusText = "Listening (${_getLanguageShortName()})...";
        _userTranscript = "";
      });
    }

    _sttService.listen(
      localeId: _selectedLocaleId,
      onResult: (text) {
        if (mounted) setState(() => _userTranscript = text);
      },
    );

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
      });
    }

    if (_userTranscript.trim().isEmpty) {
      if (mounted) {
        setState(() => _statusText = "काहीही ऐकू आले नाही.");
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
        _statusText = "विचार करत आहे...";
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
          _speakError("सर्व्हर कनेक्ट करण्यात समस्या.");
        }
      }
    } catch (e) {
      _speakError("काहीतरी चूक झाली.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _speakResponse(String text) async {
    if (mounted) {
      setState(() {
        _statusText = "बोलत आहे...";
      });
    }

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
    // Dynamic styles based on listening state
    final Color micBgColor = _isMicActive ? Colors.red.shade700 : const Color(0xFF13383A);
    final IconData micIcon = _isMicActive ? Icons.pause : Icons.mic;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F6F0), Color(0xFFC7EBD9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- APP BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "AgriAssist",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF13383A),
                      ),
                    ),
                    Row(
                      children: [
                        // Display the selected language text
                        Text(
                          _languages.entries
                              .firstWhere((e) => e.value == _selectedLocaleId)
                              .key
                              .split(' ')[0], // Gets just the native name (e.g., मराठी)
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF13383A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.settings_outlined, color: Color(0xFF13383A), size: 30),
                          onSelected: (val) {
                            setState(() {
                              _selectedLocaleId = val;
                              _sttService.stop();
                              Future.delayed(const Duration(milliseconds: 200), _startListening);
                            });
                          },
                          itemBuilder: (ctx) => _languages.entries
                              .map((e) => PopupMenuItem(value: e.value, child: Text(e.key)))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // --- CHARACTER AVATAR ---
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFB5CAC1), width: 20),
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/farmer_listening.png', fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 40),

              // --- TRANSCRIPT AREA ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Align(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
                      children: [
                        // The Status Text (e.g., Listening...)
                        TextSpan(
                          text: "$_statusText",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF13383A), // Dark green to match theme
                            fontSize: 18,
                          ),
                        ),

                        // New Line + Vertical spacing
                        const TextSpan(text: "\n"),

                        // The Spoken Text
                        TextSpan(
                          text: _userTranscript.isEmpty && _isMicActive
                              ? "काहीतरी बोला..."
                              : _userTranscript,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // --- ACTION BUTTONS ---
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),

                    // MIC / PAUSE BUTTON
                    GestureDetector(
                      onTap: () => _isMicActive ? _sttService.stop() : _startListening(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: micBgColor,
                          boxShadow: [
                            BoxShadow(
                              color: micBgColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(micIcon, color: Colors.white, size: 36),
                      ),
                    ),

                    // CLOSE BUTTON
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: _goToTextChat,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE8D5D5),
                              border: Border.all(color: const Color(0xFFD1B2B2), width: 1),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFB24D4D),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}