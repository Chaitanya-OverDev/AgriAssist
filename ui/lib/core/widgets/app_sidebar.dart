import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../features/chat/text_chat/text_chat_screen.dart';
import '../../l10n/app_localizations.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  List<dynamic> recentChats = [];
  bool isLoading = true;
  bool isNavigating = false;

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
    final loc = AppLocalizations.of(context)!;

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAF8F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.deleteChat, style: const TextStyle(color: Color(0xFF13383A))),
        content: Text(loc.deleteChatConfirm, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.ok, style: const TextStyle(color: Colors.white)),
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
          SnackBar(content: Text(loc.deleteFailed)),
        );
      }
    }
  }

  Future<void> _createNewChat() async {
    final loc = AppLocalizations.of(context)!;

    if (isNavigating) return;
    setState(() => isNavigating = true);

    final newSessionId = await ApiService.createSession(loc.newChat);

    if (!mounted) return;
    setState(() => isNavigating = false);
    Navigator.pop(context);

    if (newSessionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextChatScreen(passedSessionId: newSessionId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.createChatFailed)),
      );
    }
  }

  Future<void> _openChat(int sessionId) async {
    final loc = AppLocalizations.of(context)!;

    if (isNavigating) return;
    setState(() => isNavigating = true);

    final history = await ApiService.getChatHistory(sessionId);

    if (!mounted) return;
    setState(() => isNavigating = false);
    Navigator.pop(context);

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
        SnackBar(content: Text(loc.loadChatFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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

                  _buildMenuItem(Icons.chat_bubble_outline, loc.newChat, _createNewChat),

                  _buildMenuItem(Icons.image_outlined, loc.myGallery, () {}),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          loc.recentChats,
                          style: const TextStyle(
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

                  Expanded(
                    child: isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF13383A),
                      ),
                    )
                        : recentChats.isEmpty
                        ? Center(
                      child: Text(
                        loc.noRecentChats,
                        style: const TextStyle(color: Colors.black54),
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
    final loc = AppLocalizations.of(context)!;

    final int sessionId = chat['id'];
    final String title = chat['title'] ?? loc.newChat;
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
          onTap: () => _openChat(sessionId),
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