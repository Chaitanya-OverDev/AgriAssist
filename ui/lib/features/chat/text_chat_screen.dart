import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../routes/app_routes.dart';
import 'settings_screen.dart';
import '../../services/api_service.dart';

class TextChatScreen extends StatefulWidget {
  const TextChatScreen({super.key});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  // Track the current session ID.
  // If null, we create a new session on the first message.
  int? activeSessionId;

  // ⭐ SEND MESSAGE FUNCTION
  Future<void> sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message to UI immediately
    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    _scrollToBottom();

    try {
      // 2. Check Login Status
      if (ApiService.currentUserId == null) {
        throw Exception("User not logged in. Please restart app and login.");
      }

      // 3. Create Session if it doesn't exist
      if (activeSessionId == null) {
        // We give a temp title, the AI will auto-rename it later on the backend
        int? newSessionId = await ApiService.createSession("New Consultation");

        if (newSessionId != null) {
          activeSessionId = newSessionId;
          print("✅ Session Created: $activeSessionId");
        } else {
          throw Exception("Failed to create chat session.");
        }
      }

      // 4. Send Message to AI
      String? aiResponseText = await ApiService.sendChatMessage(activeSessionId!, text);

      if (!mounted) return;

      // 5. Update UI with AI Response
      if (aiResponseText != null) {
        setState(() {
          messages.add({
            "role": "bot",
            "text": aiResponseText
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
          "text": "❌ Error: $e"
        });
      });
      print("Chat Error: $e");
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
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.voiceChat,
              );
            },
          ),
          title: const Text(
            "AgriAssist",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              /// CHAT MESSAGES
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _botBubble("Typing...");
                    }

                    final msg = messages[index];
                    if (msg["role"] == "user") {
                      return _userBubble(msg["text"]!);
                    }
                    return _botBubble(msg["text"]!);
                  },
                ),
              ),

              /// INPUT BAR
              _chatInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOT MESSAGE ----------------
  Widget _botBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, color: Colors.black),
            strong: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- USER MESSAGE ----------------
  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFF4C8BF5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white, fontSize: 14),
            strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- INPUT BAR ----------------
  Widget _chatInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.black45),
            onPressed: () {},
          ),

          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Type message here",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.mic, color: Colors.black54),
            onPressed: () {},
          ),

          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0E3D3D),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}