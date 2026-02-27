import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';
import '../settings_screen.dart';
import '../../../services/api_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:agriassist/core/services/chat_audio_service.dart';
import 'chat_message_widgets.dart';
import 'chat_input_widget.dart';

class TextChatScreen extends StatefulWidget {
  final String? prefilledQuery;
  final int? passedSessionId;
  final List<Map<String, dynamic>>? passedMessages;

  const TextChatScreen({
    super.key,
    this.prefilledQuery,
    this.passedSessionId,
    this.passedMessages,
  });

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatAudioService _audioService = ChatAudioService();

  // STT Logic Variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  int? activeSessionId;
  bool _hasSentPrefilledQuery = false;

  @override
  void initState() {
    super.initState();
    _restoreUserFromStorage();
    _setupAudioListeners();

    if (widget.passedSessionId != null) activeSessionId = widget.passedSessionId;
    if (widget.passedMessages != null) {
      setState(() { messages = List.from(widget.passedMessages!); });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    // Handle Prefilled Query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledQuery != null && widget.prefilledQuery!.isNotEmpty && !_hasSentPrefilledQuery && messages.isEmpty) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_hasSentPrefilledQuery) {
            _hasSentPrefilledQuery = true;
            controller.text = widget.prefilledQuery!;
            sendMessage();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    _audioService.dispose();
    super.dispose();
  }

  // --- INTEGRATED SPEECH TO TEXT LOGIC ---
  void _listen() async {
    if (!_isListening) {
      // 1. Get the language saved in the Settings Screen
      final prefs = await SharedPreferences.getInstance();
      String savedLangCode = prefs.getString('selected_lang_code') ?? 'en_IN';

      // 2. Initialize the engine
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              // Updates the text box in real-time
              controller.text = result.recognizedWords;
            });
          },
          // 3. This tells the engine to listen for the specific language
          localeId: savedLangCode, 
          cancelOnError: true,
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _setupAudioListeners() {
    _audioService.addPlayingIndexListener(() { if (mounted) setState(() {}); });
  }

  Future<void> _restoreUserFromStorage() async {
    if (ApiService.currentUserId == null) {
      final storedUserId = await AuthService.getUserId();
      if (storedUserId != null) setState(() { ApiService.currentUserId = storedUserId; });
    }
  }

  Future<void> sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    _scrollToBottom();

    try {
      if (ApiService.currentUserId == null) {
        final storedUserId = await AuthService.getUserId();
        if (storedUserId != null) ApiService.currentUserId = storedUserId;
        else throw Exception("User not logged in.");
      }

      if (activeSessionId == null) {
        int? newSessionId = await ApiService.createSession("Consultation: $text");
        if (newSessionId != null) activeSessionId = newSessionId;
        else throw Exception("Failed to create chat session.");
      }

      final responseMap = await ApiService.sendChatMessage(
        activeSessionId!, 
        text, 
        isVoiceMode: false 
      );
      if (!mounted) return;
      if (responseMap != null) {
        setState(() {
          messages.add({"role": "bot", "text": responseMap['content'], "id": responseMap['id']});
        });
      }
    } catch (e) {
      if (mounted) setState(() { messages.add({"role": "bot", "text": "❌ Error: ${e.toString()}"}); });
    } finally {
      if (mounted) { setState(() { isLoading = false; }); _scrollToBottom(); }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRoutes.voiceChat);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F8EF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.voiceChat),
          ),
          title: const Text("AgriAssist", style: TextStyle(color: Colors.black)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) {
                // Refresh state when coming back from settings in case language changed
                setState(() {}); 
              }),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (isLoading && messages.isEmpty)
                const LinearProgressIndicator(color: Color(0xFF0E3D3D)),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) return ChatMessageWidgets.typingBubble("Typing...", index);
                    final msg = messages[index];
                    if (msg["role"] == "user") return ChatMessageWidgets.userBubble(msg["text"]);
                    return ChatMessageWidgets.botBubble(
                      context: context,
                      text: msg["text"],
                      index: index,
                      messageId: msg["id"],
                      audioService: _audioService,
                      onCopyPressed: (t) => Clipboard.setData(ClipboardData(text: t)),
                    );
                  },
                ),
              ),
              ChatInputWidget(
                controller: controller,
                onSendPressed: sendMessage,
                onMicPressed: _listen,
                isListening: _isListening,
                isLoggedIn: ApiService.currentUserId != null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}