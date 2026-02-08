import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../routes/app_routes.dart';
import '../settings_screen.dart';
import '../../../services/api_service.dart';
import '../../../core/services/auth_service.dart';
import 'chat_audio_service.dart';
import 'chat_message_widgets.dart';
import 'chat_input_widget.dart';

class TextChatScreen extends StatefulWidget {
  final String? prefilledQuery;

  const TextChatScreen({super.key, this.prefilledQuery});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatAudioService _audioService = ChatAudioService();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  int? activeSessionId;
  bool _hasSentPrefilledQuery = false;

  @override
  void initState() {
    super.initState();
    _restoreUserFromStorage();
    _setupAudioListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledQuery != null &&
          widget.prefilledQuery!.isNotEmpty &&
          !_hasSentPrefilledQuery) {
        Future.delayed(const Duration(milliseconds: 800), () {
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

  void _setupAudioListeners() {
    _audioService.addPlayingIndexListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _restoreUserFromStorage() async {
    if (ApiService.currentUserId == null) {
      final storedUserId = await AuthService.getUserId();
      if (storedUserId != null) {
        setState(() {
          ApiService.currentUserId = storedUserId;
        });
      }
    }
  }

  Future<void> sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

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
        int? newSessionId = await ApiService.createSession("New Consultation");
        if (newSessionId != null) activeSessionId = newSessionId;
        else throw Exception("Failed to create chat session.");
      }

      final responseMap = await ApiService.sendChatMessage(activeSessionId!, text);

      if (!mounted) return;

      if (responseMap != null) {
        setState(() {
          messages.add({
            "role": "bot",
            "text": responseMap['content'],
            "id": responseMap['id'],
          });
        });
      } else {
        setState(() {
          messages.add({
            "role": "bot",
            "text": "⚠️ Server Error: Could not get a response."
          });
        });
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          "role": "bot",
          "text": "❌ Error: ${e.toString()}"
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          backgroundColor: Color(0xFF0E3D3D),
          duration: Duration(seconds: 1),
        ),
      );
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
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.voiceChat),
          ),
          title: const Text("AgriAssist", style: TextStyle(color: Colors.black)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (widget.prefilledQuery != null && _hasSentPrefilledQuery && messages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const LinearProgressIndicator(color: Color(0xFF0E3D3D)),
                ),
              Expanded(
                child: messages.isEmpty && !isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return ChatMessageWidgets.typingBubble("Typing...", index);
                    }
                    final msg = messages[index];
                    if (msg["role"] == "user") {
                      return ChatMessageWidgets.userBubble(msg["text"]);
                    }
                    return ChatMessageWidgets.botBubble(
                      context: context,
                      text: msg["text"],
                      index: index,
                      messageId: msg["id"],
                      audioService: _audioService,
                      onCopyPressed: _copyToClipboard,
                    );
                  },
                ),
              ),
              ChatInputWidget(
                controller: controller,
                onSendPressed: sendMessage,
                isLoggedIn: ApiService.currentUserId != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 50, color: Color(0xFF0E3D3D)),
          const SizedBox(height: 10),
          const Text("Start a conversation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}