import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriassist/features/chat/voice_chat/bot_listening_screen.dart';
import './text_chat/text_chat_screen.dart';
import '../../routes/app_routes.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(); // Exit app on back press
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF8F1),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'AgriAssist',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF13383A),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF13383A), size: 30),
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
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFB5CAC1), width: 20),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/farmer_character.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              'Click on mic to start talking...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            /// 🎤 BOTTOM CONTROLS
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                children: [
                  // CHAT BUTTON (Now on the Left)
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TextChatScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF5FBF9), // Light white shade
                            border: Border.all(color: const Color(0xFFB5CAC1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.message_outlined,
                            color: Color(0xFF13383A),
                            size: 26, // Exact sizing
                          ),
                        ),
                      ),
                    ),
                  ),

                  // MIC BUTTON (Perfectly Centered)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BotListeningScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF13383A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13383A).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 36, // Exact sizing
                      ),
                    ),
                  ),

                  // Right Spacer to keep Mic in the middle
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF13383A),
            ),
          ),
        ),
      ),
    );
  }
}