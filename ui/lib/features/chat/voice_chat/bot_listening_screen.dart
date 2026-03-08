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
  bool _isBotSpeaking = false;

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _rippleAnim = CurvedAnimation(parent: _rippleController, curve: Curves.easeOut);
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
    if (_isProcessing || _isBotSpeaking) return;

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
        final response = await ApiService.sendChatMessage(_activeSessionId!, text, isVoiceMode: true);

        if (mounted) setState(() => _isProcessing = false);

        if (response != null) {
          final botText = response['content'];
          final messageId = response['id']; // <-- Extract ID

          _messages.add({"role": "bot", "text": botText, "id": messageId});

          // <-- Pass ID instead of text
          await _speakResponse(messageId);
        } else {
          _speakError("सर्व्हर कनेक्ट करण्यात समस्या.");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _speakError("काहीतरी चूक झाली.");
    }
  }

  // <-- Updated to accept int messageId
  Future<void> _speakResponse(int messageId) async {
    if (mounted) {
      setState(() {
        _isBotSpeaking = true;
        _statusText = "बोलत आहे...";
      });
    }

    // <-- Call the updated play method (using 999 as a placeholder index for the active voice mode)
    await _ttsService.play(messageId, 999);

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
      setState(() {
        _isBotSpeaking = false;
      });
      _startListening();
    }
  }

  // <-- Updated to just show text and wait, since local TTS is gone
  Future<void> _speakError(String msg) async {
    if (mounted) {
      setState(() {
        _statusText = msg;
        _isBotSpeaking = false;
      });
    }
    // Give the user 3 seconds to read the error, then turn mic back on
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _startListening();
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
    _ttsService.stop();
    _ttsService.removePlayingIndexListener();

    _rippleController.dispose();
    super.dispose();
  }

  Widget _buildDynamicMicButton() {
    final bool isBusy = _isProcessing || _isBotSpeaking;
    Color micBgColor;
    Widget iconWidget;

    if (_isProcessing) {
      micBgColor = Colors.grey.shade600;
      iconWidget = const SizedBox(
        width: 30, height: 30,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      );
    } else if (_isBotSpeaking) {
      micBgColor = Colors.blue.shade600;
      iconWidget = const Icon(Icons.volume_up_rounded, color: Colors.white, size: 36);
    } else if (_isMicActive) {
      micBgColor = Colors.red.shade700;
      iconWidget = const Icon(Icons.mic, color: Colors.white, size: 36);
    } else {
      micBgColor = const Color(0xFF13383A);
      iconWidget = const Icon(Icons.mic_none, color: Colors.white, size: 36);
    }

    return GestureDetector(
      onTap: isBusy ? null : () => _isMicActive ? _sttService.stop() : _startListening(),
      child: AnimatedBuilder(
        animation: _rippleAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (_isMicActive)
                Transform.scale(
                  scale: 1.0 + (_rippleAnim.value * 0.6),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: micBgColor.withOpacity(1.0 - _rippleAnim.value),
                    ),
                  ),
                ),
              Container(
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
                child: Center(child: iconWidget),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          _languages.entries
                              .firstWhere((e) => e.value == _selectedLocaleId)
                              .key
                              .split(' ')[0],
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Align(
                  alignment: Alignment.center,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
                      children: [
                        TextSpan(
                          text: "$_statusText\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF13383A),
                            fontSize: 18,
                          ),
                        ),
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

              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    _buildDynamicMicButton(),
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