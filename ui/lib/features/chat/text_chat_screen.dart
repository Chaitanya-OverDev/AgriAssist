import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../routes/app_routes.dart';
import 'settings_screen.dart';
import '../../services/api_service.dart';
import '../../core/services/auth_service.dart';

class TextChatScreen extends StatefulWidget {
  final String? prefilledQuery; // Add this parameter

  const TextChatScreen({super.key, this.prefilledQuery});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  int? activeSessionId;
  int? _speakingMessageIndex;
  bool _hasSentPrefilledQuery = false;

  @override
  void initState() {
    super.initState();
    _restoreUserFromStorage();

    // ✅ AUTO-SEND PREFILLED QUERY IF PROVIDED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledQuery != null &&
          widget.prefilledQuery!.isNotEmpty &&
          !_hasSentPrefilledQuery) {

        // Add a small delay for better UX
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

  Future<void> _restoreUserFromStorage() async {
    if (ApiService.currentUserId == null) {
      final storedUserId = await AuthService.getUserId();
      final storedPhoneNumber = await AuthService.getPhoneNumber();

      if (storedUserId != null) {
        setState(() {
          ApiService.currentUserId = storedUserId;
          ApiService.currentPhoneNumber = storedPhoneNumber;
        });
        print("🔍 Restored User from storage:");
        print("   User ID: $storedUserId");
        print("   Phone: $storedPhoneNumber");
      } else {
        print("⚠️ No user found in storage. User needs to login.");
      }
    }
  }

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
      // 2. Check Login Status - First try storage if not in memory
      if (ApiService.currentUserId == null) {
        final storedUserId = await AuthService.getUserId();
        if (storedUserId != null) {
          ApiService.currentUserId = storedUserId;
          print("🔄 Retrieved User ID from storage: $storedUserId");
        } else {
          throw Exception("User not logged in. Please go back and login.");
        }
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

      // Handle specific error cases
      String errorMessage = e.toString();
      if (errorMessage.contains("User not logged in")) {
        errorMessage = "Please login to continue. Tap the back button and login.";
      }

      setState(() {
        messages.add({
          "role": "bot",
          "text": "❌ $errorMessage"
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

  // ✅ COPY TO CLIPBOARD
  Future<void> _copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF0E3D3D),
        ),
      );
    }
  }

  // ✅ SPEAK TEXT (Visual feedback for now)
  void _speakText(int index, BuildContext context) {
    if (_speakingMessageIndex == index) {
      // Stop speaking if already speaking this message
      setState(() {
        _speakingMessageIndex = null;
      });
    } else {
      // Start speaking this message
      setState(() {
        _speakingMessageIndex = index;
      });

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading response...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Auto-stop after 4 seconds (simulated)
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _speakingMessageIndex = null;
          });
        }
      });
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
            FutureBuilder(
              future: AuthService.getUserName(),
              builder: (context, snapshot) {
                final userName = snapshot.data ?? '';
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Tooltip(
                    message: userName.isNotEmpty
                        ? "Logged in as $userName"
                        : "Not logged in",
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: ApiService.currentUserId != null
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: ApiService.currentUserId != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
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
              // Show loading indicator for prefilled query
              if (widget.prefilledQuery != null && _hasSentPrefilledQuery && messages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0E3D3D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Sending: ${widget.prefilledQuery}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: messages.isEmpty && !isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _botBubble("Typing...", context, false, index);
                    }

                    final msg = messages[index];
                    if (msg["role"] == "user") {
                      return _userBubble(msg["text"]!);
                    }
                    return _botBubble(msg["text"]!, context, true, index);
                  },
                ),
              ),
              _chatInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOT MESSAGE WITH ACTION BUTTONS ----------------
  Widget _botBubble(String text, BuildContext context, bool showButtons, int index) {
    final isSpeaking = _speakingMessageIndex == index;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSpeaking ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isSpeaking
                    ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, color: Colors.black),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ✅ BEAUTIFUL ACTION BUTTONS (only for actual bot messages, not "Typing...")
            if (showButtons)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    // 🔊 SPEAKER BUTTON
                    _actionButton(
                      icon: isSpeaking ? Icons.volume_off : Icons.volume_up,
                      color: isSpeaking ? Colors.red : const Color(0xFF0E3D3D),
                      tooltip: isSpeaking ? 'Stop Speaking' : 'Listen to response',
                      onPressed: () => _speakText(index, context),
                    ),

                    const SizedBox(width: 10),

                    // 📋 COPY BUTTON
                    _actionButton(
                      icon: Icons.content_copy,
                      color: const Color(0xFF0E3D3D),
                      tooltip: 'Copy response to clipboard',
                      onPressed: () => _copyToClipboard(text, context),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ BEAUTIFUL ACTION BUTTON WIDGET
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
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

  // ---------------- EMPTY STATE ----------------
  Widget _buildEmptyState() {
    // Show different empty state if we have a prefilled query
    if (widget.prefilledQuery != null && !_hasSentPrefilledQuery) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF0E3D3D),
              ),
              const SizedBox(height: 20),
              const Text(
                "Preparing your query...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3D3D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0E3D3D).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  widget.prefilledQuery!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Color(0xFF0E3D3D),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Start a conversation",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ApiService.currentUserId != null
                ? "Ask questions about farming, weather, or crop advice"
                : "Please login to start chatting",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (ApiService.currentUserId == null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.voiceChat);
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text("Go to Login"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E3D3D),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- INPUT BAR ----------------
  Widget _chatInputBar() {
    final isLoggedIn = ApiService.currentUserId != null;

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("File attachment coming soon")),
              );
            },
          ),

          Expanded(
            child: TextField(
              controller: controller,
              enabled: isLoggedIn,
              decoration: InputDecoration(
                hintText: isLoggedIn
                    ? "Type message here..."
                    : "Please login to chat",
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isLoggedIn ? Colors.grey : Colors.grey[400],
                ),
              ),
              onSubmitted: isLoggedIn ? (_) => sendMessage() : null,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.mic, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Voice input coming soon")),
              );
            },
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

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }
}