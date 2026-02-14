import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../features/chat/text_chat/text_chat_screen.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  List<dynamic> recentChats = [];
  bool isLoading = true;
  bool isNavigating = false; // Prevents double-taps while fetching history/creating session

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => isLoading = true);
    final sessions = await ApiService.getUserSessions();
    if (mounted) {
      setState(() {
        recentChats = sessions ?? [];
        isLoading = false;
      });
    }
  }

  Future<void> _confirmAndDelete(int sessionId, int index) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAF8F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Chat?", style: TextStyle(color: Color(0xFF13383A))),
        content: const Text("Are you sure you want to delete this chat history? This cannot be undone.", style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final removedChat = recentChats[index];
      setState(() {
        recentChats.removeAt(index);
      });

      final success = await ApiService.deleteChatSession(sessionId);

      if (!success && mounted) {
        setState(() {
          recentChats.insert(index, removedChat);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete chat. Please try again.")),
        );
      }
    }
  }

  // 🔹 NEW: Handle creating a new chat
  Future<void> _createNewChat() async {
    if (isNavigating) return;
    setState(() => isNavigating = true);

    final newSessionId = await ApiService.createSession("New Chat");

    if (!mounted) return;
    setState(() => isNavigating = false);
    Navigator.pop(context); // Close Drawer

    if (newSessionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextChatScreen(passedSessionId: newSessionId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create new chat session.")),
      );
    }
  }

  // 🔹 NEW: Handle opening an existing chat
  Future<void> _openChat(int sessionId) async {
    if (isNavigating) return;
    setState(() => isNavigating = true);

    final history = await ApiService.getChatHistory(sessionId);

    if (!mounted) return;
    setState(() => isNavigating = false);
    Navigator.pop(context); // Close Drawer

    if (history != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextChatScreen(
            passedSessionId: sessionId,
            passedMessages: history,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load chat history.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // To prevent interactions while loading a chat
    return AbsorbPointer(
      absorbing: isNavigating,
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F1).withOpacity(0.4),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 TOP HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF13383A)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'AgriAssist',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF13383A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔹 MAIN MENU ITEMS
                  _buildMenuItem(
                    Icons.chat_bubble_outline,
                    'New chat',
                    _createNewChat,
                  ),
                  _buildMenuItem(Icons.image_outlined, 'My Gallery', () {
                    // TODO: Navigate to gallery
                  }),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 10),

                  // 🔹 RECENT CHATS TITLE & SPINNER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          'Recent Chats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF13383A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isNavigating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF13383A),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 🔹 RECENT CHATS LIST
                  Expanded(
                    child: isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF13383A),
                      ),
                    )
                        : recentChats.isEmpty
                        ? const Center(
                      child: Text(
                        "No recent chats.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: recentChats.length,
                      itemBuilder: (context, index) {
                        final chat = recentChats[index];
                        return _buildGlassyChatItem(chat, index, context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF13383A)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF13383A),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildGlassyChatItem(dynamic chat, int index, BuildContext context) {
    final int sessionId = chat['id'];
    final String title = chat['title'] ?? 'New Chat';
    final String rawDate = chat['created_at'] ?? '';
    final String timeStr = rawDate.isNotEmpty && rawDate.length > 10
        ? rawDate.substring(0, 10)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openChat(sessionId), // 👈 Triggers fetch & navigate
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF13383A),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  icon: Icon(
                    Icons.close,
                    color: const Color(0xFF13383A).withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: () => _confirmAndDelete(sessionId, index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}