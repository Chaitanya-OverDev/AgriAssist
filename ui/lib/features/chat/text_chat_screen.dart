import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TextChatScreen extends StatelessWidget {
  const TextChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                const Text("AgriAssist", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.notifications_none),
                const SizedBox(width: 15),
                const Icon(Icons.settings_outlined),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildChatBubble("Hello how can i help you today?", isBot: true),
                  _buildChatBubble("Tell me how are you ?", isBot: false),
                  _buildChatBubble("Good what about you?", isBot: true),
                  _buildChatBubble("I am also fine", isBot: false),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(30)),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Type message here",
                        border: InputBorder.none,
                        icon: Icon(Icons.attach_file),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.mic, color: Colors.white)),
                const SizedBox(width: 10),
                const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.send, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isBot}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : const Color(0xFFFFEFBD),
          borderRadius: BorderRadius.circular(20),
          border: isBot ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}