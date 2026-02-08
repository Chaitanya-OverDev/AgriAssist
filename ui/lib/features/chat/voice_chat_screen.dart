import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for exit app
import 'bot_listening_screen.dart';
import './text_chat/text_chat_screen.dart';
import '../../routes/app_routes.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(); // ✅ Exit app on back press
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF8F1),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'AgriAssist',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xFFEAF8F1),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            const SizedBox(width: 12),
          ],
        ),

        body: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔹 TOP OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _optionCard('🌦️ Weather Report'),
                      const SizedBox(width: 12),
                      _optionCard('💰 Bazaar Bhav'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _optionCard('🌱 Crop Advice'),
                      const SizedBox(width: 12),
                      _optionCard('🐄 Livestock Care'),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// 👨‍🌾 FARMER IMAGE
            CircleAvatar(
              radius: 90,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/farmer_character.png',
                height: 130,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Click on mic to start talking...',
              style: TextStyle(color: Colors.black54),
            ),

            const Spacer(),

            /// 🎤 BOTTOM CONTROLS
            SizedBox(
              height: 90,
              width: screenWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// 💬 MESSAGE ICON
                  Positioned(
                    left: screenWidth / 2 - 140,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.message, color: Colors.black87),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TextChatScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  /// 🎤 MIC BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BotListeningScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF0E3D3D),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🔹 OPTION CARD
  Widget _optionCard(String title) {
    return Expanded(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
