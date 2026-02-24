import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Add this import
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

  // STT Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  int? activeSessionId;
  bool _hasSentPrefilledQuery = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // Initialize speech object
    _restoreUserFromStorage();
    _setupAudioListeners();

    if (widget.passedSessionId != null)
      activeSessionId = widget.passedSessionId;
    if (widget.passedMessages != null) {
      setState(() {
        messages = List.from(widget.passedMessages!);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledQuery != null &&
          widget.prefilledQuery!.isNotEmpty &&
          !_hasSentPrefilledQuery &&
          messages.isEmpty) {
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

  // --- STT LOGIC ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        // Start listening and update the text controller
        _speech.listen(
          onResult: (result) {
            setState(() {
              controller.text = result.recognizedWords;
              // If the user stops talking, the library sets finalResult to true
              if (result.finalResult) {
                _isListening = false;
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _setupAudioListeners() {
    _audioService.addPlayingIndexListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _restoreUserFromStorage() async {
    if (ApiService.currentUserId == null) {
      final storedUserId = await AuthService.getUserId();
      if (storedUserId != null)
        setState(() {
          ApiService.currentUserId = storedUserId;
        });
    }
  }

  Future<void> sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) _speech.stop(); // Stop listening if user sends manually

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    _scrollToBottom();

    try {
      if (ApiService.currentUserId == null) {
        final storedUserId = await AuthService.getUserId();
        if (storedUserId != null)
          ApiService.currentUserId = storedUserId;
        else
          throw Exception("User not logged in.");
      }

      if (activeSessionId == null) {
        int? newSessionId = await ApiService.createSession(
          "Consultation: $text",
        );
        if (newSessionId != null)
          activeSessionId = newSessionId;
        else
          throw Exception("Failed to create chat session.");
      }

      final responseMap = await ApiService.sendChatMessage(
        activeSessionId!,
        text,
      );

      if (!mounted) return;
      if (responseMap != null) {
        setState(() {
          messages.add({
            "role": "bot",
            "text": responseMap['content'],
            "id": responseMap['id'],
          });
        });
      }
    } catch (e) {
      if (mounted)
        messages.add({"role": "bot", "text": "❌ Error: ${e.toString()}"});
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.voiceChat),
          ),
          title: const Text(
            "AgriAssist",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (isLoading && messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(color: Color(0xFF0E3D3D)),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length)
                      return ChatMessageWidgets.typingBubble(
                        "Typing...",
                        index,
                      );
                    final msg = messages[index];
                    if (msg["role"] == "user")
                      return ChatMessageWidgets.userBubble(msg["text"]);
                    return ChatMessageWidgets.botBubble(
                      context: context,
                      text: msg["text"],
                      index: index,
                      messageId: msg["id"],
                      audioService: _audioService,
                      onCopyPressed: (t) =>
                          Clipboard.setData(ClipboardData(text: t)),
                    );
                  },
                ),
              ),
              ChatInputWidget(
                controller: controller,
                onSendPressed: sendMessage,
                onMicPressed: _listen, // Pass the listening function
                isListening: _isListening, // Pass the listening state
                isLoggedIn: ApiService.currentUserId != null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
