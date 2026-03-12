import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agriassist/core/services/auth_service.dart';
import 'package:agriassist/core/services/voice_recognition_service.dart';
import 'package:agriassist/core/services/chat_audio_service.dart';
import '../text_chat/text_chat_screen.dart';
import '../../../services/api_service.dart';
import 'package:agriassist/l10n/app_localizations.dart';

class BotListeningScreen extends StatefulWidget {
  const BotListeningScreen({super.key});

  @override
  State<BotListeningScreen> createState() => _BotListeningScreenState();
}

class _BotListeningScreenState extends State<BotListeningScreen>
    with SingleTickerProviderStateMixin {

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
    "मराठी": "mr-IN",
    "हिंदी": "hi-IN",
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

    _rippleAnim = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );
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
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        setState(() => _statusText = t.micNotAvailable);
      }
    }
  }

  void _startListening() {
    final t = AppLocalizations.of(context)!;

    if (_isProcessing || _isBotSpeaking) return;

    if (mounted) {
      setState(() {
        _isMicActive = true;
        _statusText = "${t.listening} (${_getLanguageShortName()})...";
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
    final t = AppLocalizations.of(context)!;

    if (mounted) {
      setState(() {
        _isMicActive = false;
      });
    }

    if (_userTranscript.trim().isEmpty) {
      if (mounted) {
        setState(() => _statusText = t.noSpeech);
        Future.delayed(const Duration(seconds: 2), _startListening);
      }
      return;
    }

    _messages.add({"role": "user", "text": _userTranscript});
    await _sendMessageToApi(_userTranscript);
  }

  Future<void> _sendMessageToApi(String text) async {
    final t = AppLocalizations.of(context)!;

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusText = t.thinking;
      });
    }

    try {
      if (_activeSessionId == null) {
        _activeSessionId = await ApiService.createSession("Voice Conversation");
      }

      if (_activeSessionId != null) {
        final response = await ApiService.sendChatMessage(
          _activeSessionId!,
          text,
          isVoiceMode: true,
        );

        if (mounted) setState(() => _isProcessing = false);

        if (response != null) {
          final botText = response['content'];
          final messageId = response['id'];

          _messages.add({
            "role": "bot",
            "text": botText,
            "id": messageId
          });

          await _speakResponse(messageId);
        } else {
          _speakError(t.serverError);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _speakError(t.somethingWrong);
    }
  }

  Future<void> _speakResponse(int messageId) async {
    final t = AppLocalizations.of(context)!;

    if (mounted) {
      setState(() {
        _isBotSpeaking = true;
        _statusText = t.speaking;
      });
    }

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

  Future<void> _speakError(String msg) async {
    if (mounted) {
      setState(() {
        _statusText = msg;
        _isBotSpeaking = false;
      });
    }

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
        .key;
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
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
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

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE4F6F0),
              Color(0xFFC7EBD9)
            ],
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

                    Text(
                      t.appTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF13383A),
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF13383A),
                        size: 30,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedLocaleId = val;
                          _sttService.stop();
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            _startListening,
                          );
                        });
                      },
                      itemBuilder: (ctx) => _languages.entries
                          .map(
                            (e) => PopupMenuItem(
                          value: e.value,
                          child: Text(e.key),
                        ),
                      )
                          .toList(),
                    ),

                  ],
                ),
              ),

              const Spacer(),

              _buildDynamicMicButton(),

              const SizedBox(height: 80),

            ],
          ),
        ),
      ),
    );
  }
}