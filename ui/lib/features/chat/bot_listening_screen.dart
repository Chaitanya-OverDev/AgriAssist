import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BotListeningScreen extends StatelessWidget {
  const BotListeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          ),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("AgriAssist", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Row(children: [Icon(Icons.notifications_none, size: 30), SizedBox(width: 15), Icon(Icons.settings_outlined, size: 30)]),
              ],
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 100,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, size: 80), // Character placeholder
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Figma ipsum component variant main layer. Pen background comment...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleAction(Icons.chat_bubble_outline),
                _buildMicButton(),
                _buildCircleAction(Icons.close),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return Container(
      height: 90,
      width: 90,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
      child: const Icon(Icons.mic, color: Colors.white, size: 35),
    );
  }

  Widget _buildCircleAction(IconData icon) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.black12,
      child: Icon(icon, color: Colors.black87),
    );
  }
}